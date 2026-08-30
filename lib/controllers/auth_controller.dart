import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum AuthState { idle, loading, authenticated, unauthenticated, error }

class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth;

  AuthController({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance {
    // Escuta mudanças de estado do Firebase em tempo real
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  AuthState _state = AuthState.idle;
  User? _user;
  String? _errorMessage;

  // Getters
  AuthState get state => _state;
  User? get user => _user;
  String? get errorMessage => _errorMessage;

  bool get isLoggedIn => _user != null;
  bool get isLoading => _state == AuthState.loading;
  bool get hasError => _state == AuthState.error;

  String? get displayName => _user?.displayName ?? _user?.email?.split('@').first;
  String? get email => _user?.email;
  String? get photoUrl => _user?.photoURL;

  // ─────────────────────────────────────────────
  // Auth State Listener
  // ─────────────────────────────────────────────

  void _onAuthStateChanged(User? user) {
    _user = user;
    _state = user != null
        ? AuthState.authenticated
        : AuthState.unauthenticated;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // Login com e-mail e senha
  // ─────────────────────────────────────────────

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading();

    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _clearError();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_translateFirebaseError(e.code));
      return false;
    } catch (e) {
      _setError('Erro inesperado. Tente novamente.');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Cadastro com e-mail e senha
  // ─────────────────────────────────────────────

  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Atualiza o nome de exibição
      await credential.user?.updateDisplayName(displayName.trim());
      await credential.user?.reload();

      _clearError();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_translateFirebaseError(e.code));
      return false;
    } catch (e) {
      _setError('Erro inesperado. Tente novamente.');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Recuperação de senha
  // ─────────────────────────────────────────────

  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading();

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _clearError();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_translateFirebaseError(e.code));
      return false;
    } catch (e) {
      _setError('Não foi possível enviar o e-mail. Tente novamente.');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Logout
  // ─────────────────────────────────────────────

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ─────────────────────────────────────────────
  // Helpers internos
  // ─────────────────────────────────────────────

  void _setLoading() {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _state = AuthState.error;
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() => _clearError();

  /// Traduz os códigos de erro do Firebase para PT-BR com linguagem zoeira
  String _translateFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Esse e-mail não tá cadastrado na garagem, não.';
      case 'wrong-password':
        return 'Senha errada! Deu BO no acesso.';
      case 'invalid-credential':
        return 'E-mail ou senha incorretos. Confere aí!';
      case 'email-already-in-use':
        return 'Esse e-mail já tá na garagem. Tenta fazer login!';
      case 'weak-password':
        return 'Essa senha tá fraca demais. Coloca pelo menos 6 caracteres.';
      case 'invalid-email':
        return 'E-mail inválido. Confere o formato e tenta de novo.';
      case 'user-disabled':
        return 'Essa conta foi desativada. Fala com o suporte.';
      case 'too-many-requests':
        return 'Muitas tentativas! Dá um tempo e tenta de novo.';
      case 'network-request-failed':
        return 'Sem conexão. Verifica a internet e tenta de novo.';
      case 'operation-not-allowed':
        return 'Este método de login não está habilitado.';
      default:
        return 'Deu BO: $code. Tenta de novo!';
    }
  }
}
