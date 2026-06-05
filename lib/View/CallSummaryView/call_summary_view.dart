import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Routes/app_routes.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Widgets/app_primary_button.dart';
import 'package:lingola_buddy/Core/Widgets/tutor_avatar_image.dart';
import 'package:lingola_buddy/Core/Widgets/user_profile_avatar.dart';
import 'package:lingola_buddy/Models/daily_conversation_model.dart';
import 'package:lingola_buddy/Models/lesson_model.dart';
import 'package:lingola_buddy/Models/tutor_model.dart';
import 'package:lingola_buddy/Core/Routes/call_navigation.dart';
import 'package:lingola_buddy/Riverpod/Controllers/CallSessionController/call_session_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/PremiumController/premium_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/UserProfileController/user_profile_controller.dart';
import 'package:lingola_buddy/Riverpod/Providers/curriculum_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/daily_conversation_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/streak_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/tutors_catalog_provider.dart';
import 'package:lingola_buddy/Services/local_notification_scheduler.dart';
import 'package:lingola_buddy/Services/revenuecat_paywall.dart';
import 'package:lingola_buddy/Services/session_local_storage.dart';

String _interp(String template, Map<String, String> vars) {
  var s = template;
  for (final e in vars.entries) {
    s = s.replaceAll('{${e.key}}', e.value);
  }
  return s;
}

/// Görüşme sonrası özet — Figma: başlık + kota rozeti, çift görüntü, istatistikler, skor, sonraki konu, CTA.
///
class CallSummaryView extends ConsumerStatefulWidget {
  const CallSummaryView({super.key});

  @override
  ConsumerState<CallSummaryView> createState() => _CallSummaryViewState();
}

class _CallSummaryViewState extends ConsumerState<CallSummaryView> {
  var _postCallSynced = false;
  var _freeCallRecorded = false;
  bool _levelAdvanced = false;
  String? _levelPrevious;
  String? _levelNew;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncAfterCall());
  }

  Future<void> _syncAfterCall() async {
    if (_postCallSynced) return;
    _postCallSynced = true;

    final session = ref.read(callSessionControllerProvider);
    final minutes = session.lastDurationSeconds ~/ 60;
    final words = session.lastWordsSpoken;
    final score = session.lastSessionScorePercent;

    try {
      await ref
          .read(streakRepositoryProvider)
          .recordPractice(
            minutes: minutes,
            wordsLearned: words,
            accuracyPercent: score > 0 ? score : null,
          );
      ref.invalidate(userStreakProvider);
    } catch (_) {}

    if (!_freeCallRecorded) {
      _freeCallRecorded = true;
      await ref.read(premiumControllerProvider.notifier).recordCompletedCall(
            durationSeconds: session.lastDurationSeconds,
          );
    }

    if (session.lastLessonCompleted) {
      final lessonId = session.activeLessonId;
      if (lessonId != null && lessonId.isNotEmpty) {
        try {
          if (lessonId.startsWith('dc_')) {
            await ref
                .read(dailyConversationRepositoryProvider)
                .complete(lessonId);
            ref.invalidate(userDailyConversationProvider);
          } else {
            final updated = await ref
                .read(lessonRepositoryProvider)
                .completeLesson(lessonId);
            if (updated.levelAdvanced &&
                updated.previousLevel != null &&
                updated.newLevel != null) {
              unawaited(
                LocalNotificationScheduler.instance.showLevelAdvanced(
                  previousLevel: updated.previousLevel!,
                  newLevel: updated.newLevel!,
                ),
              );
              if (mounted) {
                setState(() {
                  _levelAdvanced = true;
                  _levelPrevious = updated.previousLevel;
                  _levelNew = updated.newLevel;
                });
              }
            }
          }
          ref.invalidate(userCurriculumProvider);
          ref.invalidate(userStreakProvider);
          unawaited(SessionLocalStorage.clearCallReminder());
          unawaited(LocalNotificationScheduler.instance.clearCallFollowUp());
          unawaited(
            LocalNotificationScheduler.instance.syncEnabled(enabled: true),
          );
        } catch (_) {}
      }
    }
  }

  LessonModel? _lessonById(String? id, UserCurriculumModel? curriculum) {
    if (id == null || curriculum == null) return null;
    for (final l in curriculum.lessons) {
      if (l.id == id) return l;
    }
    return null;
  }

  DailyConversationModel? _dailyById(
    String? id,
    UserDailyConversationCurriculum? curriculum,
  ) {
    if (id == null || curriculum == null) return null;
    for (final c in curriculum.conversations) {
      if (c.id == id) return c;
    }
    return null;
  }

  String? _sessionTopicTitle(
    String? id,
    UserCurriculumModel? lessons,
    UserDailyConversationCurriculum? daily,
  ) {
    if (id == null) return null;
    if (id.startsWith('dc_')) {
      return _dailyById(id, daily)?.localizedTitle;
    }
    return _lessonById(id, lessons)?.localizedTitle;
  }

  Future<void> _onPrimaryCta(PremiumState premium) async {
    if (!premium.canStartCall) {
      await LingolaRevenueCatPaywall.presentSheet(context, ref);
      return;
    }

    final session = ref.read(callSessionControllerProvider);
    final curriculum = ref.read(userCurriculumProvider).value;
    final daily = ref.read(userDailyConversationProvider).value;
    final activeId = session.activeLessonId;
    final lessonId = activeId ??
        curriculum?.currentLesson?.id ??
        daily?.currentConversation?.id;
    final tutorId = session.activeTutorId ?? 'annie';
    if (lessonId == null) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.bottomNav,
        (_) => false,
      );
      return;
    }
    ref
        .read(callSessionControllerProvider.notifier)
        .bindTutor(tutorId, lessonId: lessonId);
    if (!mounted) return;
    await CallNavigation.pushSessionPreview(
      context,
      ref,
      tutorId: tutorId,
      lessonId: lessonId,
    );
  }

  static String _formatDurationMmSs(int totalSeconds) {
    final safe = totalSeconds.clamp(0, 59999);
    final m = safe ~/ 60;
    final s = safe % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(callSessionControllerProvider);
    final seconds = session.lastDurationSeconds;
    final words = session.lastWordsSpoken;
    final scorePercent = session.lastSessionScorePercent;
    final fluencyLabel = '$scorePercent%';

    final user = ref.watch(userProfileControllerProvider).user;
    final userPhotoUrl = user?.avatarUrl;
    final userLabel = (user?.displayName.trim().isNotEmpty ?? false)
        ? user!.displayName.trim()
        : AppTranslations.section('video_session', 'you');

    final premium = ref.watch(premiumControllerProvider);
    final badgeText = premium.isPro
        ? AppTranslations.sectionOr(
            'profile',
            'premium_badge_pro',
            AppTranslations.sectionOr('premium', 'badge_pro', 'Pro'),
          )
        : _interp(
            AppTranslations.section('video_session', 'badge_free'),
            {
              'current': '${premium.freeCallsUsed}',
              'total': '${premium.freeCallsTotal}',
            },
          );

    final tutorId = session.activeTutorId ?? 'sophie';
    final tutor =
        ref.watch(tutorByIdProvider(tutorId)) ??
        ref.watch(tutorsCatalogProvider).firstOrNull;
    final tutorName = tutor != null
        ? tutor.localizedDisplayName
        : AppTranslations.section('call', 'title');

    final curriculum = ref.watch(userCurriculumProvider).value;
    final dailyCurriculum = ref.watch(userDailyConversationProvider).value;
    final activeId = session.activeLessonId;
    final subject =
        _sessionTopicTitle(activeId, curriculum, dailyCurriculum) ??
        AppTranslations.section('video_session', 'practice_subject');
    final topicPreview = activeId != null && activeId.startsWith('dc_')
        ? (dailyCurriculum?.currentConversation?.localizedTitle ??
              AppTranslations.section('video_session', 'next_topic_preview'))
        : (curriculum?.currentLesson?.localizedTitle ??
              AppTranslations.section('video_session', 'next_topic_preview'));

    final feedback = _interp(
      AppTranslations.section('video_session', 'feedback_great'),
      {'name': tutorName},
    );
    final statusLine = _interp(
      AppTranslations.section('video_session', 'status_just_finished'),
      {'subject': subject},
    );
    final roleLabel = AppTranslations.section(
      'video_session',
      'role_label_teacher',
    );
    final nextChosen = _interp(
      AppTranslations.section('video_session', 'next_topic_chosen'),
      {'name': tutorName},
    );
    final nextReady = _interp(
      AppTranslations.section('video_session', 'next_topic_ready'),
      {'topic': topicPreview},
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeaderRow(
                      tutor: tutor,
                      feedback: feedback,
                      statusLine: statusLine,
                      badgeText: badgeText,
                    ),
                    if (session.lastLessonCompleted || _levelAdvanced) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (_levelAdvanced
                                      ? const Color(0xFFFF8D28)
                                      : AppColors.callPreviewCtaGreen)
                                  .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _levelAdvanced &&
                                  _levelPrevious != null &&
                                  _levelNew != null
                              ? _interp(
                                  AppTranslations.section(
                                    'video_session',
                                    'level_advanced_banner_fmt',
                                  ),
                                  {
                                    'previous': _levelPrevious!,
                                    'new': _levelNew!,
                                  },
                                )
                              : AppTranslations.section(
                                  'video_session',
                                  'lesson_completed_banner',
                                ),
                          style: AppTextStyles.notificationCardBody(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 200,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _SnapshotTile(
                                      overlayAlignment: Alignment.bottomLeft,
                                      overlay: _TeacherOverlayRich(
                                        tutorName: tutorName,
                                        roleLabel: roleLabel,
                                      ),
                                      child: tutor != null
                                          ? TutorAvatarImage(tutor: tutor)
                                          : Image.asset(
                                              'assets/images/avatar_4.png',
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _SnapshotTile(
                                      overlayAlignment: Alignment.bottomCenter,
                                      overlay: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.5,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          userLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style:
                                              AppTextStyles.callSummarySnapshotName(),
                                        ),
                                      ),
                                      child: UserProfileAvatar(
                                        imageUrl: userPhotoUrl,
                                        cover: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _StatTile(
                                    label: AppTranslations.section(
                                      'video_session',
                                      'stat_duration',
                                    ),
                                    value: _formatDurationMmSs(seconds),
                                    valueStyle:
                                        AppTextStyles.callSummaryStatValue(),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _StatTile(
                                    label: AppTranslations.section(
                                      'video_session',
                                      'stat_words',
                                    ),
                                    value: '$words',
                                    valueStyle:
                                        AppTextStyles.callSummaryStatValue(
                                          color: AppColors.brandPrimary,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _StatTile(
                                    label: AppTranslations.section(
                                      'video_session',
                                      'stat_fluency',
                                    ),
                                    value: fluencyLabel,
                                    valueStyle:
                                        AppTextStyles.callSummaryStatValue(
                                          color: AppColors.callPreviewCtaGreen,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: _SessionScoreCard(percent: scorePercent),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: _NextTopicCard(
                          title: nextChosen,
                          subtitle: nextReady,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppPrimaryButton(
                    label: premium.canStartCall
                        ? AppTranslations.section(
                            'video_session',
                            'start_new_conversation',
                          )
                        : AppTranslations.section('paywall', 'subscribe_now'),
                    decorationGradient: AppColors.primaryCtaGradient,
                    foregroundColor: Colors.white,
                    labelStyle: AppTextStyles.callPreviewStartCta(),
                    minimumHeight: 60,
                    onPressed: () => _onPrimaryCta(premium),
                  ),
                  TextButton(
                    onPressed: () {
                      ref
                          .read(callSessionControllerProvider.notifier)
                          .clearActiveSession();
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.bottomNav,
                        (_) => false,
                      );
                    },
                    child: Text(
                      AppTranslations.section('video_session', 'another_time'),
                      style: AppTextStyles.callSummaryNextTitle().copyWith(
                        color: Colors.black.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _CatalogFirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final i = iterator;
    return i.moveNext() ? i.current : null;
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.tutor,
    required this.feedback,
    required this.statusLine,
    required this.badgeText,
  });

  final TutorModel? tutor;
  final String feedback;
  final String statusLine;
  final String badgeText;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: AppColors.brandPrimary,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: tutor != null
                    ? TutorAvatarImage(tutor: tutor!)
                    : Image.asset(
                        'assets/images/avatar_4.png',
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -1.2),
                      ),
              ),
            ),
            Positioned(
              right: 5,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.callPreviewCtaGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(feedback, style: AppTextStyles.callSummaryFeedbackTitle()),
              const SizedBox(height: 4),
              Text(statusLine, style: AppTextStyles.callSummaryStatusLine()),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.brandPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.brandPrimary),
          ),
          child: Text(badgeText, style: AppTextStyles.callSummaryQuotaBadge()),
        ),
      ],
    );
  }
}

class _TeacherOverlayRich extends StatelessWidget {
  const _TeacherOverlayRich({required this.tutorName, required this.roleLabel});

  final String tutorName;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.callSummarySnapshotName(),
          children: [
            TextSpan(
              text: tutorName,
              style: AppTextStyles.callSummarySnapshotName(),
            ),
            TextSpan(
              text: ' • ',
              style: AppTextStyles.callSummarySnapshotSep(),
            ),
            TextSpan(
              text: roleLabel,
              style: AppTextStyles.callSummarySnapshotName(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SnapshotTile extends StatelessWidget {
  const _SnapshotTile({
    required this.child,
    required this.overlay,
    this.overlayAlignment = Alignment.bottomLeft,
  });

  final Widget child;
  final Widget overlay;
  final AlignmentGeometry overlayAlignment;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: Colors.white, child: child),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Align(alignment: overlayAlignment, child: overlay),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.callSummaryStatLabel()),
            Text(value, style: valueStyle),
          ],
        ),
      ),
    );
  }
}

/// Her iki uç da yuvarlak dolgu (LinearProgressIndicator kare uç verir).
class _SessionScoreProgressBar extends StatelessWidget {
  const _SessionScoreProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        const h = 12.0;
        final fill = (w * value).clamp(0.0, w);
        return SizedBox(
          height: h,
          width: w,
          child: Stack(
            children: [
              Container(
                width: w,
                height: h,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(h / 2),
                ),
              ),
              if (fill > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: fill,
                    height: h,
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary,
                      borderRadius: BorderRadius.circular(h / 2),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SessionScoreCard extends StatelessWidget {
  const _SessionScoreCard({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final p = (percent.clamp(0, 100)) / 100.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppTranslations.section('video_session', 'session_score'),
                  style: AppTextStyles.callSummaryScoreTitle(),
                ),
                Text(
                  '%$percent',
                  style: AppTextStyles.callSummaryScorePercent(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SessionScoreProgressBar(value: p),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppTranslations.section('video_session', 'level_beginner'),
                  style: AppTextStyles.callSummaryScoreFootMuted(),
                ),
                Flexible(
                  child: Text(
                    AppTranslations.section('video_session', 'cta_advanced'),
                    textAlign: TextAlign.end,
                    style: AppTextStyles.callSummaryScoreFootAccent(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NextTopicCard extends StatelessWidget {
  const _NextTopicCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/medal_star.svg',
                  width: 32,
                  height: 32,
                  colorFilter: const ColorFilter.mode(
                    AppColors.brandPrimary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.callSummaryQuotaBadge().copyWith(
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.callSummaryNextSubtitle(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
