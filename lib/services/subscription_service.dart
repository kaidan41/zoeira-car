import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:zoeira_car/models/subscription_model.dart';
import 'package:zoeira_car/models/user_access_model.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final InAppPurchase _iap;

  static const String _collection = 'subscriptions';
  static const String _usersCollection = 'users';

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  SubscriptionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    InAppPurchase? iap,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _iap = iap ?? InAppPurchase.instance;

  // ─────────────────────────────────────────────
  // FIRESTORE — estado da assinatura
  // ─────────────────────────────────────────────

  /// Retorna o estado atual da assinatura do usuário logado
  Future<SubscriptionModel> getUserSubscription() async {
    final user = _auth.currentUser;
    if (user == null) {
      return SubscriptionModel.empty('anonymous');
    }

    final doc =
        await _firestore.collection(_collection).doc(user.uid).get();

    if (!doc.exists) {
      return SubscriptionModel.empty(user.uid);
    }

    return SubscriptionModel.fromFirestore(doc);
  }

  /// Stream em tempo real do status da assinatura
  Stream<SubscriptionModel> subscriptionStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(SubscriptionModel.empty('anonymous'));
    }

    return _firestore
        .collection(_collection)
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists
            ? SubscriptionModel.fromFirestore(doc)
            : SubscriptionModel.empty(user.uid));
  }

  /// Salva/atualiza a assinatura no Firestore
  Future<void> saveSubscription(SubscriptionModel sub) async {
    await _firestore
        .collection(_collection)
        .doc(sub.userId)
        .set(sub.toFirestore(), SetOptions(merge: true));
  }

  // ─────────────────────────────────────────────
  // FIRESTORE — acesso a consultas (avulsa / grátis diária)
  // ─────────────────────────────────────────────

  /// Retorna o nível de acesso do usuário logado (créditos, desbloqueios, grátis diária)
  Future<UserAccessModel> getUserAccess() async {
    final user = _auth.currentUser;
    if (user == null) return UserAccessModel.empty;

    final doc = await _firestore.collection(_usersCollection).doc(user.uid).get();

    if (!doc.exists) return UserAccessModel.empty;
    return UserAccessModel.fromFirestore(
      doc.data() as Map<String, dynamic>,
    );
  }

  /// Stream em tempo real do acesso do usuário
  Stream<UserAccessModel> accessStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(UserAccessModel.empty);

    return _firestore
        .collection(_usersCollection)
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists
            ? UserAccessModel.fromFirestore(doc.data() as Map<String, dynamic>)
            : UserAccessModel.empty);
  }

  /// Gasta 1 crédito de consulta avulsa para desbloquear um veículo para sempre.
  /// Retorna `true` se o desbloqueio aconteceu, `false` se não há créditos.
  /// Lança exceção se o usuário não estiver logado.
  Future<bool> spendCreditOnVehicle(String vehicleId) async {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(
      code: 'no-user',
      message: 'Faça login para desbloquear a nave.',
    );

    final docRef = _firestore.collection(_usersCollection).doc(user.uid);

    try {
      final unlocked = await _firestore.runTransaction((tx) async {
        final doc = await tx.get(docRef);
        final access = doc.exists
            ? UserAccessModel.fromFirestore(doc.data() as Map<String, dynamic>)
            : UserAccessModel.empty;

        if (access.consultaCredits < 1) return false;
        if (access.isUnlocked(vehicleId)) return true;

        final updated = access.copyWith(
          consultaCredits: access.consultaCredits - 1,
          unlockedVehicleIds: [...access.unlockedVehicleIds, vehicleId],
        );
        tx.set(docRef, updated.toFirestore(), SetOptions(merge: true));
        return true;
      });
      return unlocked;
    } on FirebaseException {
      return false;
    }
  }

  /// Usa a consulta grátis de hoje para desbloquear um veículo.
  /// Retorna `true` se desbloqueou, `false` se a grátis de hoje já foi usada.
  Future<bool> useFreeConsultOnVehicle(String vehicleId) async {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(
      code: 'no-user',
      message: 'Faça login para usar a consulta grátis.',
    );

    final docRef = _firestore.collection(_usersCollection).doc(user.uid);
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final todayKey = '${now.year}-$month-$day';

    try {
      final unlocked = await _firestore.runTransaction((tx) async {
        final doc = await tx.get(docRef);
        final access = doc.exists
            ? UserAccessModel.fromFirestore(doc.data() as Map<String, dynamic>)
            : UserAccessModel.empty;

        if (access.lastFreeDate == todayKey) return false;
        if (access.isUnlocked(vehicleId)) return true;

        final updated = access.copyWith(
          lastFreeDate: todayKey,
          lastFreeVehicleId: vehicleId,
          unlockedVehicleIds: [...access.unlockedVehicleIds, vehicleId],
        );
        tx.set(docRef, updated.toFirestore(), SetOptions(merge: true));
        return true;
      });
      return unlocked;
    } on FirebaseException {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // GOOGLE PLAY BILLING — in_app_purchase
  // ─────────────────────────────────────────────

  /// Verifica se as compras in-app estão disponíveis no dispositivo
  Future<bool> isAvailable() => _iap.isAvailable();

  /// Busca os detalhes do produto de assinatura na Play Store
  Future<ProductDetails?> getSubscriptionProduct() async {
    final response = await _iap.queryProductDetails(
      {SubscriptionPlan.productId},
    );

    if (response.error != null) {
      debugPrint('IAP query error: ${response.error}');
      return null;
    }

    if (response.productDetails.isEmpty) {
      debugPrint('Produto ${SubscriptionPlan.productId} não encontrado na Play Store');
      return null;
    }

    return response.productDetails.first;
  }

  /// Busca os detalhes do produto de consulta avulsa na Play Store
  Future<ProductDetails?> getConsultaProduct() async {
    final response = await _iap.queryProductDetails(
      {ConsultationPlan.productId},
    );

    if (response.error != null) {
      debugPrint('IAP query error: ${response.error}');
      return null;
    }

    if (response.productDetails.isEmpty) {
      debugPrint('Produto ${ConsultationPlan.productId} não encontrado na Play Store');
      return null;
    }

    return response.productDetails.first;
  }

  /// Inicia o fluxo de compra da assinatura
  Future<void> purchaseSubscription(ProductDetails product) async {
    final PurchaseParam purchaseParam;

    if (Platform.isAndroid) {
      purchaseParam = GooglePlayPurchaseParam(
        productDetails: product,
        changeSubscriptionParam: null,
      );
    } else {
      purchaseParam = PurchaseParam(productDetails: product);
    }

    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Restaura compras anteriores (necessário para iOS e útil no Android)
  Future<void> restorePurchases() => _iap.restorePurchases();

  /// Escuta o stream de compras e processa atualizações
  /// [onPurchaseSuccess]: callback chamado quando a compra é confirmada
  /// [onPurchaseError]: callback chamado em caso de erro
  void listenToPurchases({
    required Future<void> Function(PurchaseDetails) onPurchaseSuccess,
    required void Function(String) onPurchaseError,
  }) {
    _purchaseSubscription?.cancel();
    _purchaseSubscription =
        _iap.purchaseStream.listen((purchases) async {
      for (final purchase in purchases) {
        await _handlePurchase(
          purchase,
          onSuccess: onPurchaseSuccess,
          onError: onPurchaseError,
        );
      }
    });
  }

  Future<void> _handlePurchase(
    PurchaseDetails purchase, {
    required Future<void> Function(PurchaseDetails) onSuccess,
    required void Function(String) onError,
  }) async {
    switch (purchase.status) {
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        // Identifica o tipo de produto e entrega o acesso
        await _deliverPurchase(purchase);
        await onSuccess(purchase);
        // Confirma a entrega para o Google Play
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        break;

      case PurchaseStatus.error:
        onError(purchase.error?.message ?? 'Erro desconhecido na compra');
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        break;

      case PurchaseStatus.canceled:
        onError('Compra cancelada pelo usuário');
        break;

      case PurchaseStatus.pending:
        // Aguardando confirmação (ex: boleto) — nada a fazer agora
        break;
    }
  }

  /// Entrega o acesso de acordo com o produto comprado:
  /// consulta avulsa vira crédito, assinatura vira assinatura ativa.
  Future<void> _deliverPurchase(PurchaseDetails purchase) async {
    if (purchase.productID == ConsultationPlan.productId) {
      await _deliverConsultaCredit(purchase);
      return;
    }
    await _deliverSubscription(purchase);
  }

  /// Adiciona 1 crédito de consulta avulsa ao usuário
  Future<void> _deliverConsultaCredit(PurchaseDetails purchase) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore.collection(_usersCollection).doc(user.uid);
    await docRef.set(
      {
        'consulta_credits': FieldValue.increment(1),
        'last_product_id': purchase.productID,
        'last_purchase_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Registra a assinatura no Firestore após compra confirmada
  Future<void> _deliverSubscription(PurchaseDetails purchase) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    // Assinatura mensal: validade de 31 dias (Google Play valida no server-side)
    final expiry = now.add(const Duration(days: 31));

    final sub = SubscriptionModel(
      userId: user.uid,
      status: SubscriptionStatus.active,
      purchaseToken: purchase.verificationData.serverVerificationData,
      productId: purchase.productID,
      startDate: now,
      expiryDate: expiry,
      autoRenewing: true,
    );

    await saveSubscription(sub);
  }

  /// Cancela o listener de compras
  void dispose() {
    _purchaseSubscription?.cancel();
  }
}
