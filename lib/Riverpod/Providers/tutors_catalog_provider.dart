import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Models/tutor_model.dart';
import 'package:lingola_buddy/Riverpod/Controllers/UserProfileController/user_profile_controller.dart';
import 'package:lingola_buddy/Riverpod/Providers/tutor_repository_provider.dart';
import 'package:lingola_buddy/Services/tutor_assets_warmup_service.dart';

final tutorsCatalogAsyncProvider = FutureProvider<List<TutorModel>>((ref) async {
  ref.watch(userProfileControllerProvider.select((s) => s.uiLanguageCode));
  final list = await ref.read(tutorRepositoryProvider).fetchTutors();
  // Tam katalog ısınması arka planda; onboarding önizlemesini kilitlemesin.
  unawaited(
    Future<void>.delayed(
      const Duration(seconds: 2),
      () => TutorAssetsWarmupService.warmupCatalog(list),
    ),
  );
  return list;
});

/// API’den yüklenen eğitmen listesi; yüklenirken veya hata durumunda boş.
final tutorsCatalogProvider = Provider<List<TutorModel>>((ref) {
  final async = ref.watch(tutorsCatalogAsyncProvider);
  return async.maybeWhen(
    data: (list) => list,
    orElse: () => const [],
  );
});

final tutorByIdProvider = Provider.family<TutorModel?, String>((ref, id) {
  return ref
      .watch(tutorsCatalogProvider)
      .where((t) => t.id == id)
      .firstOrNull;
});
