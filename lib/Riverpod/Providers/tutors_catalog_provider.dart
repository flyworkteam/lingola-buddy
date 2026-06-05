import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Models/tutor_model.dart';
import 'package:lingola_buddy/Riverpod/Controllers/UserProfileController/user_profile_controller.dart';
import 'package:lingola_buddy/Riverpod/Providers/tutor_repository_provider.dart';

final tutorsCatalogAsyncProvider = FutureProvider<List<TutorModel>>((ref) {
  ref.watch(userProfileControllerProvider.select((s) => s.uiLanguageCode));
  return ref.read(tutorRepositoryProvider).fetchTutors();
});

/// API’den yüklenen eğitmen listesi; yüklenirken / hata durumunda yedek katalog.
final tutorsCatalogProvider = Provider<List<TutorModel>>((ref) {
  final async = ref.watch(tutorsCatalogAsyncProvider);
  return async.when(
    data: (list) => list.isNotEmpty ? list : TutorModel.fallbackCatalog(),
    loading: () => TutorModel.fallbackCatalog(),
    error: (_, __) => TutorModel.fallbackCatalog(),
  );
});

final tutorByIdProvider = Provider.family<TutorModel?, String>((ref, id) {
  return ref
      .watch(tutorsCatalogProvider)
      .where((t) => t.id == id)
      .firstOrNull;
});
