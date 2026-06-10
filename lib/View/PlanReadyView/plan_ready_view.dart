import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Routes/call_navigation.dart';
import 'package:lingola_buddy/Core/Widgets/app_primary_button.dart';

class PlanReadyView extends ConsumerWidget {
  const PlanReadyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = AppTranslations.trySection('onboarding', 'plan_ready_note');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppTranslations.sectionOr(
            'onboarding',
            'plan_ready_app_bar',
            AppTranslations.section('onboarding', 'plan_ready_title'),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslations.section('onboarding', 'plan_ready_title'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                AppTranslations.section('onboarding', 'plan_ready_desc'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (note != null) ...[
                const SizedBox(height: 12),
                Text(
                  note,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              const Spacer(),
              AppPrimaryButton(
                label: AppTranslations.section(
                  'onboarding',
                  'plan_ready_button',
                ),
                onPressed: () {
                  CallNavigation.pushGuestPreview(context, ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
