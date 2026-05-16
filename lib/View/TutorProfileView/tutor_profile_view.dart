import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Routes/app_routes.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Models/app_enums.dart';
import 'package:lingola_buddy/Riverpod/Controllers/CallSessionController/call_session_controller.dart';
import 'package:lingola_buddy/Riverpod/Providers/tutors_catalog_provider.dart';

class TutorProfileView extends ConsumerWidget {
  const TutorProfileView({super.key, required this.tutorId});

  final String tutorId;

  String _nameForId(String id) {
    return AppTranslations.section('tudor', id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tutors = ref.watch(tutorsCatalogProvider);
    final tutor = tutors.firstWhere(
      (t) => t.id == tutorId,
      orElse: () => tutors.first,
    );
    final avatarPath = tutor.avatarAssetPath ?? 'assets/images/avatar_1.png';
    final displayName = _nameForId(tutor.id);
    final bioText =
        tutor.bio ?? AppTranslations.section('tudor', 'bio_fallback');

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
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: Opacity(
                  opacity: 0.45,
                  child: Image.asset(
                    avatarPath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: AppColors.brandPrimary.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),
            ),
          ),
          ColoredBox(color: Colors.white.withValues(alpha: 0.88)),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Image.asset(
                            avatarPath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const ColoredBox(
                              color: Colors.white,
                              child: Center(child: Icon(Icons.face, size: 72)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              textAlign: TextAlign.center,
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
                      Text(bioText, style: AppTextStyles.tutorProfileBio()),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.black.withValues(alpha: 0.1),
                            ),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
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
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brandPrimary,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onPressed: () {
                            ref
                                .read(callSessionControllerProvider.notifier)
                                .bindTutor(tutor.id, kind: CallKind.video);
                            Navigator.of(context, rootNavigator: true).pushNamed(
                              AppRoutes.activeCall,
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
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
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
