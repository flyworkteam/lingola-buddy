import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lingola_buddy/Core/Routes/app_routes.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Widgets/app_primary_button.dart';
import 'package:lingola_buddy/Core/Widgets/brand_aura_backdrop.dart';
import 'package:lingola_buddy/Core/Widgets/onboarding_step_progress.dart';
import 'package:lingola_buddy/Riverpod/Controllers/OnboardingCarouselController/onboarding_carousel_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/SessionController/session_controller.dart';

/// Tanıtım carousel — metinler [AppTranslations], tipografi [AppTextStyles].
class OnboardingCarouselView extends ConsumerStatefulWidget {
  const OnboardingCarouselView({super.key});

  @override
  ConsumerState<OnboardingCarouselView> createState() =>
      _OnboardingCarouselViewState();
}

class _OnboardingCarouselViewState
    extends ConsumerState<OnboardingCarouselView> {
  final PageController _pageController = PageController();

  static const Duration _autoAdvanceDelay = Duration(milliseconds: 5000);
  static const Duration _pageAnimDuration = Duration(milliseconds: 300);
  static const double _copyBlockHeightMin = 168;
  static const double _copyBlockHeightMax = 228;
  Timer? _autoAdvanceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final slides = ref.read(onboardingCarouselControllerProvider).slides;
      for (final s in slides) {
        precacheImage(AssetImage(s.assetPath), context);
      }
      _armAutoAdvance();
    });
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _armAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    if (!mounted) return;
    final carousel = ref.read(onboardingCarouselControllerProvider);
    final last = carousel.slides.length - 1;
    if (carousel.pageIndex >= last) return;
    _autoAdvanceTimer = Timer(_autoAdvanceDelay, _onAutoAdvanceTick);
  }

  void _onAutoAdvanceTick() {
    if (!mounted) return;
    final carousel = ref.read(onboardingCarouselControllerProvider);
    final last = carousel.slides.length - 1;
    if (carousel.pageIndex >= last) return;
    _pageController.nextPage(
      duration: _pageAnimDuration,
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _onPrimaryTap() async {
    final carousel = ref.read(onboardingCarouselControllerProvider);
    final lastIndex = carousel.slides.length - 1;

    if (carousel.pageIndex >= lastIndex) {
      ref.read(sessionControllerProvider.notifier).markIntroCarouselCompleted();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.onboardingLanguage);
      return;
    }

    await _pageController.nextPage(
      duration: _pageAnimDuration,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingCarouselControllerProvider);
    final slide = state.slides[state.pageIndex];
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final illCacheWidth = ((MediaQuery.sizeOf(context).width - 32) * dpr)
        .round();
    final copyBlockHeight = (MediaQuery.sizeOf(context).height * 0.24)
        .clamp(_copyBlockHeightMin, _copyBlockHeightMax)
        .toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFFFFFFFF)),
          const Positioned.fill(child: BrandAuraBackdrop()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: state.slides.length,
                      onPageChanged: (i) {
                        ref
                            .read(onboardingCarouselControllerProvider.notifier)
                            .setPage(i);
                        _armAutoAdvance();
                      },
                      itemBuilder: (context, index) {
                        final s = state.slides[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Image.asset(
                              s.assetPath,
                              fit: BoxFit.contain,
                              alignment: Alignment.bottomCenter,
                              filterQuality: FilterQuality.high,
                              gaplessPlayback: true,
                              cacheWidth: illCacheWidth,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: OnboardingStepProgress(
                            length: state.slides.length,
                            activeIndex: state.pageIndex,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: copyBlockHeight,
                          child: AnimatedSwitcher(
                            duration: _pageAnimDuration,
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeOutCubic,
                            layoutBuilder: (currentChild, previousChildren) {
                              return Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: <Widget>[
                                  ...previousChildren,
                                  if (currentChild != null) currentChild,
                                ],
                              );
                            },
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                            child: KeyedSubtree(
                              key: ValueKey<int>(state.pageIndex),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    slide.headline,
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.onboardingHeadline(),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    slide.body,
                                    textAlign: TextAlign.center,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.onboardingBody(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppPrimaryButton(
                    label: slide.ctaLabel,
                    decorationGradient: AppColors.primaryCtaGradient,
                    foregroundColor: Colors.white,
                    labelStyle: AppTextStyles.onboardingCta(),
                    minimumHeight: 60,
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 22,
                      color: Colors.white,
                    ),
                    onPressed: _onPrimaryTap,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
