import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';

/// Sohbet artı (+) menüsü — fotoğraf veya belge seçimi.
class ChatAttachmentSheet extends StatelessWidget {
  const ChatAttachmentSheet({
    super.key,
    required this.onPhoto,
    required this.onDocument,
  });

  final VoidCallback onPhoto;
  final VoidCallback onDocument;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onPhoto,
    required VoidCallback onDocument,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ChatAttachmentSheet(
        onPhoto: () {
          Navigator.of(context).pop();
          onPhoto();
        },
        onDocument: () {
          Navigator.of(context).pop();
          onDocument();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandPrimary.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE8E9EF),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppTranslations.section('chat', 'attach_title'),
              style: AppTextStyles.chatTitle().copyWith(fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              AppTranslations.section('chat', 'attach_subtitle'),
              style: AppTextStyles.chatInputHint(),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _AttachmentOptionCard(
                        icon: Icons.photo_outlined,
                        label: AppTranslations.section('chat', 'attach_photo'),
                        subtitle: AppTranslations.section(
                          'chat',
                          'attach_subtitle_photo',
                        ),
                        onTap: onPhoto,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AttachmentOptionCard(
                        icon: Icons.description_outlined,
                        label: AppTranslations.section(
                          'chat',
                          'attach_document',
                        ),
                        subtitle: AppTranslations.section(
                          'chat',
                          'attach_subtitle_document',
                        ),
                        onTap: onDocument,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppTranslations.section('chat', 'attach_cancel'),
                style: AppTextStyles.chatInputHint().copyWith(
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _AttachmentOptionCard extends StatelessWidget {
  const _AttachmentOptionCard({
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.iconAsset,
    this.icon,
  }) : assert(iconAsset != null || icon != null);

  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final String? iconAsset;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8F7FC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 150,
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [
                      AppColors.brandPrimary.withValues(alpha: 0.18),
                      AppColors.brandPrimary.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: iconAsset != null
                      ? SvgPicture.asset(
                          iconAsset!,
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                            AppColors.brandPrimary,
                            BlendMode.srcIn,
                          ),
                        )
                      : Icon(icon, color: AppColors.brandPrimary, size: 26),
                ),
              ),
              const Spacer(),
              Text(
                label,
                style: AppTextStyles.chatUserMessage().copyWith(
                  color: const Color(0xFF171717),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.chatInputHint().copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
