import 'package:flutter/material.dart';

import 'package:lingola_buddy/Core/Widgets/app_primary_button.dart';

class ProfileShareView extends StatelessWidget {
  const ProfileShareView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arkadaşa paylaş')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const AspectRatio(
              aspectRatio: 1.35,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(22)),
                  color: Color(0xfff1f5ff),
                ),
                child: Center(child: Icon(Icons.public, size: 64)),
              ),
            ),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paylaşım bağlantısı',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    const SelectableText('https://lingola.app/ref/invite-stub'),
                    Text(
                      'Gerçek link üretimi sonra eklenecek',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: AppPrimaryButton(label: 'Linki kopyala', onPressed: () {}),
        ),
      ),
    );
  }
}
