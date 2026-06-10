import 'package:lingola_buddy/Models/chat_attachment_model.dart';

enum ChatMessageRole { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.isTyping = false,
    this.attachment,
  });

  final String id;
  final ChatMessageRole role;
  final String text;
  final bool isTyping;
  final ChatAttachment? attachment;

  bool get isUser => role == ChatMessageRole.user;
  bool get isAssistant => role == ChatMessageRole.assistant;
  bool get hasAttachment => attachment != null;

  /// OpenAI geçmişi için metin (sesli mesajlarda transkript).
  String get apiText => text.trim();

  ChatMessage copyWith({
    String? id,
    ChatMessageRole? role,
    String? text,
    bool? isTyping,
    ChatAttachment? attachment,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      isTyping: isTyping ?? this.isTyping,
      attachment: attachment ?? this.attachment,
    );
  }
}
