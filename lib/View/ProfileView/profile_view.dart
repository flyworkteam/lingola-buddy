import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Routes/app_routes.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Utils/legal_link_launcher.dart';
import 'package:lingola_buddy/Core/Widgets/app_primary_button.dart';
import 'package:lingola_buddy/Core/Widgets/app_snackbar.dart';
import 'package:lingola_buddy/Core/Widgets/future_extensions_dialog.dart';
import 'package:lingola_buddy/Core/Widgets/logout_confirm_dialog.dart';
import 'package:lingola_buddy/Core/Widgets/user_profile_avatar.dart';
import 'package:lingola_buddy/Riverpod/Controllers/BottomNavController/bottom_nav_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/PremiumController/premium_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/SessionController/session_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/UserProfileController/user_profile_controller.dart';
import 'package:lingola_buddy/Riverpod/Providers/auth_repository_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/user_scoped_providers.dart';
import 'package:lingola_buddy/Services/local_notification_scheduler.dart';
import 'package:lingola_buddy/Services/revenuecat_paywall.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> _onNotificationsChanged(
  BuildContext context,
  WidgetRef ref,
  bool value,
) async {
  final notifier = ref.read(userProfileControllerProvider.notifier);
  final granted = await notifier.setNotificationsEnabled(value);
  if (!context.mounted) return;

  if (value) {
    if (granted) {
      AppSnackBar.success(
        AppTranslations.section('profile', 'notifications_enabled'),
        context: context,
      );
      return;
    }
    final permanent = await notifier
        .isNotificationPermissionPermanentlyDenied();
    if (!context.mounted) return;
    AppSnackBar.error(
      AppTranslations.section('profile', 'notifications_denied'),
      context: context,
      actionLabel: permanent
          ? AppTranslations.section('chat', 'open_settings')
          : null,
      onAction: permanent ? openAppSettings : null,
    );
    return;
  }

  AppSnackBar.info(
    AppTranslations.section('profile', 'notifications_disabled'),
    context: context,
  );
}

Future<void> _onPremiumTap(BuildContext context, WidgetRef ref) async {
  final premium = ref.read(premiumControllerProvider);
  if (premium.isPro) {
    AppSnackBar.success(
      AppTranslations.sectionOr(
        'profile',
        'premium_already_active',
        AppTranslations.sectionOr('premium', 'already_active', 'Pro active'),
      ),
      context: context,
    );
    return;
  }
  await LingolaRevenueCatPaywall.presentSheet(context, ref);
}

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  static const Color _panelBackground = Color(0xFFF6F6F6);

  Future<void> _onLogOutTap(BuildContext context, WidgetRef ref) async {
    final confirmed = await LogoutConfirmDialog.show(context);
    if (confirmed != true || !context.mounted) return;
    await _logout(context, ref);
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await FutureExtensionsDialog.guard(context, () async {
      resetUserScopedAppState(ref);
      await LocalNotificationScheduler.instance.cancelAll();
      await ref.read(authRepositoryProvider).signOut();
      await ref.read(sessionControllerProvider.notifier).clearAuthSession();
      ref.read(userProfileControllerProvider.notifier).clearUser();
      ref.read(bottomNavControllerProvider.notifier).setIndex(0);
      if (!context.mounted) return;
      await Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamedAndRemoveUntil(AppRoutes.signUp, (route) => false);
    }());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileControllerProvider);
    final premium = ref.watch(premiumControllerProvider);
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
                  trailing: _ProfileNotificationSwitch(
                    value: profileState.notificationsEnabled,
                    onChanged: (value) =>
                        _onNotificationsChanged(context, ref, value),
                  ),
                ),
                _ProfileSettingsRow(
                  iconAsset: 'assets/icons/premium.svg',
                  label: AppTranslations.section('profile', 'premium'),
                  trailing: premium.isPro
                      ? Text(
                          AppTranslations.sectionOr(
                            'profile',
                            'premium_badge_pro',
                            AppTranslations.sectionOr(
                              'premium',
                              'badge_pro',
                              'Pro',
                            ),
                          ),
                          style: AppTextStyles.notificationCardTitle().copyWith(
                            color: AppColors.brandPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                  onTap: () => _onPremiumTap(context, ref),
                ),
                // _ProfileSettingsRow(
                //   iconAsset: 'assets/icons/share.svg',
                //   label: AppTranslations.section('profile', 'share_friend'),
                //   onTap: () => Navigator.pushNamed(context, '/share'),
                // ),
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
                // _ProfileSettingsRow(
                //   iconAsset: 'assets/icons/heart.svg',
                //   label: AppTranslations.section('profile', 'rate_us'),
                //   onTap: () {},
                // ),
                _ProfileSettingsRow(
                  iconAsset: 'assets/icons/faq.svg',
                  label: AppTranslations.section('profile', 'faq'),
                  onTap: () => Navigator.pushNamed(context, '/faq'),
                ),
                _ProfileSettingsRow(
                  iconAsset: 'assets/icons/heart_plus.svg',
                  label: AppTranslations.section('profile', 'contact_us'),
                  onTap: () => LegalLinkLauncher.openContactUs(context),
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
                  onTap: () => _onLogOutTap(context, ref),
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
                UserProfileAvatar(imageUrl: avatarPath, size: 88),
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

class _ProfileNotificationSwitch extends StatelessWidget {
  const _ProfileNotificationSwitch({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      width: 48,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          activeTrackColor: AppColors.brandPrimary.withValues(alpha: 0.35),
          activeThumbColor: AppColors.brandPrimary,
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
  });

  final String iconAsset;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
