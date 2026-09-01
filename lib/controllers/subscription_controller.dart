import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:zoeira_car/controllers/auth_controller.dart';
import 'package:zoeira_car/models/subscription_model.dart';
import 'package:zoeira_car/models/user_access_model.dart';
import 'package:zoeira_car/services/subscription_service.dart';

enum SubscriptionLoadState { idle, loading, purchasing, restoring, loaded, error }

class SubscriptionController extends ChangeNotifier {
  final SubscriptionService _service;
  AuthController? _auth;

  SubscriptionController({SubscriptionService? service})
      : _service = service ?? SubscriptionService() {
    _init();
  }

  SubscriptionLoadState _state = SubscriptionLoadState.idle;
  SubscriptionModel? _subscription;
  UserAccessModel? _access;
  ProductDetails? _product;
  ProductDetails? _consultaProduct;
  String? _errorMessage;
  String? _successMessage;
  bool _iapAvailable = false;
  bool _creditUnlocking = false;
  bool _consultaPurchasing = false;
  String? _pendingUnlockVehicleId;

  // Getters
  SubscriptionLoadState get state => _state;
  SubscriptionModel? get subscription => _subscription;
  ProductDetails? get product => _product;
  ProductDetails? get consultaProduct => _consultaProduct;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get iapAvailable => _iapAvailable;

  UserAccessModel get access => _access ?? UserAccessModel.empty;
  int get credits => access.consultaCredits;

  bool get isLoading => _state == SubscriptionLoadState.loading;
  bool get isPurchasing => _state == SubscriptionLoadState.purchasing;
  bool get isRestoring => _state == SubscriptionLoadState.restoring;
  bool get isSubscriber => _subscription?.isValid ?? false;
  bool get isCreditUnlocking => _creditUnlocking;
  bool get isConsultaPurchasing => _consultaPurchasing;

  /// Esse veículo já está desbloqueado (assinatura ou avulsa paga)?
  bool isUnlocked(String vehicleId) {
    if (isSubscriber) return true;
    return access.isUnlocked(vehicleId);
  }

  // ─────────────────────────────────────────────
  // Inicialização
  // ─────────────────────────────────────────────

  Future<void> _init() async {
    _state = SubscriptionLoadState.loading;
    notifyListeners();

    try {
      _iapAvailable = await _service.isAvailable();

      // Revalida o acesso com o Google Play (fonte da verdade no servidor)
      await _service.refreshEntitlements();

      // Carrega estado da assinatura e acesso do Firestore
      _subscription = await _service.getUserSubscription();
      _access = await _service.getUserAccess();

      // Carrega produtos da Play Store (em paralelo, não bloqueia)
      if (_iapAvailable) {
        _product = await _service.getSubscriptionProduct();
        _consultaProduct = await _service.getConsultaProduct();

        // Registra listener de compras
        _service.listenToPurchases(
          onPurchaseSuccess: _onPurchaseSuccess,
          onPurchaseError: _onPurchaseError,
        );
      }

      _state = SubscriptionLoadState.loaded;
    } catch (e) {
      _state = SubscriptionLoadState.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  // Chamado pelo ProxyProvider quando AuthController muda
  void updateAuth(AuthController auth) {
    _auth = auth;
    if (auth.isLoggedIn) {
      reload();
    } else {
      _subscription = null;
      _access = null;
      _pendingUnlockVehicleId = null;
      notifyListeners();
    }
  }

  /// Recarrega o estado da assinatura e do acesso (ex: ao voltar da tela de pagamento)
  Future<void> reload() async {
    try {
      await _service.refreshEntitlements();
      _subscription = await _service.getUserSubscription();
      _access = await _service.getUserAccess();
      notifyListeners();
    } catch (_) {}
  }

  // ─────────────────────────────────────────────
  // Consulta avulsa (R$ 5)
  // ─────────────────────────────────────────────

  /// Desbloqueia 1 veículo por R$ 5: usa um crédito existente ou
  /// inicia a compra da consulta avulsa na Play Store.
  Future<bool> unlockOne(String vehicleId) async {
    if (_auth == null || !_auth!.isLoggedIn) {
      _setError('Faça login para desbloquear a nave 🚗');
      return false;
    }

    if (isUnlocked(vehicleId)) return true;

    if (credits > 0) {
      _creditUnlocking = true;
      notifyListeners();
      try {
        final ok = await _service.spendCreditOnVehicle(vehicleId);
        await reload();
        if (ok) {
          _successMessage = 'Nave desbloqueada por consulta avulsa! 🚀';
        }
        return ok;
      } catch (e) {
        _setError(_friendlyError(e));
        return false;
      } finally {
        _creditUnlocking = false;
        notifyListeners();
      }
    }

    // Sem crédito: compra a consulta avulsa e desbloqueia este veículo ao concluir
    if (_consultaProduct == null) {
      _setError('Produto de consulta indisponível no momento. Tente mais tarde.');
      return false;
    }

    if (!_iapAvailable) {
      _setError('Compras in-app não estão disponíveis neste dispositivo.');
      return false;
    }

    _pendingUnlockVehicleId = vehicleId;
    _consultaPurchasing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.purchaseSubscription(_consultaProduct!);
      return false; // resultado chega via _onPurchaseSuccess
    } catch (e) {
      _pendingUnlockVehicleId = null;
      _consultaPurchasing = false;
      _setError(_friendlyError(e));
      return false;
    }
  }

  /// Compra o plano de assinatura mensal
  Future<void> purchase() async {
    if (_auth == null || !_auth!.isLoggedIn) {
      _setError('Faça login para assinar o plano 🚗');
      return;
    }

    if (_product == null) {
      _setError('Produto não disponível no momento. Tente novamente mais tarde.');
      return;
    }

    if (!_iapAvailable) {
      _setError('Compras in-app não estão disponíveis neste dispositivo.');
      return;
    }

    _state = SubscriptionLoadState.purchasing;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _service.purchaseSubscription(_product!);
      // O resultado chega via _onPurchaseSuccess / _onPurchaseError
    } catch (e) {
      _setError(_friendlyError(e));
    }
  }

  // ─────────────────────────────────────────────
  // Restaurar compras
  // ─────────────────────────────────────────────

  Future<void> restorePurchases() async {
    _state = SubscriptionLoadState.restoring;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _service.restorePurchases();
      // Resultado chega via listener de compras
    } catch (e) {
      _setError('Não foi possível restaurar as compras: ${e.toString()}');
    }
  }

  // ─────────────────────────────────────────────
  // Callbacks internos
  // ─────────────────────────────────────────────

  Future<void> _onPurchaseSuccess(PurchaseDetails purchase) async {
    await reload();

    if (purchase.productID == ConsultationPlan.productId) {
      // Consulta avulsa comprada: desbloqueia o veículo pendente com o crédito
      final pending = _pendingUnlockVehicleId;
      if (pending != null && credits > 0) {
        _pendingUnlockVehicleId = null;
        final ok = await _service.spendCreditOnVehicle(pending);
        await reload();
        _successMessage = ok
            ? 'Nave desbloqueada por consulta avulsa! 🚀'
            : 'Consulta avulsa adquirida! Escolha a nave no raio-x.';
      } else {
        _successMessage = 'Consulta avulsa adquirida! Escolha a nave no raio-x.';
      }
      _consultaPurchasing = false;
    } else {
      _successMessage = 'Capivara da sua nave puxada! 🦫🚀';
    }

    _state = SubscriptionLoadState.loaded;
    _errorMessage = null;
    notifyListeners();
  }

  void _onPurchaseError(String message) {
    _consultaPurchasing = false;
    _setError(message);
  }

  String _friendlyError(Object e) {
    final message = e.toString();
    if (message.contains('no-user')) return 'Faça login para desbloquear a nave.';
    return 'Falha na operação: $message';
  }

  void _setError(String message) {
    _state = SubscriptionLoadState.loaded;
    _errorMessage = message;
    _successMessage = null;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}