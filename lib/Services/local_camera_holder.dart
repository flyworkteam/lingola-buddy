import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Yerel kamera önizlemesi — bağlanma ekranında ısıtılır, aktif ekranda devralınır.
class LocalCameraHolder {
  LocalCameraHolder._();
  static final LocalCameraHolder instance = LocalCameraHolder._();

  List<CameraDescription> _cameras = const [];
  CameraController? _frontController;
  Future<void>? _prewarmFuture;

  List<CameraDescription> get cameras => _cameras;

  bool get hasReadyController =>
      _frontController?.value.isInitialized ?? false;

  /// Prewarm bitene kadar bekler (aktif ekran claim etmeden önce).
  Future<void> ensureReady() {
    if (hasReadyController) return Future<void>.value();
    return prewarm();
  }

  Future<void> prewarm() {
    if (hasReadyController) return Future<void>.value();
    if (_prewarmFuture != null) return _prewarmFuture!;
    _prewarmFuture = _prewarmImpl().whenComplete(() => _prewarmFuture = null);
    return _prewarmFuture!;
  }

  Future<void> _prewarmImpl() async {
    try {
      if (!await Permission.camera.isGranted) return;
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      final front = _cameras
          .where((c) => c.lensDirection == CameraLensDirection.front)
          .toList();
      if (front.isEmpty) return;
      final controller = CameraController(
        front.first,
        ResolutionPreset.low,
        enableAudio: false,
      );
      await controller.initialize();
      await _frontController?.dispose();
      _frontController = controller;
    } catch (e) {
      debugPrint('[LocalCameraHolder] prewarm: $e');
    }
  }

  /// Hazır controller'ı aktif ekrana devreder (sahiplik çağırana geçer).
  CameraController? claimFrontController() {
    final c = _frontController;
    _frontController = null;
    return c;
  }

  Future<void> release() async {
    await _frontController?.dispose();
    _frontController = null;
    _cameras = const [];
  }
}
