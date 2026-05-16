import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Models/app_enums.dart';
import 'package:lingola_buddy/Models/user_model.dart';

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
    return UserProfileState(
      notificationsEnabled: true,
      showPremiumUpsellSeen: false,
      user: const UserModel(
        id: 'local',
        displayName: 'Lingola Kullanıcısı',
        email: 'kullanici@ornek.com',
        learnLanguageCode: 'en',
        nativeLanguageCode: 'tr',
        proficiency: ProficiencyLevel.simple,
        dailyGoal: DailyGoalBucket.medium,
      ),
    );
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
        UserProfileController.new);
