import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lingola_buddy/Core/Localization/app_translations.dart';

class OnboardingSlideModel {
  const OnboardingSlideModel({
    required this.assetPath,
    required this.headline,
    required this.body,
    required this.ctaLabel,
  });

  final String assetPath;
  final String headline;
  final String body;
  final String ctaLabel;
}

class OnboardingCarouselState {
  const OnboardingCarouselState({
    required this.slides,
    this.pageIndex = 0,
  });

  final List<OnboardingSlideModel> slides;
  final int pageIndex;

  OnboardingCarouselState copyWith({
    List<OnboardingSlideModel>? slides,
    int? pageIndex,
  }) {
    return OnboardingCarouselState(
      slides: slides ?? this.slides,
      pageIndex: pageIndex ?? this.pageIndex,
    );
  }
}

class OnboardingCarouselController extends Notifier<OnboardingCarouselState> {
  List<OnboardingSlideModel> _slidesFromTranslations() {
    return [
      OnboardingSlideModel(
        assetPath: 'assets/images/onboarding_1.png',
        headline: AppTranslations.section('onboarding', 'title1'),
        body: AppTranslations.section('onboarding', 'description1'),
        ctaLabel: AppTranslations.section('onboarding', 'button1'),
      ),
      OnboardingSlideModel(
        assetPath: 'assets/images/onboarding_2.png',
        headline: AppTranslations.section('onboarding', 'title2'),
        body: AppTranslations.section('onboarding', 'description2'),
        ctaLabel: AppTranslations.section('onboarding', 'button2'),
      ),
      OnboardingSlideModel(
        assetPath: 'assets/images/onboarding_3.png',
        headline: AppTranslations.section('onboarding', 'title3'),
        body: AppTranslations.section('onboarding', 'description3'),
        ctaLabel: AppTranslations.section('onboarding', 'button3'),
      ),
    ];
  }

  @override
  OnboardingCarouselState build() {
    return OnboardingCarouselState(slides: _slidesFromTranslations(), pageIndex: 0);
  }

  void setPage(int index) {
    final max = state.slides.length - 1;
    final clamped = index.clamp(0, max).toInt();
    state = state.copyWith(pageIndex: clamped);
  }
}

final onboardingCarouselControllerProvider =
    NotifierProvider<OnboardingCarouselController, OnboardingCarouselState>(
        OnboardingCarouselController.new);
