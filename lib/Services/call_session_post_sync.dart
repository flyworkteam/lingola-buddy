import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Riverpod/Controllers/CallSessionController/call_session_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/PremiumController/premium_controller.dart';
import 'package:lingola_buddy/Riverpod/Providers/curriculum_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/daily_conversation_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/streak_provider.dart';
import 'package:lingola_buddy/Services/local_notification_scheduler.dart';
import 'package:lingola_buddy/Services/session_local_storage.dart';

class CallSessionPostSyncResult {
  const CallSessionPostSyncResult({
    this.levelAdvanced = false,
    this.levelPrevious,
    this.levelNew,
  });

  final bool levelAdvanced;
  final String? levelPrevious;
  final String? levelNew;
}

/// Görüşme sonrası istatistik, kota ve ders ilerlemesini backend'e yazar.
abstract final class CallSessionPostSync {
  static Future<CallSessionPostSyncResult> sync(WidgetRef ref) async {
    final session = ref.read(callSessionControllerProvider);
    final minutes = session.lastDurationSeconds ~/ 60;
    final words = session.lastWordsSpoken;
    final score = session.lastSessionScorePercent;

    try {
      await ref.read(streakRepositoryProvider).recordPractice(
            minutes: minutes,
            wordsLearned: words,
            accuracyPercent: score > 0 ? score : null,
          );
      ref.invalidate(userStreakProvider);
    } catch (_) {}

    await ref.read(premiumControllerProvider.notifier).recordCompletedCall(
          durationSeconds: session.lastDurationSeconds,
        );

    if (!session.lastLessonCompleted) {
      return const CallSessionPostSyncResult();
    }

    final lessonId = session.activeLessonId;
    if (lessonId == null || lessonId.isEmpty) {
      return const CallSessionPostSyncResult();
    }

    CallSessionPostSyncResult result = const CallSessionPostSyncResult();

    try {
      if (lessonId.startsWith('dc_')) {
        await ref.read(dailyConversationRepositoryProvider).complete(lessonId);
        ref.invalidate(userDailyConversationProvider);
      } else {
        final updated =
            await ref.read(lessonRepositoryProvider).completeLesson(lessonId);
        if (updated.levelAdvanced &&
            updated.previousLevel != null &&
            updated.newLevel != null) {
          unawaited(
            LocalNotificationScheduler.instance.showLevelAdvanced(
              previousLevel: updated.previousLevel!,
              newLevel: updated.newLevel!,
            ),
          );
          result = CallSessionPostSyncResult(
            levelAdvanced: true,
            levelPrevious: updated.previousLevel,
            levelNew: updated.newLevel,
          );
        }
      }
      ref.invalidate(userCurriculumProvider);
      ref.invalidate(userStreakProvider);
      unawaited(SessionLocalStorage.clearCallReminder());
      unawaited(LocalNotificationScheduler.instance.clearCallFollowUp());
      unawaited(
        LocalNotificationScheduler.instance.syncEnabled(enabled: true),
      );
    } catch (_) {}

    return result;
  }
}
