import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  static const Duration _autoAdvanceDelay = Duration(seconds: 3);
  static const Duration _slideAnimDuration = Duration(milliseconds: 480);
  static const double _illustrationToCopyGap = 64;
  static const double _indicatorToCopyGap = 12;
  static const double _copyToButtonGap = 16;
  static const double _indicatorSlotHeight = 4;
  static const double _textBlockHeight = 168;
  static const double _copyPanelHeight =
      _indicatorSlotHeight + _indicatorToCopyGap + _textBlockHeight;
  static const double _swipeVelocityThreshold = 200;
  static const double _tapZoneWidthFraction = 0.3;
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
    super.dispose();
  }

  void _armAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    if (!mounted) return;
    _autoAdvanceTimer = Timer(_autoAdvanceDelay, _onAutoAdvanceTick);
  }

  void _onAutoAdvanceTick() {
    if (!mounted) return;
    _advanceSlide(loop: true);
    _armAutoAdvance();
  }

  void _setPageByDelta(int delta, {required bool loop}) {
    final carousel = ref.read(onboardingCarouselControllerProvider);
    final count = carousel.slides.length;
    final current = carousel.pageIndex;
    final next = current + delta;

    if (loop) {
      ref
          .read(onboardingCarouselControllerProvider.notifier)
          .setPage((next % count + count) % count);
      return;
    }

    if (next < 0 || next >= count) return;
    ref.read(onboardingCarouselControllerProvider.notifier).setPage(next);
  }

  void _advanceSlide({required bool loop}) => _setPageByDelta(1, loop: loop);

  void _retreatSlide({required bool loop}) => _setPageByDelta(-1, loop: loop);

  void _onManualPageChange(int direction) {
    if (direction > 0) {
      _advanceSlide(loop: true);
    } else if (direction < 0) {
      _retreatSlide(loop: true);
    }
    _armAutoAdvance();
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity <= -_swipeVelocityThreshold) {
      _onManualPageChange(1);
    } else if (velocity >= _swipeVelocityThreshold) {
      _onManualPageChange(-1);
    }
  }

  void _onCarouselTapUp(TapUpDetails details, double width) {
    final x = details.localPosition.dx;
    if (x < width * _tapZoneWidthFraction) {
      _onManualPageChange(-1);
    } else if (x > width * (1 - _tapZoneWidthFraction)) {
      _onManualPageChange(1);
    }
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

    _advanceSlide(loop: false);
    _armAutoAdvance();
  }

  Widget _slideTransition(Widget child, Animation<double> animation) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(opacity: curved, child: child);
  }

  Widget _copySlideContent(OnboardingSlideModel slide) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingCarouselControllerProvider);
    final slide = state.slides[state.pageIndex];
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final illCacheWidth = ((MediaQuery.sizeOf(context).width - 32) * dpr)
        .round();
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragEnd: _onHorizontalDragEnd,
                          onTapUp: (details) =>
                              _onCarouselTapUp(details, constraints.maxWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: _slideAnimDuration,
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  transitionBuilder: _slideTransition,
                                  child: Padding(
                                    key: ValueKey<int>(state.pageIndex),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: Image.asset(
                                        slide.assetPath,
                                        fit: BoxFit.contain,
                                        alignment: Alignment.topCenter,
                                        filterQuality: FilterQuality.high,
                                        gaplessPlayback: true,
                                        cacheWidth: illCacheWidth,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: _illustrationToCopyGap),
                              SizedBox(
                                height: _copyPanelHeight,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(
                                      height: _indicatorSlotHeight,
                                      child: Center(
                                        child: OnboardingStepProgress(
                                          length: state.slides.length,
                                          activeIndex: state.pageIndex,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: _indicatorToCopyGap * 2,
                                    ),
                                    SizedBox(
                                      height: _textBlockHeight,
                                      child: ClipRect(
                                        child: AnimatedSwitcher(
                                          duration: _slideAnimDuration,
                                          switchInCurve: Curves.easeOutCubic,
                                          switchOutCurve: Curves.easeInCubic,
                                          layoutBuilder:
                                              (currentChild, previousChildren) {
                                                return Stack(
                                                  alignment:
                                                      Alignment.topCenter,
                                                  clipBehavior: Clip.hardEdge,
                                                  children: [
                                                    ...previousChildren,
                                                    if (currentChild != null)
                                                      currentChild,
                                                  ],
                                                );
                                              },
                                          transitionBuilder: _slideTransition,
                                          child: KeyedSubtree(
                                            key: ValueKey<int>(state.pageIndex),
                                            child: _copySlideContent(slide),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: _copyToButtonGap / 2),
                  AppPrimaryButton(
                    label: slide.ctaLabel,
                    decorationGradient: AppColors.primaryCtaGradient,
                    foregroundColor: Colors.white,
                    labelStyle: AppTextStyles.onboardingCta(),
                    minimumHeight: 60,
                    icon: SvgPicture.asset("assets/icons/right_arrow.svg"),
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
