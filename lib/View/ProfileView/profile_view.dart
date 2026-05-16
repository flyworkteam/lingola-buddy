import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lingola_buddy/Core/Routes/app_routes.dart';
import 'package:lingola_buddy/Core/Widgets/app_primary_button.dart';
import 'package:lingola_buddy/Riverpod/Controllers/BottomNavController/bottom_nav_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/SessionController/session_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/UserProfileController/user_profile_controller.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    ref.read(sessionControllerProvider.notifier).resetOnboardingDemo();
    ref.read(bottomNavControllerProvider.notifier).setIndex(0);
    await Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
      AppRoutes.splash,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileControllerProvider);
    final user = profileState.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const CircleAvatar(radius: 36, child: Icon(Icons.face)),
                  const SizedBox(height: 12),
                  Text(
                    user?.displayName ?? '—',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(user?.email ?? ''),
                  const SizedBox(height: 12),
                  AppPrimaryButton(
                    label: 'Profili düzenle',
                    onPressed: () =>
                        Navigator.pushNamed(context, '/settings'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Genel ayarlar', style: TextStyle(fontWeight: FontWeight.w600)),
          _tile(context, Icons.language_outlined, 'Dil', () {
            Navigator.pushNamed(context, '/language');
          }),
          SwitchListTile.adaptive(
            secondary: Icon(
              Icons.notifications_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: const Text('Bildirimler'),
            value: profileState.notificationsEnabled,
            onChanged: (value) =>
                ref.read(userProfileControllerProvider.notifier).toggleNotifications(value),
          ),
          _tile(context, Icons.workspace_premium_outlined, 'Premium', () {}),
          _tile(context, Icons.ios_share_outlined, 'Arkadaşa paylaş', () {
            Navigator.pushNamed(context, '/share');
          }),
          _tile(context, Icons.trending_up, 'İlerleme', () {
            Navigator.pushNamed(context, '/progress');
          }),
          const SizedBox(height: 12),
          const Text('Destek', style: TextStyle(fontWeight: FontWeight.w600)),
          _tile(context, Icons.star_border_rounded, 'Bizi değerlendir', () {}),
          _tile(context, Icons.help_outline, 'SSS', () {
            Navigator.pushNamed(context, '/faq');
          }),
          _tile(context, Icons.mail_outline, 'Bizimle iletişim', () {}),
          const SizedBox(height: 12),
          const Text('Yasal', style: TextStyle(fontWeight: FontWeight.w600)),
          _tile(context, Icons.privacy_tip_outlined, 'Gizlilik politikası', () {
            Navigator.pushNamed(context, '/privacy');
          }),
          _tile(context, Icons.gavel_rounded, 'Kullanım şartları', () {
            Navigator.pushNamed(context, '/terms');
          }),
          const SizedBox(height: 16),
          AppPrimaryButton(
            label: 'Çıkış yap',
            onPressed: () => _logout(context, ref),
          ),
        ],
      ),
    );
  }
}

Widget _tile(
  BuildContext context,
  IconData icon,
  String title,
  VoidCallback onTap,
) {
  return ListTile(
    leading: Icon(icon),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}
