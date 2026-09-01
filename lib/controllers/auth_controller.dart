import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum AuthState { idle, loading, authenticated, unauthenticated, error }

class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthController({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance {
    // Inicializa o usuário de forma síncrona
    _user = _auth.currentUser;
    _state = _user != null
        ? AuthState.authenticated
        : AuthState.unauthenticated;

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

  static const List<String> adminEmails = [
    'mltecno@hotmail.com',
    'zoeiracarcontato@gmail.com',
  ];

  bool get isLoggedIn => _user != null;
  bool get isAdmin =>
      _user != null &&
      adminEmails.contains(_user!.email?.toLowerCase().trim());
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
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      _user = credential.user ?? _auth.currentUser;

      // Garante ou atualiza o registro do usuário no Firestore
      if (_user != null) {
        try {
          await _firestore.collection('users').doc(_user!.uid).set({
            'uid': _user!.uid,
            'email': email.trim(),
            'displayName': _user!.displayName ?? email.trim().split('@').first,
            'last_login_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Aviso: Falha ao atualizar dados de login no Firestore: $e');
        }
      }

      _clearError();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_translateFirebaseError(e.code));
      return false;
    } catch (e) {
      _setError('Erro ao entrar: $e');
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

      final user = credential.user;
      if (user != null) {
        // Atualiza o nome de exibição no Firebase Auth
        await user.updateDisplayName(displayName.trim());
        await user.reload();
        _user = _auth.currentUser;

        // Grava o documento do usuário no Firestore com perfil inicial
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'displayName': displayName.trim(),
          'email': email.trim(),
          'unlocked_vehicle_ids': <String>[],
          'consulta_credits': 0,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'last_login_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      _clearError();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_translateFirebaseError(e.code));
      return false;
    } catch (e) {
      _setError('Erro ao criar conta: $e');
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
      _setError('Não foi possível enviar o e-mail: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Logout
  // ─────────────────────────────────────────────

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // Atualizar Avatar / Foto de Perfil
  // ─────────────────────────────────────────────

  Future<bool> updateAvatar(String avatarUrl) async {
    final current = _auth.currentUser;
    if (current == null) return false;

    try {
      await current.updatePhotoURL(avatarUrl);
      await _firestore.collection('users').doc(current.uid).set({
        'photo_url': avatarUrl,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _user = _auth.currentUser;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
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

  /// Traduz os códigos de erro do Firebase para PT-BR com linguagem amigável e zoeira
  String _translateFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Esse e-mail não tá cadastrado na garagem. Que tal criar uma conta?';
      case 'wrong-password':
        return 'Senha incorreta! Dá uma conferida e tenta de novo.';
      case 'invalid-credential':
        return 'E-mail ou senha incorretos. Confere aí!';
      case 'email-already-in-use':
        return 'Esse e-mail já tá cadastrado na garagem. Tenta fazer login!';
      case 'weak-password':
        return 'Essa senha tá fraca demais. Coloca pelo menos 6 caracteres.';
      case 'invalid-email':
        return 'E-mail inválido. Confere o formato (ex: nome@email.com).';
      case 'user-disabled':
        return 'Essa conta foi desativada. Fala com o suporte.';
      case 'too-many-requests':
        return 'Muitas tentativas em sequência! Aguarde alguns minutos e tente de novo.';
      case 'network-request-failed':
        return 'Sem conexão com a internet. Verifica sua rede e tenta de novo.';
      case 'operation-not-allowed':
        return 'O login com E-mail/Senha não está ativado no Firebase Console (Authentication > Sign-in method).';
      case 'channel-error':
        return 'Preencha todos os campos corretamente.';
      default:
        return 'Erro ($code). Verifique os dados e tente novamente.';
    }
  }
}
