import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Repositories/auth_repository.dart';
import 'package:lingola_buddy/Riverpod/Providers/lingola_auth_service_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ApiAuthRepository(ref.watch(lingolaAuthServiceProvider));
});
