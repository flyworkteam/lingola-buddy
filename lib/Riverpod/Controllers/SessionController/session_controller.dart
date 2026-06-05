import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Riverpod/Providers/session_initial_state_provider.dart';
import 'package:lingola_buddy/Services/session_local_storage.dart';

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
  SessionState build() => ref.watch(sessionInitialStateProvider);

  Future<void> markIntroCarouselCompleted() async {
    state = state.copyWith(hasCompletedIntroCarousel: true);
    await SessionLocalStorage.setIntroCarouselCompleted(true);
  }

  Future<void> markPreferenceWizardCompleted() async {
    state = state.copyWith(hasCompletedPreferenceWizard: true);
    await SessionLocalStorage.setPreferenceWizardCompleted(true);
  }

  Future<void> markPostCallUpsellCompleted() async {
    state = state.copyWith(hasCompletedPostCallUpsell: true);
    await SessionLocalStorage.setPostCallUpsellCompleted(true);
  }

  void markAuthenticated(bool value) {
    state = state.copyWith(isAuthenticated: value);
  }

  /// Çıkış: intro carousel cihazda kalır; yalnızca auth sıfırlanır.
  Future<void> clearAuthSession() async {
    await SessionLocalStorage.clearAuth();
    state = SessionState(
      hasCompletedIntroCarousel: state.hasCompletedIntroCarousel,
      hasCompletedPreferenceWizard: state.hasCompletedPreferenceWizard,
      hasCompletedPostCallUpsell: state.hasCompletedPostCallUpsell,
      isAuthenticated: false,
    );
  }

  void resetOnboardingDemo() {
    state = const SessionState();
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
