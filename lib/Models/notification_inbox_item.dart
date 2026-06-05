class NotificationInboxItem {
  const NotificationInboxItem({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.deliveredAt,
  });

  final String id;
  final String emoji;
  final String title;
  final String description;
  final DateTime deliveredAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'emoji': emoji,
        'title': title,
        'description': description,
        'deliveredAt': deliveredAt.millisecondsSinceEpoch,
      };

  factory NotificationInboxItem.fromJson(Map<String, dynamic> json) {
    return NotificationInboxItem(
      id: json['id'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '🔔',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      deliveredAt: DateTime.fromMillisecondsSinceEpoch(
        (json['deliveredAt'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}

/// Zamanlanmış; henüz kutuya düşmemiş bildirim.
class PendingNotificationRecord {
  const PendingNotificationRecord({
    required this.notificationId,
    required this.emoji,
    required this.title,
    required this.description,
    required this.scheduledAt,
  });

  final int notificationId;
  final String emoji;
  final String title;
  final String description;
  final DateTime scheduledAt;

  Map<String, dynamic> toJson() => {
        'notificationId': notificationId,
        'emoji': emoji,
        'title': title,
        'description': description,
        'scheduledAt': scheduledAt.millisecondsSinceEpoch,
      };

  factory PendingNotificationRecord.fromJson(Map<String, dynamic> json) {
    return PendingNotificationRecord(
      notificationId: (json['notificationId'] as num?)?.toInt() ?? 0,
      emoji: json['emoji'] as String? ?? '🔔',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      scheduledAt: DateTime.fromMillisecondsSinceEpoch(
        (json['scheduledAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  NotificationInboxItem toInboxItem() {
    return NotificationInboxItem(
      id: '${notificationId}_${scheduledAt.millisecondsSinceEpoch}',
      emoji: emoji,
      title: title,
      description: description,
      deliveredAt: scheduledAt,
    );
  }
}
