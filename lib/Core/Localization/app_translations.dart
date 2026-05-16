import 'dart:convert';

import 'package:flutter/services.dart';

/// `assets/translations/tr.json` — [load] çağrılmadan [section] kullanılmamalı ([main] içinde yükle).
abstract final class AppTranslations {
  AppTranslations._();

  static Map<String, dynamic>? _root;

  static Future<void> load() async {
    final raw = await rootBundle.loadString('assets/translations/tr.json');
    _root = json.decode(raw) as Map<String, dynamic>;
  }

  static String section(String chapter, String key) {
    final root = _root;
    if (root == null) {
      throw StateError('AppTranslations.load() henüz çağrılmadı.');
    }
    final map = root[chapter];
    if (map is! Map<String, dynamic>) {
      throw StateError('Çeviri bölümü bulunamadı: $chapter');
    }
    final value = map[key];
    if (value is! String) {
      throw StateError('Çeviri anahtarı bulunamadı: $chapter.$key');
    }
    return value;
  }
}
