import 'package:flutter/services.dart';

/// Native mikrofon izni (iOS / Android / macOS MethodChannel).
abstract final class MicrophonePermissionPlatform {
  MicrophonePermissionPlatform._();

  static const MethodChannel _channel = MethodChannel(
    'com.flywork.lingolabuddy/microphone',
  );

  static Future<bool> isGranted() async {
    try {
      final granted = await _channel.invokeMethod<bool>('isGranted');
      return granted ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> prepareSession() async {
    try {
      await _channel.invokeMethod<void>('prepare');
    } catch (_) {}
  }

  /// Kayıt sonrası sesli mesaj oynatımı için AVAudioSession (iOS).
  static Future<void> preparePlayback() async {
    try {
      await _channel.invokeMethod<void>('preparePlayback');
    } catch (_) {}
  }

  static Future<bool> request() async {
    try {
      final granted = await _channel.invokeMethod<bool>('request');
      return granted ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
