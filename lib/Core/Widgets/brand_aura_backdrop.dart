import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:lingola_buddy/Core/Theme/app_colors.dart';

/// Figma: tam beyaz zemin üzerinde köşelerde yüksek bulanıklıklı nane / lavanta halkaları.
/// Splash ve onboarding carousel ile aynı görsel.
class BrandAuraBackdrop extends StatelessWidget {
  const BrandAuraBackdrop({super.key});

  static const double blurSigma = 88;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 0,
          left: -250,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: blurSigma,
              sigmaY: blurSigma,
            ),
            child: Container(
              width: 340,
              height: 340,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.splashAuraMint,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: -200,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: blurSigma,
              sigmaY: blurSigma,
            ),
            child: Container(
              width: 360,
              height: 360,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.splashAuraLavender,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
