import 'package:flutter/material.dart';

import 'package:lingola_buddy/Core/Theme/app_colors.dart';

/// Onboarding: Figma — pasif 16×4, aktif 38×4, aralık 8, köşe 999.
class OnboardingStepProgress extends StatelessWidget {
  const OnboardingStepProgress({
    super.key,
    required this.length,
    required this.activeIndex,
  });

  final int length;
  final int activeIndex;

  static const double _inactiveWidth = 16;
  static const double _activeWidth = 38;
  static const double _height = 4;
  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(length, (i) {
        final active = i == activeIndex;
        return Padding(
          padding: EdgeInsets.only(right: i == length - 1 ? 0 : _gap),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: active ? _activeWidth : _inactiveWidth,
            height: _height,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.brandPrimary
                  : AppColors.onboardingProgressInactive,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}
