import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

abstract final class ProfilePhotoStorage {
  ProfilePhotoStorage._();

  static const _key = 'profile_avatar_path';

  static Future<String?> readPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_key);
    if (path == null || path.isEmpty) return null;
    if (!File(path).existsSync()) {
      await prefs.remove(_key);
      return null;
    }
    return path;
  }

  static Future<void> savePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, path);
  }

  static Future<void> clear({String? pathToDelete}) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = pathToDelete ?? prefs.getString(_key);
    if (stored != null && stored.isNotEmpty) {
      try {
        final file = File(stored);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    await prefs.remove(_key);
  }
}
