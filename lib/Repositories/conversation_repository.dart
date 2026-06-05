import 'dart:io';

import 'package:lingola_buddy/Models/chat_attachment_model.dart';
import 'package:lingola_buddy/Models/chat_message_model.dart';
import 'package:lingola_buddy/Models/conversation_model.dart';
import 'package:lingola_buddy/Services/http_api_service.dart';

class ConversationRepository {
  ConversationRepository({HttpApiService? http}) : _http = http ?? HttpApiService();

  final HttpApiService _http;

  Future<List<ConversationSummaryModel>> fetchSummaries() async {
    final envelope = await _http.get('/conversations/me');
    final data = envelope['data'] as Map<String, dynamic>? ?? {};
    final list = data['conversations'] as List<dynamic>? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(_summaryFromJson)
        .where((s) => s.lastMessagePreview?.trim().isNotEmpty == true)
        .toList();
  }

  Future<bool> hasMessages(String tutorId) async {
    final envelope = await _http.get('/conversations/tutor/$tutorId/has-messages');
    final data = envelope['data'] as Map<String, dynamic>? ?? {};
    return data['hasMessages'] as bool? ?? false;
  }

  Future<List<ChatMessage>> fetchMessages(String tutorId) async {
    final envelope = await _http.get('/conversations/tutor/$tutorId/messages');
    final data = envelope['data'] as Map<String, dynamic>? ?? {};
    final list = data['messages'] as List<dynamic>? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(_messageFromJson)
        .whereType<ChatMessage>()
        .toList();
  }

  Future<void> deleteConversation(String tutorId) async {
    await _http.delete('/conversations/tutor/$tutorId');
  }

  Future<void> saveMessage({
    required String tutorId,
    required ChatMessage message,
  }) async {
    await _http.post(
      '/conversations/tutor/$tutorId/messages',
      body: {
        'role': message.role.name,
        'text': message.text,
        'clientId': message.id,
        if (message.attachment != null)
          'attachment': _attachmentToJson(message.attachment!),
      },
      authenticated: true,
    );
  }

  static ConversationSummaryModel _summaryFromJson(Map<String, dynamic> json) {
    final updatedAt = json['updatedAtIso'] as String? ?? '';
    return ConversationSummaryModel(
      tutorId: json['tutorId'] as String? ?? '',
      tutorName: json['tutorId'] as String? ?? '',
      updatedAtIso: updatedAt,
      lastMessagePreview: json['lastMessagePreview'] as String?,
    );
  }

  static ChatMessage? _messageFromJson(Map<String, dynamic> json) {
    final roleRaw = json['role'] as String?;
    if (roleRaw == null) return null;
    final role = ChatMessageRole.values
        .where((r) => r.name == roleRaw)
        .firstOrNull;
    if (role == null) return null;

    ChatAttachment? attachment;
    final att = json['attachment'];
    if (att is Map<String, dynamic>) {
      attachment = _attachmentFromJson(att);
    }

    return ChatMessage(
      id: json['id'] as String? ?? 'db-${json.hashCode}',
      role: role,
      text: json['text'] as String? ?? '',
      attachment: attachment,
    );
  }

  static Map<String, dynamic> _attachmentToJson(ChatAttachment a) {
    return {
      'kind': a.kind.name,
      'localPath': a.localPath,
      'displayName': a.displayName,
      if (a.duration != null) 'durationMs': a.duration!.inMilliseconds,
    };
  }

  static ChatAttachment? _attachmentFromJson(Map<String, dynamic> json) {
    final kindRaw = json['kind'] as String?;
    final localPath = json['localPath'] as String?;
    final displayName = json['displayName'] as String?;
    final kind = ChatAttachmentKind.values
        .where((k) => k.name == kindRaw)
        .firstOrNull;
    if (kind == null || localPath == null || displayName == null) return null;
    if (!File(localPath).existsSync()) return null;
    final ms = json['durationMs'];
    return ChatAttachment(
      kind: kind,
      localPath: localPath,
      displayName: displayName,
      duration: ms is num ? Duration(milliseconds: ms.toInt()) : null,
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final i = iterator;
    return i.moveNext() ? i.current : null;
  }
}
