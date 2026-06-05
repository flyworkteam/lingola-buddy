import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Widgets/app_primary_button.dart';

/// Çıkış yapmadan önce onay — `true` onay, `false` / `null` iptal.
class LogoutConfirmDialog extends StatelessWidget {
  const LogoutConfirmDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) => const LogoutConfirmDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/logout.svg',
                    width: 28,
                    height: 28,
                    colorFilter: const ColorFilter.mode(
                      AppColors.brandPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppTranslations.section('logout_dialog', 'title'),
                textAlign: TextAlign.center,
                style: AppTextStyles.chatTitle().copyWith(fontSize: 20),
              ),
              const SizedBox(height: 10),
              Text(
                AppTranslations.section('logout_dialog', 'message'),
                textAlign: TextAlign.center,
                style: AppTextStyles.onboardingBody().copyWith(
                  color: const Color(0xFF6B6B6B),
                ),
              ),
              const SizedBox(height: 24),
              AppPrimaryButton(
                label: AppTranslations.section('logout_dialog', 'confirm'),
                foregroundColor: Colors.white,
                labelStyle: AppTextStyles.homeCharacterCta().copyWith(
                  color: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  AppTranslations.section('common', 'cancel'),
                  style: AppTextStyles.chatInputHint().copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF171717),
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
