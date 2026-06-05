import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Riverpod/Controllers/SessionController/session_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/UserProfileController/user_profile_controller.dart';

/// Oturum açık ve geçerli API kullanıcı kimliği. Değişince hesaba özel provider'lar yenilenir.
final authenticatedUserIdProvider = Provider<String?>((ref) {
  final session = ref.watch(sessionControllerProvider);
  if (!session.isAuthenticated) return null;

  final userId = ref.watch(
    userProfileControllerProvider.select((s) => s.user?.id),
  );
  if (userId == null || userId.isEmpty || userId == 'local') return null;
  return userId;
});
