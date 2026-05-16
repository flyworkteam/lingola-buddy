import 'package:flutter/material.dart';

/// Sihirbaz adımları: tam beyaz zemin (aura yok — tasarım).
class OnboardingWizardPageShell extends StatelessWidget {
  const OnboardingWizardPageShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: child,
        ),
      ),
    );
  }
}
