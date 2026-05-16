import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Models/app_enums.dart';
import 'package:lingola_buddy/Riverpod/Controllers/CallSessionController/call_session_controller.dart';
import 'package:lingola_buddy/Riverpod/Providers/tutors_catalog_provider.dart';

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
  bool _speakerOn = true;
  bool _micMuted = false;

  static const ColorFilter _whiteIcon = ColorFilter.mode(
    Colors.white,
    BlendMode.srcIn,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(callSessionControllerProvider.notifier)
          .bindTutor(widget.tutorId, kind: CallKind.voice);
    });
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
    final tutors = ref.watch(tutorsCatalogProvider);
    final matches = tutors.where((t) => t.id == widget.tutorId);
    final tutor = matches.isEmpty ? tutors.first : matches.first;
    final displayName = AppTranslations.section('tudor', tutor.id);
    final avatarPath = tutor.avatarAssetPath ?? 'assets/images/avatar_4.png';
    final status = AppTranslations.section('tudor', 'signal_connecting');

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
                child: Image.asset(
                  avatarPath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  alignment: Alignment.center,
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
                          child: Image.asset(
                            avatarPath,
                            width: avatarSize,
                            height: avatarSize,
                            fit: BoxFit.cover,
                            alignment: const Alignment(0, -0.15),
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
                          onTap: () => setState(() => _speakerOn = !_speakerOn),
                          iconOpacity: _speakerOn ? 1 : 1,
                        ),
                        const SizedBox(width: VoiceCallView._controlGap),
                        _roundControl(
                          asset: _micMuted
                              ? 'assets/icons/microphone_slash.svg'
                              : 'assets/icons/microphone.svg',
                          onTap: () => setState(() => _micMuted = !_micMuted),
                          iconOpacity: _micMuted ? 1 : 1,
                        ),
                        const SizedBox(width: VoiceCallView._controlGap),
                        _roundControl(
                          asset: 'assets/icons/call_end_slash.svg',
                          onTap: () => Navigator.of(context).maybePop(),
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
