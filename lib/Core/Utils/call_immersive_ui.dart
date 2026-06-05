import 'package:flutter/services.dart';

/// Görüşme sırasında sistem gezinme çubuğunu gizler.
abstract final class CallImmersiveUi {
  static Future<void> enter() {
    return SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  static Future<void> exit() {
    return SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}
