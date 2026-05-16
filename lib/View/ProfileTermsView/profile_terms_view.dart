import 'package:flutter/material.dart';

class ProfileTermsView extends StatelessWidget {
  const ProfileTermsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kullanım şartları')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Şartlar metni daha sonra gelecek.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
