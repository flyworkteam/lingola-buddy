import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Routes/app_routes.dart';
import 'package:lingola_buddy/Core/Utils/legal_link_launcher.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Widgets/app_primary_button.dart';
import 'package:lingola_buddy/Core/Widgets/user_profile_avatar.dart';
import 'package:lingola_buddy/Riverpod/Controllers/BottomNavController/bottom_nav_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/SessionController/session_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/UserProfileController/user_profile_controller.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  static const Color _panelBackground = Color(0xFFF6F6F6);

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    ref.read(sessionControllerProvider.notifier).resetOnboardingDemo();
    ref.read(bottomNavControllerProvider.notifier).setIndex(0);
    await Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil(AppRoutes.splash, (route) => false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileControllerProvider);
    final user = profileState.user;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          physics: ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            Text(
              AppTranslations.section('profile', 'title'),
              style: AppTextStyles.homeWelcomeTitle().copyWith(
                fontSize: 20,
                height: 28 / 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: const Color(0xFF171717),
              ),
            ),
            const SizedBox(height: 32),
            _ProfileHeaderCard(
              displayName: user?.displayName ?? '—',
              email: user?.email ?? '',
              avatarPath: user?.avatarUrl,
              onEdit: () => Navigator.pushNamed(context, '/settings'),
            ),
            const SizedBox(height: 16),
            _ProfileSettingsPanel(
              children: [
                _ProfileSettingsRow(
                  iconAsset: 'assets/icons/language.svg',
                  label: AppTranslations.section('profile', 'language'),
                  onTap: () => Navigator.pushNamed(context, '/language'),
                ),
                _ProfileSettingsRow(
                  iconAsset: 'assets/icons/notification_profile.svg',
                  label: AppTranslations.section('profile', 'notifications'),
                  compactTrailing: true,
                  trailing: Transform.scale(
                    scale: 0.8,
                    child: Switch.adaptive(
                      padding: EdgeInsets.zero,
                      value: profileState.notificationsEnabled,
                      activeTrackColor: AppColors.brandPrimary.withValues(
                        alpha: 0.35,
                      ),
                      activeThumbColor: AppColors.brandPrimary,
                      onChanged: (value) => ref
                          .read(userProfileControllerProvider.notifier)
                          .toggleNotifications(value),
                    ),
                  ),
                ),
                _ProfileSettingsRow(
                  iconAsset: 'assets/icons/premium.svg',
                  label: AppTranslations.section('profile', 'premium'),
                  onTap: () {},
                ),
                _ProfileSettingsRow(
                  iconAsset: 'assets/icons/share.svg',
                  label: AppTranslations.section('profile', 'share_friend'),
                  onTap: () => Navigator.pushNamed(context, '/share'),
                ),
                _ProfileSettingsRow(
                  iconAsset: 'assets/icons/progress.svg',
                  label: AppTranslations.section('profile', 'progress'),
                  onTap: () => Navigator.pushNamed(context, '/progress'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ProfileSettingsPanel(
              sectionLabel: AppTranslations.section(
                'profile',
                'section_support',
              ),
              children: [
                _ProfileSettingsRow(
                  iconAsset: 'assets/icons/heart.svg',
                  label: AppTranslations.section('profile', 'rate_us'),
                  onTap: () {},
                ),
                _ProfileSettingsRow(
                  iconAsset: 'assets/icons/faq.svg',
                  label: AppTranslations.section('profile', 'faq'),
                  onTap: () => Navigator.pushNamed(context, '/faq'),
                ),
                _ProfileSettingsRow(
                  iconAsset: 'assets/icons/heart_plus.svg',
                  label: AppTranslations.section('profile', 'contact_us'),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ProfileSettingsPanel(
              sectionLabel: AppTranslations.section('profile', 'section_legal'),
              children: [
                _ProfileSettingsRow(
                  iconAsset: 'assets/icons/privacy.svg',
                  label: AppTranslations.section('profile', 'privacy_policy'),
                  onTap: () => LegalLinkLauncher.openPrivacyPolicy(context),
                ),
                _ProfileSettingsRow(
                  iconAsset: 'assets/icons/shake_hands.svg',
                  label: AppTranslations.section('profile', 'terms_of_use'),
                  onTap: () => LegalLinkLauncher.openTermsOfService(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ProfileSettingsPanel(
              children: [
                _ProfileSettingsRow(
                  iconAsset: 'assets/icons/logout.svg',
                  label: AppTranslations.section('profile', 'log_out'),
                  showChevron: false,
                  onTap: () => _logout(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.displayName,
    required this.email,
    required this.avatarPath,
    required this.onEdit,
  });

  final String displayName;
  final String email;
  final String? avatarPath;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ProfileView._panelBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              children: [
                UserProfileAvatar(localPath: avatarPath, size: 88),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.homeCharacterName().copyWith(
                    fontSize: 20,
                    height: 24 / 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.notificationCardBody().copyWith(
                    color: const Color(0xFf727590),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: AppPrimaryButton(
                    label: AppTranslations.section('profile', 'edit_profile'),
                    minimumHeight: 38,
                    fullWidth: false,
                    iconLeading: true,
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    labelStyle: AppTextStyles.homeCharacterCta().copyWith(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    icon: SvgPicture.asset(
                      'assets/icons/edit.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                    onPressed: onEdit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSettingsPanel extends StatelessWidget {
  const _ProfileSettingsPanel({this.sectionLabel, required this.children});

  final String? sectionLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ProfileView._panelBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (sectionLabel != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 2, 4, 6),
                child: Text(
                  sectionLabel!,
                  style: AppTextStyles.homeSectionTitle().copyWith(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.25,
                    color: const Color(0xFF727590),
                  ),
                ),
              ),
            ],
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 4),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileSettingsRow extends StatelessWidget {
  const _ProfileSettingsRow({
    required this.iconAsset,
    required this.label,
    this.onTap,
    this.trailing,
    this.showChevron = true,
    this.compactTrailing = false,
  });

  final String iconAsset;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showChevron;
  final bool compactTrailing;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: EdgeInsets.fromLTRB(10, 10, compactTrailing ? 4 : 10, 10),
      child: Row(
        children: [
          SvgPicture.asset(
            iconAsset,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Color(0xFF171717),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.notificationCardTitle().copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (trailing != null)
            trailing!
          else if (showChevron)
            SvgPicture.asset(
              'assets/icons/ic_rarrow.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
AppColors.secondaryText,
                BlendMode.srcIn,
              ),
            ),
        ],
      ),
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: trailing != null ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 50),
          child: content,
        ),
      ),
    );
  }
}
