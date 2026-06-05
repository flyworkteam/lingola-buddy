import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Routes/app_routes.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Widgets/app_primary_button.dart';
import 'package:lingola_buddy/Core/Widgets/onboarding_option_tile.dart';
import 'package:lingola_buddy/Core/Widgets/onboarding_wizard_page_shell.dart';
import 'package:lingola_buddy/Core/Widgets/onboarding_wizard_top_bar.dart';
import 'package:lingola_buddy/Models/lesson_model.dart';
import 'package:lingola_buddy/Riverpod/Controllers/OnboardingPrefsController/onboarding_prefs_controller.dart';

class _LevelRow {
  const _LevelRow({
    required this.level,
    required this.label,
    required this.subtitle,
    required this.iconAsset,
  });

  final CefrLevel level;
  final String label;
  final String subtitle;
  final String iconAsset;
}

/// CEFR İngilizce seviyesi (A1–C2).
class OnboardingLevelView extends ConsumerWidget {
  const OnboardingLevelView({super.key});

  static const int wizardStep = 2;
  static const int wizardTotal = 3;

  static const List<_LevelRow> _rows = [
    _LevelRow(
      level: CefrLevel.a1,
      label: 'A1',
      subtitle: 'Beginner — first words & phrases',
      iconAsset: 'assets/icons/hand_holding_seeding.svg',
    ),
    _LevelRow(
      level: CefrLevel.a2,
      label: 'A2',
      subtitle: 'Elementary — simple everyday talk',
      iconAsset: 'assets/icons/speak.svg',
    ),
    _LevelRow(
      level: CefrLevel.b1,
      label: 'B1',
      subtitle: 'Intermediate — opinions & travel',
      iconAsset: 'assets/icons/running.svg',
    ),
    _LevelRow(
      level: CefrLevel.b2,
      label: 'B2',
      subtitle: 'Upper intermediate — debates & work',
      iconAsset: 'assets/icons/lightning.svg',
    ),
    _LevelRow(
      level: CefrLevel.c1,
      label: 'C1',
      subtitle: 'Advanced — nuance & fluency',
      iconAsset: 'assets/icons/fire.svg',
    ),
    _LevelRow(
      level: CefrLevel.c2,
      label: 'C2',
      subtitle: 'Mastery — near-native control',
      iconAsset: 'assets/icons/rocket.svg',
    ),
  ];

  static Widget _ctaArrowIcon() {
    return SvgPicture.asset(
      'assets/icons/right_arrow.svg',
      width: 22,
      height: 22,
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
    );
  }

  static void _goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.pushReplacementNamed(context, AppRoutes.onboardingLanguage);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingPrefsControllerProvider).cefrLevel;

    return OnboardingWizardPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnboardingWizardTopBar(
            currentStep: OnboardingLevelView.wizardStep,
            totalSteps: OnboardingLevelView.wizardTotal,
            onBack: () => OnboardingLevelView._goBack(context),
          ),
          const SizedBox(height: 24),
          Text(
            AppTranslations.section('onboarding', 'question2'),
            style: AppTextStyles.onboardingWizardTitle(),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your English level (CEFR). We\'ll build 8–12 lessons for your band.',
            style: AppTextStyles.onboardingWizardSubtitle(),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final row = _rows[index];
                return OnboardingOptionTile(
                  leading: SvgPicture.asset(
                    row.iconAsset,
                    width: 28,
                    height: 28,
                    colorFilter: ColorFilter.mode(
                      selected == row.level
                          ? AppColors.brandPrimary
                          : AppColors.secondaryText,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: '${row.label} — ${row.subtitle}',
                  selected: selected == row.level,
                  onTap: () => ref
                      .read(onboardingPrefsControllerProvider.notifier)
                      .selectCefrLevel(row.level),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          AppPrimaryButton(
            label: AppTranslations.section('onboarding', 'button2_continue'),
            decorationGradient: AppColors.primaryCtaGradient,
            foregroundColor: Colors.white,
            labelStyle: AppTextStyles.onboardingCta(),
            minimumHeight: 60,
            icon: _ctaArrowIcon(),
            onPressed: selected == null
                ? null
                : () => Navigator.pushNamed(context, AppRoutes.onboardingGoal),
          ),
        ],
      ),
    );
  }
}
