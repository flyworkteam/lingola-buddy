import 'package:lingola_buddy/Models/tutor_model.dart';
import 'package:lingola_buddy/Services/tutor_api_service.dart';

abstract class TutorRepository {
  Future<List<TutorModel>> fetchTutors();
}

class ApiTutorRepository implements TutorRepository {
  ApiTutorRepository({TutorApiService? api}) : _api = api ?? TutorApiService();

  final TutorApiService _api;

  @override
  Future<List<TutorModel>> fetchTutors() async {
    try {
      final tutors = await _api.fetchTutors();
      if (tutors.isNotEmpty) return tutors;
    } catch (_) {}
    return TutorModel.fallbackCatalog();
  }
}
