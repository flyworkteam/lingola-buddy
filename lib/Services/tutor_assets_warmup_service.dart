import 'dart:async';

import 'package:lingola_buddy/Models/tutor_model.dart';
import 'package:lingola_buddy/Services/rive_preload_service.dart';
import 'package:lingola_buddy/Services/tutor_asset_cache_service.dart';

/// Katalog yüklendiğinde tüm eğitmen görsellerini ve .riv dosyalarını önbelleğe alır.
abstract final class TutorAssetsWarmupService {
  TutorAssetsWarmupService._();

  static Future<void> warmupCatalog(List<TutorModel> tutors) async {
    if (tutors.isEmpty) return;

    await Future.wait(
      tutors.map(warmupTutor),
      eagerError: false,
    );
  }

  static Future<void> warmupTutor(TutorModel tutor) async {
    final photo = tutor.photoUrl.trim();
    final riv = tutor.resolvedRivUrl;

    await Future.wait([
      if (photo.startsWith('http'))
        TutorAssetCacheService.instance.getCachedFile(photo),
      RivePreloadService.instance.ensureLoader(riv),
    ], eagerError: false);
  }
}
