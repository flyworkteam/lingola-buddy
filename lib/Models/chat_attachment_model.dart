enum ChatAttachmentKind { image, document, voice }

class ChatAttachment {
  const ChatAttachment({
    required this.kind,
    required this.localPath,
    required this.displayName,
    this.duration,
  });

  final ChatAttachmentKind kind;
  final String localPath;
  final String displayName;
  final Duration? duration;

  bool get isImage => kind == ChatAttachmentKind.image;
  bool get isDocument => kind == ChatAttachmentKind.document;
  bool get isVoice => kind == ChatAttachmentKind.voice;
}
