import 'package:lingola_buddy/Models/lesson_model.dart';
import 'package:lingola_buddy/Services/http_api_service.dart';

class LessonRepository {
  LessonRepository({HttpApiService? http}) : _http = http ?? HttpApiService();

  final HttpApiService _http;

  Future<UserCurriculumModel> fetchMyCurriculum() async {
    final envelope = await _http.get('/lessons/me');
    final data = envelope['data'] as Map<String, dynamic>;
    return UserCurriculumModel.fromJson(data);
  }

  Future<UserCurriculumModel> setCurrentLesson(String lessonId) async {
    final envelope = await _http.put(
      '/lessons/me/current',
      body: {'lessonId': lessonId},
    );
    final data = envelope['data'] as Map<String, dynamic>;
    return UserCurriculumModel.fromJson(data);
  }

  Future<UserCurriculumModel> completeLesson(String lessonId) async {
    final envelope = await _http.post(
      '/lessons/me/$lessonId/complete',
      authenticated: true,
    );
    final data = envelope['data'] as Map<String, dynamic>;
    return UserCurriculumModel.fromJson(data);
  }

  Future<UserCurriculumModel> setCefrLevel(String cefrLevel) async {
    final envelope = await _http.put(
      '/lessons/me/level',
      body: {'cefrLevel': cefrLevel},
    );
    final data = envelope['data'] as Map<String, dynamic>;
    return UserCurriculumModel.fromJson(data);
  }
}
