import 'package:lingola_buddy/Models/tutor_model.dart';
import 'package:lingola_buddy/Services/http_api_service.dart';

class TutorApiService {
  TutorApiService({HttpApiService? http}) : _http = http ?? HttpApiService();

  final HttpApiService _http;

  Future<List<TutorModel>> fetchTutors() async {
    final envelope = await _http.get('/tutors', authenticated: false);
    final data = envelope['data'] as Map<String, dynamic>;
    final list = data['tutors'] as List<dynamic>? ?? [];
    return list
        .map((e) => TutorModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TutorModel?> fetchTutorById(String id) async {
    final envelope = await _http.get('/tutors/$id', authenticated: false);
    final data = envelope['data'] as Map<String, dynamic>;
    final json = data['tutor'] as Map<String, dynamic>?;
    if (json == null) return null;
    return TutorModel.fromJson(json);
  }
}
