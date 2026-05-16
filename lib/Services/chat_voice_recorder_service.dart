import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:lingola_buddy/Services/microphone_permission_platform.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class ChatVoiceRecorderException implements Exception {
  ChatVoiceRecorderException(this.message, {this.openSettings = false});

  final String message;
  final bool openSettings;

  @override
  String toString() => message;
}

class ChatVoiceRecorderService {
  ChatVoiceRecorderService({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();
  StreamSubscription<Amplitude>? _amplitudeSub;
  String? _activePath;
  DateTime? _startedAt;

  Stream<double> get amplitudeStream => _amplitudeController.stream;

  static double normalizeDb(double db) {
    const floor = -55.0;
    if (db <= floor) return 0.06;
    return ((db - floor) / -floor).clamp(0.06, 1.0);
  }

  static const _speechConfigAndroid = RecordConfig(
    encoder: AudioEncoder.aacLc,
    sampleRate: 44100,
    numChannels: 1,
    bitRate: 128000,
  );

  /// iOS/macOS: AVPlayer ile uyumlu WAV (m4a bazen oynatılamıyor).
  static const _speechConfigApple = RecordConfig(
    encoder: AudioEncoder.wav,
    sampleRate: 44100,
    numChannels: 1,
  );

  static const _speechConfigWavFallback = RecordConfig(
    encoder: AudioEncoder.wav,
    sampleRate: 44100,
    numChannels: 1,
  );

  static bool get _preferWav =>
      !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  Future<void> ensurePermission() async {
    if (await _recorder.hasPermission(request: false)) return;

    if (await _recorder.hasPermission()) return;

    if (await MicrophonePermissionPlatform.isGranted()) return;

    final nativeGranted = await MicrophonePermissionPlatform.request();
    if (nativeGranted) return;

    throw ChatVoiceRecorderException(
      'Mikrofon izni kapalı. Ayarlardan Lingola Buddy için mikrofonu açın.',
      openSettings: true,
    );
  }

  Future<void> start() async {
    if (await _recorder.isRecording()) return;

    if (kIsWeb) {
      throw ChatVoiceRecorderException(
        'Sesli mesaj bu ortamda desteklenmiyor.',
      );
    }

    await ensurePermission();
    await MicrophonePermissionPlatform.prepareSession();

    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    if (_preferWav) {
      final path = '${dir.path}/chat_voice_$stamp.wav';
      await _recorder.start(_speechConfigApple, path: path);
      _activePath = path;
    } else {
      var path = '${dir.path}/chat_voice_$stamp.m4a';
      try {
        await _recorder.start(_speechConfigAndroid, path: path);
      } catch (_) {
        path = '${dir.path}/chat_voice_$stamp.wav';
        await _recorder.start(_speechConfigWavFallback, path: path);
      }
      _activePath = path;
    }

    _startedAt = DateTime.now();
    _startAmplitudeListener();
  }

  void _startAmplitudeListener() {
    _amplitudeSub?.cancel();
    _amplitudeSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 70))
        .listen((amp) {
      if (!_amplitudeController.isClosed) {
        _amplitudeController.add(normalizeDb(amp.current));
      }
    });
  }

  void _stopAmplitudeListener() {
    _amplitudeSub?.cancel();
    _amplitudeSub = null;
    if (!_amplitudeController.isClosed) {
      _amplitudeController.add(0);
    }
  }

  Future<String?> stop() async {
    if (!await _recorder.isRecording()) {
      return _activePath;
    }

    _stopAmplitudeListener();
    final path = await _recorder.stop();
    final resolved = path ?? _activePath;
    _activePath = null;
    _startedAt = null;
    if (resolved != null && _preferWav) {
      await MicrophonePermissionPlatform.preparePlayback();
    }
    return resolved;
  }

  Future<void> cancel() async {
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    _stopAmplitudeListener();
    final path = _activePath;
    _activePath = null;
    _startedAt = null;
    if (path != null) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  Future<bool> get isRecordingActive => _recorder.isRecording();

  Duration? get elapsed {
    final started = _startedAt;
    if (started == null) return null;
    return DateTime.now().difference(started);
  }

  /// Geçici kaydı kalıcı sohbet klasörüne kopyalar.
  Future<String> persistRecording(String tempPath) async {
    final dir = await getApplicationDocumentsDirectory();
    final voiceDir = Directory(p.join(dir.path, 'chat_attachments', 'voice'));
    if (!await voiceDir.exists()) {
      await voiceDir.create(recursive: true);
    }

    final ext = p.extension(tempPath).isEmpty ? '.m4a' : p.extension(tempPath);
    final destPath = p.join(
      voiceDir.path,
      'voice_${DateTime.now().millisecondsSinceEpoch}$ext',
    );
    await File(tempPath).copy(destPath);
    try {
      final temp = File(tempPath);
      if (await temp.exists()) await temp.delete();
    } catch (_) {}
    return destPath;
  }

  Future<void> dispose() async {
    await cancel();
    await _amplitudeSub?.cancel();
    await _amplitudeController.close();
    await _recorder.dispose();
  }
}
