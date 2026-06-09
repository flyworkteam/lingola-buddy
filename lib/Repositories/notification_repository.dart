import 'package:lingola_buddy/Models/notification_inbox_item.dart';
import 'package:lingola_buddy/Services/http_api_service.dart';

class NotificationRepository {
  NotificationRepository({HttpApiService? http}) : _http = http ?? HttpApiService();

  final HttpApiService _http;

  Future<List<NotificationInboxItem>> fetchMine({int limit = 50}) async {
    final envelope = await _http.get('/notifications/me?limit=$limit');
    final data = envelope['data'] as Map<String, dynamic>? ?? {};
    final list = data['notifications'] as List<dynamic>? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(_fromJson)
        .where((e) => e.title.trim().isNotEmpty)
        .toList();
  }

  Future<void> record(NotificationInboxItem item) async {
    await _http.post(
      '/notifications/me',
      body: _toJson(item),
      authenticated: true,
    );
  }

  Future<void> syncBatch(List<NotificationInboxItem> items) async {
    if (items.isEmpty) return;
    await _http.post(
      '/notifications/me/sync',
      body: {
        'notifications': items.map(_toJson).toList(),
      },
      authenticated: true,
    );
  }

  Future<void> clearAll() async {
    await _http.delete('/notifications/me');
  }

  NotificationInboxItem _fromJson(Map<String, dynamic> json) {
    final deliveredRaw = json['deliveredAtIso'] as String?;
    return NotificationInboxItem(
      id: json['id'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '🔔',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      deliveredAt: deliveredRaw != null
          ? DateTime.tryParse(deliveredRaw) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> _toJson(NotificationInboxItem item) {
    final type = item.id.split('_').firstOrNull ?? 'reminder';
    return {
      'clientKey': item.id,
      'notificationType': type,
      'emoji': item.emoji,
      'title': item.title,
      'body': item.description,
      'description': item.description,
      'deliveredAtIso': item.deliveredAt.toUtc().toIso8601String(),
    };
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
