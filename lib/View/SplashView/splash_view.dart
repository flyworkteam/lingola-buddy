import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lingola_buddy/Core/Config/app_config.dart';
import 'package:lingola_buddy/Core/Routes/app_routes.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Widgets/brand_aura_backdrop.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Riverpod/Controllers/SessionController/session_controller.dart';

/// PNG, `app_icon.svg` içindeki gömülü rastır; `flutter_svg` pattern+image çizmediği için ayrı dosyada tutulur ([tool/extract_svg_png.py] ile üretilebilir).
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
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final session = ref.read(sessionControllerProvider);
    if (session.isAuthenticated) {
      Navigator.pushReplacementNamed(context, AppRoutes.bottomNav);
      return;
    }
    if (!session.hasCompletedIntroCarousel) {
      Navigator.pushReplacementNamed(context, AppRoutes.onboardingCarousel);
      return;
    }
    if (!session.hasCompletedPreferenceWizard) {
      Navigator.pushReplacementNamed(context, AppRoutes.onboardingLanguage);
      return;
    }
    Navigator.pushReplacementNamed(context, AppRoutes.generatingPlan);
  }

  /// Figma Frame 2: mor kutu içi dikey gradient
  static const LinearGradient _splashIconCardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF8F56FF),
      AppColors.brandPrimary,
      Color(0xFF5A17D4),
    ],
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
                          padding: const EdgeInsets.only( top: 5.0, right: 10.0, left: 10.0),
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
                const SizedBox(height: 24),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.brandPrimary
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
