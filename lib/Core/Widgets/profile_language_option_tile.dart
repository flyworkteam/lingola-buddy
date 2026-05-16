import 'package:flutter/material.dart';

import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';

/// Profil dil seçimi satırı — Figma: 57px, 12px köşe (pill değil).
///
/// Seçili değil: beyaz dolgu, kenarlık yok, siyah metin.
/// Seçili: #7429FF %20 dolgu, 1px #7429FF kenarlık, mor metin.
class ProfileLanguageOptionTile extends StatelessWidget {
  const ProfileLanguageOptionTile({
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

  static const double rowHeight = 57;
  static const double cornerRadius = 12;
  static const double _leadingSize = 36;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(cornerRadius),
        child: Ink(
          height: rowHeight,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.brandPrimary.withValues(alpha: 0.2)
                : Colors.white,
            borderRadius: BorderRadius.circular(cornerRadius),
            border: selected
                ? Border.all(color: AppColors.brandPrimary, width: 1)
                : null,
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: _leadingSize,
                height: _leadingSize,
                child: Center(child: leading),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.profileLanguageRow(
                    selected: selected,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
