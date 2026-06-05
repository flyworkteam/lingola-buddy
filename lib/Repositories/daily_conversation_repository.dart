import 'package:lingola_buddy/Models/daily_conversation_model.dart';
import 'package:lingola_buddy/Services/http_api_service.dart';

class DailyConversationRepository {
  DailyConversationRepository({HttpApiService? http})
      : _http = http ?? HttpApiService();

  final HttpApiService _http;

  Future<UserDailyConversationCurriculum> fetchMyCurriculum() async {
    final envelope = await _http.get('/daily-conversations/me');
    final data = envelope['data'] as Map<String, dynamic>;
    return UserDailyConversationCurriculum.fromJson(data);
  }

  Future<UserDailyConversationCurriculum> setCurrent(String conversationId) async {
    final envelope = await _http.put(
      '/daily-conversations/me/current',
      body: {'conversationId': conversationId},
    );
    final data = envelope['data'] as Map<String, dynamic>;
    return UserDailyConversationCurriculum.fromJson(data);
  }

  Future<UserDailyConversationCurriculum> complete(String conversationId) async {
    final envelope = await _http.post(
      '/daily-conversations/me/$conversationId/complete',
      authenticated: true,
    );
    final data = envelope['data'] as Map<String, dynamic>;
    return UserDailyConversationCurriculum.fromJson(data);
  }
}
