import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Misafir girişi için cihaza özgü sabit kimlik.
class DeviceIdService {
  DeviceIdService._();

  static const _prefsKey = 'lingola_device_id';

  static Future<String> getStableDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_prefsKey);
    if (cached != null && cached.length >= 16) return cached;

    String raw;
    final plugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await plugin.androidInfo;
      raw = info.id;
    } else if (Platform.isIOS) {
      final info = await plugin.iosInfo;
      raw = info.identifierForVendor ?? const Uuid().v4();
    } else {
      raw = const Uuid().v4();
    }

    final id = 'lb_${raw}_${const Uuid().v4().substring(0, 8)}';
    await prefs.setString(_prefsKey, id);
    return id;
  }
}
