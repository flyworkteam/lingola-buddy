import 'package:flutter/material.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';

class ProfilePhotoSheet extends StatelessWidget {
  const ProfilePhotoSheet({
    super.key,
    required this.onGallery,
    required this.onCamera,
    required this.onRemove,
    required this.showRemove,
  });

  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onRemove;
  final bool showRemove;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onGallery,
    required VoidCallback onCamera,
    required VoidCallback onRemove,
    required bool showRemove,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfilePhotoSheet(
        onGallery: () {
          Navigator.of(context).pop();
          onGallery();
        },
        onCamera: () {
          Navigator.of(context).pop();
          onCamera();
        },
        onRemove: () {
          Navigator.of(context).pop();
          onRemove();
        },
        showRemove: showRemove,
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
              AppTranslations.section('profile_settings', 'photo_sheet_title'),
              style: AppTextStyles.chatTitle().copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            _SheetTile(
              icon: Icons.photo_outlined,
              label: AppTranslations.section('profile_settings', 'from_gallery'),
              onTap: onGallery,
            ),
            _SheetTile(
              icon: Icons.photo_camera_outlined,
              label: AppTranslations.section('profile_settings', 'from_camera'),
              onTap: onCamera,
            ),
            if (showRemove) ...[
              const Divider(height: 1, indent: 20, endIndent: 20),
              _SheetTile(
                icon: Icons.delete_outline,
                label: AppTranslations.section('profile_settings', 'remove_photo'),
                onTap: onRemove,
                destructive: true,
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppTranslations.section('chat', 'attach_cancel'),
                style: AppTextStyles.chatInputHint().copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFE53935) : const Color(0xFF171717);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: destructive
                      ? const Color(0xFFFFEBEE)
                      : AppColors.brandPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: destructive ? const Color(0xFFE53935) : AppColors.brandPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.chatUserMessage().copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
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
