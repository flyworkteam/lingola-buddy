import 'package:flutter/material.dart';

import 'package:lingola_buddy/View/ActiveCallView/active_call_view.dart';
import 'package:lingola_buddy/View/BottomNavBarView/bottom_navbar_view.dart';
import 'package:lingola_buddy/Models/call_preview_args.dart';
import 'package:lingola_buddy/View/CallPreviewView/call_preview_view.dart';
import 'package:lingola_buddy/View/CallSummaryView/call_summary_view.dart';
import 'package:lingola_buddy/View/GeneratingPlanView/generating_plan_view.dart';
import 'package:lingola_buddy/View/HomeView/notifications_view.dart';
import 'package:lingola_buddy/View/OnboardingCarouselView/onboarding_carousel_view.dart';
import 'package:lingola_buddy/View/OnboardingGoalView/onboarding_goal_view.dart';
import 'package:lingola_buddy/View/OnboardingLanguageView/onboarding_language_view.dart';
import 'package:lingola_buddy/View/OnboardingLevelView/onboarding_level_view.dart';
import 'package:lingola_buddy/View/PlanReadyView/plan_ready_view.dart';
import 'package:lingola_buddy/View/SignUpView/sign_up_view.dart';
import 'package:lingola_buddy/View/SplashView/splash_view.dart';
import 'package:lingola_buddy/View/VideoCallView/video_call_view.dart';

/// Kök [MaterialApp] rotaları (PDF’deki `AppRoutes` yapısına paralel)
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String onboardingCarousel = '/onboarding';
  static const String onboardingLanguage = '/onboarding/language';
  static const String onboardingLevel = '/onboarding/level';
  static const String onboardingGoal = '/onboarding/goal';
  static const String generatingPlan = '/onboarding/plan-generating';
  static const String planReady = '/onboarding/plan-ready';
  static const String callPreview = '/call/preview';
  /// Görüntülü arama (onboarding önizlemeden veya kök navigator’dan).
  static const String videoCall = '/call/video';
  static const String activeCall = '/call/active';
  static const String callSummary = '/call/summary';
  static const String signUp = '/auth/sign-up';
  static const String bottomNav = '/app';
  static const String notifications = '/notifications';

  static Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashView(),
    onboardingCarousel: (_) => const OnboardingCarouselView(),
    onboardingLanguage: (_) => const OnboardingLanguageView(),
    onboardingLevel: (_) => const OnboardingLevelView(),
    onboardingGoal: (_) => const OnboardingGoalView(),
    generatingPlan: (_) => const GeneratingPlanView(),
    planReady: (_) => const PlanReadyView(),
    callPreview: (ctx) {
      final args = _parseCallPreviewArgs(ModalRoute.of(ctx)?.settings.arguments);
      return CallPreviewView(args: args);
    },
    activeCall: (_) => const ActiveCallView(),
    callSummary: (_) => const CallSummaryView(),
    signUp: (_) => const SignUpView(),
    bottomNav: (_) => const BottomNavBarView(),
    notifications: (_) => const NotificationsView(),
  };

  /// Kök ve sekme navigator'ları için ortak arama rotaları.
  static Route<dynamic>? buildCallRoute(RouteSettings settings) {
    switch (settings.name) {
      case callPreview:
        final args = _parseCallPreviewArgs(settings.arguments);
        return MaterialPageRoute<void>(
          builder: (_) => CallPreviewView(args: args),
          settings: settings,
        );
      case videoCall:
        final tutorId = settings.arguments is String
            ? settings.arguments as String
            : 'annie';
        return MaterialPageRoute<void>(
          builder: (_) => VideoCallView(tutorId: tutorId),
          settings: settings,
        );
      case activeCall:
        return MaterialPageRoute<void>(
          builder: (_) => const ActiveCallView(),
          settings: settings,
        );
      case callSummary:
        return MaterialPageRoute<void>(
          builder: (_) => const CallSummaryView(),
          settings: settings,
        );
      default:
        return null;
    }
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    return buildCallRoute(settings);
  }

  static CallPreviewArgs _parseCallPreviewArgs(Object? raw) {
    if (raw is CallPreviewArgs) return raw;
    if (raw is String && raw.isNotEmpty) {
      return CallPreviewArgs.guest(tutorId: raw);
    }
    return const CallPreviewArgs.guest();
  }
}
