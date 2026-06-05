import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Repositories/tutor_repository.dart';

final tutorRepositoryProvider = Provider<TutorRepository>(
  (ref) => ApiTutorRepository(),
);
