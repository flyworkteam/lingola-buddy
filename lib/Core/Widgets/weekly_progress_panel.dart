import 'package:flutter/material.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';

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

class WeeklyProgressPanel extends StatelessWidget {
  const WeeklyProgressPanel({
    super.key,
    required this.translationChapter,
    this.selectedDayKey = 'thu',
    this.stats = homeProgressStats,
  });

  final String translationChapter;
  final String selectedDayKey;
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

  static const _dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppTranslations.section(translationChapter, 'this_week'),
              style: AppTextStyles.homeConversationSubtitle().copyWith(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            _WeekStrip(
              translationChapter: translationChapter,
              selectedDayKey: selectedDayKey,
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 10.0;
                final tileWidth = (constraints.maxWidth - spacing) / 2;
                final tileHeight = (tileWidth * 1.5)
                    .clamp(120.0, 140.0)
                    .toDouble();

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
                    return _ProgressStatTile(
                      translationChapter: translationChapter,
                      stat: stats[index],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.translationChapter,
    required this.selectedDayKey,
  });

  final String translationChapter;
  final String selectedDayKey;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final key in WeeklyProgressPanel._dayKeys)
              Text(
                AppTranslations.section(translationChapter, key).toUpperCase(),
                style: AppTextStyles.homeDayLabel(
                  color: key == selectedDayKey
                      ? AppColors.brandPrimary
                      : AppColors.secondaryText,
                ).copyWith(fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProgressStatTile extends StatelessWidget {
  const _ProgressStatTile({
    required this.translationChapter,
    required this.stat,
  });

  final String translationChapter;
  final WeeklyProgressStatConfig stat;

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
              AppTranslations.section(translationChapter, stat.valueKey),
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
