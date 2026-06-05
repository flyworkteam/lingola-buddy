import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Utils/realtime_auth_token.dart';
import 'package:lingola_buddy/Models/app_enums.dart';
import 'package:lingola_buddy/Riverpod/Controllers/CallSessionController/call_session_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/UserProfileController/user_profile_controller.dart';
import 'package:lingola_buddy/Core/Widgets/tutor_avatar_image.dart';
import 'package:lingola_buddy/Riverpod/Providers/tutors_catalog_provider.dart';
import 'package:lingola_buddy/Services/local_notification_scheduler.dart';
import 'package:lingola_buddy/Services/realtime_call_engine.dart';
import 'package:lingola_buddy/Services/session_local_storage.dart';

/// Sesli arama — bağlanıyor: bulanık portre, ortada avatar, alt kontroller.
class VoiceCallView extends ConsumerStatefulWidget {
  const VoiceCallView({super.key, required this.tutorId});

  final String tutorId;

  static const double _controlButtonSize = 60;
  static const double _controlGap = 24;
  static const double _blurSigma = 28;

  @override
  ConsumerState<VoiceCallView> createState() => _VoiceCallViewState();
}

class _VoiceCallViewState extends ConsumerState<VoiceCallView> {
  RealtimeCallEngine? _engine;
  bool _speakerOn = false;
  bool _micMuted = false;
  RealtimeCallPhase _phase = RealtimeCallPhase.connecting;
  int _elapsedSeconds = 0;
  Timer? _durationTimer;
  DateTime? _callStartedAt;
  bool _durationStarted = false;

  static const ColorFilter _whiteIcon = ColorFilter.mode(
    Colors.white,
    BlendMode.srcIn,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    unawaited(_engine?.end());
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final lessonId = ref.read(callSessionControllerProvider).activeLessonId;
    ref
        .read(callSessionControllerProvider.notifier)
        .bindTutor(widget.tutorId, kind: CallKind.voice, lessonId: lessonId);

    final lang = ref.read(userProfileControllerProvider).uiLanguageCode;
    final engine = RealtimeCallEngine(
      tutorId: widget.tutorId,
      languageCode: lang,
      lessonId: lessonId,
      getAuthToken: () => ensureRealtimeAuthToken(ref),
      onPhaseChanged: (p) {
        if (!mounted) return;
        setState(() => _phase = p);
      },
      onServerEnded: () {
        if (!mounted) return;
        Navigator.of(context).pop();
      },
    );
    engine.onUserSpeechStarted = _startCallDuration;
    engine.onConnectionReady = () {
      if (!mounted) return;
      setState(() => _speakerOn = engine.isSpeakerOn);
    };
    _engine = engine;
    await engine.start();
    if (!mounted) return;
    setState(() {
      _speakerOn = engine.isSpeakerOn;
      _micMuted = engine.isMuted;
    });
  }

  String _statusLabel() {
    switch (_phase) {
      case RealtimeCallPhase.connecting:
        return AppTranslations.section('tudor', 'signal_connecting');
      case RealtimeCallPhase.listening:
        return AppTranslations.section('tudor', 'signal_listening');
      case RealtimeCallPhase.thinking:
        return AppTranslations.section('tudor', 'signal_thinking');
      case RealtimeCallPhase.speaking:
        return AppTranslations.section('tudor', 'signal_speaking');
      case RealtimeCallPhase.error:
        return AppTranslations.section('tudor', 'signal_error');
    }
  }

  void _startCallDuration() {
    if (_durationStarted) return;
    _durationStarted = true;
    _callStartedAt = DateTime.now();
    _elapsedSeconds = 0;
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _callStartedAt == null) return;
      setState(() {
        _elapsedSeconds = DateTime.now().difference(_callStartedAt!).inSeconds;
      });
    });
  }

  Future<void> _endCall() async {
    _durationTimer?.cancel();
    final elapsed = _durationStarted ? _elapsedSeconds : 0;
    final session = ref.read(callSessionControllerProvider);
    final words = _engine?.userWordsSpoken ?? 0;
    final score = RealtimeCallEngine.computeSessionScore(
      durationSeconds: elapsed,
      words: words,
    );
    final lessonCompleted = session.activeLessonId != null &&
        session.activeLessonId!.isNotEmpty &&
        elapsed >= 120;
    ref.read(callSessionControllerProvider.notifier).endCall(
          durationSeconds: elapsed,
          wordsSpoken: words,
          sessionScorePercent: score,
          lessonCompleted: lessonCompleted,
        );
    final lessonId = session.activeLessonId;
    if (!lessonCompleted &&
        lessonId != null &&
        lessonId.isNotEmpty) {
      final title = lessonId.startsWith('dc_')
          ? AppTranslations.dailyConversationField(
              lessonId,
              'title',
              fallback: lessonId,
            )
          : AppTranslations.lessonField(
              lessonId,
              'title',
              fallback: lessonId,
            );
      unawaited(
        LocalNotificationScheduler.instance.scheduleCallFollowUp(
          lessonId: lessonId,
          lessonTitle: title,
        ),
      );
    } else {
      unawaited(SessionLocalStorage.clearCallReminder());
      unawaited(LocalNotificationScheduler.instance.clearCallFollowUp());
    }
    await _engine?.end();
    if (mounted) Navigator.of(context).maybePop();
  }

  Widget _roundControl({
    required String asset,
    required VoidCallback onTap,
    Color? backgroundColor,
    double? iconOpacity,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          width: VoiceCallView._controlButtonSize,
          height: VoiceCallView._controlButtonSize,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Opacity(
              opacity: iconOpacity ?? 1,
              child: SvgPicture.asset(asset, colorFilter: _whiteIcon),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tutor = ref.watch(tutorByIdProvider(widget.tutorId)) ??
        ref.watch(tutorsCatalogProvider).first;
    final displayName = tutor.localizedDisplayName;
    final status = _statusLabel();

    final avatarSize = (MediaQuery.sizeOf(context).width * 0.52).clamp(
      200.0,
      260.0,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: VoiceCallView._blurSigma,
                sigmaY: VoiceCallView._blurSigma,
              ),
              child: Transform.scale(
                scale: 1.15,
                child: TutorAvatarImage(
                  tutor: tutor,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  alignment: Alignment.center,
                  fallbackAsset: 'assets/images/avatar_4.png',
                ),
              ),
            ),
          ),
          ColoredBox(color: Colors.black.withValues(alpha: 0.5)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            style: IconButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(40, 48),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: SvgPicture.asset(
                              'assets/icons/arrow_left.svg',
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              displayName,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.callPreviewNameOnDark(),
                            ),
                            Text(
                              '$status..',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.callPreviewSubtitleOnDark(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: ClipOval(
                          child: TutorAvatarImage(
                            tutor: tutor,
                            width: avatarSize,
                            height: avatarSize,
                            alignment: const Alignment(0, -0.15),
                            fallbackAsset: 'assets/images/avatar_4.png',
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _roundControl(
                          asset: _speakerOn
                              ? 'assets/icons/volume.svg'
                              : 'assets/icons/volume_slash.svg',
                          onTap: () async {
                            final next = !_speakerOn;
                            setState(() => _speakerOn = next);
                            await _engine?.setSpeakerOn(next);
                          },
                          iconOpacity: _speakerOn ? 1 : 0.45,
                        ),
                        const SizedBox(width: VoiceCallView._controlGap),
                        _roundControl(
                          asset: _micMuted
                              ? 'assets/icons/microphone_slash.svg'
                              : 'assets/icons/microphone.svg',
                          onTap: () {
                            final next = !_micMuted;
                            setState(() => _micMuted = next);
                            _engine?.setMuted(next);
                          },
                          iconOpacity: _micMuted ? 0.45 : 1,
                        ),
                        const SizedBox(width: VoiceCallView._controlGap),
                        _roundControl(
                          asset: 'assets/icons/call_end_slash.svg',
                          onTap: _endCall,
                          backgroundColor: AppColors.activeCallEndHangup,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
