import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lingola_buddy/Models/app_enums.dart';
import 'package:lingola_buddy/Models/user_model.dart';
import 'package:lingola_buddy/Services/profile_photo_service.dart';
import 'package:lingola_buddy/Services/profile_photo_storage.dart';

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
    Future.microtask(_hydrateStoredAvatar);
    return UserProfileState(
      notificationsEnabled: true,
      showPremiumUpsellSeen: false,
      user: const UserModel(
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

  Future<void> _hydrateStoredAvatar() async {
    final path = await ProfilePhotoStorage.readPath();
    if (path == null) return;
    final current = state.user;
    if (current == null) return;
    state = state.copyWith(user: current.copyWith(avatarUrl: path));
  }

  void applyOnboardingPrefs({
    required String learnLanguageCode,
    required String nativeLanguageCode,
    required ProficiencyLevel proficiency,
    required DailyGoalBucket dailyGoal,
  }) {
    final current = state.user;
    if (current == null) return;
    state = state.copyWith(
      user: current.copyWith(
        learnLanguageCode: learnLanguageCode,
        nativeLanguageCode: nativeLanguageCode,
        proficiency: proficiency,
        dailyGoal: dailyGoal,
      ),
    );
  }

  void updateDisplayName(String name) {
    final current = state.user;
    if (current == null) return;
    state = state.copyWith(user: current.copyWith(displayName: name));
  }

  Future<bool> updateProfilePhoto(ImageSource source) async {
    final current = state.user;
    if (current == null) return false;

    final path = await _photos.pickAndPersist(
      source: source,
      previousPath: current.avatarUrl,
    );
    if (path == null) return false;

    state = state.copyWith(user: current.copyWith(avatarUrl: path));
    return true;
  }

  Future<void> removeProfilePhoto() async {
    final current = state.user;
    if (current == null) return;

    await _photos.removeStoredPhoto(current.avatarUrl);
    state = state.copyWith(user: current.copyWith(clearAvatar: true));
  }

  void toggleNotifications(bool value) {
    state = state.copyWith(notificationsEnabled: value);
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
