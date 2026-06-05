import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Core/Config/app_config.dart';
import 'package:lingola_buddy/Core/Routes/app_routes.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Widgets/brand_aura_backdrop.dart';
import 'package:lingola_buddy/Riverpod/Controllers/PremiumController/premium_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/SessionController/session_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/UserProfileController/user_profile_controller.dart';
import 'package:lingola_buddy/Riverpod/Providers/auth_repository_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/user_scoped_providers.dart';
import 'package:lingola_buddy/Services/local_notification_scheduler.dart';
import 'package:lingola_buddy/Services/session_local_storage.dart';
import 'package:lingola_buddy/Services/revenuecat_service.dart';

const String _splashIconPng = 'assets/images/splash_app_icon.png';

/// Açılış ekranı: marka gösterimi sonrasında oturum durumuna göre yönlenme
class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    var session = ref.read(sessionControllerProvider);

    if (session.isAuthenticated) {
      try {
        final restored = await ref
            .read(authRepositoryProvider)
            .restoreSession()
            .timeout(const Duration(seconds: 5));
        if (!mounted) return;
        if (restored != null) {
          await RevenueCatService.instance.syncUserIdentity(restored.user.id);
          if (!mounted) return;
          resetUserScopedAppState(ref);
          ref
              .read(userProfileControllerProvider.notifier)
              .setAuthenticatedUser(restored.user);
          ref.read(sessionControllerProvider.notifier).markAuthenticated(true);
          final notifOn = await SessionLocalStorage.getNotificationsEnabled();
          if (notifOn) {
            await LocalNotificationScheduler.instance.syncEnabled(enabled: true);
          }
          await ref.read(premiumControllerProvider.notifier).refresh();
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, AppRoutes.bottomNav);
          return;
        }
      } catch (_) {}

      await ref.read(sessionControllerProvider.notifier).clearAuthSession();
      if (!mounted) return;
      session = ref.read(sessionControllerProvider);
    }

    if (!session.hasCompletedIntroCarousel) {
      Navigator.pushReplacementNamed(context, AppRoutes.onboardingCarousel);
      return;
    }
    if (!session.hasCompletedPreferenceWizard) {
      Navigator.pushReplacementNamed(context, AppRoutes.onboardingLanguage);
      return;
    }
    if (!session.isAuthenticated) {
      Navigator.pushReplacementNamed(context, AppRoutes.signUp);
      return;
    }
    Navigator.pushReplacementNamed(context, AppRoutes.generatingPlan);
  }

  static const LinearGradient _splashIconCardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF8F56FF), AppColors.brandPrimary, Color(0xFF5A17D4)],
    stops: [0.0, 0.42, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFFFFFFFF)),
          const Positioned.fill(child: BrandAuraBackdrop()),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 134,
                  height: 133,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: _splashIconCardGradient,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 5.0,
                            right: 10.0,
                            left: 10.0,
                          ),
                          child: Image.asset(
                            _splashIconPng,
                            fit: BoxFit.cover,
                            alignment: const Alignment(0, -1.5),
                            gaplessPlayback: true,
                            filterQuality: FilterQuality.high,
                            cacheWidth: (134 * dpr).round(),
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 56,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(AppConfig.appName, style: AppTextStyles.splashAppTitle()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
