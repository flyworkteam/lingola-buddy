import 'dart:math';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Routes/app_routes.dart';
import 'package:lingola_buddy/Core/Routes/call_navigation.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Utils/call_topic_display.dart';
import 'package:lingola_buddy/Core/Widgets/tutor_avatar_image.dart';
import 'package:lingola_buddy/Models/app_enums.dart';
import 'package:lingola_buddy/Models/call_preview_args.dart';
import 'package:lingola_buddy/Models/tutor_model.dart';
import 'package:lingola_buddy/Riverpod/Controllers/CallSessionController/call_session_controller.dart';
import 'package:lingola_buddy/Riverpod/Providers/tutors_catalog_provider.dart';
import 'package:lingola_buddy/Services/premium_call_gate.dart';

/// Gelen pratik görüşmesi önizlemesi — misafir (onboarding) veya oturum (gerçek ders/eğitmen).
class CallPreviewView extends ConsumerStatefulWidget {
  const CallPreviewView({super.key, required this.args});

  final CallPreviewArgs args;

  @override
  ConsumerState<CallPreviewView> createState() => _CallPreviewViewState();
}

class _CallPreviewViewState extends ConsumerState<CallPreviewView> {
  String? _resolvedGuestTutorId;

  String _resolveTutorId(List<TutorModel> catalog) {
    if (widget.args.isGuestPreview) {
      if (widget.args.tutorId != null && widget.args.tutorId!.isNotEmpty) {
        return widget.args.tutorId!;
      }
      _resolvedGuestTutorId ??= catalog.isEmpty
          ? 'sophie'
          : catalog[Random().nextInt(catalog.length)].id;
      return _resolvedGuestTutorId!;
    }
    return widget.args.tutorId ?? 'annie';
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(tutorsCatalogProvider);
    final tutorId = _resolveTutorId(catalog);
    final tutor =
        ref.watch(tutorByIdProvider(tutorId)) ??
        catalog.where((t) => t.id == tutorId).firstOrNull;
    final topic = widget.args.isGuestPreview
        ? null
        : resolveCallTopicDisplay(ref, widget.args.lessonId);

    if (tutor == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tutorDisplayName = tutor.localizedDisplayName;
    final subtitle = widget.args.isGuestPreview
        ? AppTranslations.interpolate(AppTranslations.section('call', 'desc'), {
            'name': tutorDisplayName,
          })
        : topic != null
        ? AppTranslations.interpolate(
            topic.isDailyConversation
                ? AppTranslations.section('call', 'desc_with_daily')
                : AppTranslations.section('call', 'desc_with_lesson'),
            {
              'name': tutorDisplayName,
              'lesson': topic.emojiTitle,
              'topic': topic.emojiTitle,
            },
          )
        : AppTranslations.interpolate(AppTranslations.section('call', 'desc'), {
            'name': tutorDisplayName,
          });

    final mq = MediaQuery.sizeOf(context);
    final avatarR = (mq.width * 0.31).clamp(96.0, 121.0);
    final avatarSize = avatarR * 2;
    final avatarCacheSize = TutorAvatarImage.decodePixels(context, avatarSize);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: TutorAvatarImage(
                tutor: tutor,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                alignment: const Alignment(0, 0.5),
              ),
            ),
          ),
          ColoredBox(color: Colors.black.withValues(alpha: 0.75)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                            final root = Navigator.of(
                              context,
                              rootNavigator: true,
                            );
                            if (root.canPop()) {
                              root.pop();
                              return;
                            }
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.bottomNav,
                              (_) => false,
                            );
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
                                    tutorDisplayName,
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
                              subtitle,
                              textAlign: TextAlign.center,
                              softWrap: true,
                              maxLines: 3,
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
                      child: SizedBox(
                        width: avatarR * 2,
                        height: avatarR * 2,
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
                              fit: BoxFit.cover,
                              alignment: const Alignment(0, -1.2),
                              cacheWidth: avatarCacheSize,
                              cacheHeight: avatarCacheSize,
                              loadingBackgroundColor: Colors.white,
                              hideAssetFallback: true,
                            ),
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
                              final lessonId = widget.args.lessonId;
                              void startVideo() {
                                ref
                                    .read(
                                      callSessionControllerProvider.notifier,
                                    )
                                    .bindTutor(
                                      tutorId,
                                      kind: CallKind.video,
                                      lessonId: lessonId,
                                    );
                                CallNavigation.pushVideo(context, tutorId);
                              }

                              if (widget.args.isGuestPreview) {
                                startVideo();
                                return;
                              }

                              PremiumCallGate.runIfAllowed(
                                context,
                                ref,
                                () async => startVideo(),
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
                                      borderRadius: BorderRadius.circular(999),
                                      gradient:
                                          AppColors.callPreviewCtaSheenGradient,
                                    ),
                                    child: const SizedBox.expand(),
                                  ),
                                  Center(
                                    child: Text(
                                      AppTranslations.section('call', 'button'),
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
                      if (widget.args.isGuestPreview) ...[
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.signUp,
                              (_) => false,
                            );
                          },
                          child: Text(
                            AppTranslations.section('call', 'another_time'),
                            style: AppTextStyles.callPreviewDeferLink(),
                          ),
                        ),
                      ],
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
