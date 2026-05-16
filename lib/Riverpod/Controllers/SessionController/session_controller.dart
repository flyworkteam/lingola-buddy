import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionState {
  const SessionState({
    this.hasCompletedIntroCarousel = false,
    this.hasCompletedPreferenceWizard = false,
    this.hasCompletedPostCallUpsell = false,
    this.isAuthenticated = false,
  });

  final bool hasCompletedIntroCarousel;
  final bool hasCompletedPreferenceWizard;
  final bool hasCompletedPostCallUpsell;
  final bool isAuthenticated;

  SessionState copyWith({
    bool? hasCompletedIntroCarousel,
    bool? hasCompletedPreferenceWizard,
    bool? hasCompletedPostCallUpsell,
    bool? isAuthenticated,
  }) {
    return SessionState(
      hasCompletedIntroCarousel:
          hasCompletedIntroCarousel ?? this.hasCompletedIntroCarousel,
      hasCompletedPreferenceWizard:
          hasCompletedPreferenceWizard ?? this.hasCompletedPreferenceWizard,
      hasCompletedPostCallUpsell:
          hasCompletedPostCallUpsell ?? this.hasCompletedPostCallUpsell,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() => const SessionState();

  void markIntroCarouselCompleted() {
    state = state.copyWith(hasCompletedIntroCarousel: true);
  }

  void markPreferenceWizardCompleted() {
    state = state.copyWith(hasCompletedPreferenceWizard: true);
  }

  void markPostCallUpsellCompleted() {
    state = state.copyWith(hasCompletedPostCallUpsell: true);
  }

  void markAuthenticated(bool value) {
    state = state.copyWith(isAuthenticated: value);
  }

  void resetOnboardingDemo() {
    state = const SessionState();
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
