import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return StubAuthRepository();
});
