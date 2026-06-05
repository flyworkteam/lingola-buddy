import 'package:flutter/material.dart';
import 'package:lingola_buddy/Models/tutor_model.dart';

/// Eğitmen portresi — önce CDN [photoUrl], yoksa yerel asset.
class TutorAvatarImage extends StatelessWidget {
  const TutorAvatarImage({
    super.key,
    required this.tutor,
    this.fallbackAsset = 'assets/images/avatar_1.png',
    this.fit = BoxFit.cover,
    this.alignment = Alignment.topCenter,
    this.width,
    this.height,
    this.cacheWidth,
    this.cacheHeight,
    this.filterQuality = FilterQuality.medium,
    this.gaplessPlayback = true,
  });

  final TutorModel tutor;
  final String fallbackAsset;
  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;
  final int? cacheWidth;
  final int? cacheHeight;
  final FilterQuality filterQuality;
  final bool gaplessPlayback;

  /// Mantıksal boyuta göre decode pikseli (jank önleme, bulanıklık için üst sınır yükseltildi).
  static int decodePixels(BuildContext context, double logicalSize) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return (logicalSize * dpr).round().clamp(64, 1280);
  }

  /// Portre CDN görselleri — yüz yerine üst gövde (CallPreview ile uyumlu).
  static const Alignment portraitAlignment = Alignment(0, 0.35);

  static NetworkImage? networkProvider(TutorModel tutor) {
    final url = tutor.photoUrl.trim();
    if (!url.startsWith('http')) return null;
    return NetworkImage(url);
  }

  static Future<void> precache(
    BuildContext context,
    TutorModel tutor, {
    int? cacheWidth,
    int? cacheHeight,
  }) async {
    final provider = networkProvider(tutor);
    if (provider == null) return;
    await precacheImage(
      ResizeImage(provider, width: cacheWidth, height: cacheHeight),
      context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = tutor.photoUrl.trim();
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        alignment: alignment,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        filterQuality: filterQuality,
        gaplessPlayback: gaplessPlayback,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return ColoredBox(
            color: const Color(0xFFF6F6F6),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator.adaptive(
                  strokeWidth: 2,
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Image.asset(
      fallbackAsset,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      filterQuality: filterQuality,
      gaplessPlayback: gaplessPlayback,
      errorBuilder: (_, __, ___) =>
          const Center(child: Icon(Icons.face_rounded, size: 48)),
    );
  }
}
