import 'package:lingola_buddy/Models/streak_model.dart';
import 'package:lingola_buddy/Services/http_api_service.dart';

class StreakRepository {
  StreakRepository({HttpApiService? http}) : _http = http ?? HttpApiService();

  final HttpApiService _http;

  Future<StreakDashboardModel> fetchMyStreak() async {
    final envelope = await _http.get('/stats/streak/me');
    final data = envelope['data'] as Map<String, dynamic>;
    return StreakDashboardModel.fromJson(data);
  }

  Future<StreakDashboardModel> recordPractice({
    int minutes = 0,
    int wordsLearned = 0,
    int? accuracyPercent,
  }) async {
    final envelope = await _http.post(
      '/stats/practice/me',
      body: {
        'minutes': minutes,
        if (wordsLearned > 0) 'wordsLearned': wordsLearned,
        if (accuracyPercent != null) 'accuracyPercent': accuracyPercent,
      },
      authenticated: true,
    );
    final data = envelope['data'] as Map<String, dynamic>;
    return StreakDashboardModel.fromJson(data);
  }
}
