import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class CallPermissionStatus {
  const CallPermissionStatus({
    required this.microphone,
    required this.camera,
  });

  final bool microphone;
  final bool camera;

  bool get canStartVoiceCall => microphone;
  bool get canStartVideoCall => microphone;
  bool get cameraGranted => camera;
}

Future<bool> ensureMicrophonePermission() async {
  final r = await _requestPermission(Permission.microphone, 'mikrofon');
  return r;
}

Future<bool> ensureCameraPermission() async {
  final r = await _requestPermission(Permission.camera, 'kamera');
  return r;
}

/// Görüntülü arama: mikrofon zorunlu, kamera önizleme için istenir (red olursa arama yine açılır).
Future<CallPermissionStatus> requestVideoCallPermissions() async {
  if (kIsWeb) {
    return const CallPermissionStatus(microphone: false, camera: false);
  }
  if (!(Platform.isIOS || Platform.isAndroid)) {
    return const CallPermissionStatus(microphone: true, camera: true);
  }

  final mic = await _requestPermission(Permission.microphone, 'mikrofon');
  final cam = await _requestPermission(Permission.camera, 'kamera');
  debugPrint(
    '[CallPermissions] video call — mic=$mic camera=$cam '
    '(micStatus=${await Permission.microphone.status}, '
    'camStatus=${await Permission.camera.status})',
  );
  return CallPermissionStatus(microphone: mic, camera: cam);
}

@Deprecated('Use requestVideoCallPermissions')
Future<bool> ensureVideoCallPermissions() async {
  final s = await requestVideoCallPermissions();
  return s.microphone;
}

Future<bool> _requestPermission(Permission permission, String label) async {
  if (kIsWeb) return false;
  if (!(Platform.isIOS || Platform.isAndroid)) return true;

  var status = await permission.status;
  debugPrint('[CallPermissions] $label başlangıç: $status');

  if (status.isDenied || status.isRestricted || status.isLimited) {
    status = await permission.request();
    debugPrint('[CallPermissions] $label istek sonrası: $status');
  }

  if (status.isPermanentlyDenied) {
    debugPrint('[CallPermissions] $label kalıcı red — Ayarlar açılıyor');
    await openAppSettings();
    return false;
  }

  return status.isGranted;
}
