import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Models/streak_model.dart';
import 'package:lingola_buddy/Repositories/streak_repository.dart';
import 'package:lingola_buddy/Riverpod/Providers/authenticated_user_scope_provider.dart';

final streakRepositoryProvider = Provider<StreakRepository>(
  (ref) => StreakRepository(),
);

final userStreakProvider = FutureProvider<StreakDashboardModel>((ref) async {
  final userId = ref.watch(authenticatedUserIdProvider);
  if (userId == null) {
    throw StateError('Streak requires an authenticated user');
  }
  return ref.read(streakRepositoryProvider).fetchMyStreak();
});
