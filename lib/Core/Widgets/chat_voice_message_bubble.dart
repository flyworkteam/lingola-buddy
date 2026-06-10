import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Utils/duration_format.dart';
import 'package:lingola_buddy/Core/Widgets/voice_waveform_bars.dart';
import 'package:lingola_buddy/Services/chat_voice_playback_service.dart';

enum ChatVoiceBubbleVariant { user, tutor }

class ChatVoiceMessageBubble extends StatefulWidget {
  const ChatVoiceMessageBubble({
    super.key,
    required this.path,
    required this.duration,
    this.variant = ChatVoiceBubbleVariant.user,
  });

  final String path;
  final Duration duration;
  final ChatVoiceBubbleVariant variant;

  @override
  State<ChatVoiceMessageBubble> createState() => _ChatVoiceMessageBubbleState();
}

class _ChatVoiceMessageBubbleState extends State<ChatVoiceMessageBubble> {
  AudioPlayer get _player => ChatVoicePlaybackService.sharedPlayer;

  bool _playing = false;
  Duration _position = Duration.zero;
  StreamSubscription<Duration>? _positionSub;

  bool get _isActive =>
      ChatVoicePlaybackService.playback.value.activePath == widget.path;

  @override
  void initState() {
    super.initState();
    ChatVoicePlaybackService.playback.addListener(_syncFromPlayback);
    _syncFromPlayback();

    _positionSub = _player.onPositionChanged.listen((position) {
      if (!mounted || !_isActive || !_playing) return;
      setState(() => _position = position);
    });
  }

  @override
  void dispose() {
    ChatVoicePlaybackService.playback.removeListener(_syncFromPlayback);
    _positionSub?.cancel();
    super.dispose();
  }

  void _syncFromPlayback() {
    if (!mounted) return;
    final snap = ChatVoicePlaybackService.playback.value;
    final isThis = snap.activePath == widget.path;
    final playing = isThis && snap.isPlaying;
    setState(() {
      _playing = playing;
      if (!isThis || !playing) {
        _position = Duration.zero;
      }
    });
  }

  Future<void> _togglePlay() async {
    if (!File(widget.path).existsSync()) return;

    final snap = ChatVoicePlaybackService.playback.value;
    final pausingThis = snap.activePath == widget.path && snap.isPlaying;
    if (pausingThis) {
      setState(() => _playing = false);
    } else if (snap.activePath != widget.path) {
      setState(() {
        _playing = true;
        _position = Duration.zero;
      });
    }

    try {
      await ChatVoicePlaybackService.play(widget.path);
    } catch (e, st) {
      debugPrint('Voice playback failed: $e\n$st');
      if (mounted) _syncFromPlayback();
    }
  }

  double get _playbackLevel {
    if (!_playing || widget.duration.inMilliseconds <= 0) return 0.12;
    final progress =
        _position.inMilliseconds / widget.duration.inMilliseconds;
    return (0.2 + progress * 0.8).clamp(0.12, 1.0);
  }

  bool get _isTutor => widget.variant == ChatVoiceBubbleVariant.tutor;

  @override
  Widget build(BuildContext context) {
    final total = widget.duration.inMilliseconds > 0
        ? widget.duration
        : const Duration(seconds: 1);
    final label = _playing
        ? DurationFormat.mmSs(_position)
        : DurationFormat.mmSs(total);
    final playBg = _isTutor
        ? AppColors.brandPrimary.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.22);
    final playIcon = _isTutor ? AppColors.brandPrimary : Colors.white;
    final waveColor = _isTutor ? AppColors.brandPrimary : Colors.white;
    final labelStyle = _isTutor
        ? AppTextStyles.chatTutorMessage().copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B6E76),
            fontFeatures: const [FontFeature.tabularFigures()],
          )
        : AppTextStyles.chatUserMessage().copyWith(
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      child: Row(
        children: [
          Material(
            color: playBg,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => unawaited(_togglePlay()),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: playIcon,
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
                  color: waveColor,
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
              style: labelStyle,
            ),
          ),
        ],
      ),
    );
  }
}
