import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Services/user_profile_api_service.dart';

final userProfileApiProvider = Provider<UserProfileApiService>((ref) {
  return UserProfileApiService();
});
