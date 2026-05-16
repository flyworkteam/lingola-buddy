import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingola_buddy/Core/Config/app_navigator.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Routes/app_routes.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Widgets/character_card.dart';
import 'package:lingola_buddy/Core/Widgets/weekly_progress_panel.dart';
import 'package:lingola_buddy/Riverpod/Providers/tutors_catalog_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/user_provider.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final tutors = ref.watch(tutorsCatalogProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(96),
        child: _HomeAppBar(
          displayName: user?.displayName,
          onLanguagePressed: () {},
          onNotificationsPressed: () {
            appNavigatorKey.currentState?.pushNamed(AppRoutes.notifications);
          },
        ),
      ),
      body: ListView(
        physics: ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          const _StreakCard(),
          const SizedBox(height: 8),
          const _ResumeLessonCard(),
          const SizedBox(height: 8),
          _SectionHeader(
            title: AppTranslations.section('home', 'character_label'),
            actionLabel: AppTranslations.section('home', 'view_all'),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: CharacterCard.designHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: tutors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final tutor = tutors[index];
                return CharacterCard(
                  tutor: tutor,
                  displayName: AppTranslations.section('tudor', tutor.id),
                  buttonLabel: AppTranslations.section('tudor', 'start_talking'),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/tutor',
                    arguments: tutor.id,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          _SectionHeader(
            title: AppTranslations.section('home', 'daily_conversation'),
            actionLabel: AppTranslations.section('home', 'view_all'),
          ),
          const SizedBox(height: 8),
          const _DailyConversationCard(),
          const SizedBox(height: 10),
          Text(
            AppTranslations.section('home', 'progress_label'),
            style: AppTextStyles.homeSectionTitle(),
          ),
          const SizedBox(height: 10),
          const WeeklyProgressPanel(translationChapter: 'home'),
        ],
      ),
    );
  }
}

class _HomeAppBar extends StatelessWidget {
  const _HomeAppBar({
    required this.displayName,
    required this.onLanguagePressed,
    required this.onNotificationsPressed,
  });

  final String? displayName;
  final VoidCallback onLanguagePressed;
  final VoidCallback onNotificationsPressed;

  @override
  Widget build(BuildContext context) {
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
                    '👋 ${AppTranslations.section('home', 'greeting_morning')}',
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
              assetPath: 'assets/icons/english.svg',
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

class _StreakCard extends StatelessWidget {
  const _StreakCard();

  static const _days = [
    _DayState(labelKey: 'mon', iconPath: 'assets/icons/tick.svg'),
    _DayState(labelKey: 'tue', iconPath: 'assets/icons/tick.svg'),
    _DayState(labelKey: 'wed', iconPath: 'assets/icons/tick.svg'),
    _DayState(
      labelKey: 'thu',
      iconPath: 'assets/icons/fire_tick.svg',
      active: true,
    ),
    _DayState(labelKey: 'fri', iconPath: 'assets/icons/empty_day.svg'),
    _DayState(labelKey: 'sat', iconPath: 'assets/icons/empty_day.svg'),
    _DayState(labelKey: 'sun', iconPath: 'assets/icons/empty_day.svg'),
  ];

  @override
  Widget build(BuildContext context) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [for (final day in _days) _StreakDay(day: day)],
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakDay extends StatelessWidget {
  const _StreakDay({required this.day});

  final _DayState day;

  @override
  Widget build(BuildContext context) {
    final labelColor = day.active
        ? const Color(0xFFFF8D28)
        : Colors.white.withValues(
            alpha: day.iconPath.contains('empty') ? 0.2 : 1,
          );

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

class _ResumeLessonCard extends StatelessWidget {
  const _ResumeLessonCard();

  @override
  Widget build(BuildContext context) {
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
                Text(
                  AppTranslations.section('home', 'lesson_progress'),
                  style: AppTextStyles.homeLessonProgress(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '☕ ${AppTranslations.section('home', 'coffee_shop_title')}',
              style: AppTextStyles.homeScenarioTitle(),
            ),
            const SizedBox(height: 4),
            Text(
              AppTranslations.section('home', 'level_daily_conversation'),
              style: AppTextStyles.homeScenarioSubtitle(),
            ),
            const SizedBox(height: 16),
            const _GradientProgressBar(value: 0.52),
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
                onPressed: () {},
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
  const _SectionHeader({required this.title, required this.actionLabel});

  final String title;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTextStyles.homeSectionTitle())),
        TextButton(
          onPressed: () {},
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
  });

  final String labelKey;
  final String iconPath;
  final bool active;
}

class _DailyConversationCard extends StatelessWidget {
  const _DailyConversationCard();

  @override
  Widget build(BuildContext context) {
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
                            AppTranslations.section('home', 'today_topic'),
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
                        AppTranslations.section(
                          'home',
                          'making_plans_with_friends',
                        ),
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
                  onPressed: () {},
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
