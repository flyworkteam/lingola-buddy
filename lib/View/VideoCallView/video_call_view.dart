import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Routes/app_routes.dart';
import 'package:lingola_buddy/Core/Routes/call_navigation.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Utils/call_immersive_ui.dart';
import 'package:lingola_buddy/Core/Utils/call_permissions.dart';
import 'package:lingola_buddy/Core/Utils/realtime_auth_token.dart';
import 'package:lingola_buddy/Core/Widgets/tutor_avatar_image.dart';
import 'package:lingola_buddy/Models/app_enums.dart';
import 'package:lingola_buddy/Riverpod/Controllers/CallSessionController/call_session_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/UserProfileController/user_profile_controller.dart';
import 'package:lingola_buddy/Riverpod/Providers/realtime_call_holder_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/tutors_catalog_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/user_provider.dart';
import 'package:lingola_buddy/Services/local_camera_holder.dart';
import 'package:lingola_buddy/Services/realtime_call_engine.dart';

/// Görüntülü arama — bağlanırken sadece durum + kapat; kontroller aktif ekranda.
class VideoCallView extends ConsumerStatefulWidget {
  const VideoCallView({super.key, required this.tutorId});

  final String tutorId;

  static const double _controlButtonSize = 60;

  @override
  ConsumerState<VideoCallView> createState() => _VideoCallViewState();
}

class _VideoCallViewState extends ConsumerState<VideoCallView> {
  RealtimeCallPhase _phase = RealtimeCallPhase.connecting;
  bool _handoffToActive = false;
  bool _ending = false;

  static const ColorFilter _whiteIcon = ColorFilter.mode(
    Colors.white,
    BlendMode.srcIn,
  );

  @override
  void initState() {
    super.initState();
    unawaited(CallImmersiveUi.enter());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(callSessionControllerProvider.notifier).markCallStarted();
      // İlk kare çizilsin; izin + websocket aynı frame'de UI'ı kilitlemesin.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(_bootstrap()),
      );
    });
  }

  @override
  void dispose() {
    unawaited(CallImmersiveUi.exit());
    if (!_handoffToActive && !_ending) {
      unawaited(ref.read(realtimeCallHolderProvider.notifier).detachAndEnd());
      unawaited(LocalCameraHolder.instance.release());
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final lessonId = ref.read(callSessionControllerProvider).activeLessonId;
    ref
        .read(callSessionControllerProvider.notifier)
        .bindTutor(widget.tutorId, kind: CallKind.video, lessonId: lessonId);

    final perms = await requestVideoCallPermissions();
    if (!mounted) return;
    if (!perms.canStartVideoCall) {
      setState(() => _phase = RealtimeCallPhase.error);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mikrofon izni gerekli. Ayarlar → Lingola Buddy → Mikrofon.',
          ),
        ),
      );
      return;
    }

    if (perms.cameraGranted) {
      unawaited(LocalCameraHolder.instance.prewarm());
    }

    final lang = ref.read(userProfileControllerProvider).uiLanguageCode;
    final learnerName = ref.read(currentUserProvider)?.displayName ?? '';
    final engine = RealtimeCallEngine(
      tutorId: widget.tutorId,
      languageCode: lang,
      lessonId: lessonId,
      learnerDisplayName: learnerName,
      videoMode: true,
      getAuthToken: () => ensureRealtimeAuthToken(ref),
      onPhaseChanged: (p) {
        if (!mounted) return;
        setState(() => _phase = p);
      },
      onConnectionReady: _openActiveCall,
    );
    ref.read(realtimeCallHolderProvider.notifier).attach(engine);
    await engine.start(skipPermissionRequest: true);
  }

  void _openActiveCall() {
    if (!mounted) return;
    _handoffToActive = true;
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushReplacementNamed(AppRoutes.activeCall);
  }

  void _popToPreviousScreen() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    CallNavigation.popPreview(context);
  }

  Future<void> _cancelCall() async {
    if (_ending) return;
    _ending = true;
    // Önce ekrandan çık; bağlantı kesme arka planda (VoiceCallView ile aynı).
    if (mounted) _popToPreviousScreen();
    unawaited(ref.read(realtimeCallHolderProvider.notifier).detachAndEnd());
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

  @override
  Widget build(BuildContext context) {
    final tutor =
        ref.read(tutorByIdProvider(widget.tutorId)) ??
        ref.read(tutorsCatalogProvider).first;
    final displayName = tutor.localizedDisplayName;
    final status = _statusLabel();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final avatarSize = (screenWidth * 0.52).clamp(200.0, 260.0);
    final bgCacheWidth = TutorAvatarImage.decodePixels(context, screenWidth);
    final avatarCacheWidth = TutorAvatarImage.decodePixels(context, avatarSize);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          TutorAvatarImage(
            tutor: tutor,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
            cacheWidth: bgCacheWidth,
            filterQuality: FilterQuality.low,
            fallbackAsset: 'assets/images/avatar_4.png',
          ),
          ColoredBox(color: Colors.black.withValues(alpha: 0.72)),
          Column(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top + 8,
                  left: 8,
                  right: 16,
                ),
                child: SizedBox(
                  height: 56,
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
                          onPressed: () => unawaited(_cancelCall()),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.callPreviewNameOnDark(),
                          ),
                          Text(
                            '$status..',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.callPreviewSubtitleOnDark(),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                      child: SizedBox(
                        width: avatarSize,
                        height: avatarSize,
                        child: TutorAvatarImage(
                          tutor: tutor,
                          alignment: const Alignment(0, -0.15),
                          cacheWidth: avatarCacheWidth,
                          cacheHeight: avatarCacheWidth,
                          fallbackAsset: 'assets/images/avatar_4.png',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom + 28,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => unawaited(_cancelCall()),
                    child: Ink(
                      width: VideoCallView._controlButtonSize,
                      height: VideoCallView._controlButtonSize,
                      decoration: const BoxDecoration(
                        color: AppColors.activeCallEndHangup,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/icons/call_end_slash.svg',
                          width: 26,
                          height: 26,
                          colorFilter: _whiteIcon,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
