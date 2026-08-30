import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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

  /// Revalida o acesso com a Cloud Function (source of truth = Google Play)
  /// e atualiza o Firestore quando necessário. Usado no start e no restore.
  Future<void> refreshEntitlements() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await FirebaseFunctions.instance
          .httpsCallable('verifyEntitlements')
          .call();
    } catch (_) {
      // Refresh é best-effort: falhas não derrubam o app.
    }
  }

  // ─────────────────────────────────────────────
  // FIRESTORE — acesso a consultas (avulsa)
  // ─────────────────────────────────────────────

  /// Retorna o nível de acesso do usuário logado (créditos, desbloqueios)
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
  /// A transação roda na Cloud Function `unlockVehicle` (fonte da verdade no
  /// servidor, não confiável no cliente). Retorna `true` se desbloqueou,
  /// `false` se não há créditos.
  /// Lança exceção se o usuário não estiver logado.
  Future<bool> spendCreditOnVehicle(String vehicleId) async {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(
      code: 'no-user',
      message: 'Faça login para desbloquear a nave.',
    );

    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('unlockVehicle')
          .call({'vehicleId': vehicleId});
      final data = result.data as Map<String, dynamic>;
      return data['unlocked'] == true;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition') return false; // sem créditos
      rethrow;
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
        // Entrega o acesso validando o recibo na Cloud Function
        try {
          await _deliverPurchase(purchase);
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          await onSuccess(purchase);
        } on FirebaseFunctionsException catch (e) {
          if (e.code == 'failed-precondition') {
            // Pagamento pendente: não confirma, a Play reentrega ao concluir
            onError(e.message ?? 'Pagamento pendente na Play Store.');
            return;
          }
          onError(e.code == 'unauthenticated'
              ? 'Faça login para validar a compra.'
              : e.message ?? 'Falha ao validar a compra na Play Store.');
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
        } catch (e) {
          onError('Falha ao confirmar a compra: $e');
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
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

  /// Envia o recibo da compra para a Cloud Function `completePurchase`,
  /// que valida o token na API do Google Play e concede o acesso no
  /// Firestore (assinatura vigente ou +1 crédito de consulta).
  Future<void> _deliverPurchase(PurchaseDetails purchase) async {
    final token = purchase.verificationData.serverVerificationData;
    if (token.isEmpty) {
      debugPrint(
          'Compra sem token de verificação — não dá pra validar no servidor.');
      return;
    }
    await FirebaseFunctions.instance
        .httpsCallable('completePurchase')
        .call({
      'productId': purchase.productID,
      'purchaseToken': token,
    });
  }

  /// Cancela o listener de compras
  void dispose() {
    _purchaseSubscription?.cancel();
  }
}
