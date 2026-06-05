import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Models/conversation_model.dart';
import 'package:lingola_buddy/Models/tutor_model.dart';
import 'package:lingola_buddy/Riverpod/Providers/authenticated_user_scope_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/conversation_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/tutors_catalog_provider.dart';

/// Sohbet mesajı olan eğitmenler (sunucu / DB).

final talkHistoryProvider =
    FutureProvider<List<ConversationSummaryModel>>((ref) async {
  final userId = ref.watch(authenticatedUserIdProvider);
  if (userId == null) {
    throw StateError('Talk history requires an authenticated user');
  }
  return ref.read(conversationRepositoryProvider).fetchSummaries();
});

/// Üst bölümde gösterilen öne çıkan eğitmen kartları.
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
