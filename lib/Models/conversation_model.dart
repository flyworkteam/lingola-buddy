// Geçmiş sohbet/satır özeti için iskelet (chat mesaj içeriği ileride eklenecek)

class ConversationSummaryModel {
  const ConversationSummaryModel({
    required this.tutorId,
    required this.tutorName,
    required this.updatedAtIso,
    this.lastMessagePreview,
  });

  final String tutorId;
  final String tutorName;
  final String updatedAtIso;
  final String? lastMessagePreview;
}
