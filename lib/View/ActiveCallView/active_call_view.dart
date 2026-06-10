import 'dart:async' show Timer, unawaited;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Routes/app_routes.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Utils/call_permissions.dart';
import 'package:lingola_buddy/Core/Utils/realtime_auth_token.dart';
import 'package:lingola_buddy/Riverpod/Controllers/CallSessionController/call_session_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/UserProfileController/user_profile_controller.dart';
import 'package:lingola_buddy/Core/Widgets/local_camera_preview.dart';
import 'package:lingola_buddy/Core/Widgets/tutor_avatar_image.dart';
import 'package:lingola_buddy/Core/Widgets/tutor_rive_avatar.dart';
import 'package:lingola_buddy/Models/app_enums.dart';
import 'package:lingola_buddy/Models/tutor_model.dart';
import 'package:lingola_buddy/Riverpod/Providers/realtime_call_holder_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/tutors_catalog_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/user_provider.dart';
import 'package:lingola_buddy/Services/local_camera_holder.dart';
import 'package:lingola_buddy/Services/local_notification_scheduler.dart';
import 'package:lingola_buddy/Services/realtime_call_engine.dart';
import 'package:lingola_buddy/Services/session_local_storage.dart';
import 'package:permission_handler/permission_handler.dart';

/// Aktif görüşme — Figma: üst başlık + iki video kartı, altta koyu şerit ve 4 kontrol.
class ActiveCallView extends ConsumerStatefulWidget {
  const ActiveCallView({super.key});

  static const double _videoRadius = 16;
  static const double _controlBarHeight = 99;
  static const double _controlButtonSize = 60;
  static const double _controlGap = 16;
  static const int _maxVideoCallSeconds = 60;

  static const String _remoteAvatar = 'assets/images/avatar_4.png';

  @override
  ConsumerState<ActiveCallView> createState() => _ActiveCallViewState();
}

class _ActiveCallViewState extends ConsumerState<ActiveCallView> {
  Timer? _timer;
  DateTime? _callStartedAt;
  RealtimeCallEngine? _engine;
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  CameraLensDirection _lensDirection = CameraLensDirection.front;
  bool _cameraLoading = true;
  bool _cameraSwitching = false;

  bool _micMuted = false;
  bool _speakerOn = true;
  bool _lipSyncAudible = false;
  bool _endingCall = false;

  static const ColorFilter _whiteIcon = ColorFilter.mode(
    Colors.white,
    BlendMode.srcIn,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    _startCallDuration();

    var engine = ref.read(realtimeCallHolderProvider);
    if (engine == null) {
      final session = ref.read(callSessionControllerProvider);
      final tutorId = session.activeTutorId ?? 'sophie';
      final lang = ref.read(userProfileControllerProvider).uiLanguageCode;
      final lessonId = session.activeLessonId;
      final profileUser = ref.read(currentUserProvider);
      final learnerName = profileUser != null && profileUser.id != 'local'
          ? profileUser.displayName.trim()
          : '';
      engine = RealtimeCallEngine(
        tutorId: tutorId,
        languageCode: lang,
        lessonId: lessonId,
        freeTalk: RealtimeCallEngine.isFreeTalk(lessonId),
        learnerDisplayName: learnerName,
        videoMode: true,
        getAuthToken: () => ensureRealtimeAuthToken(ref),
      );
      ref.read(callSessionControllerProvider.notifier).bindTutor(
            tutorId,
            kind: CallKind.video,
            lessonId: lessonId,
          );
      ref.read(realtimeCallHolderProvider.notifier).attach(engine);
      await engine.start();
    }
    _engine = engine;
    _lipSyncAudible = engine.lipSyncAudible;
    engine.onLipSyncAudibleChanged = (audible) {
      if (!mounted) return;
      setState(() => _lipSyncAudible = audible);
    };
    engine.bindServerEndedHandler(() {
      if (!mounted) return;
      unawaited(_endCall());
    });
    await engine.activateForActiveCall();
    if (!mounted) return;
    final live = _engine!;
    setState(() {
      _micMuted = live.isMuted;
      _speakerOn = live.isSpeakerOn;
    });
    _scheduleCameraLast();
  }

  bool get _applyOnboardingTimeLimit =>
      ref.read(callSessionControllerProvider).onboardingGuestCallLimit;

  void _startCallDuration() {
    if (_callStartedAt != null) return;
    _callStartedAt = DateTime.now();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _callStartedAt == null || _endingCall) return;
      final elapsed = _resolvedElapsedSeconds();
      if (_applyOnboardingTimeLimit &&
          elapsed >= ActiveCallView._maxVideoCallSeconds) {
        _timer?.cancel();
        unawaited(_endCall());
        return;
      }
      setState(() {});
    });
    if (mounted) setState(() {});
  }

  int _resolvedElapsedSeconds() {
    if (_callStartedAt == null) return 0;
    return DateTime.now().difference(_callStartedAt!).inSeconds;
  }

  /// Kamera yalnızca önizleme — ilk kare çizildikten sonra (idle kuyruğuna güvenme).
  void _scheduleCameraLast() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_initCamera());
    });
  }

  Future<void> _initCamera() async {
    if (!mounted) return;

    await LocalCameraHolder.instance.ensureReady();
    if (!mounted) return;

    final prewarmed = LocalCameraHolder.instance.claimFrontController();
    if (prewarmed != null && prewarmed.value.isInitialized) {
      _cameras = LocalCameraHolder.instance.cameras;
      if (mounted) {
        setState(() {
          _cameraController = prewarmed;
          _lensDirection = CameraLensDirection.front;
          _cameraLoading = false;
        });
      }
      _deferAudioRefreshAfterCamera();
      return;
    }

    final ok = await Permission.camera.isGranted || await ensureCameraPermission();
    if (!ok || !mounted) {
      if (mounted) setState(() => _cameraLoading = false);
      return;
    }
    try {
      _cameras = LocalCameraHolder.instance.cameras;
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
      }
      if (_cameras.isEmpty) {
        if (mounted) setState(() => _cameraLoading = false);
        return;
      }
      await _openCamera(_lensDirection);
    } catch (e) {
      debugPrint('ActiveCallView camera: $e');
      if (mounted) setState(() => _cameraLoading = false);
    }
  }

  void _deferAudioRefreshAfterCamera() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_engine?.refreshAudioSessionAfterCamera());
    });
  }

  CameraDescription? _cameraForLens(CameraLensDirection direction) {
    final list = _cameras.where((c) => c.lensDirection == direction).toList();
    return list.isEmpty ? null : list.first;
  }

  /// Önizleme kamerası — yalnızca görüntü; mikrofon/ses [RealtimeCallEngine]'de.
  Future<void> _openCamera(CameraLensDirection direction) async {
    if (_cameraSwitching) return;
    final desc = _cameraForLens(direction);
    if (desc == null) {
      if (mounted) setState(() => _cameraLoading = false);
      return;
    }
    _cameraSwitching = true;
    try {
      await _cameraController?.dispose();
      final controller = CameraController(
        desc,
        ResolutionPreset.low,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _lensDirection = desc.lensDirection;
        _cameraController = controller;
        _cameraLoading = false;
      });
      _deferAudioRefreshAfterCamera();
    } catch (e) {
      debugPrint('ActiveCallView camera: $e');
      if (mounted) setState(() => _cameraLoading = false);
    } finally {
      _cameraSwitching = false;
    }
  }

  Future<void> _flipCamera() async {
    if (_cameraSwitching || _cameras.length < 2) return;
    final next = _lensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    if (_cameraForLens(next) == null) return;
    await _openCamera(next);
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_cameraController?.dispose());
    super.dispose();
  }

  String _formatDuration() {
    final elapsed = _resolvedElapsedSeconds();
    final m = elapsed ~/ 60;
    final s = elapsed % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _endCall() async {
    if (_endingCall) return;
    _endingCall = true;
    _timer?.cancel();
    final session = ref.read(callSessionControllerProvider);
    final rawElapsed = _resolvedElapsedSeconds();
    final elapsed = session.onboardingGuestCallLimit
        ? rawElapsed.clamp(0, ActiveCallView._maxVideoCallSeconds)
        : rawElapsed;
    final engine = ref.read(realtimeCallHolderProvider);
    final words = engine?.userWordsSpoken ?? 0;
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
    await ref.read(realtimeCallHolderProvider.notifier).detachAndEnd();
    if (!mounted) return;
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil(AppRoutes.callSummary, (route) => false);
  }

  Widget _roundControlButton({
    required String asset,
    required VoidCallback onTap,
    Color? backgroundColor,
    double? iconOpacity,
  }) {
    final bg = backgroundColor ?? Colors.white.withValues(alpha: 0.2);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          width: ActiveCallView._controlButtonSize,
          height: ActiveCallView._controlButtonSize,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
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

  Widget _localPreviewContent() {
    final c = _cameraController;
    if (c != null && c.value.isInitialized && !_cameraLoading) {
      return LocalCameraPreview(controller: c);
    }
    if (_cameraLoading) {
      return const ColoredBox(
        color: Color(0xFF2A2A2A),
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38),
        ),
      );
    }
    return const ColoredBox(
      color: Color(0xFF2A2A2A),
      child: Center(
        child: Icon(Icons.videocam_off_outlined, color: Colors.white38, size: 32),
      ),
    );
  }

  Widget _videoCard({
    TutorModel? tutor,
    required Widget? bottomOverlay,
    bool isLocalPreview = false,
    bool dimContent = false,
    int? portraitCacheWidth,
  }) {
    final Widget portrait;
    if (tutor != null) {
      portrait = TutorRiveAvatar(
        tutor: tutor,
        isTalking: _lipSyncAudible,
        fit: BoxFit.cover,
        alignment: const Alignment(0, -0.15),
        fallbackAsset: ActiveCallView._remoteAvatar,
        cacheWidth: portraitCacheWidth,
        cacheHeight: portraitCacheWidth,
        loadingBackgroundColor: const Color(0xFFF6F6F6),
        hideAssetFallback: true,
      );
    } else if (isLocalPreview) {
      portrait = _localPreviewContent();
    } else {
      portrait = const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(ActiveCallView._videoRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: const Color(0xFFF6F6F6),
            child: portrait,
          ),
          if (dimContent)
            ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
          if (bottomOverlay != null)
            Positioned(left: 0, right: 0, bottom: 0, child: bottomOverlay),
        ],
      ),
    );
  }

  Widget _controlBar() {
    return SizedBox(
      height: ActiveCallView._controlBarHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(ActiveCallView._videoRadius),
            bottomRight: Radius.circular(ActiveCallView._videoRadius),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _roundControlButton(
                asset: 'assets/icons/video.svg',
                onTap: _flipCamera,
              ),
              const SizedBox(width: ActiveCallView._controlGap),
              _roundControlButton(
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
              const SizedBox(width: ActiveCallView._controlGap),
              _roundControlButton(
                asset: _micMuted
                    ? 'assets/icons/microphone_slash.svg'
                    : 'assets/icons/microphone.svg',
                onTap: () {
                  final next = !_micMuted;
                  setState(() => _micMuted = next);
                  _engine?.setMuted(next);
                },
              ),
              const SizedBox(width: ActiveCallView._controlGap),
              _roundControlButton(
                asset: 'assets/icons/call_end_slash.svg',
                onTap: _endCall,
                backgroundColor: AppColors.activeCallEndHangup,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(callSessionControllerProvider);
    final tutorId = session.activeTutorId ?? 'sophie';
    final tutor = ref.watch(tutorByIdProvider(tutorId)) ??
        ref.watch(tutorsCatalogProvider).first;
    final name = tutor.localizedDisplayName;
    final cardWidth = MediaQuery.sizeOf(context).width - 32;
    final portraitCacheWidth = TutorAvatarImage.decodePixels(context, cardWidth);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 60,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: _endCall,
                      icon: SvgPicture.asset(
                        'assets/icons/arrow_left.svg',
                        width: 24,
                        height: 24,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.activeCallParticipantName(),
                      ),
                      Text(
                        _formatDuration(),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.activeCallTimer(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: _videoCard(
                  tutor: tutor,
                  bottomOverlay: null,
                  portraitCacheWidth: portraitCacheWidth,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: _videoCard(
                  isLocalPreview: true,
                  bottomOverlay: _controlBar(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
