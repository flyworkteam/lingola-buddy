import 'package:flutter/material.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Widgets/app_primary_button.dart';

/// Sohbet silmeden önce onay — `true` onay, `false` / `null` iptal.
class DeleteConversationConfirmDialog extends StatelessWidget {
  const DeleteConversationConfirmDialog({
    super.key,
    required this.tutorName,
  });

  final String tutorName;

  static const Color _destructive = Color(0xFFE53935);

  static Future<bool?> show(
    BuildContext context, {
    required String tutorName,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) =>
          DeleteConversationConfirmDialog(tutorName: tutorName),
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
                  color: _destructive.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 28,
                  color: _destructive,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppTranslations.section('talk', 'delete_title'),
                textAlign: TextAlign.center,
                style: AppTextStyles.chatTitle().copyWith(fontSize: 20),
              ),
              const SizedBox(height: 10),
              Text(
                AppTranslations.interpolate(
                  AppTranslations.section('talk', 'delete_message'),
                  {'name': tutorName},
                ),
                textAlign: TextAlign.center,
                style: AppTextStyles.onboardingBody().copyWith(
                  color: const Color(0xFF6B6B6B),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: AppPrimaryButton(
                  label: AppTranslations.section('talk', 'delete_confirm'),
                  backgroundColor: _destructive,
                  fullWidth: false,
                  foregroundColor: Colors.white,
                  labelStyle: AppTextStyles.homeCharacterCta().copyWith(
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
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
