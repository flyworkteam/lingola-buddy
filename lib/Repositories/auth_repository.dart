import 'package:lingola_buddy/Services/lingola_auth_service.dart';

abstract class AuthRepository {
  Future<AuthResult> signInWithGoogle();
  Future<AuthResult> signInWithApple();
  Future<AuthResult> signInAsGuest();
  Future<AuthResult?> restoreSession();
  Future<void> signOut();
  Future<void> deleteAccount();
}

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._auth);

  final LingolaAuthService _auth;

  @override
  Future<AuthResult> signInWithGoogle() => _auth.signInWithGoogle();

  @override
  Future<AuthResult> signInWithApple() => _auth.signInWithApple();

  @override
  Future<AuthResult> signInAsGuest() => _auth.signInAsGuest();

  @override
  Future<AuthResult?> restoreSession() => _auth.restoreSession();

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> deleteAccount() => _auth.deleteAccount();
}
