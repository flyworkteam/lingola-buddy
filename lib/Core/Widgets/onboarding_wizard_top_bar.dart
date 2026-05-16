import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Widgets/onboarding_wizard_progress_bar.dart';

String _wizardStepLabel(int current, int total) {
  return AppTranslations.section(
    'onboarding',
    'wizard_step_label',
  ).replaceAll('{current}', '$current').replaceAll('{total}', '$total');
}

class OnboardingWizardTopBar extends StatelessWidget {
  const OnboardingWizardTopBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
  }) : assert(currentStep >= 1),
       assert(totalSteps >= currentStep);

  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final progress = currentStep / totalSteps;
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          icon: SvgPicture.asset(
            'assets/icons/left_arrow.svg',
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 1),
              BlendMode.srcIn,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OnboardingWizardProgressBar(fraction: progress),
          ),
        ),
        Text(
          _wizardStepLabel(currentStep, totalSteps),
          style: AppTextStyles.onboardingWizardStepLabel(),
        ),
      ],
    );
  }
}
