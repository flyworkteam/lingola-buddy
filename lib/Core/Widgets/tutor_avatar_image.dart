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
    this.loadingBackgroundColor,
    this.loadingIndicatorColor,
    this.hideAssetFallback = false,
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
  final Color? loadingBackgroundColor;
  final Color? loadingIndicatorColor;
  final bool hideAssetFallback;

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
        gaplessPlayback: hideAssetFallback ? false : gaplessPlayback,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return _loadingPlaceholder();
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _loadingPlaceholder(
            value: progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded /
                    progress.expectedTotalBytes!
                : null,
          );
        },
        errorBuilder: (_, __, ___) =>
            hideAssetFallback ? _loadingPlaceholder() : _fallback(),
      );
    }
    return hideAssetFallback ? _loadingPlaceholder() : _fallback();
  }

  Widget _loadingPlaceholder({double? value}) {
    final bg = loadingBackgroundColor ?? const Color(0xFFF6F6F6);
    final indicator = loadingIndicatorColor;
    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: bg,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: indicator != null
                ? CircularProgressIndicator(
                    strokeWidth: 2,
                    color: indicator,
                    value: value,
                  )
                : CircularProgressIndicator.adaptive(
                    strokeWidth: 2,
                    value: value,
                  ),
          ),
        ),
      ),
    );
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
