import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingola_buddy/Core/Config/app_navigator.dart';
import 'package:lingola_buddy/Core/Config/app_ui_languages.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Routes/app_routes.dart';
import 'package:lingola_buddy/Core/Routes/call_navigation.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Utils/time_of_day_greeting.dart';
import 'package:lingola_buddy/Core/Widgets/character_card.dart';
import 'package:lingola_buddy/Core/Widgets/weekly_progress_panel.dart';
import 'package:lingola_buddy/Models/app_enums.dart';
import 'package:lingola_buddy/Models/streak_model.dart';
import 'package:lingola_buddy/Riverpod/Controllers/BottomNavController/bottom_nav_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/CallSessionController/call_session_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/UserProfileController/user_profile_controller.dart';
import 'package:lingola_buddy/Riverpod/Providers/curriculum_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/daily_conversation_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/streak_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/tutors_catalog_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/user_provider.dart';

Future<void> _openLessonCall(
  BuildContext context,
  WidgetRef ref, {
  required String lessonId,
  String? tutorId,
}) async {
  final resolvedTutor =
      tutorId ??
      ref.read(callSessionControllerProvider).activeTutorId ??
      'annie';
  ref.read(callSessionControllerProvider.notifier).bindTutor(
        resolvedTutor,
        kind: CallKind.video,
        lessonId: lessonId,
      );
  await CallNavigation.pushSessionVideo(
    context,
    ref,
    tutorId: resolvedTutor,
  );
}

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(96),
        child: _HomeAppBar(
          onLanguagePressed: () => Navigator.of(context).pushNamed('/language'),
          onNotificationsPressed: () {
            appNavigatorKey.currentState?.pushNamed(AppRoutes.notifications);
          },
        ),
      ),
      body: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          const RepaintBoundary(child: _StreakCard()),
          const SizedBox(height: 8),
          const RepaintBoundary(child: _ResumeLessonCard()),
          const SizedBox(height: 8),
          _SectionHeader(
            title: AppTranslations.section('home', 'character_label'),
            actionLabel: AppTranslations.section('home', 'view_all'),
            onAction: () =>
                ref.read(bottomNavControllerProvider.notifier).setIndex(1),
          ),
          const SizedBox(height: 8),
          const RepaintBoundary(child: _HomeFeaturedTutorsRow()),
          const SizedBox(height: 8),
          _SectionHeader(
            title: AppTranslations.section('home', 'daily_conversation'),
            actionLabel: AppTranslations.section('home', 'view_all'),
            onAction: () =>
                Navigator.of(context).pushNamed('/daily-conversations'),
          ),
          const SizedBox(height: 8),
          const RepaintBoundary(child: _DailyConversationCard()),
          const SizedBox(height: 10),
          Text(
            AppTranslations.section('home', 'progress_label'),
            style: AppTextStyles.homeSectionTitle(),
          ),
          const SizedBox(height: 10),
          const RepaintBoundary(
            child: WeeklyProgressPanel(translationChapter: 'home'),
          ),
        ],
      ),
    );
  }
}

/// Ana sayfada yatay kaydırma yok — ilk 2 eğitmen yan yana.
class _HomeFeaturedTutorsRow extends ConsumerWidget {
  const _HomeFeaturedTutorsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tutors = ref.watch(tutorsCatalogProvider);
    if (tutors.isEmpty) return const SizedBox.shrink();

    final featured = tutors.length > 2 ? tutors.sublist(0, 2) : tutors;
    final lessonId = ref.watch(
      userCurriculumProvider.select((c) => c.value?.currentLesson?.id),
    );

    return SizedBox(
      height: CharacterCard.designHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < featured.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: CharacterCard(
                tutor: featured[i],
                height: CharacterCard.designHeight,
                displayName: featured[i].localizedDisplayName,
                buttonLabel: AppTranslations.section('tudor', 'start_talking'),
                onPressed: () {
                  if (lessonId != null && lessonId.isNotEmpty) {
                    _openLessonCall(
                      context,
                      ref,
                      lessonId: lessonId,
                      tutorId: featured[i].id,
                    );
                    return;
                  }
                  Navigator.pushNamed(
                    context,
                    '/tutor',
                    arguments: featured[i].id,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HomeAppBar extends ConsumerWidget {
  const _HomeAppBar({
    required this.onLanguagePressed,
    required this.onNotificationsPressed,
  });

  final VoidCallback onLanguagePressed;
  final VoidCallback onNotificationsPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = ref.watch(
      currentUserProvider.select((u) => u?.displayName),
    );
    final uiLanguageCode = ref.watch(
      userProfileControllerProvider.select((s) => s.uiLanguageCode),
    );
    final trimmedName = displayName?.trim();
    final welcomeName = trimmedName == null || trimmedName.isEmpty
        ? 'Lingola'
        : trimmedName;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TimeOfDayGreeting.line(),
                    style: AppTextStyles.homeGreeting(),
                  ),
                  Text(
                    '${AppTranslations.section('home', 'welcome')} $welcomeName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.homeWelcomeTitle(),
                  ),
                ],
              ),
            ),
            _RoundSvgButton(
              assetPath: AppUiLanguages.flagAssetFor(uiLanguageCode),
              onPressed: onLanguagePressed,
              backgroundColor: Colors.black.withValues(alpha: 0.1),
            ),
            const SizedBox(width: 8),
            _RoundSvgButton(
              assetPath: 'assets/icons/notification.svg',
              onPressed: onNotificationsPressed,
              backgroundColor: Colors.black,
              iconSize: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundSvgButton extends StatelessWidget {
  const _RoundSvgButton({
    required this.assetPath,
    required this.onPressed,
    required this.backgroundColor,
    this.iconSize = 27,
  });

  final String assetPath;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: Material(
        color: backgroundColor,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Center(
            child: SvgPicture.asset(
              assetPath,
              width: iconSize,
              height: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}

class _StreakCard extends ConsumerWidget {
  const _StreakCard();

  static DateTime? _parseYmd(String? value) {
    if (value == null || value.length < 10) return null;
    final parts = value.substring(0, 10).split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  /// Mevcut seride bu takvim gününün kaçıncı günü (1 = ilk gün).
  static int _streakDayIndex({
    required String dateYmd,
    required String? lastPracticeDate,
    required int streakDays,
  }) {
    if (streakDays < 1) return 1;
    final last = _parseYmd(lastPracticeDate);
    final day = _parseYmd(dateYmd);
    if (last == null || day == null) return 1;
    final streakStart = last.subtract(Duration(days: streakDays - 1));
    return day.difference(streakStart).inDays + 1;
  }

  static String _iconFor({
    required bool practiced,
    required int streakDayIndex,
  }) {
    if (!practiced) return 'assets/icons/empty_day.svg';
    if (streakDayIndex < 3) return 'assets/icons/tick.svg';
    return 'assets/icons/fire_tick.svg';
  }

  static _DayState _dayStateFor(
    StreakDayModel d, {
    required String? lastPracticeDate,
    required int streakDays,
  }) {
    final streakDayIndex = d.practiced
        ? _streakDayIndex(
            dateYmd: d.date,
            lastPracticeDate: lastPracticeDate,
            streakDays: streakDays,
          )
        : 0;
    return _DayState(
      labelKey: d.dayKey,
      iconPath: _iconFor(
        practiced: d.practiced,
        streakDayIndex: streakDayIndex,
      ),
      active: d.practiced && streakDayIndex >= 3,
      dimmed: !d.practiced,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(userStreakProvider);
    final dashboard = streakAsync.value;
    final week = dashboard?.week ?? [];
    final streakDays = dashboard?.streakDays ?? 0;
    final lastPracticeDate = dashboard?.lastPracticeDate;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslations.section('home', 'past_7_days'),
              style: AppTextStyles.homeStreakTitle(),
            ),
            const SizedBox(height: 4),
            Text(
              AppTranslations.section('home', 'streak_desc'),
              style: AppTextStyles.homeStreakDescription(),
            ),
            const SizedBox(height: 10),
            streakAsync.when(
              loading: () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  7,
                  (_) => const SizedBox(width: 32, height: 48),
                ),
              ),
              error: (_, __) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _fallbackWeek()
                    .map((d) => _StreakDay(day: d))
                    .toList(),
              ),
              data: (_) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (week.isEmpty)
                    for (final d in _fallbackWeek()) _StreakDay(day: d)
                  else
                    for (final d in week)
                      _StreakDay(
                        day: _dayStateFor(
                          d,
                          lastPracticeDate: lastPracticeDate,
                          streakDays: streakDays,
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

  static List<_DayState> _fallbackWeek() {
    const keys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    return keys
        .map(
          (k) => _DayState(
            labelKey: k,
            iconPath: 'assets/icons/empty_day.svg',
            dimmed: true,
          ),
        )
        .toList();
  }
}

class _StreakDay extends StatelessWidget {
  const _StreakDay({required this.day});

  final _DayState day;

  @override
  Widget build(BuildContext context) {
    final labelColor = day.active
        ? const Color(0xFFFF8D28)
        : Colors.white.withValues(alpha: day.dimmed ? 0.2 : 1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(day.iconPath, width: 32, height: 32),
        const SizedBox(height: 8),
        Text(
          AppTranslations.section('home', day.labelKey).toUpperCase(),
          style: AppTextStyles.homeDayLabel(color: labelColor),
        ),
      ],
    );
  }
}

class _ResumeLessonCard extends ConsumerWidget {
  const _ResumeLessonCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final curriculum = ref.watch(userCurriculumProvider).value;
    final lesson = curriculum?.currentLesson;
    final lessonIndex = lesson != null && curriculum != null
        ? curriculum.lessons.indexWhere((l) => l.id == lesson.id) + 1
        : 0;
    final progressLabel = curriculum != null && lessonIndex > 0
        ? AppTranslations.interpolate(
            AppTranslations.section('home', 'lesson_progress_fmt'),
            {'current': '$lessonIndex', 'total': '${curriculum.totalCount}'},
          )
        : AppTranslations.section('home', 'lesson_progress');
    final title = lesson != null
        ? '${lesson.scenarioEmoji} ${lesson.localizedTitle}'
        : '☕ ${AppTranslations.section('home', 'coffee_shop_title')}';
    final subtitle = lesson != null
        ? AppTranslations.interpolate(
            AppTranslations.section('home', 'level_subtitle_fmt'),
            {
              'level': curriculum!.cefrLevel,
              'subtitle': lesson.localizedSubtitle,
            },
          )
        : AppTranslations.section('home', 'level_daily_conversation');
    final progressValue = curriculum?.progressFraction ?? 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _PurpleDot(),
                        const SizedBox(width: 4),
                        Text(
                          AppTranslations.section('home', 'pick_up'),
                          style: AppTextStyles.homeResumeBadge(),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Text(progressLabel, style: AppTextStyles.homeLessonProgress()),
              ],
            ),
            const SizedBox(height: 20),
            Text(title, style: AppTextStyles.homeScenarioTitle()),
            const SizedBox(height: 4),
            Text(subtitle, style: AppTextStyles.homeScenarioSubtitle()),

            const SizedBox(height: 16),
            _GradientProgressBar(value: progressValue),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                onPressed: lesson == null
                    ? null
                    : () => _openLessonCall(context, ref, lessonId: lesson.id),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppTranslations.section('home', 'continue'),
                      style: AppTextStyles.signUpGuestLink(),
                    ),
                    const SizedBox(width: 18),
                    SvgPicture.asset(
                      'assets/icons/right_arrow.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        Colors.black,
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurpleDot extends StatelessWidget {
  const _PurpleDot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 8,
      height: 8,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.brandPrimary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _GradientProgressBar extends StatelessWidget {
  const _GradientProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final progress = value.clamp(0.0, 1.0);

    return SizedBox(
      height: 14,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFE5E5E5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: progress,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.primaryCtaGradient,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTextStyles.homeSectionTitle())),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
          ),
          child: Text(actionLabel, style: AppTextStyles.homeSectionAction()),
        ),
      ],
    );
  }
}

class _DayState {
  const _DayState({
    required this.labelKey,
    required this.iconPath,
    this.active = false,
    this.dimmed = false,
  });

  final String labelKey;
  final String iconPath;
  final bool active;
  final bool dimmed;
}

class _DailyConversationCard extends ConsumerWidget {
  const _DailyConversationCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Çeviri yenilendiğinde kartı yeniden çiz.
    ref.watch(
      userProfileControllerProvider.select((s) => s.uiLanguageCode),
    );
    final dcCurriculum = ref.watch(userDailyConversationProvider).value;
    final topic = dcCurriculum?.currentConversation;
    final level = dcCurriculum?.cefrLevel ?? 'A1';
    final topicTitle =
        topic?.localizedTitle ??
        AppTranslations.section('home', 'today_topic');
    final scenarioLine = topic != null
        ? AppTranslations.interpolate(
            AppTranslations.section('home', 'level_subtitle_fmt'),
            {
              'level': level,
              'subtitle': topic.localizedSubtitle,
            },
          )
        : AppTranslations.section('home', 'making_plans_with_friends');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: SvgPicture.asset(
                          'assets/icons/chat.svg',
                          width: 50,
                          height: 50,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topicTitle,
                            style: AppTextStyles.homeConversationTitle(),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${AppTranslations.section('home', 'new')} • ${AppTranslations.section('home', 'suitable_for_your_level')}',
                            style: AppTextStyles.homeConversationSubtitle(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Text(
                      '🗓️',
                      style: AppTextStyles.homeConversationInfo(
                        color: AppColors.brandPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        scenarioLine,
                        style: AppTextStyles.homeConversationInfo(
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ),
                    SvgPicture.asset(
                      'assets/icons/clock.svg',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppTranslations.section('home', 'duration_estimate'),
                      style: AppTextStyles.homeConversationInfo(
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: topic == null
                      ? () =>
                          Navigator.of(context).pushNamed('/daily-conversations')
                      : () => _openLessonCall(
                            context,
                            ref,
                            lessonId: topic.id,
                          ),
                  child: Text(
                    AppTranslations.section('home', 'start_conversation'),
                    style: AppTextStyles.homeConversationInfo(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
