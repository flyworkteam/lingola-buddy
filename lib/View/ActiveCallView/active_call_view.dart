import 'dart:async' show Timer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Routes/app_routes.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Riverpod/Controllers/CallSessionController/call_session_controller.dart';
import 'package:lingola_buddy/Riverpod/Providers/tutors_catalog_provider.dart';

/// Aktif görüşme — Figma: üst başlık + iki video kartı, altta koyu şerit ve 4 kontrol.
///
/// Uzaktaki ve yerel görüntü şimdilik [Image.asset] ile (ileride `camera` / WebRTC
/// önizlemesi buraya bağlanabilir; canlı kamera için manifest izinleri ve paket
/// kurulumu gerektiğinden demo aşamasında statik görsel kullanılıyor).
class ActiveCallView extends ConsumerStatefulWidget {
  const ActiveCallView({super.key});

  static const double _videoRadius = 16;
  static const double _controlBarHeight = 99;
  static const double _controlButtonSize = 60;
  static const double _controlIconSize = 26;
  static const double _controlGap = 16;

  static const String _remoteAvatar = 'assets/images/avatar_4.png';
  static const String _localAvatar = 'assets/images/avatar_2.png';

  @override
  ConsumerState<ActiveCallView> createState() => _ActiveCallViewState();
}

class _ActiveCallViewState extends ConsumerState<ActiveCallView> {
  Timer? _timer;
  int _elapsedSeconds = 0;

  bool _videoOn = true;
  bool _micMuted = true;
  bool _speakerMuted = true;

  static const ColorFilter _whiteIcon = ColorFilter.mode(
    Colors.white,
    BlendMode.srcIn,
  );

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration() {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _endCall() {
    ref
        .read(callSessionControllerProvider.notifier)
        .endCall(durationSeconds: _elapsedSeconds);
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushReplacementNamed(AppRoutes.callSummary);
  }

  NavigatorState get _rootNav => Navigator.of(context, rootNavigator: true);

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

  Widget _videoCard({
    required String imageAsset,
    required Widget? bottomOverlay,
    bool dimContent = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(ActiveCallView._videoRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: const Color(0xFFF6F6F6),
            child: Image.asset(
              imageAsset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
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
                onTap: () => setState(() => _videoOn = !_videoOn),
                iconOpacity: _videoOn ? 1 : 0.45,
              ),
              const SizedBox(width: ActiveCallView._controlGap),
              _roundControlButton(
                asset: _speakerMuted
                    ? 'assets/icons/volume_slash.svg'
                    : 'assets/icons/volume.svg',
                onTap: () => setState(() => _speakerMuted = !_speakerMuted),
              ),
              const SizedBox(width: ActiveCallView._controlGap),
              _roundControlButton(
                asset: _micMuted
                    ? 'assets/icons/microphone_slash.svg'
                    : 'assets/icons/microphone.svg',
                onTap: () => setState(() => _micMuted = !_micMuted),
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
    final tutors = ref.watch(tutorsCatalogProvider);
    final tutorId = session.activeTutorId ?? 'sophie';
    final matches = tutors.where((t) => t.id == tutorId);
    final tutor = matches.isEmpty ? tutors.first : matches.first;
    final name = AppTranslations.section('tudor', tutor.id);
    final remoteAvatar = tutor.avatarAssetPath ?? ActiveCallView._remoteAvatar;

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
                      onPressed: () {
                        if (_rootNav.canPop()) {
                          _rootNav.pop();
                        } else {
                          _rootNav.pushNamedAndRemoveUntil(
                            AppRoutes.bottomNav,
                            (_) => false,
                          );
                        }
                      },
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
                  imageAsset: remoteAvatar,
                  bottomOverlay: null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: _videoCard(
                  imageAsset: ActiveCallView._localAvatar,
                  bottomOverlay: _controlBar(),
                  dimContent: !_videoOn,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
