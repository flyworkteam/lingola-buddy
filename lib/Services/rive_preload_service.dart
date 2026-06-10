import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:rive/rive.dart' as rive;
import 'package:lingola_buddy/Services/tutor_asset_cache_service.dart';

/// Tutor .riv dosyalarını disk önbelleğinden yükler.
class RivePreloadService {
  RivePreloadService._();
  static final RivePreloadService instance = RivePreloadService._();

  final Map<String, rive.FileLoader> _cache = {};
  final Map<String, Future<rive.FileLoader?>> _loading = {};

  static String? normalizeRiveUrl(String? raw) {
    if (raw == null) return null;
    final t = raw.trim();
    if (t.isEmpty) return null;
    final lower = t.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) return t;
    return 'https://$t';
  }

  void preload(String? rawUrl) {
    unawaited(ensureLoader(rawUrl));
  }

  Future<rive.FileLoader?> ensureLoader(String? rawUrl) async {
    final url = normalizeRiveUrl(rawUrl);
    if (url == null) return null;

    final cached = _cache[url];
    if (cached != null) return cached;

    return _loading.putIfAbsent(url, () async {
      try {
        final loader = await _loadLoader(url);
        if (loader != null) _cache[url] = loader;
        return loader;
      } finally {
        _loading.remove(url);
      }
    });
  }

  Future<rive.FileLoader?> _loadLoader(String url) async {
    try {
      final file = await TutorAssetCacheService.instance.getCachedFile(url);
      if (file != null) {
        final riveFile = await rive.File.path(
          file.path,
          riveFactory: rive.Factory.rive,
        );
        if (riveFile != null) {
          if (kDebugMode) debugPrint('[RivePreload] ready (disk) $url');
          return rive.FileLoader.fromFile(
            riveFile,
            riveFactory: rive.Factory.rive,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[RivePreload] disk failed $url — $e');
    }

    if (kDebugMode) debugPrint('[RivePreload] fallback url $url');
    final loader = rive.FileLoader.fromUrl(url, riveFactory: rive.Factory.rive);
    loader.file().then((_) {
      if (kDebugMode) debugPrint('[RivePreload] ready (url) $url');
    }).catchError((Object e) {
      if (kDebugMode) debugPrint('[RivePreload] failed $url — $e');
      _cache.remove(url);
    });
    return loader;
  }

  rive.FileLoader? obtainOrCreateLoader(String? rawUrl) {
    final url = normalizeRiveUrl(rawUrl);
    if (url == null) return null;
    preload(rawUrl);
    return _cache[url];
  }

  rive.FileLoader? getLoader(String? rawUrl) {
    final url = normalizeRiveUrl(rawUrl);
    if (url == null) return null;
    return _cache[url];
  }
}
