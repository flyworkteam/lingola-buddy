import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lingola_buddy/Models/app_enums.dart';
import 'package:lingola_buddy/Models/lesson_model.dart';
import 'package:lingola_buddy/Models/user_model.dart';
import 'package:lingola_buddy/Riverpod/Providers/notifications_initial_enabled_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/ui_language_initial_code_provider.dart';
import 'package:lingola_buddy/Services/notification_permission_service.dart';
import 'package:lingola_buddy/Services/local_notification_scheduler.dart';
import 'package:lingola_buddy/Services/session_local_storage.dart';
import 'package:lingola_buddy/Riverpod/Providers/user_profile_api_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/user_profile_initial_user_provider.dart';
import 'package:lingola_buddy/Services/http_api_service.dart';
import 'package:lingola_buddy/Services/profile_photo_service.dart';
import 'package:lingola_buddy/Services/user_profile_api_service.dart';

final profilePhotoServiceProvider = Provider<ProfilePhotoService>((ref) {
  return ProfilePhotoService();
});

class UserProfileState {
  const UserProfileState({
    required this.notificationsEnabled,
    required this.showPremiumUpsellSeen,
    this.user,
    this.uiLanguageCode = 'tr',
  });

  final UserModel? user;
  final bool notificationsEnabled;
  final bool showPremiumUpsellSeen;
  final String uiLanguageCode;

  UserProfileState copyWith({
    UserModel? user,
    bool? notificationsEnabled,
    bool? showPremiumUpsellSeen,
    String? uiLanguageCode,
  }) {
    return UserProfileState(
      user: user ?? this.user,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      showPremiumUpsellSeen:
          showPremiumUpsellSeen ?? this.showPremiumUpsellSeen,
      uiLanguageCode: uiLanguageCode ?? this.uiLanguageCode,
    );
  }
}

class UserProfileController extends Notifier<UserProfileState> {
  @override
  UserProfileState build() {
    final restored = ref.watch(userProfileInitialUserProvider);
    final uiLanguageCode = ref.watch(uiLanguageInitialCodeProvider);
    final notificationsEnabled = ref.watch(notificationsInitialEnabledProvider);
    return UserProfileState(
      notificationsEnabled: notificationsEnabled,
      showPremiumUpsellSeen: false,
      uiLanguageCode: uiLanguageCode,
      user: restored ??
          const UserModel(
            id: 'local',
            displayName: 'Emrah D.',
            email: 'emrah12345@gmail.com',
            learnLanguageCode: 'en',
            nativeLanguageCode: 'tr',
            proficiency: ProficiencyLevel.simple,
            dailyGoal: DailyGoalBucket.medium,
          ),
    );
  }

  ProfilePhotoService get _photos => ref.read(profilePhotoServiceProvider);

  UserProfileApiService get _profileApi => ref.read(userProfileApiProvider);

  void setAuthenticatedUser(UserModel user) {
    state = state.copyWith(user: user);
  }

  void clearUser() {
    state = state.copyWith(
      user: const UserModel(
        id: 'local',
        displayName: 'Lingola User',
        email: '',
        learnLanguageCode: 'en',
        nativeLanguageCode: 'tr',
      ),
    );
  }

  void applyOnboardingPrefs({
    required String learnLanguageCode,
    required String nativeLanguageCode,
    CefrLevel? cefrLevel,
    ProficiencyLevel? proficiency,
    required DailyGoalBucket dailyGoal,
  }) {
    final current = state.user;
    if (current == null) return;
    state = state.copyWith(
      user: current.copyWith(
        learnLanguageCode: learnLanguageCode,
        nativeLanguageCode: nativeLanguageCode,
        cefrLevel: cefrLevel,
        proficiency: proficiency,
        dailyGoal: dailyGoal,
      ),
    );
  }

  Future<void> saveDisplayName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ApiException('Name cannot be empty');
    }

    final current = state.user;
    if (current == null) return;

    if (current.id == 'local') {
      state = state.copyWith(user: current.copyWith(displayName: trimmed));
      return;
    }

    final updated = await _profileApi.updateUsername(trimmed);
    state = state.copyWith(user: updated);
  }

  Future<bool> updateProfilePhoto(ImageSource source) async {
    final current = state.user;
    if (current == null) return false;

    final localPath = await _photos.pickImagePath(source);
    if (localPath == null) return false;

    final updated = await _profileApi.uploadProfilePhoto(localPath);
    state = state.copyWith(user: updated);
    return true;
  }

  Future<void> removeProfilePhoto() async {
    final current = state.user;
    if (current == null) return;

    final updated = await _profileApi.removeProfilePhoto();
    state = state.copyWith(user: updated);
  }

  /// Açık: izin ister. Kapalı: yalnızca tercihi kaydeder.
  /// Dönüş: izin verildi mi (kapalıda her zaman `false`).
  Future<bool> setNotificationsEnabled(bool value) async {
    if (!value) {
      await SessionLocalStorage.setNotificationsEnabled(false);
      state = state.copyWith(notificationsEnabled: false);
      await LocalNotificationScheduler.instance.cancelAll();
      return false;
    }

    final granted = await NotificationPermissionService.request();
    await SessionLocalStorage.setNotificationsEnabled(granted);
    state = state.copyWith(notificationsEnabled: granted);
    if (granted) {
      await LocalNotificationScheduler.instance.syncEnabled(enabled: true);
    } else {
      await LocalNotificationScheduler.instance.cancelAll();
    }
    return granted;
  }

  Future<bool> isNotificationPermissionPermanentlyDenied() {
    return NotificationPermissionService.isPermanentlyDenied();
  }

  void setUiLanguageCode(String code) {
    state = state.copyWith(uiLanguageCode: code);
  }

  Future<void> loadFromStubRepository() async {
    // Şimdilik iskelet: AuthRepository entegrasyonu için yer tutucu
  }
}

final userProfileControllerProvider =
    NotifierProvider<UserProfileController, UserProfileState>(
      UserProfileController.new,
    );
