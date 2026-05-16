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
import 'package:lingola_buddy/Riverpod/Controllers/OnboardingPrefsController/onboarding_prefs_controller.dart';

class _LanguageRow {
  const _LanguageRow({
    required this.code,
    required this.translationKey,
    required this.flagAsset,
  });

  final String code;
  final String translationKey;
  final String flagAsset;
}

/// Dil seçimi (1 / 3) — üst sihirbaz, bayraklı satırlar, «Daha fazlasını gör +», gradient CTA.
class OnboardingLanguageView extends ConsumerStatefulWidget {
  const OnboardingLanguageView({super.key});

  @override
  ConsumerState<OnboardingLanguageView> createState() =>
      _OnboardingLanguageViewState();
}

class _OnboardingLanguageViewState extends ConsumerState<OnboardingLanguageView> {
  static const int wizardStep = 1;
  static const int wizardTotal = 3;

  /// İlk ekranda gösterilen dil sayısı; kalanı «Daha fazlasını gör +» ile açılır.
  static const int _initialLanguageCount = 5;

  static const List<_LanguageRow> _allRows = [
    _LanguageRow(
      code: 'en',
      translationKey: 'option1',
      flagAsset: 'assets/icons/english.svg',
    ),
    _LanguageRow(
      code: 'de',
      translationKey: 'option2',
      flagAsset: 'assets/icons/german.svg',
    ),
    _LanguageRow(
      code: 'it',
      translationKey: 'option3',
      flagAsset: 'assets/icons/italian.svg',
    ),
    _LanguageRow(
      code: 'fr',
      translationKey: 'option4',
      flagAsset: 'assets/icons/french.svg',
    ),
    _LanguageRow(
      code: 'tr',
      translationKey: 'option5',
      flagAsset: 'assets/icons/turkish.svg',
    ),
    _LanguageRow(
      code: 'ja',
      translationKey: 'option6',
      flagAsset: 'assets/icons/japanese.svg',
    ),
    _LanguageRow(
      code: 'es',
      translationKey: 'option7',
      flagAsset: 'assets/icons/spanish.svg',
    ),
    _LanguageRow(
      code: 'ru',
      translationKey: 'option8',
      flagAsset: 'assets/icons/russian.svg',
    ),
    _LanguageRow(
      code: 'ko',
      translationKey: 'option9',
      flagAsset: 'assets/icons/korean.svg',
    ),
    _LanguageRow(
      code: 'hi',
      translationKey: 'option10',
      flagAsset: 'assets/icons/hindi.svg',
    ),
    _LanguageRow(
      code: 'pt',
      translationKey: 'option11',
      flagAsset: 'assets/icons/portuguese.svg',
    ),
    _LanguageRow(
      code: 'zh',
      translationKey: 'option12',
      flagAsset: 'assets/icons/chinese.svg',
    ),
  ];

  bool _seeMoreExpanded = false;

  static void _goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.pushReplacementNamed(context, AppRoutes.onboardingCarousel);
  }

  static Widget _ctaArrowIcon() {
    return SvgPicture.asset(
      'assets/icons/right_arrow.svg',
      width: 22,
      height: 22,
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(onboardingPrefsControllerProvider).learnLanguageCode;
    final showSeeMoreRow = !_seeMoreExpanded;
    final languageCount =
        _seeMoreExpanded ? _allRows.length : _initialLanguageCount;
    final listItemCount = languageCount + (showSeeMoreRow ? 1 : 0);

    return OnboardingWizardPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnboardingWizardTopBar(
            currentStep: wizardStep,
            totalSteps: wizardTotal,
            onBack: () => _goBack(context),
          ),
          const SizedBox(height: 24),
          Text(
            AppTranslations.section('onboarding', 'question1'),
            style: AppTextStyles.onboardingWizardTitle(),
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 8),
          Text(
            AppTranslations.section('onboarding', 'q1_desc'),
            style: AppTextStyles.onboardingWizardSubtitle(),
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: listItemCount,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (showSeeMoreRow && index == languageCount) {
                  return Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AppColors.brandPrimary,
                      ),
                      onPressed: () => setState(() => _seeMoreExpanded = true),
                      child: Text(
                        '${AppTranslations.section('onboarding', 'see_more')} +',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.onboardingLanguageRow(color: Colors.black)
                      ),
                    ),
                  );
                }
                final row = _allRows[index];
                final label = AppTranslations.section(
                  'onboarding',
                  row.translationKey,
                );
                return OnboardingOptionTile(
                  leading: ClipOval(
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: SvgPicture.asset(
                        row.flagAsset,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                  label: label,
                  selected: selected == row.code,
                  onTap: () {
                    ref
                        .read(onboardingPrefsControllerProvider.notifier)
                        .selectLearnLanguage(row.code);
                    ref
                        .read(onboardingPrefsControllerProvider.notifier)
                        .selectNativeLanguage('tr');
                  },
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
                : () => Navigator.pushNamed(context, AppRoutes.onboardingLevel),
          ),
        ],
      ),
    );
  }
}
