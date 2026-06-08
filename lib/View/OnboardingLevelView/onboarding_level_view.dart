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
    required this.translationKey,
    required this.iconAsset,
  });

  final CefrLevel level;
  final String translationKey;
  final String iconAsset;
}

/// Dil yeterlilik seviyesi (2 / 3).
class OnboardingLevelView extends ConsumerWidget {
  const OnboardingLevelView({super.key});

  static const int wizardStep = 2;
  static const int wizardTotal = 3;

  static const List<_LevelRow> _rows = [
    _LevelRow(
      level: CefrLevel.a1,
      translationKey: 'option2_1',
      iconAsset: 'assets/icons/hand_holding_seeding.svg',
    ),
    _LevelRow(
      level: CefrLevel.a2,
      translationKey: 'option2_2',
      iconAsset: 'assets/icons/speak.svg',
    ),
    _LevelRow(
      level: CefrLevel.b1,
      translationKey: 'option2_3',
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
            AppTranslations.section('onboarding', 'q2_desc'),
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
                final label = AppTranslations.section(
                  'onboarding',
                  row.translationKey,
                );
                return OnboardingOptionTile(
                  leading: SvgPicture.asset(
                    row.iconAsset,
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                    colorFilter: ColorFilter.mode(
                      selected == row.level
                          ? AppColors.brandPrimary
                          : AppColors.secondaryText,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: label,
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
            label: AppTranslations.section('common', 'continue'),
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
