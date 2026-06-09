import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// REST + WS için API kök adresi.
///
/// Varsayılan: `https://lingolabuddy.fly-work.com`
///
/// Yerel geliştirme için `.env`:
/// - `API_BASE_URL=http://192.168.x.x:3011` veya
/// - `USE_LOCAL_API=true` (simülatör/emülatör → 127.0.0.1 / 10.0.2.2)
class ApiConfig {
  ApiConfig._();

  static const String productionBaseUrl = 'https://lingolabuddy.fly-work.com';
  static const int defaultPort = 3011;

  static String get baseUrl {
    final explicit = _env('API_BASE_URL');
    if (explicit != null) return _stripTrailingSlash(explicit);

    final lanHost = _env('API_LAN_HOST') ?? _env('DEV_HOST_IP');
    if (lanHost != null) return 'http://$lanHost:$defaultPort';

    final physical = _env('API_BASE_URL_PHYSICAL');
    if (physical != null) return _stripTrailingSlash(physical);

    if (_useLocalApi) {
      if (kIsWeb) return _simulatorBaseUrl();
      if (Platform.isIOS && _isIosSimulator) return _simulatorBaseUrl();
      if (Platform.isAndroid && _isAndroidEmulator) {
        return 'http://10.0.2.2:$defaultPort';
      }
    }

    return productionBaseUrl;
  }

  static bool get _useLocalApi => _env('USE_LOCAL_API') == 'true';

  static String get resolvedKind {
    if (baseUrl == productionBaseUrl) return 'production';
    if (kIsWeb) return 'web';
    if (Platform.isIOS && _isIosSimulator) return 'ios-simulator';
    if (Platform.isAndroid && _isAndroidEmulator) return 'android-emulator';
    if (Platform.isIOS || Platform.isAndroid) return 'physical-device';
    return 'desktop';
  }

  static String _simulatorBaseUrl() => 'http://127.0.0.1:$defaultPort';

  static bool get _isIosSimulator =>
      Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');

  static bool get _isAndroidEmulator {
    final serial = Platform.environment['ANDROID_SERIAL'];
    return Platform.environment.containsKey('ANDROID_EMULATOR') ||
        (serial != null && serial.startsWith('emulator'));
  }

  static String? _env(String key) {
    final value = dotenv.env[key]?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  static String _stripTrailingSlash(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
}
