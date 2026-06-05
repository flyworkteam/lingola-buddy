import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Models/daily_conversation_model.dart';
import 'package:lingola_buddy/Repositories/daily_conversation_repository.dart';
import 'package:lingola_buddy/Riverpod/Providers/authenticated_user_scope_provider.dart';

final dailyConversationRepositoryProvider = Provider<DailyConversationRepository>(
  (ref) => DailyConversationRepository(),
);

final userDailyConversationProvider =
    FutureProvider<UserDailyConversationCurriculum>((ref) async {
  final userId = ref.watch(authenticatedUserIdProvider);
  if (userId == null) {
    throw StateError('Daily conversations require an authenticated user');
  }
  return ref.read(dailyConversationRepositoryProvider).fetchMyCurriculum();
});
