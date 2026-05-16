import 'package:flutter/material.dart';

import 'package:lingola_buddy/View/ActiveCallView/active_call_view.dart';
import 'package:lingola_buddy/View/BottomNavBarView/bottom_navbar_view.dart';
import 'package:lingola_buddy/View/CallPreviewView/call_preview_view.dart';
import 'package:lingola_buddy/View/CallSummaryView/call_summary_view.dart';
import 'package:lingola_buddy/View/GeneratingPlanView/generating_plan_view.dart';
import 'package:lingola_buddy/View/HomeView/notifications_view.dart';
import 'package:lingola_buddy/View/OnboardingCarouselView/onboarding_carousel_view.dart';
import 'package:lingola_buddy/View/OnboardingGoalView/onboarding_goal_view.dart';
import 'package:lingola_buddy/View/OnboardingLanguageView/onboarding_language_view.dart';
import 'package:lingola_buddy/View/OnboardingLevelView/onboarding_level_view.dart';
import 'package:lingola_buddy/View/PaywallView/paywall_view.dart';
import 'package:lingola_buddy/View/PlanReadyView/plan_ready_view.dart';
import 'package:lingola_buddy/View/SignUpView/sign_up_view.dart';
import 'package:lingola_buddy/View/SplashView/splash_view.dart';

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
  static const String activeCall = '/call/active';
  static const String callSummary = '/call/summary';
  static const String paywall = '/paywall';
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
    callPreview: (_) => const CallPreviewView(),
    activeCall: (_) => const ActiveCallView(),
    callSummary: (_) => const CallSummaryView(),
    paywall: (_) => const PaywallView(),
    signUp: (_) => const SignUpView(),
    bottomNav: (_) => const BottomNavBarView(),
    notifications: (_) => const NotificationsView(),
  };

  /// Basit parametre gerektiren geçişler için genişletilebilir yapı (ileride `go_router` vb.)
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    return null;
  }
}
