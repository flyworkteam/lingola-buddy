import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lingola_buddy/Models/notification_inbox_item.dart';
import 'package:lingola_buddy/Repositories/notification_repository.dart';
import 'package:lingola_buddy/Services/session_local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gelen yerel bildirimlerin uygulama içi geçmişi (hesap başına, backend ile senkron).
abstract final class NotificationInboxStore {
  NotificationInboxStore._();

  static const _guestScope = 'guest';
  static final NotificationRepository _api = NotificationRepository();

  static String _scopeKey(String? userId) {
    final id = userId?.trim();
    if (id == null || id.isEmpty || id == 'local') return _guestScope;
    return id;
  }

  static String _deliveredKey(String scope) => 'notif_inbox_delivered_$scope';
  static String _pendingKey(String scope) => 'notif_inbox_pending_$scope';

  static Future<String> _scope() async {
    final userId = await SessionLocalStorage.getAuthUserId();
    return _scopeKey(userId);
  }

  static Future<bool> _hasAuth() async {
    final token = await SessionLocalStorage.getAuthToken();
    return token != null && token.isNotEmpty;
  }

  static String emojiForNotificationId(int id) {
    switch (id) {
      case 100:
        return '☀️';
      case 101:
        return '📚';
      case 102:
        return '🌙';
      case 200:
        return '🔥';
      case 201:
        return '📈';
      case 300:
        return '📖';
      case 301:
        return '📞';
      case 302:
        return '🎉';
      default:
        return '🔔';
    }
  }

  static Future<void> replacePending(List<PendingNotificationRecord> records) async {
    final scope = await _scope();
    final prefs = await SharedPreferences.getInstance();
    final encoded = records.map((e) => e.toJson()).toList();
    await prefs.setString(_pendingKey(scope), jsonEncode(encoded));
  }

  static Future<void> trackPending({
    required int notificationId,
    required String title,
    required String description,
    required DateTime scheduledAt,
  }) async {
    final scope = await _scope();
    final prefs = await SharedPreferences.getInstance();
    final existing = _decodePending(prefs.getString(_pendingKey(scope)));
    existing.removeWhere((e) => e.notificationId == notificationId);
    existing.add(
      PendingNotificationRecord(
        notificationId: notificationId,
        emoji: emojiForNotificationId(notificationId),
        title: title,
        description: description,
        scheduledAt: scheduledAt,
      ),
    );
    await prefs.setString(
      _pendingKey(scope),
      jsonEncode(existing.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> recordDelivered(NotificationInboxItem item) async {
    final scope = await _scope();
    final prefs = await SharedPreferences.getInstance();
    final list = _decodeDelivered(prefs.getString(_deliveredKey(scope)));
    list.removeWhere((e) => e.id == item.id);
    list.insert(0, item);
    final trimmed = list.take(50).toList();
    await prefs.setString(
      _deliveredKey(scope),
      jsonEncode(trimmed.map((e) => e.toJson()).toList()),
    );
    unawaited(_syncItemToBackend(item));
  }

  /// Zamanı gelen bekleyen bildirimleri gelen kutusuna taşır.
  static Future<void> flushDueDeliveries() async {
    final scope = await _scope();
    final prefs = await SharedPreferences.getInstance();
    final pending = _decodePending(prefs.getString(_pendingKey(scope)));
    if (pending.isEmpty) return;

    final now = DateTime.now();
    final due = pending.where((p) => !p.scheduledAt.isAfter(now)).toList();
    if (due.isEmpty) return;

    final remaining =
        pending.where((p) => p.scheduledAt.isAfter(now)).toList();
    for (final p in due) {
      await recordDelivered(p.toInboxItem());
    }
    await prefs.setString(
      _pendingKey(scope),
      jsonEncode(remaining.map((e) => e.toJson()).toList()),
    );
  }

  static Future<List<NotificationInboxItem>> loadDelivered() async {
    await flushDueDeliveries();

    final scope = await _scope();
    final prefs = await SharedPreferences.getInstance();
    final local = _decodeDelivered(prefs.getString(_deliveredKey(scope)));

    if (await _hasAuth()) {
      try {
        final remote = await _api.fetchMine();
        final remoteIds = remote.map((e) => e.id).toSet();
        final missing =
            local.where((e) => !remoteIds.contains(e.id)).toList();
        if (missing.isNotEmpty) {
          unawaited(_api.syncBatch(missing).catchError((_) {}));
        }

        final merged = _mergeItems(remote, local);
        await _cacheDelivered(merged);
        return merged;
      } catch (_) {
        // Ağ hatasında yerel önbelleğe düş.
      }
    }

    return local;
  }

  static Future<void> clearAll() async {
    final scope = await _scope();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deliveredKey(scope));
    await prefs.remove(_pendingKey(scope));

    if (await _hasAuth()) {
      unawaited(_api.clearAll().catchError((_) {}));
    }
  }

  static Future<void> handleNotificationResponse(
    NotificationResponse response,
  ) async {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final notificationId = (map['notificationId'] as num?)?.toInt() ?? 0;
      final title = map['title'] as String? ?? '';
      final body = map['body'] as String? ?? '';
      final scheduledAtMs = (map['scheduledAt'] as num?)?.toInt();
      final deliveredAt = scheduledAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(scheduledAtMs)
          : DateTime.now();

      await recordDelivered(
        NotificationInboxItem(
          id: '${notificationId}_${deliveredAt.millisecondsSinceEpoch}',
          emoji: emojiForNotificationId(notificationId),
          title: title,
          description: body,
          deliveredAt: DateTime.now(),
        ),
      );
    } catch (_) {}
  }

  static Future<void> _cacheDelivered(List<NotificationInboxItem> items) async {
    final scope = await _scope();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _deliveredKey(scope),
      jsonEncode(items.take(50).map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> _syncItemToBackend(NotificationInboxItem item) async {
    if (!await _hasAuth()) return;
    try {
      await _api.record(item);
    } catch (_) {}
  }

  static List<NotificationInboxItem> _mergeItems(
    List<NotificationInboxItem> primary,
    List<NotificationInboxItem> secondary,
  ) {
    final byId = <String, NotificationInboxItem>{};
    for (final item in [...primary, ...secondary]) {
      byId[item.id] = item;
    }
    final merged = byId.values.toList()
      ..sort((a, b) => b.deliveredAt.compareTo(a.deliveredAt));
    return merged.take(50).toList();
  }

  static List<NotificationInboxItem> _decodeDelivered(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(NotificationInboxItem.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static List<PendingNotificationRecord> _decodePending(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(PendingNotificationRecord.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // Arka planda yalnızca senkron prefs erişimi güvenli değil; açılışta flush yeterli.
}
