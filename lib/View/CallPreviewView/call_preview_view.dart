import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Routes/app_routes.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Riverpod/Controllers/CallSessionController/call_session_controller.dart';

/// Gelen pratik görüşmesi önizlemesi — Figma: bulanık portre, üstte geri + başlık, ortada avatar, gradient CTA.
class CallPreviewView extends ConsumerWidget {
  const CallPreviewView({super.key});

  static const String _avatarAsset = 'assets/images/avatar_4.png';
  static const EdgeInsets _screenPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 20);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = AppTranslations.section('call', 'title');
    final desc = AppTranslations.section('call', 'desc');
    final mq = MediaQuery.sizeOf(context);
    final avatarR = (mq.width * 0.31).clamp(96.0, 121.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Transform.scale(
                scale: 0.92,
                alignment: Alignment.center,
                child: Image.asset(
                  _avatarAsset,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  alignment: const Alignment(0, 0.5),
                ),
              ),
            ),
          ),
          ColoredBox(color: Colors.black.withValues(alpha: 0.75)),
          SafeArea(
            child: Padding(
              padding: _screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            } else {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                AppRoutes.bottomNav,
                                (_) => false,
                              );
                            }
                          },
                          child: SvgPicture.asset(
                            'assets/icons/arrow_left.svg',
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/call.svg',
                                  width: 22,
                                  height: 22,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style:
                                        AppTextStyles.callPreviewNameOnDark(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              desc,
                              textAlign: TextAlign.center,
                              softWrap: true,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.callPreviewSubtitleOnDark(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            _avatarAsset,
                            width: avatarR * 2,
                            height: avatarR * 2,
                            fit: BoxFit.cover,
                            alignment: const Alignment(0, -1.2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () {
                              ref
                                  .read(
                                    callSessionControllerProvider.notifier,
                                  )
                                  .bindTutor('sophie');
                              Navigator.pushNamed(
                                context,
                                AppRoutes.activeCall,
                              );
                            },
                            child: Ink(
                              decoration: BoxDecoration(
                                color: AppColors.callPreviewCtaGreen,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(999),
                                      gradient:
                                          AppColors.callPreviewCtaSheenGradient,
                                    ),
                                    child: const SizedBox.expand(),
                                  ),
                                  Center(
                                    child: Text(
                                      AppTranslations.section(
                                        'call',
                                        'button',
                                      ),
                                      style:
                                          AppTextStyles.callPreviewStartCta(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            // Navigator.of(context).pop();
                            Navigator.pushNamed(
                              context,
                              AppRoutes.paywall,
                            );
                          } else {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.bottomNav,
                              (_) => false,
                            );
                          }
                        },
                        child: Text(
                          AppTranslations.section('call', 'another_time'),
                          style: AppTextStyles.callPreviewDeferLink(),
                        ),
                      ),
                    ],
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
