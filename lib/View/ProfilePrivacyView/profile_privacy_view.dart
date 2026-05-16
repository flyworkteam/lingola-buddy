import 'package:flutter/material.dart';

class ProfilePrivacyView extends StatelessWidget {
  const ProfilePrivacyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gizlilik politikası')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Metin olarak gizlilik politikası daha sonra gelecek.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
