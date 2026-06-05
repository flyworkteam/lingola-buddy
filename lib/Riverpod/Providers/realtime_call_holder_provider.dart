import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Services/realtime_call_engine.dart';

/// VideoCallView → ActiveCallView geçişinde WebSocket oturumunu taşır.
class RealtimeCallHolder extends Notifier<RealtimeCallEngine?> {
  @override
  RealtimeCallEngine? build() => null;

  void attach(RealtimeCallEngine engine) {
    state = engine;
  }

  Future<void> detachAndEnd() async {
    final engine = state;
    state = null;
    await engine?.end();
  }
}

final realtimeCallHolderProvider =
    NotifierProvider<RealtimeCallHolder, RealtimeCallEngine?>(
  RealtimeCallHolder.new,
);
