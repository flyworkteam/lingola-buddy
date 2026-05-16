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
import 'package:lingola_buddy/Models/app_enums.dart';
import 'package:lingola_buddy/Riverpod/Controllers/OnboardingPrefsController/onboarding_prefs_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/SessionController/session_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/UserProfileController/user_profile_controller.dart';

class _GoalRow {
  const _GoalRow({
    required this.bucket,
    required this.translationKey,
    required this.iconAsset,
  });

  final DailyGoalBucket bucket;
  final String translationKey;
  final String iconAsset;
}

/// Günlük pratik süresi (3 / 3) — Figma ile aynı sihirbaz iskelesi ve ikonlu seçenekler.
class OnboardingGoalView extends ConsumerWidget {
  const OnboardingGoalView({super.key});

  static const int wizardStep = 3;
  static const int wizardTotal = 3;

  static const List<_GoalRow> _rows = [
    _GoalRow(
      bucket: DailyGoalBucket.short,
      translationKey: 'option3_1',
      iconAsset: 'assets/icons/lightning.svg',
    ),
    _GoalRow(
      bucket: DailyGoalBucket.medium,
      translationKey: 'option3_2',
      iconAsset: 'assets/icons/running.svg',
    ),
    _GoalRow(
      bucket: DailyGoalBucket.long,
      translationKey: 'option3_3',
      iconAsset: 'assets/icons/fire.svg',
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
    Navigator.pushReplacementNamed(context, AppRoutes.onboardingLevel);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(onboardingPrefsControllerProvider);
    final selected = prefs.dailyGoal;
    final canSubmit =
        selected != null &&
        prefs.learnLanguageCode != null &&
        prefs.proficiency != null;

    return OnboardingWizardPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnboardingWizardTopBar(
            currentStep: OnboardingGoalView.wizardStep,
            totalSteps: OnboardingGoalView.wizardTotal,
            onBack: () => OnboardingGoalView._goBack(context),
          ),
          const SizedBox(height: 24),
          Text(
            AppTranslations.section('onboarding', 'question3'),
            style: AppTextStyles.onboardingWizardTitle(),
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 8),
          Text(
            AppTranslations.section('onboarding', 'q3_desc'),
            style: AppTextStyles.onboardingWizardSubtitle(),
            textAlign: TextAlign.start,
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
                    colorFilter: ColorFilter.mode( selected == row.bucket ? AppColors.brandPrimary : AppColors.secondaryText, BlendMode.srcIn),
                  ),
                  label: label,
                  selected: selected == row.bucket,
                  onTap: () => ref
                      .read(onboardingPrefsControllerProvider.notifier)
                      .selectDailyGoal(row.bucket),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          AppPrimaryButton(
            label: AppTranslations.section('onboarding', 'button3_continue'),
            decorationGradient: AppColors.primaryCtaGradient,
            foregroundColor: Colors.white,
            labelStyle: AppTextStyles.onboardingCta(),
            minimumHeight: 60,
            icon: _ctaArrowIcon(),
            onPressed: !canSubmit
                ? null
                : () {
                    ref
                        .read(userProfileControllerProvider.notifier)
                        .applyOnboardingPrefs(
                          learnLanguageCode: prefs.learnLanguageCode ?? 'en',
                          nativeLanguageCode: prefs.nativeLanguageCode ?? 'tr',
                          proficiency:
                              prefs.proficiency ?? ProficiencyLevel.simple,
                          dailyGoal: selected,
                        );
                    ref
                        .read(sessionControllerProvider.notifier)
                        .markPreferenceWizardCompleted();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.generatingPlan,
                      (route) => false,
                    );
                  },
          ),
        ],
      ),
    );
  }
}
