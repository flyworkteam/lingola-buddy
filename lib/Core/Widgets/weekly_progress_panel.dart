import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Models/learning_progress_model.dart';
import 'package:lingola_buddy/Models/streak_model.dart';
import 'package:lingola_buddy/Riverpod/Providers/streak_provider.dart';

/// Haftalık ilerleme paneli — ana sayfa ve profil ilerleme ekranında ortak.
class WeeklyProgressStatConfig {
  const WeeklyProgressStatConfig({
    required this.icon,
    required this.valueKey,
    required this.labelKey,
    required this.color,
  });

  final String icon;
  final String valueKey;
  final String labelKey;
  final Color color;
}

class WeeklyProgressPanel extends ConsumerStatefulWidget {
  const WeeklyProgressPanel({
    super.key,
    required this.translationChapter,
    this.stats = homeProgressStats,
  });

  final String translationChapter;
  final List<WeeklyProgressStatConfig> stats;

  static const List<WeeklyProgressStatConfig> homeProgressStats = [
    WeeklyProgressStatConfig(
      icon: '📚',
      valueKey: 'word_value',
      labelKey: 'word_label',
      color: AppColors.brandPrimary,
    ),
    WeeklyProgressStatConfig(
      icon: '🎯',
      valueKey: 'accuracy_value',
      labelKey: 'accuracy_label',
      color: AppColors.callPreviewCtaGreen,
    ),
    WeeklyProgressStatConfig(
      icon: '⏰',
      valueKey: 'time_value',
      labelKey: 'time_label',
      color: Colors.black,
    ),
    WeeklyProgressStatConfig(
      icon: '🏆',
      valueKey: 'level_value',
      labelKey: 'level_label',
      color: Color(0xFFFF8D28),
    ),
  ];

  static const List<WeeklyProgressStatConfig> profileProgressStats = [
    WeeklyProgressStatConfig(
      icon: '📚',
      valueKey: 'word_value',
      labelKey: 'word',
      color: AppColors.brandPrimary,
    ),
    WeeklyProgressStatConfig(
      icon: '🎯',
      valueKey: 'accuracy_value',
      labelKey: 'accuracy',
      color: AppColors.callPreviewCtaGreen,
    ),
    WeeklyProgressStatConfig(
      icon: '⏰',
      valueKey: 'time_value',
      labelKey: 'time',
      color: Colors.black,
    ),
    WeeklyProgressStatConfig(
      icon: '🏆',
      valueKey: 'level_value',
      labelKey: 'level',
      color: Color(0xFFFF8D28),
    ),
  ];

  static const dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  static String valueForStat({
    required WeeklyProgressStatConfig stat,
    required StreakDayModel? selectedDay,
    required LearningProgressModel? progress,
    required String translationChapter,
    int totalPracticeMinutes = 0,
  }) {
    if (selectedDay == null && progress == null) {
      return AppTranslations.section(translationChapter, stat.valueKey);
    }
    switch (stat.valueKey) {
      case 'word_value':
        return '${selectedDay?.wordsLearned ?? 0}';
      case 'accuracy_value':
        final acc = selectedDay?.accuracyPercent ?? 0;
        return AppTranslations.interpolate(
          AppTranslations.section(translationChapter, 'accuracy_fmt'),
          {'n': '$acc'},
        );
      case 'time_value':
        final dayMinutes = selectedDay?.minutes ?? 0;
        return AppTranslations.interpolate(
          AppTranslations.section(translationChapter, 'minutes_fmt'),
          {'n': '$dayMinutes'},
        );
      case 'level_value':
        return progress?.cefrLevel ?? 'A1';
      default:
        return AppTranslations.section(translationChapter, stat.valueKey);
    }
  }

  @override
  ConsumerState<WeeklyProgressPanel> createState() =>
      _WeeklyProgressPanelState();
}

class _WeeklyProgressPanelState extends ConsumerState<WeeklyProgressPanel> {
  String? _selectedDayKey;

  StreakDayModel? _dayForKey(List<StreakDayModel> week, String key) {
    for (final d in week) {
      if (d.dayKey == key) return d;
    }
    return week.isNotEmpty ? week.first : null;
  }

  static String? _todayKeyFromWeek(List<StreakDayModel> week) {
    for (final d in week) {
      if (d.isToday) return d.dayKey;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final streakAsync = ref.watch(userStreakProvider);
    final dashboard = streakAsync.when(
      data: (data) => data,
      loading: () => null,
      error: (_, __) => null,
    );
    final week = dashboard?.week ?? [];
    final progress = dashboard?.progress;
    final totalPracticeMinutes = dashboard?.totalPracticeMinutes ?? 0;
    final todayKey = _todayKeyFromWeek(week) ?? progress?.todayDayKey ?? 'mon';
    final selectedKey = _selectedDayKey ?? todayKey;
    final selectedDay = _dayForKey(week, selectedKey);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppTranslations.section(widget.translationChapter, 'this_week'),
              style: AppTextStyles.homeConversationSubtitle().copyWith(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            _WeekStrip(
              translationChapter: widget.translationChapter,
              week: week,
              selectedDayKey: selectedKey,
              onDaySelected: (key) => setState(() => _selectedDayKey = key),
            ),
            const SizedBox(height: 10),
            streakAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, __) => _StatsGrid(
                translationChapter: widget.translationChapter,
                stats: widget.stats,
                selectedDay: null,
                progress: null,
                totalPracticeMinutes: 0,
              ),
              data: (_) => _StatsGrid(
                translationChapter: widget.translationChapter,
                stats: widget.stats,
                selectedDay: selectedDay,
                progress: progress,
                totalPracticeMinutes: totalPracticeMinutes,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.translationChapter,
    required this.stats,
    required this.selectedDay,
    required this.progress,
    required this.totalPracticeMinutes,
  });

  final String translationChapter;
  final List<WeeklyProgressStatConfig> stats;
  final StreakDayModel? selectedDay;
  final LearningProgressModel? progress;
  final int totalPracticeMinutes;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final tileWidth = (constraints.maxWidth - spacing) / 2;
        final tileHeight = (tileWidth * 1.5).clamp(120.0, 140.0).toDouble();

        return GridView.builder(
          padding: EdgeInsets.zero,
          itemCount: stats.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            mainAxisExtent: tileHeight,
          ),
          itemBuilder: (context, index) {
            final stat = stats[index];
            return _ProgressStatTile(
              translationChapter: translationChapter,
              stat: stat,
              valueText: WeeklyProgressPanel.valueForStat(
                stat: stat,
                selectedDay: selectedDay,
                progress: progress,
                translationChapter: translationChapter,
                totalPracticeMinutes: totalPracticeMinutes,
              ),
            );
          },
        );
      },
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.translationChapter,
    required this.week,
    required this.selectedDayKey,
    required this.onDaySelected,
  });

  final String translationChapter;
  final List<StreakDayModel> week;
  final String selectedDayKey;
  final ValueChanged<String> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final byKey = {for (final d in week) d.dayKey: d};

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final key in WeeklyProgressPanel.dayKeys)
              _DayChip(
                label: AppTranslations.section(
                  translationChapter,
                  key,
                ).toUpperCase(),
                selected: key == selectedDayKey,
                practiced: byKey[key]?.practiced ?? false,
                isToday: byKey[key]?.isToday ?? false,
                onTap: () => onDaySelected(key),
              ),
          ],
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.selected,
    required this.practiced,
    required this.isToday,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool practiced;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.brandPrimary
        : practiced
        ? Colors.black87
        : AppColors.secondaryText;

    return Material(
      color: selected
          ? AppColors.brandPrimary.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.homeDayLabel(color: color).copyWith(
                  fontSize: 14,
                  fontWeight: selected || isToday
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressStatTile extends StatelessWidget {
  const _ProgressStatTile({
    required this.translationChapter,
    required this.stat,
    required this.valueText,
  });

  final String translationChapter;
  final WeeklyProgressStatConfig stat;
  final String valueText;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stat.icon, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 4),
            Text(
              valueText,
              style: AppTextStyles.homeProgressValue(color: stat.color),
            ),
            Text(
              AppTranslations.section(
                translationChapter,
                stat.labelKey,
              ).toUpperCase(),
              style: AppTextStyles.homeProgressLabel(),
            ),
          ],
        ),
      ),
    );
  }
}
