import 'package:lingola_buddy/Core/Config/api_config.dart';

/// WebSocket realtime arama endpoint'i ([ApiConfig.baseUrl] ile aynı host).
class RealtimeConfig {
  RealtimeConfig._();

  static String get wsBaseUrl {
    final base = ApiConfig.baseUrl.trim();
    final uri = Uri.parse(base.endsWith('/') ? base.substring(0, base.length - 1) : base);
    final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final portPart = uri.hasPort ? ':${uri.port}' : '';
    final path = '/realtime';
    return '$wsScheme://${uri.host}$portPart$path';
  }
}
