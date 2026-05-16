import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Models/user_model.dart';
import 'package:lingola_buddy/Riverpod/Controllers/UserProfileController/user_profile_controller.dart';

/// Oturumdaki kullanıcı modelinin türevlenmiş görünümü (ekranlar `ref.watch` ile kullanır)
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(userProfileControllerProvider).user;
});
