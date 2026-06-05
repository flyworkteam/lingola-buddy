import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart' as pcm;
import 'package:lingola_buddy/Core/Config/realtime_config.dart';
import 'package:lingola_buddy/Core/Utils/call_permissions.dart';
import 'package:lingola_buddy/Services/realtime_call_log.dart';
import 'package:record/record.dart';

enum RealtimeCallPhase {
  connecting,
  listening,
  thinking,
  speaking,
  error,
}

typedef RealtimeCallPhaseCallback = void Function(RealtimeCallPhase phase);
typedef RealtimeVisemeTimelineCallback = void Function(Map<String, dynamic> msg);
typedef RealtimeLipSyncAudibleCallback = void Function(bool audible);

class _AudioChunk {
  _AudioChunk(this.bytes, this.durationMs);
  final Uint8List bytes;
  final int durationMs;
}

/// Mindcoach voiceChatServerV2 ile uyumlu WebSocket + PCM16 oynatma/kayıt motoru.
class RealtimeCallEngine {
  RealtimeCallEngine({
    required this.tutorId,
    required this.languageCode,
    required this.getAuthToken,
    this.lessonId,
    this.learnerDisplayName,
    this.videoMode = false,
    this.onPhaseChanged,
    this.onVisemeTimeline,
    this.onConnectionReady,
    this.onServerEnded,
    this.onEnded,
  });

  final String tutorId;
  final String languageCode;
  final Future<String> Function() getAuthToken;
  final String? lessonId;
  final String? learnerDisplayName;
  final bool videoMode;
  RealtimeCallPhaseCallback? onPhaseChanged;
  RealtimeLipSyncAudibleCallback? onLipSyncAudibleChanged;
  final RealtimeVisemeTimelineCallback? onVisemeTimeline;
  VoidCallback? onConnectionReady;
  /// İlk kez kullanıcı konuşmaya başladığında (VAD).
  VoidCallback? onUserSpeechStarted;
  /// Sunucu `call_ended_idle` veya WS kapandığında (veda sonrası kapatma).
  VoidCallback? onServerEnded;

  void bindServerEndedHandler(VoidCallback handler) {
    onServerEnded = handler;
  }
  final VoidCallback? onEnded;

  static const MethodChannel _audioChannel = MethodChannel(
    'lingolabuddy/voice_audio_session',
  );

  static const int sampleRate = 24000;
  static const int channels = 1;

  WebSocket? _ws;
  StreamSubscription<dynamic>? _wsSub;
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _micSub;
  bool _micActive = false;

  final Queue<Int16List> _pcmChunks = Queue<Int16List>();
  int _pcmChunkOffset = 0;
  int _pcmTotalSamples = 0;
  bool _pcmSetup = false;
  bool _pcmStarted = false;

  bool _isRinging = false;
  int _ringSamplePos = 0;
  /// Tek “çalıyor” darbesi (~0,9 sn); tekrarlayan zil döngüsü yok.
  static const int _ringOnSamples = (sampleRate * 9) ~/ 10;
  DateTime? _lastAudioSessionConfigAt;

  RealtimeCallPhase _phase = RealtimeCallPhase.connecting;
  bool _muted = false;
  bool _speakerOn = false;
  bool _disposed = false;
  bool _serverEnded = false;
  bool _receivedAiPcmThisTurn = false;
  bool _lipSyncAudible = false;
  bool _userSpeechStartedFired = false;
  /// Görüntülü aramada aktif ekran açılmadan WS/mikrofon/AI sesi kapalı.
  bool _callActivated = false;
  bool _serverReady = false;
  bool _uiReadySent = false;
  Completer<void>? _sessionReadyCompleter;

  bool get _conversationLive => !videoMode || _callActivated;

  int _micBytesSent = 0;
  int _micChunksSent = 0;
  int _userWordsSpoken = 0;

  int get userWordsSpoken => _userWordsSpoken;

  /// Oturum puanı — süre ve konuşulan kelime sayısına göre (0–100); sabit değil.
  static int computeSessionScore({
    required int durationSeconds,
    required int words,
  }) {
    if (durationSeconds <= 0 && words <= 0) return 0;
    final fromDuration = (durationSeconds / 10).floor().clamp(0, 45);
    final fromWords = (words * 2).clamp(0, 55);
    return (fromDuration + fromWords).clamp(0, 100);
  }

  static int _countWords(String text) {
    final t = text.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }
  DateTime? _lastMicLogAt;
  DateTime? _lastMicRmsLogAt;

  int _highRmsStreakMs = 0;
  bool _bargeInSent = false;
  final Queue<_AudioChunk> _preRoll = Queue<_AudioChunk>();
  DateTime? _micGateOpenAt;
  DateTime? _aiSpeakingSince;
  int _lastPlaybackRms = 0;

  Timer? _aiSpeakingWatchdog;
  DateTime? _lastAiPcmReceivedAt;
  Timer? _aiPlaybackIdleTimer;

  static const int _aiPlaybackIdleMs = 1600;
  static const int _aiPlaybackStuckQueueFlushMs = 3000;
  static const int _postSpeechCooldownMs = 250;
  static const int _bargeInSustainedMs = 100;
  static const int _preRollMaxMs = 500;
  static const int _bargeInMinAiSpeakingMs = 250;
  static const int _bargeInRmsThresholdEarpiece = 1700;
  static const int _bargeInRmsThresholdSpeaker = 2400;
  static const double _bargeInPlaybackRatio = 2.0;

  RealtimeCallPhase get phase => _phase;
  bool get isSpeakerOn => _speakerOn;
  bool get isMuted => _muted;
  bool get lipSyncAudible => _lipSyncAudible;

  void _setLipSyncAudible(bool audible) {
    if (_lipSyncAudible == audible) return;
    _lipSyncAudible = audible;
    onLipSyncAudibleChanged?.call(audible);
  }

  void _setPhase(RealtimeCallPhase p) {
    if (_phase == p) return;
    RealtimeCallLog.d('phase → $p (speaker=$_speakerOn muted=$_muted)');
    _phase = p;
    onPhaseChanged?.call(p);
  }

  Future<void> start({bool skipPermissionRequest = false}) async {
    if (_disposed) return;
    _serverReady = false;
    _uiReadySent = false;
    _callActivated = false;
    _sessionReadyCompleter = Completer<void>();
    RealtimeCallLog.d(
      'start tutor=$tutorId lesson=$lessonId lang=$languageCode video=$videoMode ws=${RealtimeConfig.wsBaseUrl}',
    );

    if (!skipPermissionRequest &&
        !kIsWeb &&
        (Platform.isIOS || Platform.isAndroid)) {
      if (videoMode) {
        final perms = await requestVideoCallPermissions();
        if (!perms.canStartVideoCall) {
          RealtimeCallLog.e(
            'mikrofon izni reddedildi (kamera=${perms.cameraGranted})',
          );
          _setPhase(RealtimeCallPhase.error);
          return;
        }
        if (!perms.cameraGranted) {
          RealtimeCallLog.w(
            'kamera izni yok — arama sesli devam, yerel önizleme kapalı olabilir',
          );
        }
      } else {
        final ok = await ensureMicrophonePermission();
        if (!ok) {
          RealtimeCallLog.e('mikrofon izni reddedildi');
          _setPhase(RealtimeCallPhase.error);
          return;
        }
      }
    }

    await _configureAudioSession(forceEarpiece: !videoMode);
    await _initPcmPlayer();
    await _startRingTone();
    await _connect();
  }

  Future<void> end({bool fromServer = false}) async {
    if (_disposed) return;
    _disposed = true;
    _setLipSyncAudible(false);
    RealtimeCallLog.d(
      'end() fromServer=$fromServer micChunks=$_micChunksSent micBytes=$_micBytesSent',
    );
    _stopRingTone();
    await _stopMic();
    try {
      await _ws?.close();
    } catch (_) {}
    await _wsSub?.cancel();
    _ws = null;
    _flushPcm();
    try {
      await pcm.FlutterPcmSound.release();
    } catch (_) {}
    _pcmSetup = false;
    _pcmStarted = false;
    await _resetAudioSession();
    onEnded?.call();
    if (fromServer) onServerEnded?.call();
  }

  void setMuted(bool value) {
    _muted = value;
    RealtimeCallLog.d('mic muted=$value');
    if (!value) {
      _micGateOpenAt = null;
    }
  }

  Future<void> setSpeakerOn(bool on) async {
    _speakerOn = on;
    RealtimeCallLog.d('speaker on=$on');
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) return;
    try {
      await _audioChannel.invokeMethod('setSpeakerOn', {'on': on});
      await _setProximityMonitoring(!on);
    } catch (e) {
      RealtimeCallLog.e('setSpeakerOn', e);
    }
  }

  Future<void> _configureAudioSession({bool? forceEarpiece}) async {
    if (_disposed) return;
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) return;
    final now = DateTime.now();
    if (_lastAudioSessionConfigAt != null &&
        now.difference(_lastAudioSessionConfigAt!).inMilliseconds < 450) {
      return;
    }
    _lastAudioSessionConfigAt = now;
    try {
      await _audioChannel.invokeMethod('configureForVoiceCall');
      final useSpeaker = forceEarpiece == true
          ? false
          : (forceEarpiece == false ? true : _speakerOn);
      _speakerOn = useSpeaker;
      await _audioChannel.invokeMethod('setSpeakerOn', {'on': useSpeaker});
      await _setProximityMonitoring(!useSpeaker);
      RealtimeCallLog.d('audio session ready speaker=$useSpeaker');
    } catch (e) {
      RealtimeCallLog.e('configureAudioSession', e);
    }
  }

  Future<void> _resetAudioSession() async {
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) return;
    try {
      await _audioChannel.invokeMethod('resetAudioSession');
      await _setProximityMonitoring(false);
    } catch (e) {
      RealtimeCallLog.e('resetAudioSession', e);
    }
  }

  Future<void> _setProximityMonitoring(bool on) async {
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) return;
    try {
      await _audioChannel.invokeMethod('setProximityMonitoring', {'on': on});
    } catch (e) {
      RealtimeCallLog.e('proximity', e);
    }
  }

  Future<void> _initPcmPlayer() async {
    if (_pcmSetup) return;
    try {
      await pcm.FlutterPcmSound.setup(
        sampleRate: sampleRate,
        channelCount: channels,
        iosAudioCategory: pcm.IosAudioCategory.playAndRecord,
      );
      await pcm.FlutterPcmSound.setFeedThreshold((sampleRate * 0.25).round());
      pcm.FlutterPcmSound.setFeedCallback(_onPcmFeed);
      _pcmSetup = true;
      await _ensurePcmStarted();
      RealtimeCallLog.d('PCM player hazır');
    } catch (e) {
      RealtimeCallLog.e('PCM setup', e);
    }
  }

  Future<void> _ensurePcmStarted() async {
    if (!_pcmSetup || _pcmStarted) return;
    try {
      pcm.FlutterPcmSound.start();
      _pcmStarted = true;
    } catch (e) {
      RealtimeCallLog.e('PCM start', e);
    }
  }

  Future<void> _startRingTone() async {
    if (_isRinging) return;
    _isRinging = true;
    _ringSamplePos = 0;
    await _ensurePcmStarted();
    RealtimeCallLog.d('ring tone başladı');
    _feedRingToneChunk();
  }

  void _stopRingTone() {
    if (!_isRinging) return;
    _isRinging = false;
    RealtimeCallLog.d('ring tone durdu');
    _flushPcm();
  }

  void _playPickupChime() {
    if (!_pcmStarted) return;
    const int totalSamples = sampleRate ~/ 4;
    final samples = Int16List(totalSamples);
    final half = totalSamples ~/ 2;
    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final freq = i < half ? 660.0 : 880.0;
      var s = sin(2 * pi * freq * t) * 0.28;
      const fade = 360;
      final localI = i < half ? i : i - half;
      final localLen = half;
      if (localI < fade) {
        s *= localI / fade;
      } else if (localI > localLen - fade) {
        s *= (localLen - localI) / fade;
      }
      samples[i] = (s * 32767).round().clamp(-32767, 32767);
    }
    _pcmChunks.add(samples);
    _pcmTotalSamples += totalSamples;
    _onPcmFeed(0);
    RealtimeCallLog.d('pickup chime');
  }

  void _feedRingToneChunk() {
    if (!_isRinging || !_pcmStarted) return;
    if (_ringSamplePos >= _ringOnSamples) return;
    const chunkSamples = 6000;
    final samples = Int16List(chunkSamples);
    const f1 = 440.0;
    const f2 = 480.0;
    const amp = 0.22;
    final toWrite = min(chunkSamples, _ringOnSamples - _ringSamplePos);
    for (int i = 0; i < toWrite; i++) {
      final pos = _ringSamplePos + i;
      final t = pos / sampleRate;
      var sample = (sin(2 * pi * f1 * t) + sin(2 * pi * f2 * t)) * 0.5 * amp;
      const fade = 800;
      if (pos < fade) {
        sample *= pos / fade;
      } else if (pos > _ringOnSamples - fade) {
        sample *= (_ringOnSamples - pos) / fade;
      }
      samples[i] = (sample * 32767).round().clamp(-32767, 32767);
    }
    _ringSamplePos += toWrite;
    if (toWrite == 0) return;
    try {
      pcm.FlutterPcmSound.feed(
        pcm.PcmArrayInt16(bytes: samples.buffer.asByteData(0, toWrite * 2)),
      );
    } catch (e) {
      RealtimeCallLog.e('ring feed', e);
    }
  }

  void _onPcmFeed(int remainingFrames) {
    if (!_pcmStarted) return;

    if (_isRinging) {
      if (_ringSamplePos < _ringOnSamples) {
        _feedRingToneChunk();
      } else {
        _isRinging = false;
      }
      return;
    }

    if (_pcmTotalSamples == 0) return;

    final maxSamples = (sampleRate * 0.5).round();
    final toSend = _pcmTotalSamples < maxSamples ? _pcmTotalSamples : maxSamples;

    final out = Int16List(toSend);
    var dst = 0;
    var sumSq = 0.0;
    while (dst < toSend && _pcmChunks.isNotEmpty) {
      final head = _pcmChunks.first;
      final avail = head.length - _pcmChunkOffset;
      final copy = avail < toSend - dst ? avail : toSend - dst;
      out.setRange(dst, dst + copy, head, _pcmChunkOffset);
      for (var i = 0; i < copy; i++) {
        final v = head[_pcmChunkOffset + i].toDouble();
        sumSq += v * v;
      }
      dst += copy;
      if (copy == avail) {
        _pcmChunks.removeFirst();
        _pcmChunkOffset = 0;
      } else {
        _pcmChunkOffset += copy;
      }
    }
    _pcmTotalSamples -= toSend;
    if (toSend > 0) {
      _lastPlaybackRms = sqrt(sumSq / toSend).round();
      pcm.FlutterPcmSound.feed(
        pcm.PcmArrayInt16(bytes: out.buffer.asByteData(0, toSend * 2)),
      );
      if (_phase == RealtimeCallPhase.speaking && !_lipSyncAudible) {
        _setLipSyncAudible(true);
      }
    }
    // playback_done yalnızca _waitForPcmDrainAndListen içinde gönderilir.
  }

  String _learnerNameQuery() {
    final name = learnerDisplayName?.trim() ?? '';
    if (name.isEmpty) return '';
    return '&displayName=${Uri.encodeQueryComponent(name)}';
  }

  Future<void> _connect() async {
    try {
      final token = await getAuthToken();
      final url =
          '${RealtimeConfig.wsBaseUrl}'
          '?token=${Uri.encodeQueryComponent(token)}'
          '&tutorId=${Uri.encodeQueryComponent(tutorId)}'
          '&lang=${Uri.encodeQueryComponent(languageCode)}'
          '&video=${videoMode ? '1' : '0'}'
          '${lessonId != null && lessonId!.isNotEmpty ? '&lessonId=${Uri.encodeQueryComponent(lessonId!)}' : ''}'
          '${_learnerNameQuery()}';

      RealtimeCallLog.d('WS bağlanıyor…');
      _ws = await WebSocket.connect(url);
      _wsSub = _ws!.listen(
        _onWsData,
        onError: (e) {
          RealtimeCallLog.e('WS error', e);
          _setPhase(RealtimeCallPhase.error);
        },
        onDone: () {
          RealtimeCallLog.d('WS kapandı disposed=$_disposed serverEnded=$_serverEnded');
          if (!_disposed) {
            unawaited(end(fromServer: true));
          }
        },
        cancelOnError: false,
      );
    } catch (e) {
      RealtimeCallLog.e('connect', e);
      _setPhase(RealtimeCallPhase.error);
    }
  }

  void _onWsData(dynamic data) {
    if (data is String) {
      try {
        _handleJson(jsonDecode(data) as Map<String, dynamic>);
      } catch (e) {
        RealtimeCallLog.e('JSON parse', e);
      }
    } else if (data is List<int>) {
      _enqueuePcm(Uint8List.fromList(data));
    }
  }

  void _markServerReady() {
    if (_serverReady) return;
    _serverReady = true;
    final c = _sessionReadyCompleter;
    if (c != null && !c.isCompleted) {
      c.complete();
    }
  }

  /// Sunucuya aktif ekran hazır sinyali (karşılama TTS).
  Future<void> _sendUiReady() async {
    if (_uiReadySent || _disposed) return;
    for (var i = 0; i < 10; i++) {
      if (_disposed) return;
      if (_ws?.readyState == WebSocket.open) {
        _sendJson({'type': 'call_ui_ready'});
        _uiReadySent = true;
        RealtimeCallLog.d('WS → call_ui_ready');
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    RealtimeCallLog.e('call_ui_ready gönderilemedi (WS hazır değil)');
  }

  /// Aktif görüşme ekranı hazır — karşılama + mikrofon burada başlar.
  Future<void> activateForActiveCall() async {
    if (_disposed) return;

    if (!_serverReady) {
      final wait = _sessionReadyCompleter?.future;
      if (wait != null) {
        try {
          await wait.timeout(const Duration(seconds: 15));
        } catch (_) {
          RealtimeCallLog.e('connection_success beklenirken zaman aşımı');
        }
      }
    }
    if (_disposed) return;

    if (videoMode) {
      _speakerOn = true;
    }

    _callActivated = true;
    RealtimeCallLog.d('aktif görüşme (UI hazır)');
    _stopRingTone();
    await _ensurePcmStarted();
    _lastAudioSessionConfigAt = null;
    await _configureAudioSession(forceEarpiece: !videoMode && !_speakerOn);
    await _sendUiReady();
    _setPhase(RealtimeCallPhase.listening);
    if (!_disposed && !_muted) {
      await _startMic();
    }
  }

  /// Kamera yalnızca önizleme; initialize sonrası ses oturumunu geri yükle.
  Future<void> refreshAudioSessionAfterCamera() async {
    if (_disposed) return;
    _lastAudioSessionConfigAt = null;
    await _configureAudioSession(forceEarpiece: !videoMode && !_speakerOn);
  }

  Future<void> _onConnectionReady() async {
    if (_disposed) return;
    _markServerReady();
    _stopRingTone();
    if (videoMode) {
      onConnectionReady?.call();
      return;
    }
    await _configureAudioSession(forceEarpiece: !videoMode);
    _playPickupChime();
    _setPhase(RealtimeCallPhase.listening);
    _callActivated = true;
    onConnectionReady?.call();
    if (!_disposed && !_muted) {
      await _startMic();
    }
  }

  void _handleJson(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    RealtimeCallLog.d('WS ← $type');
    switch (type) {
      case 'connection_success':
        unawaited(_onConnectionReady());
        break;
      case 'user_speech_started':
        RealtimeCallLog.d('OpenAI VAD: konuşma başladı');
        // AI konuşurken hoparlör yankısı VAD tetikleyebilir — fazı bozma (RIV ağız).
        if (_phase == RealtimeCallPhase.speaking) break;
        if (!_userSpeechStartedFired && _conversationLive) {
          _userSpeechStartedFired = true;
          onUserSpeechStarted?.call();
        }
        if (!_muted) _setPhase(RealtimeCallPhase.listening);
        break;
      case 'user_speech_stopped':
        RealtimeCallLog.d('OpenAI VAD: konuşma bitti → thinking');
        if (!_muted) _setPhase(RealtimeCallPhase.thinking);
        break;
      case 'transcript':
        final transcriptText = msg['text'] as String? ?? '';
        _userWordsSpoken += _countWords(transcriptText);
        RealtimeCallLog.d('kullanıcı transcript: "$transcriptText"');
        break;
      case 'ai_speaking_start':
        if (!_conversationLive) break;
        _stopRingTone();
        _flushPcm();
        _receivedAiPcmThisTurn = false;
        _setLipSyncAudible(false);
        _setPhase(RealtimeCallPhase.speaking);
        _aiSpeakingSince = DateTime.now();
        _armAiSpeakingWatchdog();
        _armAiPlaybackIdleMonitor();
        break;
      case 'ai_response_complete':
        if (!_conversationLive) break;
        _cancelAiSpeakingWatchdog();
        unawaited(_waitForPcmDrainAndListen());
        break;
      case 'barge_in':
        _flushPcm();
        _setLipSyncAudible(false);
        _setPhase(RealtimeCallPhase.listening);
        _micGateOpenAt = DateTime.now().add(
          const Duration(milliseconds: _postSpeechCooldownMs),
        );
        if (!_muted) unawaited(_rebindMic());
        break;
      case 'call_ended_idle':
        RealtimeCallLog.d('sunucu aramayı kapattı (idle/veda)');
        _serverEnded = true;
        unawaited(end(fromServer: true));
        break;
      case 'viseme_timeline':
        if (videoMode && _conversationLive) onVisemeTimeline?.call(msg);
        break;
      case 'error':
        final err = msg['error'];
        final detail = msg['detail'];
        RealtimeCallLog.e(
          'sunucu error: $err${detail != null ? ' — $detail' : ''}',
        );
        _setPhase(RealtimeCallPhase.error);
        break;
    }
  }

  void _enqueuePcm(Uint8List bytes) {
    if (!_conversationLive) return;
    if (bytes.length < 2 || bytes.length % 2 != 0) return;
    _receivedAiPcmThisTurn = true;
    final n = bytes.length ~/ 2;
    final samples = Int16List(n);
    final bd = ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length);
    for (var i = 0; i < n; i++) {
      samples[i] = bd.getInt16(i * 2, Endian.little);
    }
    _pcmChunks.add(samples);
    _pcmTotalSamples += n;
    _lastAiPcmReceivedAt = DateTime.now();
    _ensurePcmStarted();
    _onPcmFeed(0);
  }

  void _flushPcm() {
    _pcmChunks.clear();
    _pcmChunkOffset = 0;
    _pcmTotalSamples = 0;
    _resetBargeInState();
  }

  void _sendPlaybackDone() {
    if (_ws?.readyState != WebSocket.open) return;
    _sendJson({'type': 'playback_done'});
    RealtimeCallLog.d('WS → playback_done');
  }

  Future<void> _waitForPcmDrainAndListen() async {
    if (_disposed) return;
    _cancelAiPlaybackIdleMonitor();

    // OpenAI metin bittiğinde ElevenLabs PCM henüz gelmemiş olabilir — erken
    // playback_done sunucuda idle/veda tetikler.
    if (!_receivedAiPcmThisTurn) {
      final waitPcmDeadline = DateTime.now().add(const Duration(seconds: 8));
      while (!_receivedAiPcmThisTurn && DateTime.now().isBefore(waitPcmDeadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        if (_disposed) return;
      }
      if (!_receivedAiPcmThisTurn) {
        RealtimeCallLog.w(
          'ai_response_complete ama AI PCM gelmedi — playback_done erteleniyor',
        );
      }
    }

    final deadline = DateTime.now().add(const Duration(seconds: 25));
    while (_pcmTotalSamples > 0 && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (_disposed) return;
    }
    if (_pcmTotalSamples > 0) {
      RealtimeCallLog.w('PCM drain timeout — kuyruk temizleniyor');
      _flushPcm();
    }
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (_disposed) return;

    _sendPlaybackDone();
    _setLipSyncAudible(false);
    _setPhase(RealtimeCallPhase.listening);
    _micGateOpenAt = DateTime.now().add(
      const Duration(milliseconds: _postSpeechCooldownMs),
    );
    _aiSpeakingSince = null;
    _resetBargeInState();
    if (!_disposed && !_muted) await _rebindMic();
  }

  void _armAiSpeakingWatchdog() {
    _aiSpeakingWatchdog?.cancel();
    _aiSpeakingWatchdog = Timer(const Duration(seconds: 75), () {
      if (_phase == RealtimeCallPhase.speaking) {
        RealtimeCallLog.w('AI speaking watchdog — dinlemeye dön');
        unawaited(_waitForPcmDrainAndListen());
      }
    });
  }

  void _cancelAiSpeakingWatchdog() {
    _aiSpeakingWatchdog?.cancel();
    _aiSpeakingWatchdog = null;
  }

  void _armAiPlaybackIdleMonitor() {
    _cancelAiPlaybackIdleMonitor();
    _aiPlaybackIdleTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (_phase != RealtimeCallPhase.speaking) return;
      final base = _lastAiPcmReceivedAt ?? _aiSpeakingSince;
      if (base == null) return;
      final stallMs = DateTime.now().difference(base).inMilliseconds;
      if (_pcmTotalSamples > 0 && stallMs >= _aiPlaybackStuckQueueFlushMs) {
        RealtimeCallLog.w('PCM stuck flush ($stallMs ms)');
        _flushPcm();
      }
      if (stallMs >= _aiPlaybackIdleMs) {
        unawaited(_waitForPcmDrainAndListen());
      }
    });
  }

  void _cancelAiPlaybackIdleMonitor() {
    _aiPlaybackIdleTimer?.cancel();
    _aiPlaybackIdleTimer = null;
    _lastAiPcmReceivedAt = null;
  }

  void _sendJson(Map<String, dynamic> obj) {
    final type = obj['type'];
    if (_ws?.readyState == WebSocket.open) {
      _ws!.add(jsonEncode(obj));
      return;
    }
    RealtimeCallLog.e(
      'WS gönderilemedi ($type) readyState=${_ws?.readyState}',
    );
  }

  int _computeRms(Uint8List chunk) {
    final n = chunk.length ~/ 2;
    if (n == 0) return 0;
    final bd = ByteData.view(chunk.buffer, chunk.offsetInBytes, n * 2);
    var sumSq = 0.0;
    for (var i = 0; i < n; i++) {
      final s = bd.getInt16(i * 2, Endian.little);
      sumSq += s * s;
    }
    return sqrt(sumSq / n).round();
  }

  int _chunkMs(Uint8List chunk) =>
      ((chunk.length ~/ 2) / sampleRate * 1000).round();

  void _resetBargeInState() {
    _highRmsStreakMs = 0;
    _bargeInSent = false;
    _preRoll.clear();
  }

  void _logMicActivity(Uint8List chunk, {required bool forwarded}) {
    final now = DateTime.now();
    if (_lastMicLogAt == null ||
        now.difference(_lastMicLogAt!).inSeconds >= 2) {
      _lastMicLogAt = now;
      RealtimeCallLog.d(
        'mic phase=$_phase forwarded=$forwarded '
        'chunks=$_micChunksSent bytes=$_micBytesSent muted=$_muted',
      );
    }
    if (forwarded &&
        (_lastMicRmsLogAt == null ||
            now.difference(_lastMicRmsLogAt!).inMilliseconds >= 500)) {
      _lastMicRmsLogAt = now;
      RealtimeCallLog.d('mic rms=${_computeRms(chunk)} len=${chunk.length}');
    }
  }

  Future<void> _startMic() async {
    if (_disposed || _micActive) return;
    final has = await _recorder.hasPermission();
    if (!has) {
      RealtimeCallLog.e('record.hasPermission false');
      _setPhase(RealtimeCallPhase.error);
      return;
    }
    await _configureAudioSession(forceEarpiece: !videoMode && !_speakerOn);
    RealtimeCallLog.d('mikrofon stream başlıyor @${sampleRate}Hz');
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: channels,
      ),
    );
    if (_disposed) {
      await _stopMic();
      return;
    }
    _micSub = stream.listen((chunk) {
      if (_disposed) return;
      if (chunk.isEmpty || chunk.length % 2 != 0) return;
      if (_muted) {
        _logMicActivity(chunk, forwarded: false);
        return;
      }
      if (_ws?.readyState != WebSocket.open) {
        _logMicActivity(chunk, forwarded: false);
        return;
      }
      final gate = _micGateOpenAt;
      if (gate != null && DateTime.now().isBefore(gate)) {
        _logMicActivity(chunk, forwarded: false);
        return;
      }
      _micGateOpenAt = null;

      if (_phase == RealtimeCallPhase.speaking) {
        final durMs = _chunkMs(chunk);
        final rms = _computeRms(chunk);
        final threshold = max(
          _speakerOn
              ? _bargeInRmsThresholdSpeaker
              : _bargeInRmsThresholdEarpiece,
          (_lastPlaybackRms * _bargeInPlaybackRatio).round(),
        );
        final speakingFor = _aiSpeakingSince == null
            ? 0
            : DateTime.now().difference(_aiSpeakingSince!).inMilliseconds;
        _preRoll.add(_AudioChunk(chunk, durMs));
        var buffered = 0;
        for (final c in _preRoll) {
          buffered += c.durationMs;
        }
        while (buffered > _preRollMaxMs && _preRoll.length > 1) {
          buffered -= _preRoll.removeFirst().durationMs;
        }
        if (!_bargeInSent &&
            speakingFor >= _bargeInMinAiSpeakingMs &&
            rms >= threshold) {
          _highRmsStreakMs += durMs;
          if (_highRmsStreakMs >= _bargeInSustainedMs) {
            RealtimeCallLog.d('barge-in rms=$rms');
            _bargeInSent = true;
            _sendJson({'type': 'barge_in_request'});
            for (final c in _preRoll) {
              if (c.bytes.length % 2 == 0 && c.bytes.isNotEmpty) {
                _ws!.add(c.bytes);
              }
            }
            _preRoll.clear();
            _setPhase(RealtimeCallPhase.listening);
          }
        } else {
          _highRmsStreakMs = 0;
        }
        return;
      }

      _resetBargeInState();
      _ws!.add(chunk);
      _micChunksSent++;
      _micBytesSent += chunk.length;
      _logMicActivity(chunk, forwarded: true);
    });
    _micActive = true;
  }

  Future<void> _stopMic() async {
    if (!_micActive) return;
    await _micSub?.cancel();
    _micSub = null;
    try {
      await _recorder.stop();
    } catch (_) {}
    _micActive = false;
    _resetBargeInState();
    RealtimeCallLog.d('mikrofon durdu');
  }

  Future<void> _rebindMic() async {
    if (_disposed || _muted || !_conversationLive) return;
    RealtimeCallLog.d('mikrofon yeniden bağlanıyor…');
    await _stopMic();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (_disposed || _muted || _ws?.readyState != WebSocket.open) return;
    await _configureAudioSession(forceEarpiece: !videoMode && !_speakerOn);
    await _startMic();
  }
}
