import 'package:flutter/foundation.dart';
import 'package:rive/rive.dart' as rive;

/// Tutor .riv dosyalarını CDN'den önbelleğe alır.
class RivePreloadService {
  RivePreloadService._();
  static final RivePreloadService instance = RivePreloadService._();

  final Map<String, rive.FileLoader> _cache = {};

  static String? normalizeRiveUrl(String? raw) {
    if (raw == null) return null;
    final t = raw.trim();
    if (t.isEmpty) return null;
    final lower = t.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) return t;
    return 'https://$t';
  }

  void preload(String? rawUrl) {
    final url = normalizeRiveUrl(rawUrl);
    if (url == null) return;
    if (_cache.containsKey(url)) return;

    debugPrint('[RivePreload] start $url');
    final loader = rive.FileLoader.fromUrl(url, riveFactory: rive.Factory.rive);
    _cache[url] = loader;
    loader.file().then((_) {
      debugPrint('[RivePreload] ready $url');
    }).catchError((Object e) {
      debugPrint('[RivePreload] failed $url — $e');
      _cache.remove(url);
    });
  }

  rive.FileLoader? obtainOrCreateLoader(String? rawUrl) {
    final url = normalizeRiveUrl(rawUrl);
    if (url == null) return null;
    if (_cache.containsKey(url)) return _cache[url]!;
    preload(rawUrl);
    return _cache[url];
  }

  rive.FileLoader? getLoader(String? rawUrl) {
    final url = normalizeRiveUrl(rawUrl);
    if (url == null) return null;
    return _cache[url];
  }
}
