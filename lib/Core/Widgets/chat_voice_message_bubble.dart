import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Utils/duration_format.dart';
import 'package:lingola_buddy/Core/Widgets/voice_waveform_bars.dart';
import 'package:lingola_buddy/Services/chat_voice_playback_service.dart';

class ChatVoiceMessageBubble extends StatefulWidget {
  const ChatVoiceMessageBubble({
    super.key,
    required this.path,
    required this.duration,
  });

  final String path;
  final Duration duration;

  @override
  State<ChatVoiceMessageBubble> createState() => _ChatVoiceMessageBubbleState();
}

class _ChatVoiceMessageBubbleState extends State<ChatVoiceMessageBubble> {
  AudioPlayer get _player => ChatVoicePlaybackService.sharedPlayer;

  bool _playing = false;
  Duration _position = Duration.zero;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<void>? _completeSub;

  bool get _isActive => ChatVoicePlaybackService.activePath == widget.path;

  @override
  void initState() {
    super.initState();
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      final active = _isActive;
      setState(() {
        _playing = active && state == PlayerState.playing;
        if (!active) {
          _position = Duration.zero;
        }
      });
    });
    _positionSub = _player.onPositionChanged.listen((position) {
      if (!mounted || !_isActive) return;
      setState(() => _position = position);
    });
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _playing = false;
        _position = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _positionSub?.cancel();
    _completeSub?.cancel();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (!File(widget.path).existsSync()) return;

    try {
      await ChatVoicePlaybackService.play(widget.path);
    } catch (e, st) {
      debugPrint('Voice playback failed: $e\n$st');
    }
  }

  double get _playbackLevel {
    if (!_playing || widget.duration.inMilliseconds <= 0) return 0.12;
    final progress =
        _position.inMilliseconds / widget.duration.inMilliseconds;
    return (0.2 + progress * 0.8).clamp(0.12, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.duration.inMilliseconds > 0
        ? widget.duration
        : const Duration(seconds: 1);
    final label = _playing
        ? DurationFormat.mmSs(_position)
        : DurationFormat.mmSs(total);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.22),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _togglePlay,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                child: VoiceWaveformBars(
                  level: _playbackLevel,
                  height: 28,
                  barCount: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: AppTextStyles.chatUserMessage().copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
