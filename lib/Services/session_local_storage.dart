import 'dart:convert';

import 'package:lingola_buddy/Core/Config/device_ui_language.dart';
import 'package:lingola_buddy/Riverpod/Controllers/SessionController/session_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cihazda kalıcı oturum ve onboarding bayrakları.
class SessionLocalStorage {
  SessionLocalStorage._();

  static const _keyAuthToken = 'auth_token';
  static const _keyUserId = 'auth_user_id';
  static const _keyCredential = 'auth_credential';
  static const _keyIntroCarousel = 'intro_carousel_completed';
  static const _keyPreferenceWizard = 'preference_wizard_completed';
  static const _keyPostCallUpsell = 'post_call_upsell_completed';
  static const _keyUiLanguageCode = 'ui_language_code';
  static const _keyUiLanguageManual = 'ui_language_manual';
  static const _keyNotificationsEnabled = 'notifications_enabled';
  static const _keyCallReminderTitle = 'notif_call_lesson_title';
  static const _keyCallReminderAtMs = 'notif_call_reminder_at_ms';
  static const _keyFreeCallsUsedPrefix = 'premium_free_calls_used_';
  static const _keyPendingPracticeQueue = 'pending_practice_queue';

  static Future<SessionState> loadSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyAuthToken);
    return SessionState(
      hasCompletedIntroCarousel: prefs.getBool(_keyIntroCarousel) ?? false,
      hasCompletedPreferenceWizard: prefs.getBool(_keyPreferenceWizard) ?? false,
      hasCompletedPostCallUpsell: prefs.getBool(_keyPostCallUpsell) ?? false,
      isAuthenticated: token != null && token.isNotEmpty,
    );
  }

  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAuthToken);
  }

  static Future<String?> getAuthUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  static Future<void> saveAuth({
    required String token,
    required String userId,
    required String credential,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAuthToken, token);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyCredential, credential);
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAuthToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyCredential);
  }

  static Future<void> setIntroCarouselCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIntroCarousel, value);
  }

  static Future<void> setPreferenceWizardCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPreferenceWizard, value);
  }

  static Future<void> setPostCallUpsellCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPostCallUpsell, value);
  }

  static Future<bool> isUiLanguageManual() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUiLanguageManual) ?? false;
  }

  /// Profilde elle seçilmediyse cihaz dili; seçildiyse kayıtlı tercih.
  static Future<String> resolveUiLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    final manual = prefs.getBool(_keyUiLanguageManual) ?? false;
    if (manual) {
      return prefs.getString(_keyUiLanguageCode) ?? DeviceUiLanguage.resolve();
    }
    final device = DeviceUiLanguage.resolve();
    await prefs.setString(_keyUiLanguageCode, device);
    return device;
  }

  static Future<String> getUiLanguageCode() => resolveUiLanguageCode();

  static Future<void> setUiLanguageCode(
    String code, {
    bool manual = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUiLanguageCode, code);
    if (manual) {
      await prefs.setBool(_keyUiLanguageManual, true);
    }
  }

  static Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? false;
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, value);
  }

  static Future<void> saveCallReminder({
    required String lessonTitle,
    required int fireAtMs,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCallReminderTitle, lessonTitle);
    await prefs.setInt(_keyCallReminderAtMs, fireAtMs);
  }

  static Future<PendingCallReminder?> loadCallReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final title = prefs.getString(_keyCallReminderTitle);
    final atMs = prefs.getInt(_keyCallReminderAtMs);
    if (title == null || atMs == null) return null;
    return PendingCallReminder(
      lessonTitle: title,
      fireAt: DateTime.fromMillisecondsSinceEpoch(atMs),
    );
  }

  static Future<void> clearCallReminder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCallReminderTitle);
    await prefs.remove(_keyCallReminderAtMs);
  }

  static Future<int> getFreeCallsUsed(String userId) async {
    if (userId.isEmpty) return 0;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_keyFreeCallsUsedPrefix$userId') ?? 0;
  }

  static Future<void> setFreeCallsUsed(String userId, int value) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_keyFreeCallsUsedPrefix$userId', value.clamp(0, 999));
  }

  static Future<int> incrementFreeCallsUsed(String userId) async {
    final current = await getFreeCallsUsed(userId);
    final next = current + 1;
    await setFreeCallsUsed(userId, next);
    return next;
  }

  static Future<void> enqueuePendingPractice({
    required int durationSeconds,
    int wordsLearned = 0,
    int? accuracyPercent,
  }) async {
    if (durationSeconds <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyPendingPracticeQueue) ?? [];
    raw.add(
      jsonEncode({
        'durationSeconds': durationSeconds,
        'wordsLearned': wordsLearned,
        if (accuracyPercent != null) 'accuracyPercent': accuracyPercent,
      }),
    );
    await prefs.setStringList(_keyPendingPracticeQueue, raw);
  }

  static Future<List<PendingPracticeEntry>> drainPendingPractice() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyPendingPracticeQueue) ?? [];
    await prefs.remove(_keyPendingPracticeQueue);
    final out = <PendingPracticeEntry>[];
    for (final line in raw) {
      try {
        final map = jsonDecode(line) as Map<String, dynamic>;
        final seconds = (map['durationSeconds'] as num?)?.toInt() ?? 0;
        if (seconds <= 0) continue;
        out.add(
          PendingPracticeEntry(
            durationSeconds: seconds,
            wordsLearned: (map['wordsLearned'] as num?)?.toInt() ?? 0,
            accuracyPercent: (map['accuracyPercent'] as num?)?.toInt(),
          ),
        );
      } catch (_) {}
    }
    return out;
  }
}

class PendingCallReminder {
  const PendingCallReminder({
    required this.lessonTitle,
    required this.fireAt,
  });

  final String lessonTitle;
  final DateTime fireAt;
}

class PendingPracticeEntry {
  const PendingPracticeEntry({
    required this.durationSeconds,
    this.wordsLearned = 0,
    this.accuracyPercent,
  });

  final int durationSeconds;
  final int wordsLearned;
  final int? accuracyPercent;
}
