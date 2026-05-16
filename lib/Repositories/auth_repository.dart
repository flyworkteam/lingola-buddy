import 'package:lingola_buddy/Models/user_model.dart';

/// Kimlik doğrulama için depo katmanı iskeleti (Google/Apple vb. daha sonra bağlanır)
abstract class AuthRepository {
  Future<UserModel?> fetchCurrentUser();
  Future<UserModel?> signOut();
}

class StubAuthRepository implements AuthRepository {
  @override
  Future<UserModel?> fetchCurrentUser() async {
    return const UserModel(
      id: 'demo',
      displayName: 'Örnek Kullanıcı',
      email: 'ornek@lingola.dev',
      learnLanguageCode: 'en',
    );
  }

  @override
  Future<UserModel?> signOut() async => null;
}
