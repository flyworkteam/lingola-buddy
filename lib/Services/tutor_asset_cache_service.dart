import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Eğitmen fotoğraf ve .riv dosyalarını diskte önbelleğe alır.
class TutorAssetCacheService {
  TutorAssetCacheService._();
  static final TutorAssetCacheService instance = TutorAssetCacheService._();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 45),
    ),
  );

  final Map<String, Future<File?>> _inflight = {};
  Directory? _root;

  Future<Directory> _rootDir() async {
    if (_root != null) return _root!;
    _root = Directory(
      p.join(
        (await getApplicationSupportDirectory()).path,
        'tutor_asset_cache',
      ),
    );
    if (!await _root!.exists()) {
      await _root!.create(recursive: true);
    }
    return _root!;
  }

  static String _cacheFileName(String url) {
    final uri = Uri.parse(url);
    var ext = p.extension(uri.path).toLowerCase();
    if (ext.isEmpty || ext.length > 8) {
      ext = '.bin';
    }
    final digest = sha256.convert(utf8.encode(url.trim())).toString();
    return '$digest$ext';
  }

  Future<File?> getCachedFile(String url) {
    final normalized = url.trim();
    if (!normalized.startsWith('http')) {
      return Future.value(null);
    }

    return _inflight.putIfAbsent(normalized, () async {
      try {
        final root = await _rootDir();
        final file = File(p.join(root.path, _cacheFileName(normalized)));

        if (await file.exists()) {
          final len = await file.length();
          if (len > 128) return file;
          await file.delete();
        }

        await _dio.download(normalized, file.path);
        if (await file.length() > 128) {
          if (kDebugMode) {
            debugPrint('[TutorAssetCache] saved ${file.path}');
          }
          return file;
        }

        if (await file.exists()) await file.delete();
        return null;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[TutorAssetCache] failed $normalized — $e');
        }
        return null;
      } finally {
        _inflight.remove(normalized);
      }
    });
  }

  void preload(String url) {
    unawaited(getCachedFile(url));
  }

  Future<File?> cachedFileIfReady(String url) async {
    final normalized = url.trim();
    if (!normalized.startsWith('http')) return null;
    final root = await _rootDir();
    final file = File(p.join(root.path, _cacheFileName(normalized)));
    if (await file.exists() && await file.length() > 128) return file;
    return null;
  }
}
