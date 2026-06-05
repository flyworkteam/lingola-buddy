import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Models/notification_inbox_item.dart';
import 'package:lingola_buddy/Models/streak_model.dart';
import 'package:lingola_buddy/Repositories/lesson_repository.dart';
import 'package:lingola_buddy/Repositories/streak_repository.dart';
import 'package:lingola_buddy/Services/notification_inbox_store.dart';
import 'package:lingola_buddy/Services/notification_permission_service.dart';
import 'package:lingola_buddy/Services/notification_personalization.dart';
import 'package:lingola_buddy/Services/session_local_storage.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Uygulama diline göre zamanlanmış yerel bildirimler (hatırlatıcı, seri, ilerleme, yarım ders).
class LocalNotificationScheduler {
  LocalNotificationScheduler._();

  static final LocalNotificationScheduler instance =
      LocalNotificationScheduler._();

  static const _channelId = 'lingola_learning_reminders';

  static const int idMorning = 100;
  static const int idAfternoon = 101;
  static const int idEvening = 102;
  static const int idStreak = 200;
  static const int idProgress = 201;
  static const int idUnfinishedLesson = 300;
  static const int idCallFollowUp = 301;
  static const int idLevelAdvanced = 302;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.local);
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        NotificationInboxStore.handleNotificationResponse(response);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    _initialized = true;
  }

  Future<void> onNotificationOpened(NotificationResponse response) async {
    await NotificationInboxStore.handleNotificationResponse(response);
  }

  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
    await SessionLocalStorage.clearCallReminder();
  }

  Future<void> clearCallFollowUp() async {
    await initialize();
    await SessionLocalStorage.clearCallReminder();
    await _plugin.cancel(idCallFollowUp);
  }

  /// Bildirim tercihi açıkken tüm planı yeniler (dil + kişiselleştirme).
  Future<void> syncEnabled({required bool enabled}) async {
    if (!enabled) {
      await cancelAll();
      return;
    }
    final granted = await NotificationPermissionService.isGranted();
    if (!granted) return;

    NotificationPersonalization? data;
    try {
      final token = await SessionLocalStorage.getAuthToken();
      if (token != null && token.isNotEmpty) {
        final curriculum = await LessonRepository().fetchMyCurriculum();
        StreakDashboardModel? streak;
        try {
          streak = await StreakRepository().fetchMyStreak();
        } catch (_) {}
        data = NotificationPersonalization.fromData(
          curriculum: curriculum,
          streak: streak,
        );
      }
    } catch (e) {
      debugPrint('LocalNotificationScheduler personalization: $e');
    }

    await syncWithPersonalization(data: data);
  }

  Future<void> syncWithPersonalization({
    NotificationPersonalization? data,
  }) async {
    await initialize();
    final granted = await NotificationPermissionService.isGranted();
    if (!granted) return;

    await cancelAll();
    await NotificationInboxStore.replacePending([]);

    await _scheduleDaily(
      id: idMorning,
      hour: 9,
      minute: 0,
      titleKey: 'reminder_morning_title',
      bodyKey: 'reminder_morning_body',
    );
    await _scheduleDaily(
      id: idAfternoon,
      hour: 14,
      minute: 0,
      titleKey: 'reminder_afternoon_title',
      bodyKey: 'reminder_afternoon_body',
    );
    await _scheduleDaily(
      id: idEvening,
      hour: 19,
      minute: 0,
      titleKey: 'reminder_evening_title',
      bodyKey: 'reminder_evening_body',
    );

    if (data != null) {
      if (data.streakDays > 0 && !data.practicedToday) {
        await _scheduleDaily(
          id: idStreak,
          hour: 20,
          minute: 30,
          titleKey: 'streak_title',
          bodyKey: 'streak_body',
          vars: {'streak': '${data.streakDays}'},
        );
      }

      if (data.totalCount > 0) {
        await _scheduleWeekly(
          id: idProgress,
          weekday: DateTime.monday,
          hour: 10,
          minute: 0,
          titleKey: 'progress_title',
          bodyKey: 'progress_body',
          vars: {
            'completed': '${data.completedCount}',
            'total': '${data.totalCount}',
            'percent': '${data.progressPercent}',
          },
        );
      }

      final lesson = data.unfinishedLessonTitle;
      if (lesson != null && lesson.isNotEmpty) {
        await _scheduleOneShot(
          id: idUnfinishedLesson,
          after: const Duration(hours: 4),
          titleKey: 'unfinished_lesson_title',
          bodyKey: 'unfinished_lesson_body',
          vars: {'lesson': lesson},
        );
      }
    }

    await _restoreCallFollowUp();
  }

  /// Seviyedeki tüm dersler bitince anında bildirim + gelen kutusu kaydı.
  Future<void> showLevelAdvanced({
    required String previousLevel,
    required String newLevel,
  }) async {
    await initialize();

    final title = _text('level_advanced_title');
    final body = _text(
      'level_advanced_body_fmt',
      vars: {'previous': previousLevel, 'new': newLevel},
    );
    final now = DateTime.now();
    final payload = jsonEncode({
      'notificationId': idLevelAdvanced,
      'title': title,
      'body': body,
      'scheduledAt': now.millisecondsSinceEpoch,
    });

    await NotificationInboxStore.recordDelivered(
      NotificationInboxItem(
        id: '${idLevelAdvanced}_${now.millisecondsSinceEpoch}',
        emoji: NotificationInboxStore.emojiForNotificationId(idLevelAdvanced),
        title: title,
        description: body,
        deliveredAt: now,
      ),
    );

    final enabled = await SessionLocalStorage.getNotificationsEnabled();
    if (!enabled) return;
    final granted = await NotificationPermissionService.isGranted();
    if (!granted) return;

    await _plugin.show(
      idLevelAdvanced,
      title,
      body,
      _notificationDetails(),
      payload: payload,
    );
  }

  /// Görüşme yarım bırakıldığında 2 saat sonra hatırlatma.
  Future<void> scheduleCallFollowUp({
    required String lessonId,
    required String lessonTitle,
  }) async {
    final title = lessonTitle.trim().isNotEmpty
        ? lessonTitle
        : AppTranslations.lessonField(lessonId, 'title', fallback: lessonId);
    final at = DateTime.now().add(const Duration(hours: 2));
    await SessionLocalStorage.saveCallReminder(
      lessonTitle: title,
      fireAtMs: at.millisecondsSinceEpoch,
    );

    final enabled = await SessionLocalStorage.getNotificationsEnabled();
    if (!enabled) return;
    final granted = await NotificationPermissionService.isGranted();
    if (!granted) return;

    await initialize();
    await _plugin.cancel(idCallFollowUp);
    await _scheduleOneShot(
      id: idCallFollowUp,
      at: at,
      titleKey: 'call_unfinished_title',
      bodyKey: 'call_unfinished_body',
      vars: {'lesson': title},
    );
  }

  Future<void> _restoreCallFollowUp() async {
    final pending = await SessionLocalStorage.loadCallReminder();
    if (pending == null) return;
    if (pending.fireAt.isBefore(DateTime.now())) {
      await SessionLocalStorage.clearCallReminder();
      return;
    }
    await _scheduleOneShot(
      id: idCallFollowUp,
      at: pending.fireAt,
      titleKey: 'call_unfinished_title',
      bodyKey: 'call_unfinished_body',
      vars: {'lesson': pending.lessonTitle},
    );
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String titleKey,
    required String bodyKey,
    Map<String, String> vars = const {},
  }) async {
    final when = _nextInstanceOfTime(hour, minute);
    await _zonedSchedule(
      id: id,
      when: when,
      titleKey: titleKey,
      bodyKey: bodyKey,
      vars: vars,
      matchComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleWeekly({
    required int id,
    required int weekday,
    required int hour,
    required int minute,
    required String titleKey,
    required String bodyKey,
    Map<String, String> vars = const {},
  }) async {
    final when = _nextInstanceOfWeekday(weekday, hour, minute);
    await _zonedSchedule(
      id: id,
      when: when,
      titleKey: titleKey,
      bodyKey: bodyKey,
      vars: vars,
      matchComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> _scheduleOneShot({
    required int id,
    Duration? after,
    DateTime? at,
    required String titleKey,
    required String bodyKey,
    Map<String, String> vars = const {},
  }) async {
    final target = at ?? DateTime.now().add(after ?? const Duration(hours: 2));
    if (!target.isAfter(DateTime.now())) return;
    await _zonedSchedule(
      id: id,
      when: tz.TZDateTime.from(target, tz.local),
      titleKey: titleKey,
      bodyKey: bodyKey,
      vars: vars,
    );
  }

  Future<void> _zonedSchedule({
    required int id,
    required tz.TZDateTime when,
    required String titleKey,
    required String bodyKey,
    Map<String, String> vars = const {},
    DateTimeComponents? matchComponents,
  }) async {
    final title = _text(titleKey);
    final body = _text(bodyKey, vars: vars);
    final details = _notificationDetails();
    final payload = jsonEncode({
      'notificationId': id,
      'title': title,
      'body': body,
      'scheduledAt': when.millisecondsSinceEpoch,
    });

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: matchComponents,
      payload: payload,
    );

    await NotificationInboxStore.trackPending(
      notificationId: id,
      title: title,
      description: body,
      scheduledAt: when,
    );
  }

  NotificationDetails _notificationDetails() {
    final channelName = _text('channel_name');
    final channelDesc = _text('channel_desc');
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  String _text(String key, {Map<String, String> vars = const {}}) {
    final raw = AppTranslations.trySection('local_notifications', key) ?? key;
    return vars.isEmpty ? raw : AppTranslations.interpolate(raw, vars);
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    var scheduled = _nextInstanceOfTime(hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

