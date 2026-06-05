import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Widgets/tutor_avatar_image.dart';
import 'package:lingola_buddy/Core/Routes/call_navigation.dart';
import 'package:lingola_buddy/Riverpod/Controllers/CallSessionController/call_session_controller.dart';
import 'package:lingola_buddy/Riverpod/Providers/curriculum_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/tutors_catalog_provider.dart';

class TutorProfileView extends ConsumerWidget {
  const TutorProfileView({super.key, required this.tutorId});

  final String tutorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tutor =
        ref.watch(tutorByIdProvider(tutorId)) ??
        ref.watch(tutorsCatalogProvider).first;
    final displayName = tutor.localizedDisplayName;
    final bioText = tutor.localizedDescription;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: SvgPicture.asset(
            'assets/icons/arrow_left.svg',
            width: 24,
            height: 24,
          ),
        ),
        title: Text(
          AppTranslations.section('tudor', 'character_profile'),
          style: AppTextStyles.tutorProfileScreenTitle(),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.45,
                child: TutorAvatarImage(tutor: tutor, fit: BoxFit.cover),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.88),
                      Colors.white.withValues(alpha: 0.88),
                      Colors.white,
                    ],
                    stops: const [0.0, 0.5, 0.82],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ColoredBox(
                            color: Colors.white.withValues(alpha: 0.7),
                            child: TutorAvatarImage(
                              tutor: tutor,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              textAlign: TextAlign.start,
                              style: AppTextStyles.tutorProfileName(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SvgPicture.asset(
                            'assets/icons/america.svg',
                            width: 22,
                            height: 22,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bioText,
                        style: AppTextStyles.tutorProfileBio(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Colors.transparent),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/voice',
                            arguments: tutor.id,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/icons/voice_call.svg',
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                AppTranslations.section('tudor', 'voice_call'),
                                style:
                                    AppTextStyles.tutorProfileCallButtonLabel(
                                      color: Colors.black,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brandPrimary,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          onPressed: () async {
                            final lessonId =
                                ref.read(userCurriculumProvider).value?.currentLesson?.id;
                            if (lessonId == null) return;
                            ref
                                .read(callSessionControllerProvider.notifier)
                                .bindTutor(tutor.id, lessonId: lessonId);
                            await CallNavigation.pushSessionPreview(
                              context,
                              ref,
                              tutorId: tutor.id,
                              lessonId: lessonId,
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/icons/video_call.svg',
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                AppTranslations.section('tudor', 'video_call'),
                                style:
                                    AppTextStyles.tutorProfileCallButtonLabel(
                                      color: Colors.white,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/chat',
                            arguments: tutor.id,
                          ),
                          child: Text(
                            AppTranslations.section('tudor', 'text_message'),
                            style: AppTextStyles.tutorProfileTextMessage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
