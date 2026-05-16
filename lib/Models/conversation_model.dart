class ConversationSummaryModel {
  const ConversationSummaryModel({
    required this.tutorId,
    required this.tutorName,
    required this.updatedAtIso,
    this.lastMessagePreview,
    this.timeLabel,
  });

  final String tutorId;
  final String tutorName;
  final String updatedAtIso;
  final String? lastMessagePreview;
  final String? timeLabel;
}
