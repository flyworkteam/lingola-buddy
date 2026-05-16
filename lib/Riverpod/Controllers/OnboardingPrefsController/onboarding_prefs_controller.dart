import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Models/app_enums.dart';

class OnboardingPrefsState {
  const OnboardingPrefsState({
    this.nativeLanguageCode,
    this.learnLanguageCode,
    this.proficiency,
    this.dailyGoal,
  });

  final String? nativeLanguageCode;
  final String? learnLanguageCode;
  final ProficiencyLevel? proficiency;
  final DailyGoalBucket? dailyGoal;

  OnboardingPrefsState copyWith({
    String? nativeLanguageCode,
    String? learnLanguageCode,
    ProficiencyLevel? proficiency,
    DailyGoalBucket? dailyGoal,
  }) {
    return OnboardingPrefsState(
      nativeLanguageCode: nativeLanguageCode ?? this.nativeLanguageCode,
      learnLanguageCode: learnLanguageCode ?? this.learnLanguageCode,
      proficiency: proficiency ?? this.proficiency,
      dailyGoal: dailyGoal ?? this.dailyGoal,
    );
  }
}

/// Dil / seviye / günlük hedef adımları için geçici seçimler (ileride API’ye yazılır)
class OnboardingPrefsController extends Notifier<OnboardingPrefsState> {
  @override
  OnboardingPrefsState build() => const OnboardingPrefsState();

  void selectNativeLanguage(String code) {
    state = state.copyWith(nativeLanguageCode: code);
  }

  void selectLearnLanguage(String code) {
    state = state.copyWith(learnLanguageCode: code);
  }

  void selectProficiency(ProficiencyLevel level) {
    state = state.copyWith(proficiency: level);
  }

  void selectDailyGoal(DailyGoalBucket bucket) {
    state = state.copyWith(dailyGoal: bucket);
  }
}

final onboardingPrefsControllerProvider =
    NotifierProvider<OnboardingPrefsController, OnboardingPrefsState>(
        OnboardingPrefsController.new);
