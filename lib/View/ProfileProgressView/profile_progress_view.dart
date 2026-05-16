import 'package:flutter/material.dart';

import 'package:lingola_buddy/Core/Widgets/app_primary_button.dart';

class ProfileProgressView extends StatelessWidget {
  const ProfileProgressView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final days = const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return Scaffold(
      appBar: AppBar(title: const Text('İlerleme')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final d in days) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(d),
                      side: BorderSide(
                        color: d == 'THU' ? scheme.primary : scheme.outlineVariant,
                      ),
                      backgroundColor:
                          d == 'THU' ? scheme.primaryContainer.withValues(alpha: 0.5) : null,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: _ProgressCard(icon: Icons.menu_book, title: 'WORD', subtitle: '247')),
              SizedBox(width: 10),
              Expanded(child: _ProgressCard(icon: Icons.gps_fixed, title: 'ACCURACY', subtitle: '89%')),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(child: _ProgressCard(icon: Icons.timer_outlined, title: 'TIME', subtitle: '30 min')),
              SizedBox(width: 10),
              Expanded(child: _ProgressCard(icon: Icons.emoji_events_outlined, title: 'LEVEL', subtitle: 'B1')),
            ],
          ),
          const SizedBox(height: 28),
          AppPrimaryButton(label: 'İlerlemeyi paylaş', onPressed: () {}),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            Text(subtitle, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
