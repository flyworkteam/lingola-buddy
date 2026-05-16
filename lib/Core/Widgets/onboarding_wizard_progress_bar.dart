import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:lingola_buddy/Core/Theme/app_colors.dart';

/// Figma: 12px pill iz; mor dolgunun sol ve sağ uçları tam yuvarlak.
class OnboardingWizardProgressBar extends StatelessWidget {
  const OnboardingWizardProgressBar({super.key, required this.fraction});

  final double fraction;

  static const double _height = 12;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final t = fraction.clamp(0.0, 1.0);
        final raw = w * t;
        final fillW = math.min(w, math.max(raw, _height));
        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: _height,
            width: w,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                ColoredBox(color: Colors.black.withValues(alpha: 0.08)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      width: fillW,
                      height: _height,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Color(0xFF8F56FF), AppColors.brandPrimary],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
