import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Models/lesson_model.dart';
import 'package:lingola_buddy/Repositories/lesson_repository.dart';
import 'package:lingola_buddy/Riverpod/Providers/authenticated_user_scope_provider.dart';

final lessonRepositoryProvider = Provider<LessonRepository>(
  (ref) => LessonRepository(),
);

final userCurriculumProvider = FutureProvider<UserCurriculumModel>((ref) async {
  final userId = ref.watch(authenticatedUserIdProvider);
  if (userId == null) {
    throw StateError('Curriculum requires an authenticated user');
  }
  return ref.read(lessonRepositoryProvider).fetchMyCurriculum();
});
