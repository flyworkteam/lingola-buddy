import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Models/app_enums.dart';

class CallSessionState {
  const CallSessionState({
    this.activeTutorId,
    this.kind = CallKind.video,
    this.lastDurationSeconds = 0,
    this.planProgress = 0,
  });

  final String? activeTutorId;
  final CallKind kind;
  final int lastDurationSeconds;
  /// Plan oluşturma ekranı için kaba ilerleme (0–1)
  final double planProgress;

  CallSessionState copyWith({
    String? activeTutorId,
    CallKind? kind,
    int? lastDurationSeconds,
    double? planProgress,
  }) {
    return CallSessionState(
      activeTutorId: activeTutorId ?? this.activeTutorId,
      kind: kind ?? this.kind,
      lastDurationSeconds: lastDurationSeconds ?? this.lastDurationSeconds,
      planProgress: planProgress ?? this.planProgress,
    );
  }
}

class CallSessionController extends Notifier<CallSessionState> {
  @override
  CallSessionState build() => const CallSessionState();

  void bindTutor(String tutorId, {CallKind kind = CallKind.video}) {
    state = state.copyWith(activeTutorId: tutorId, kind: kind);
  }

  void setPlanProgress(double value) {
    state = state.copyWith(planProgress: value.clamp(0, 1).toDouble());
  }

  void endCall({int durationSeconds = 420}) {
    state = state.copyWith(lastDurationSeconds: durationSeconds);
  }

  void clearActiveSession() {
    state = state.copyWith(activeTutorId: null, lastDurationSeconds: 0);
  }
}

final callSessionControllerProvider =
    NotifierProvider<CallSessionController, CallSessionState>(
        CallSessionController.new);
