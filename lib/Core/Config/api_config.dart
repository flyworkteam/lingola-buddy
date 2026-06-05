import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// REST + WS için API kök adresi.
///
/// - iOS Simulator → `127.0.0.1`
/// - Android Emulator → `10.0.2.2`
/// - Fiziksel cihaz → `.env` içindeki `API_LAN_HOST` / `API_BASE_URL`
class ApiConfig {
  ApiConfig._();

  static const int defaultPort = 3011;

  static String get baseUrl {
    if (kIsWeb) {
      return _physicalBaseUrl() ?? _simulatorBaseUrl();
    }

    if (Platform.isIOS && _isIosSimulator) {
      return _simulatorBaseUrl();
    }

    if (Platform.isAndroid && _isAndroidEmulator) {
      return 'http://10.0.2.2:$defaultPort';
    }

    return _physicalBaseUrl() ?? _simulatorBaseUrl();
  }

  static String get resolvedKind {
    if (kIsWeb) return 'web';
    if (Platform.isIOS && _isIosSimulator) return 'ios-simulator';
    if (Platform.isAndroid && _isAndroidEmulator) return 'android-emulator';
    if (Platform.isIOS || Platform.isAndroid) return 'physical-device';
    return 'desktop';
  }

  static String _simulatorBaseUrl() => 'http://127.0.0.1:$defaultPort';

  static String? _physicalBaseUrl() {
    final explicit = _env('API_BASE_URL_PHYSICAL');
    if (explicit != null) return _stripTrailingSlash(explicit);

    final lanHost = _env('API_LAN_HOST') ?? _env('DEV_HOST_IP');
    if (lanHost != null) {
      return 'http://$lanHost:$defaultPort';
    }

    final fromEnv = _env('API_BASE_URL');
    if (fromEnv == null) return null;

    final uri = Uri.tryParse(fromEnv);
    if (uri == null) return _stripTrailingSlash(fromEnv);

    if (uri.host == '127.0.0.1' || uri.host == 'localhost') {
      return null;
    }

    return _stripTrailingSlash(fromEnv);
  }

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
