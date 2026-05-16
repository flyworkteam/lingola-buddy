import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lingola_buddy/Core/Routes/app_routes.dart';
import 'package:lingola_buddy/Core/Widgets/app_primary_button.dart';
import 'package:lingola_buddy/Riverpod/Controllers/CallSessionController/call_session_controller.dart';

class PlanReadyView extends ConsumerWidget {
  const PlanReadyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hazır')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Planınız hazır. Şimdi konuşabilirsiniz.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Video/görüşme bileşeni ve gerçek arama servisleri daha sonra bağlanır.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const Spacer(),
              AppPrimaryButton(
                label: 'Start Talking ->',
                onPressed: () {
                  ref.read(callSessionControllerProvider.notifier).bindTutor('sophie');
                  Navigator.pushNamed(context, AppRoutes.callPreview);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
