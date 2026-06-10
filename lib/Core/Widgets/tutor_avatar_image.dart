import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lingola_buddy/Core/Widgets/avatar_shimmer.dart';
import 'package:lingola_buddy/Models/tutor_model.dart';
import 'package:lingola_buddy/Services/tutor_asset_cache_service.dart';

/// Eğitmen portresi — disk önbelleği; yüklenene kadar shimmer.
class TutorAvatarImage extends StatelessWidget {
  const TutorAvatarImage({
    super.key,
    required this.tutor,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.topCenter,
    this.width,
    this.height,
    this.cacheWidth,
    this.cacheHeight,
    this.filterQuality = FilterQuality.medium,
    this.gaplessPlayback = true,
    this.shimmerBaseColor,
    this.shimmerHighlightColor,
    this.borderRadius = BorderRadius.zero,
  });

  final TutorModel tutor;
  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;
  final int? cacheWidth;
  final int? cacheHeight;
  final FilterQuality filterQuality;
  final bool gaplessPlayback;
  final Color? shimmerBaseColor;
  final Color? shimmerHighlightColor;
  final BorderRadius borderRadius;

  /// Mantıksal boyuta göre decode pikseli (jank önleme, bulanıklık için üst sınır yükseltildi).
  static int decodePixels(BuildContext context, double logicalSize) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return (logicalSize * dpr).round().clamp(64, 1280);
  }

  /// Portre CDN görselleri — yüz yerine üst gövde (CallPreview ile uyumlu).
  static const Alignment portraitAlignment = Alignment(0, 0.35);

  static Future<void> precache(
    BuildContext context,
    TutorModel tutor, {
    int? cacheWidth,
    int? cacheHeight,
  }) async {
    final url = tutor.photoUrl.trim();
    if (!url.startsWith('http')) return;

    TutorAssetCacheService.instance.preload(url);
    final file = await TutorAssetCacheService.instance.getCachedFile(url);
    if (file == null || !context.mounted) return;

    await precacheImage(
      ResizeImage(
        FileImage(file),
        width: cacheWidth,
        height: cacheHeight,
      ),
      context,
    );
  }

  Widget _shimmer() {
    return AvatarShimmer(
      width: width,
      height: height,
      baseColor: shimmerBaseColor ?? const Color(0xFFE8E8EC),
      highlightColor: shimmerHighlightColor ?? const Color(0xFFF8F8FA),
      borderRadius: borderRadius,
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = tutor.photoUrl.trim();
    if (!url.startsWith('http')) {
      return _shimmer();
    }

    return _CachedTutorPhoto(
      url: url,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      filterQuality: filterQuality,
      gaplessPlayback: gaplessPlayback,
      borderRadius: borderRadius,
      shimmer: _shimmer(),
    );
  }
}

class _CachedTutorPhoto extends StatefulWidget {
  const _CachedTutorPhoto({
    required this.url,
    required this.fit,
    required this.width,
    required this.height,
    required this.alignment,
    required this.cacheWidth,
    required this.cacheHeight,
    required this.filterQuality,
    required this.gaplessPlayback,
    required this.borderRadius,
    required this.shimmer,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final int? cacheWidth;
  final int? cacheHeight;
  final FilterQuality filterQuality;
  final bool gaplessPlayback;
  final BorderRadius borderRadius;
  final Widget shimmer;

  @override
  State<_CachedTutorPhoto> createState() => _CachedTutorPhotoState();
}

class _CachedTutorPhotoState extends State<_CachedTutorPhoto> {
  File? _file;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant _CachedTutorPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _file = null;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final ready =
        await TutorAssetCacheService.instance.cachedFileIfReady(widget.url);
    if (ready != null && mounted) {
      setState(() => _file = ready);
      return;
    }

    final file =
        await TutorAssetCacheService.instance.getCachedFile(widget.url);
    if (mounted) setState(() => _file = file);
  }

  @override
  Widget build(BuildContext context) {
    final file = _file;
    if (file == null) {
      return widget.shimmer;
    }

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Image.file(
        file,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        alignment: widget.alignment,
        cacheWidth: widget.cacheWidth,
        cacheHeight: widget.cacheHeight,
        filterQuality: widget.filterQuality,
        gaplessPlayback: widget.gaplessPlayback,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return widget.shimmer;
        },
        errorBuilder: (_, __, ___) => widget.shimmer,
      ),
    );
  }
}
