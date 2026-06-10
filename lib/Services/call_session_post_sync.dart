import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Core/Config/premium_config.dart';
import 'package:lingola_buddy/Riverpod/Controllers/CallSessionController/call_session_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/PremiumController/premium_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/SessionController/session_controller.dart';
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
    final isAuthenticated = ref.read(sessionControllerProvider).isAuthenticated;

    if (!isAuthenticated) {
      await _queueSession(session);
      return const CallSessionPostSyncResult();
    }

    await _recordPracticeForSession(ref, session);
    await _flushPendingPractice(ref);

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

  /// Giriş sonrası misafir görüşmelerini sunucuya aktarır.
  static Future<void> flushPendingAfterLogin(WidgetRef ref) async {
    if (!ref.read(sessionControllerProvider).isAuthenticated) return;
    await _flushPendingPractice(ref);
  }

  static Future<void> _queueSession(CallSessionState session) async {
    if (session.lastDurationSeconds <
        PremiumConfig.minDurationToCountSeconds) {
      return;
    }
    await SessionLocalStorage.enqueuePendingPractice(
      durationSeconds: session.lastDurationSeconds,
      wordsLearned: session.lastWordsSpoken,
      accuracyPercent: session.lastSessionScorePercent > 0
          ? session.lastSessionScorePercent
          : null,
    );
  }

  static Future<void> _recordPracticeForSession(
    WidgetRef ref,
    CallSessionState session,
  ) async {
    if (session.lastDurationSeconds <
        PremiumConfig.minDurationToCountSeconds) {
      return;
    }
    try {
      await ref.read(streakRepositoryProvider).recordPractice(
            durationSeconds: session.lastDurationSeconds,
            wordsLearned: session.lastWordsSpoken,
            accuracyPercent: session.lastSessionScorePercent > 0
                ? session.lastSessionScorePercent
                : null,
          );
      ref.invalidate(userStreakProvider);
    } catch (_) {}
  }

  static Future<void> _flushPendingPractice(WidgetRef ref) async {
    final pending = await SessionLocalStorage.drainPendingPractice();
    if (pending.isEmpty) return;

    for (final entry in pending) {
      if (entry.durationSeconds < PremiumConfig.minDurationToCountSeconds) {
        continue;
      }
      try {
        await ref.read(streakRepositoryProvider).recordPractice(
              durationSeconds: entry.durationSeconds,
              wordsLearned: entry.wordsLearned,
              accuracyPercent: entry.accuracyPercent,
            );
      } catch (_) {}
    }
    ref.invalidate(userStreakProvider);
  }
}
