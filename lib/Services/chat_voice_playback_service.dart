import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:lingola_buddy/Services/microphone_permission_platform.dart';
import 'package:path/path.dart' as p;

/// Sohbet sesli mesajlarını platforma uygun şekilde oynatır.
abstract final class ChatVoicePlaybackService {
  static final AudioPlayer sharedPlayer = AudioPlayer();
  static String? activePath;
  static bool _audioContextReady = false;

  static Future<void> stopPlayback() async {
    activePath = null;
    try {
      await sharedPlayer.stop();
    } catch (_) {}
  }

  static String? mimeTypeForPath(String path) {
    switch (p.extension(path).toLowerCase()) {
      case '.m4a':
      case '.mp4':
        return 'audio/mp4';
      case '.aac':
        return 'audio/aac';
      case '.wav':
        return 'audio/wav';
      case '.caf':
        return 'audio/x-caf';
      case '.mp3':
        return 'audio/mpeg';
      default:
        return null;
    }
  }

  static Future<void> _ensureAudioContext(AudioPlayer player) async {
    if (!_audioContextReady) {
      await player.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {AVAudioSessionOptions.mixWithOthers},
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.speech,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );
      _audioContextReady = true;
    }

    if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
      await MicrophonePermissionPlatform.preparePlayback();
    }
  }

  static Future<void> play(String path) async {
    final player = sharedPlayer;
    final file = File(path);
    if (!await file.exists()) {
      throw StateError('Ses dosyası bulunamadı.');
    }
    if (await file.length() < 128) {
      throw StateError('Ses dosyası boş veya bozuk.');
    }

    await _ensureAudioContext(player);

    final source = DeviceFileSource(
      path,
      mimeType: mimeTypeForPath(path),
    );

    final state = player.state;
    if (state == PlayerState.playing) {
      await player.pause();
      return;
    }

    if (state == PlayerState.paused) {
      await player.resume();
      return;
    }

    await player.stop();
    activePath = path;
    await player.play(source);
  }
}
