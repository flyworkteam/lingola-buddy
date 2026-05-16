import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lingola_buddy/Core/Widgets/app_primary_button.dart';
import 'package:lingola_buddy/Riverpod/Controllers/UserProfileController/user_profile_controller.dart';

class ProfileLanguageView extends ConsumerWidget {
  const ProfileLanguageView({super.key});

  static const _codes = <String>[
    'en',
    'de',
    'it',
    'fr',
    'tr',
    'ja',
    'es',
    'ru',
    'ko',
    'hi',
    'pt',
    'zh',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(userProfileControllerProvider).uiLanguageCode;

    return Scaffold(
      appBar: AppBar(title: const Text('Uygulama dili')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _codes.length,
              itemBuilder: (context, index) {
                final code = _codes[index];
                return ListTile(
                  title: Text(code.toUpperCase()),
                  subtitle: Text('Bayrak + çeviri sonradan (stub)'),
                  trailing: Icon(
                    selected == code
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                  ),
                  onTap: () => ref
                      .read(userProfileControllerProvider.notifier)
                      .setUiLanguageCode(code),
                  selected: selected == code,
                  selectedTileColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.35),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppPrimaryButton(label: 'Kaydet', onPressed: () {}),
          ),
        ],
      ),
    );
  }
}
