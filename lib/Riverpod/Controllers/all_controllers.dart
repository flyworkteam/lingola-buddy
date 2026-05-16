import 'package:lingola_buddy/Riverpod/Controllers/BottomNavController/bottom_nav_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/CallSessionController/call_session_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/OnboardingCarouselController/onboarding_carousel_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/OnboardingPrefsController/onboarding_prefs_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/SessionController/session_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/UserProfileController/user_profile_controller.dart';

/// Controller provider’larının bulunabilirliği için PDF’de istenen toplu erişim noktası
abstract final class AllControllers {
  static final sessionViewController = sessionControllerProvider;

  static final onboardingCarouselViewController =
      onboardingCarouselControllerProvider;

  static final onboardingPrefsViewController =
      onboardingPrefsControllerProvider;

  static final bottomNavViewController = bottomNavControllerProvider;

  static final callSessionViewController = callSessionControllerProvider;

  static final userProfileViewController = userProfileControllerProvider;
}
