import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Routes/app_routes.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Widgets/app_primary_button.dart';
import 'package:lingola_buddy/Core/Widgets/brand_aura_backdrop.dart';
import 'package:lingola_buddy/Riverpod/Controllers/SessionController/session_controller.dart';

/// Abonelik / paywall — Figma tipografi ve [premuim_man.svg] illüstrasyonu.
class PaywallView extends ConsumerStatefulWidget {
  const PaywallView({super.key});

  @override
  ConsumerState<PaywallView> createState() => _PaywallViewState();
}

class _PaywallViewState extends ConsumerState<PaywallView> {
  static const String _heroAsset = 'assets/icons/premuim_man.svg';

  bool _freeTrialActive = true;

  Future<void> _openShell(BuildContext context) async {
    ref.read(sessionControllerProvider.notifier).markAuthenticated(true);
    if (!context.mounted) return;
    await Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.bottomNav,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BrandAuraBackdrop(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: SvgPicture.asset(
                            _heroAsset,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            AppTranslations.section('paywall', 'headline'),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.paywallHeadline(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            AppTranslations.section('paywall', 'subheadline'),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.paywallSubheadline(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _PaywallFeatureRow(
                          text: AppTranslations.section(
                            'paywall',
                            'feature_unlimited',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _PaywallFeatureRow(
                          text: AppTranslations.section(
                            'paywall',
                            'feature_scenarios',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _PaywallFeatureRow(
                          text: AppTranslations.section(
                            'paywall',
                            'feature_feedback',
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary.withValues(
                              alpha: 0.20,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.brandPrimary),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.section(
                                  'paywall',
                                  'three_days_free',
                                ),
                                textAlign: TextAlign.center,
                                style: AppTextStyles.paywallPlanHighlight(),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppTranslations.section(
                                  'paywall',
                                  'per_month_price',
                                ),
                                textAlign: TextAlign.center,
                                style: AppTextStyles.paywallPlanPriceLine(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                AppTranslations.section(
                                  'paywall',
                                  'free_trial_active',
                                ),
                                style: AppTextStyles.paywallRowEmphasis(
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Switch(
                              value: _freeTrialActive,
                              onChanged: (v) =>
                                  setState(() => _freeTrialActive = v),
                              activeThumbColor: Colors.white,
                              activeTrackColor: AppColors.brandPrimary,
                              inactiveThumbColor: Colors.grey,
                              inactiveTrackColor: Colors.grey.shade300,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _PaymentSummaryCard(freeTrialActive: _freeTrialActive),
                        const SizedBox(height: 28),
                        AppPrimaryButton(
                          label: AppTranslations.section(
                            'paywall',
                            'subscribe_now',
                          ),
                          decorationGradient: AppColors.primaryCtaGradient,
                          foregroundColor: Colors.white,
                          labelStyle: AppTextStyles.onboardingCta(),
                          minimumHeight: 56,
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.signUp),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: () => _openShell(context),
                            child: Text(
                              AppTranslations.section(
                                'paywall',
                                'continue_without_purchasing',
                              ),
                              style: AppTextStyles.paywallDeferSecondary(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaywallFeatureRow extends StatelessWidget {
  const _PaywallFeatureRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          'assets/icons/verified_check.svg',
          width: 20,
          height: 20,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppTextStyles.paywallFeatureLine())),
      ],
    );
  }
}

class _PaymentSummaryCard extends StatelessWidget {
  const _PaymentSummaryCard({required this.freeTrialActive});

  final bool freeTrialActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  AppTranslations.section('paywall', 'payable_today'),
                  style: AppTextStyles.paywallRowEmphasis(
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: freeTrialActive
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppTranslations.section(
                                'paywall',
                                'three_days_free_charge',
                              ),
                              style: AppTextStyles.paywallSheetAccentLine(),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              AppTranslations.section(
                                'paywall',
                                'amount_zero',
                              ),
                              style: AppTextStyles.paywallSheetMutedAmount(),
                            ),
                          ],
                        )
                   
                      : Text(
                          AppTranslations.section('paywall', 'price_due'),
                          textAlign: TextAlign.end,
                          style: AppTextStyles.paywallPaymentBold(),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  AppTranslations.section('paywall', 'payment_date_line'),
                  style: AppTextStyles.paywallPaymentBold(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(
                    AppTranslations.section('paywall', 'price_due'),
                    textAlign: TextAlign.end,
                    style: AppTextStyles.paywallPaymentBold(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppColors.brandPrimary,
              ),
              child: Text(
                AppTranslations.section('paywall', 'cancel_anytime'),
                style: AppTextStyles.paywallInlineLink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
