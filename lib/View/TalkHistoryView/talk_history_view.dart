import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lingola_buddy/Riverpod/Providers/talk_history_provider.dart';

class TalkHistoryView extends ConsumerWidget {
  const TalkHistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(talkHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Geçmiş konuşmalar')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final row = items[index];
          return Material(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.pushNamed(
                context,
                '/chat',
                arguments: row.tutorId,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const CircleAvatar(child: Icon(Icons.chat_outlined)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.tutorName,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            row.lastMessagePreview ?? '',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/chat',
                        arguments: row.tutorId,
                      ),
                      child: const Text('Devam'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
