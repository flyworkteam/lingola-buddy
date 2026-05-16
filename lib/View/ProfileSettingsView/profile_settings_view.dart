import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Widgets/app_primary_button.dart';
import 'package:lingola_buddy/Core/Widgets/profile_photo_sheet.dart';
import 'package:lingola_buddy/Core/Widgets/user_profile_avatar.dart';
import 'package:lingola_buddy/Riverpod/Controllers/UserProfileController/user_profile_controller.dart';

class ProfileSettingsView extends ConsumerStatefulWidget {
  const ProfileSettingsView({super.key});

  static const Color _panelBackground = Color(0xFFF6F6F6);

  @override
  ConsumerState<ProfileSettingsView> createState() =>
      _ProfileSettingsViewState();
}

class _ProfileSettingsViewState extends ConsumerState<ProfileSettingsView> {
  TextEditingController? _name;
  TextEditingController? _email;

  @override
  void dispose() {
    _name?.dispose();
    _email?.dispose();
    super.dispose();
  }

  void _ensureControllers(UserProfileState state) {
    _name ??= TextEditingController(text: state.user?.displayName ?? '');
    _email ??= TextEditingController(text: state.user?.email ?? '');
  }

  void _save() {
    ref
        .read(userProfileControllerProvider.notifier)
        .updateDisplayName(_name!.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppTranslations.section('common', 'save_changes')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openPhotoSheet() {
    final user = ref.read(userProfileControllerProvider).user;
    final hasCustomPhoto =
        user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty;

    ProfilePhotoSheet.show(
      context,
      showRemove: hasCustomPhoto,
      onGallery: () => _pickPhoto(ImageSource.gallery),
      onCamera: () => _pickPhoto(ImageSource.camera),
      onRemove: _removePhoto,
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final updated = await ref
          .read(userProfileControllerProvider.notifier)
          .updateProfilePhoto(source);
      if (!mounted) return;
      if (updated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppTranslations.section('profile_settings', 'photo_updated'),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.section('profile_settings', 'photo_error'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _removePhoto() async {
    await ref.read(userProfileControllerProvider.notifier).removeProfilePhoto();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppTranslations.section('profile_settings', 'photo_updated'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileControllerProvider);
    _ensureControllers(profileState);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  IconButton(
                    style: IconButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => Navigator.of(context).maybePop(),

                    icon: SvgPicture.asset(
                      'assets/icons/arrow_left.svg',
                      width: 24,
                      height: 24,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      AppTranslations.section('profile_settings', 'title'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.homeWelcomeTitle().copyWith(
                        fontSize: 20,
                        height: 28 / 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: const Color(0xFF171717),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                children: [
                  _PhotoPanel(
                    avatarPath: profileState.user?.avatarUrl,
                    onChangePhoto: _openPhotoSheet,
                  ),
                  const SizedBox(height: 8),
                  _FormPanel(nameController: _name!, emailController: _email!),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppPrimaryButton(
                    label: AppTranslations.section(
                      'profile_settings',
                      'save_changes',
                    ),
                    foregroundColor: Colors.white,
                    labelStyle: AppTextStyles.homeCharacterCta().copyWith(
                      color: Colors.white,
                    ),
                    onPressed: _save,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE53935),
                    ),
                    child: Text(
                      AppTranslations.section(
                        'profile_settings',
                        'delete_account',
                      ),
                      style: AppTextStyles.notificationCardTitle().copyWith(
                        color: const Color(0xFFE53935),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPanel extends StatelessWidget {
  const _PhotoPanel({
    required this.avatarPath,
    required this.onChangePhoto,
  });

  final String? avatarPath;
  final VoidCallback onChangePhoto;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ProfileSettingsView._panelBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                UserProfileAvatar(localPath: avatarPath, size: 76),
                const Spacer(),
                AppPrimaryButton(
                  label: AppTranslations.section(
                    'profile_settings',
                    'change_photo',
                  ),
                  minimumHeight: 38,
                  fullWidth: false,
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  labelStyle: AppTextStyles.homeCharacterCta().copyWith(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  onPressed: onChangePhoto,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormPanel extends StatelessWidget {
  const _FormPanel({
    required this.nameController,
    required this.emailController,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ProfileSettingsView._panelBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileSettingsField(
              label: AppTranslations.section('profile_settings', 'name'),
              controller: nameController,
            ),
            const SizedBox(height: 12),
            _ProfileSettingsField(
              label: AppTranslations.section('profile_settings', 'email'),
              controller: emailController,
              readOnly: true,
              suffixIcon: SvgPicture.asset(
                'assets/icons/lock.svg',
                width: 20,
                height: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSettingsField extends StatelessWidget {
  const _ProfileSettingsField({
    required this.label,
    required this.controller,
    this.readOnly = false,
    this.suffixIcon,
  });

  final String label;
  final TextEditingController controller;
  final bool readOnly;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: AppTextStyles.homeSectionTitle().copyWith(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.25,
              color: const Color(0xFF727590),
            ),
          ),
        ),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 50,
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              style: AppTextStyles.notificationCardTitle().copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: readOnly
                    ? const Color(0xFF96989C)
                    : const Color(0xFF171717),
              ),
              cursorColor: AppColors.brandPrimary,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.fromLTRB(
                  14,
                  14,
                  suffixIcon != null ? 8 : 14,
                  14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                suffixIcon: suffixIcon == null
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: suffixIcon,
                      ),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
