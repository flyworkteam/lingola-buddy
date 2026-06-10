import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:lingola_buddy/Services/microphone_permission_platform.dart';
import 'package:path/path.dart' as p;

/// Sohbet sesli mesaj oynatma anlık durumu (UI optimistic güncelleme).
class ChatVoicePlaybackSnapshot {
  const ChatVoicePlaybackSnapshot({
    this.activePath,
    this.isPlaying = false,
  });

  final String? activePath;
  final bool isPlaying;
}

/// Sohbet sesli mesajlarını platforma uygun şekilde oynatır.
abstract final class ChatVoicePlaybackService {
  static final AudioPlayer sharedPlayer = AudioPlayer();
  static final ValueNotifier<ChatVoicePlaybackSnapshot> playback =
      ValueNotifier(const ChatVoicePlaybackSnapshot());

  static String? get activePath => playback.value.activePath;
  static bool _audioContextReady = false;
  static bool _listenersAttached = false;

  static void _attachListeners() {
    if (_listenersAttached) return;
    _listenersAttached = true;

    sharedPlayer.onPlayerComplete.listen((_) {
      _emit(activePath: null, isPlaying: false);
    });
  }

  static void _emit({String? activePath, required bool isPlaying}) {
    playback.value = ChatVoicePlaybackSnapshot(
      activePath: activePath,
      isPlaying: isPlaying,
    );
  }

  static Future<void> stopPlayback() async {
    _emit(activePath: null, isPlaying: false);
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
    _attachListeners();

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

    final sameFile = activePath == path;
    final state = player.state;

    if (sameFile) {
      if (state == PlayerState.playing) {
        _emit(activePath: path, isPlaying: false);
        await player.pause();
        return;
      }
      if (state == PlayerState.paused) {
        _emit(activePath: path, isPlaying: true);
        await player.resume();
        return;
      }
    }

    await player.stop();
    _emit(activePath: path, isPlaying: true);
    try {
      await player.play(source);
    } catch (e) {
      _emit(activePath: null, isPlaying: false);
      rethrow;
    }
  }
}
