import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Models/app_enums.dart';

class CallSessionState {
  const CallSessionState({
    this.activeTutorId,
    this.activeLessonId,
    this.kind = CallKind.video,
    this.callStartedAt,
    this.lastDurationSeconds = 0,
    this.lastWordsSpoken = 0,
    this.lastSessionScorePercent = 0,
    this.lastLessonCompleted = false,
    this.planProgress = 0,
  });

  final String? activeTutorId;
  final String? activeLessonId;
  final CallKind kind;
  /// Görüntülü arama bağlanma ekranı açıldığında başlar; aktif ekranda devam eder.
  final DateTime? callStartedAt;
  final int lastDurationSeconds;
  final int lastWordsSpoken;
  final int lastSessionScorePercent;
  final bool lastLessonCompleted;
  /// Plan oluşturma ekranı için kaba ilerleme (0–1)
  final double planProgress;

  CallSessionState copyWith({
    String? activeTutorId,
    String? activeLessonId,
    CallKind? kind,
    DateTime? callStartedAt,
    bool clearCallStartedAt = false,
    int? lastDurationSeconds,
    int? lastWordsSpoken,
    int? lastSessionScorePercent,
    bool? lastLessonCompleted,
    double? planProgress,
  }) {
    return CallSessionState(
      activeTutorId: activeTutorId ?? this.activeTutorId,
      activeLessonId: activeLessonId ?? this.activeLessonId,
      kind: kind ?? this.kind,
      callStartedAt: clearCallStartedAt
          ? null
          : (callStartedAt ?? this.callStartedAt),
      lastDurationSeconds: lastDurationSeconds ?? this.lastDurationSeconds,
      lastWordsSpoken: lastWordsSpoken ?? this.lastWordsSpoken,
      lastSessionScorePercent:
          lastSessionScorePercent ?? this.lastSessionScorePercent,
      lastLessonCompleted: lastLessonCompleted ?? this.lastLessonCompleted,
      planProgress: planProgress ?? this.planProgress,
    );
  }
}

class CallSessionController extends Notifier<CallSessionState> {
  @override
  CallSessionState build() => const CallSessionState();

  void bindTutor(
    String tutorId, {
    CallKind kind = CallKind.video,
    String? lessonId,
  }) {
    state = state.copyWith(
      activeTutorId: tutorId,
      activeLessonId: lessonId,
      kind: kind,
    );
  }

  void markCallStarted([DateTime? at]) {
    if (state.callStartedAt != null) return;
    state = state.copyWith(callStartedAt: at ?? DateTime.now());
  }

  void setPlanProgress(double value) {
    state = state.copyWith(planProgress: value.clamp(0, 1).toDouble());
  }

  void endCall({
    required int durationSeconds,
    int wordsSpoken = 0,
    int sessionScorePercent = 0,
    bool lessonCompleted = false,
  }) {
    state = state.copyWith(
      lastDurationSeconds: durationSeconds,
      lastWordsSpoken: wordsSpoken,
      lastSessionScorePercent: sessionScorePercent.clamp(0, 100),
      lastLessonCompleted: lessonCompleted,
    );
  }

  void clearActiveSession() {
    state = const CallSessionState();
  }
}

final callSessionControllerProvider =
    NotifierProvider<CallSessionController, CallSessionState>(
        CallSessionController.new);
