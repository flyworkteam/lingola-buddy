import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:rive/rive.dart' as rive;
import 'package:lingola_buddy/Services/tutor_asset_cache_service.dart';

/// Tutor .riv dosyalarını disk önbelleğinden veya CDN'den yükler.
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
        final fromDisk = await _loaderFromPath(file.path);
        if (fromDisk != null) {
          _log('ready (disk) $url');
          return fromDisk;
        }
      }
    } catch (e) {
      _log('disk failed $url — $e');
    }

    final fromNetwork = await _loaderFromUrl(url);
    if (fromNetwork != null) {
      _log('ready (network) $url');
      return fromNetwork;
    }

    _log('failed $url');
    return null;
  }

  Future<rive.FileLoader?> _loaderFromPath(String path) async {
    for (final factory in _factories) {
      try {
        final riveFile = await rive.File.path(path, riveFactory: factory);
        if (riveFile == null) continue;
        return rive.FileLoader.fromFile(riveFile, riveFactory: factory);
      } catch (e) {
        _log('path $factory — $e');
      }
    }
    return null;
  }

  Future<rive.FileLoader?> _loaderFromUrl(String url) async {
    for (final factory in _factories) {
      try {
        final riveFile = await rive.File.url(url, riveFactory: factory);
        if (riveFile == null) continue;
        return rive.FileLoader.fromFile(riveFile, riveFactory: factory);
      } catch (e) {
        _log('url $factory — $e');
      }
    }
    return null;
  }

  /// Release iOS'ta native renderer sessizce düşebilir — Flutter renderer yedek.
  static List<rive.Factory> get _factories => [
        rive.Factory.rive,
        rive.Factory.flutter,
      ];

  static void _log(String message) {
    if (kDebugMode) debugPrint('[RivePreload] $message');
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
