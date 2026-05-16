import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Models/conversation_model.dart';

final talkHistoryProvider = Provider<List<ConversationSummaryModel>>((ref) {
  return const [
    ConversationSummaryModel(
      tutorId: 'sophie',
      tutorName: 'Sophie',
      updatedAtIso: '2026-05-07T10:00:00Z',
      lastMessagePreview: 'Harika bir pratik oldu...',
    ),
    ConversationSummaryModel(
      tutorId: 'james',
      tutorName: 'James',
      updatedAtIso: '2026-05-06T18:30:00Z',
      lastMessagePreview: 'Telaffuz için tekrar deneyelim.',
    ),
  ];
});
