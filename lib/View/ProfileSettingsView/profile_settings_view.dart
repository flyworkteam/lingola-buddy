import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lingola_buddy/Core/Widgets/app_primary_button.dart';
import 'package:lingola_buddy/Riverpod/Controllers/UserProfileController/user_profile_controller.dart';

class ProfileSettingsView extends ConsumerStatefulWidget {
  const ProfileSettingsView({super.key});

  @override
  ConsumerState<ProfileSettingsView> createState() => _ProfileSettingsViewState();
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

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileControllerProvider);
    _ensureControllers(profileState);

    final nameCtl = _name!;
    final emailCtl = _email!;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil ayarları')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(child: CircleAvatar(radius: 44, child: Icon(Icons.face))),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text('Fotoğrafı değiştir (stub)'),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameCtl,
            decoration: const InputDecoration(labelText: 'Ad'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emailCtl,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'E-posta',
              suffixIcon: Icon(Icons.lock_outline, size: 18),
              helperText: 'Doğrulama sonrası değiştirilebilir (stub)',
            ),
          ),
          const SizedBox(height: 24),
          AppPrimaryButton(
            label: 'Değişiklikleri kaydet',
            onPressed: () {
              ref
                  .read(userProfileControllerProvider.notifier)
                  .updateDisplayName(nameCtl.text.trim());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kaydedildi (lokal)')),
              );
            },
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {},
              child: Text(
                'Hesabı sil',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
