import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Models/conversation_model.dart';
import 'package:lingola_buddy/Models/tutor_model.dart';
import 'package:lingola_buddy/Riverpod/Providers/tutors_catalog_provider.dart';

final talkHistoryProvider = Provider<List<ConversationSummaryModel>>((ref) {
  return const [
    ConversationSummaryModel(
      tutorId: 'lee',
      tutorName: 'Lee',
      updatedAtIso: '2026-05-16T10:00:00Z',
      timeLabel: '10:00 AM',
      lastMessagePreview:
          'Hey! I was about to explode with boredom. Your energy has reached me!',
    ),
    ConversationSummaryModel(
      tutorId: 'sophie',
      tutorName: 'Sophie',
      updatedAtIso: '2026-05-16T09:30:00Z',
      timeLabel: '10:00 AM',
      lastMessagePreview:
          'Hey! I was about to explode with boredom. Your energy has reached me!',
    ),
  ];
});

/// Sohbet geçmişi üst bölümünde gösterilen öne çıkan eğitmenler.
final talkFeaturedTutorsProvider = Provider<List<TutorModel>>((ref) {
  const featuredIds = ['clara', 'james'];
  final catalog = ref.watch(tutorsCatalogProvider);
  return [
    for (final id in featuredIds) catalog.where((t) => t.id == id).firstOrNull,
  ].whereType<TutorModel>().toList();
});

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final i = iterator;
    return i.moveNext() ? i.current : null;
  }
}
