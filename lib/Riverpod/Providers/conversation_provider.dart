import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Repositories/conversation_repository.dart';

final conversationRepositoryProvider = Provider<ConversationRepository>(
  (ref) => ConversationRepository(),
);
