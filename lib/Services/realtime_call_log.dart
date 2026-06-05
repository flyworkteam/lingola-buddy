import 'package:flutter/foundation.dart';

/// Sesli/görüntülü arama tanılama logları ([REALTIME_CALL]).
abstract final class RealtimeCallLog {
  static void d(String message) {
    debugPrint('[REALTIME_CALL] $message');
  }

  static void w(String message) {
    debugPrint('[REALTIME_CALL] ⚠️ $message');
  }

  static void e(String message, [Object? err]) {
    if (err != null) {
      debugPrint('[REALTIME_CALL] ❌ $message — $err');
    } else {
      debugPrint('[REALTIME_CALL] ❌ $message');
    }
  }
}
