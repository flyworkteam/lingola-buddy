import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lingola_buddy/Models/app_enums.dart';
import 'package:lingola_buddy/Models/lesson_model.dart';
import 'package:lingola_buddy/Models/user_model.dart';
import 'package:lingola_buddy/Services/device_id_service.dart';
import 'package:lingola_buddy/Services/google_sign_in_config.dart';
import 'package:lingola_buddy/Services/http_api_service.dart';
import 'package:lingola_buddy/Services/revenuecat_service.dart';
import 'package:lingola_buddy/Services/session_local_storage.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthResult {
  const AuthResult({required this.user, required this.token});

  final UserModel user;
  final String token;
}

class LingolaAuthService {
  LingolaAuthService({HttpApiService? http}) : _http = http ?? HttpApiService();

  final HttpApiService _http;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = createConfiguredGoogleSignIn();

  Future<AuthResult> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw ApiException('Google ile giriş iptal edildi');
      }

      final auth = await account.authentication;
      if (auth.idToken == null || auth.idToken!.isEmpty) {
        throw ApiException('Google ID token alınamadı');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      final userCred = await _firebaseAuth.signInWithCredential(credential);
      return _exchangeFirebaseToken(userCred, credentialType: 'google');
    } on PlatformException catch (e) {
      debugPrint('Google Sign-In PlatformException: ${e.code} ${e.message}');
      throw ApiException(e.message ?? 'Google ile giriş başarısız');
    } catch (e, st) {
      debugPrint('Google Sign-In error: $e\n$st');
      if (e is ApiException) rethrow;
      throw ApiException('Google ile giriş başarısız: $e');
    }
  }

  Future<AuthResult> signInWithApple() async {
    try {
      final available = await SignInWithApple.isAvailable();
      if (!available) {
        throw ApiException('Apple ile giriş bu cihazda kullanılamıyor');
      }

      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = apple.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw ApiException('Apple kimlik jetonu alınamadı');
      }

      final oauth = OAuthProvider('apple.com').credential(
        idToken: idToken,
        accessToken: apple.authorizationCode,
      );
      final userCred = await _firebaseAuth.signInWithCredential(oauth);
      return _exchangeFirebaseToken(userCred, credentialType: 'apple');
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw ApiException('Apple ile giriş iptal edildi');
      }
      debugPrint('Apple Sign-In: ${e.code} ${e.message}');
      throw ApiException(e.message);
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Apple auth: ${e.code} ${e.message}');
      throw ApiException(e.message ?? 'Apple ile giriş başarısız');
    } on PlatformException catch (e) {
      debugPrint('Apple Sign-In PlatformException: ${e.code} ${e.message}');
      throw ApiException(e.message ?? 'Apple ile giriş başarısız');
    } catch (e, st) {
      debugPrint('Apple Sign-In error: $e\n$st');
      if (e is ApiException) rethrow;
      throw ApiException('Apple ile giriş başarısız: $e');
    }
  }

  Future<AuthResult> signInAsGuest() async {
    final deviceId = await DeviceIdService.getStableDeviceId();
    final envelope = await _http.post(
      '/auth/guest',
      body: {'deviceId': deviceId},
    );
    return _parseAuthData(envelope['data'] as Map<String, dynamic>);
  }

  Future<AuthResult?> restoreSession() async {
    final token = await SessionLocalStorage.getAuthToken();
    if (token == null || token.isEmpty) return null;

    try {
      final envelope = await _http.get('/auth/me');
      final data = envelope['data'] as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>;
      return AuthResult(
        user: mapApiUser(userJson),
        token: token,
      );
    } catch (_) {
      await SessionLocalStorage.clearAuth();
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _http.post('/auth/logout', authenticated: true);
    } catch (_) {}

    await RevenueCatService.instance.logOut();
    await SessionLocalStorage.clearAuth();
    await _firebaseAuth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  Future<void> deleteAccount() async {
    await _http.delete('/auth/account', authenticated: true);
    await _deleteFirebaseUserIfPresent();
    await _clearLocalAuth();
  }

  Future<void> _deleteFirebaseUserIfPresent() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase user.delete: ${e.code} ${e.message}');
    } catch (e) {
      debugPrint('Firebase user.delete failed: $e');
    }
  }

  Future<void> _clearLocalAuth() async {
    await RevenueCatService.instance.logOut();
    await SessionLocalStorage.clearAuth();
    try {
      await _firebaseAuth.signOut();
    } catch (_) {}
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  Future<AuthResult> _exchangeFirebaseToken(
    UserCredential userCred, {
    required String credentialType,
  }) async {
    final idToken = await userCred.user?.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw ApiException('Firebase ID token missing');
    }

    final envelope = await _http.post(
      '/auth/firebase',
      body: {'idToken': idToken},
    );
    return _parseAuthData(envelope['data'] as Map<String, dynamic>);
  }

  Future<AuthResult> _parseAuthData(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    final userJson = data['user'] as Map<String, dynamic>;
    final user = mapApiUser(userJson);
    final credential = userJson['credential'] as String? ?? 'guest';

    await SessionLocalStorage.saveAuth(
      token: token,
      userId: user.id,
      credential: credential,
    );
    await RevenueCatService.instance.syncUserIdentity(user.id);

    return AuthResult(user: user, token: token);
  }

  UserModel mapApiUser(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final username = json['username'] as String? ?? 'Lingola User';
    final email = (json['credentialData'] as Map<String, dynamic>?)?['email']
            as String? ??
        '';
    final photo = json['profilePhotoUrl'] as String?;
    final nativeLang = json['nativeLang'] as String?;

    final profRaw = json['proficiency'] as String?;
    final cefr = CefrLevel.fromCode(profRaw) ??
        CefrLevel.fromLegacyProficiency(profRaw);

    return UserModel(
      id: id,
      displayName: username,
      email: email,
      avatarUrl: photo,
      nativeLanguageCode: nativeLang,
      learnLanguageCode: json['learnLanguageCode'] as String? ?? 'en',
      proficiency: _legacyProficiency(profRaw),
      cefrLevel: cefr,
      currentLessonId: json['currentLessonId'] as String?,
      dailyGoal: _dailyGoalFrom(json['dailyGoal'] as String?),
    );
  }

  ProficiencyLevel? _legacyProficiency(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'none':
        return ProficiencyLevel.none;
      case 'simple':
        return ProficiencyLevel.simple;
      case 'fluent':
        return ProficiencyLevel.fluent;
      default:
        return null;
    }
  }

  DailyGoalBucket? _dailyGoalFrom(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'short':
        return DailyGoalBucket.short;
      case 'medium':
        return DailyGoalBucket.medium;
      case 'long':
        return DailyGoalBucket.long;
      default:
        return null;
    }
  }
}
