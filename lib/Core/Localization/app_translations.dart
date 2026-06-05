import 'dart:convert';

import 'package:flutter/services.dart';

/// `assets/translations/tr.json` taban; diğer diller `assets/translations/{locale}.json` ile birleştirilir.
abstract final class AppTranslations {
  AppTranslations._();

  static const supportedLocaleCodes = [
    'en',
    'de',
    'it',
    'fr',
    'tr',
    'ja',
    'es',
    'ru',
    'ko',
    'hi',
    'pt',
    'zh',
  ];

  static Map<String, dynamic>? _root;
  static String _locale = 'tr';

  static String get locale => _locale;

  static Future<void> load({String locale = 'tr'}) async {
    _locale = supportedLocaleCodes.contains(locale) ? locale : 'tr';
    final tr = await _loadJsonFile('assets/translations/tr.json');
    if (tr == null) {
      throw StateError('tr.json yüklenemedi.');
    }
    if (_locale == 'tr') {
      _root = await _mergeDailyConversations(tr, 'tr');
      return;
    }
    final overlay = await _loadJsonFile('assets/translations/$_locale.json');
    final merged = overlay != null ? _deepMerge(tr, overlay) : tr;
    _root = await _mergeDailyConversations(merged, _locale);
  }

  static Future<Map<String, dynamic>> _mergeDailyConversations(
    Map<String, dynamic> base,
    String locale,
  ) async {
    final dailyOverlay = await _loadJsonFile(
      'assets/translations/daily_conversations/$locale.json',
    );
    if (dailyOverlay == null) return base;
    return Map<String, dynamic>.from(base)
      ..['daily_conversations'] = dailyOverlay;
  }

  static Future<void> setLocale(String locale) => load(locale: locale);

  static String section(String chapter, String key) {
    final value = trySection(chapter, key);
    if (value != null) return value;
    throw StateError('Çeviri anahtarı bulunamadı: $chapter.$key');
  }

  /// [section] gibi; yoksa [fallback] döner (hot reload / eksik anahtar çöküşünü önler).
  static String sectionOr(String chapter, String key, String fallback) {
    return trySection(chapter, key) ?? fallback;
  }

  static String? trySection(String chapter, String key) {
    final root = _root;
    if (root == null) {
      throw StateError('AppTranslations.load() henüz çağrılmadı.');
    }
    return _readSection(root, chapter, key);
  }

  /// `lessons.a1_01.title` gibi iç içe çeviri; yoksa [fallback].
  static String lessonField(
    String lessonId,
    String field, {
    required String fallback,
  }) {
    final root = _root;
    if (root == null) return fallback;
    final lessons = root['lessons'];
    if (lessons is Map<String, dynamic>) {
      final entry = lessons[lessonId];
      if (entry is Map<String, dynamic>) {
        final value = entry[field];
        if (value is String && value.trim().isNotEmpty) return value;
      }
    }
    return fallback;
  }

  /// `daily_conversations.dc_a1_01.title` — günlük konuşma metinleri.
  static String dailyConversationField(
    String conversationId,
    String field, {
    required String fallback,
  }) {
    final root = _root;
    if (root == null) return fallback;
    final map = root['daily_conversations'];
    if (map is Map<String, dynamic>) {
      final entry = map[conversationId];
      if (entry is Map<String, dynamic>) {
        final value = entry[field];
        if (value is String && value.trim().isNotEmpty) return value;
      }
    }
    return fallback;
  }

  static String interpolate(String template, Map<String, String> vars) {
    var s = template;
    for (final e in vars.entries) {
      s = s.replaceAll('{${e.key}}', e.value);
    }
    return s;
  }

  static Future<Map<String, dynamic>?> _loadJsonFile(String assetPath) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      return json.decode(raw) as Map<String, dynamic>;
    } on Object {
      return null;
    }
  }

  static Map<String, dynamic> _deepMerge(
    Map<String, dynamic> base,
    Map<String, dynamic> overlay,
  ) {
    final result = Map<String, dynamic>.from(base);
    for (final entry in overlay.entries) {
      final key = entry.key;
      final value = entry.value;
      final existing = result[key];
      if (value is Map<String, dynamic> &&
          existing is Map<String, dynamic>) {
        result[key] = _deepMerge(existing, value);
      } else {
        result[key] = value;
      }
    }
    return result;
  }

  static String? _readSection(
    Map<String, dynamic> root,
    String chapter,
    String key,
  ) {
    final map = root[chapter];
    if (map is! Map<String, dynamic>) return null;
    final value = map[key];
    return value is String ? value : null;
  }
}
