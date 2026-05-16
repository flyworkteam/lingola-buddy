import 'package:flutter/material.dart';

import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';

/// Sihirbaz seçenek satırı — Figma: 57px pill, solda ikon alanı 36.
class OnboardingOptionTile extends StatelessWidget {
  const OnboardingOptionTile({
    super.key,
    required this.leading,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Widget leading;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const double _rowHeight = 57;
  static const double _leadingBox = 36;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.brandPrimary.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.10);
    final fillColor = selected
        ? AppColors.brandPrimary.withValues(alpha: 0.10)
        : Colors.white;
    final textColor = selected
        ? AppColors.brandPrimary
        : AppColors.secondaryText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          height: _rowHeight,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: _leadingBox,
                height: _leadingBox,
                child: Center(child: leading),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.onboardingLanguageRow(color: textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
