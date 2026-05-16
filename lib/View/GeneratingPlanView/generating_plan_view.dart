import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Routes/app_routes.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Widgets/app_primary_button.dart';
import 'package:lingola_buddy/Core/Widgets/brand_aura_backdrop.dart';
import 'package:lingola_buddy/Riverpod/Controllers/CallSessionController/call_session_controller.dart';

/// Kişiselleştirilmiş plan animasyonu: aura, checklist illüstrasyonu, sırayla tamamlanan maddeler, hazır CTA.
class GeneratingPlanView extends ConsumerStatefulWidget {
  const GeneratingPlanView({super.key});

  static const String _illustrationPng =
      'assets/images/plan_checklist_illustration.png';
  static const String _checkIconAsset = 'assets/icons/verified_check.svg';
  static const String _pendingIconAsset = 'assets/icons/history.svg';

  static const Duration _stepDelay = Duration(milliseconds: 900);
  static const Duration _readyPause = Duration(milliseconds: 450);

  @override
  ConsumerState<GeneratingPlanView> createState() => _GeneratingPlanViewState();
}

class _GeneratingPlanViewState extends ConsumerState<GeneratingPlanView> {
  int _completedSteps = 0;
  bool _ready = false;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSequence());
  }

  @override
  void dispose() {
    _cancelled = true;
    super.dispose();
  }

  Future<void> _runSequence() async {
    for (var i = 0; i < 3; i++) {
      await Future<void>.delayed(GeneratingPlanView._stepDelay);
      if (!mounted || _cancelled) return;
      setState(() => _completedSteps = i + 1);
      ref
          .read(callSessionControllerProvider.notifier)
          .setPlanProgress((i + 1) / 3);
    }
    await Future<void>.delayed(GeneratingPlanView._readyPause);
    if (!mounted || _cancelled) return;
    setState(() => _ready = true);
    ref.read(callSessionControllerProvider.notifier).setPlanProgress(1);
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
    final keys = ['plan_desc1', 'plan_desc2', 'plan_desc3'];
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final illCacheW = ((MediaQuery.sizeOf(context).width - 40) * dpr)
        .round()
        .clamp(1, 4096);

    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFFFFFFFF)),
          const Positioned.fill(child: BrandAuraBackdrop()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 220),
                            child: Center(
                              child: Image.asset(
                                GeneratingPlanView._illustrationPng,
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                filterQuality: FilterQuality.high,
                                cacheWidth: illCacheW,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 320),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeOutCubic,
                            transitionBuilder:
                                (Widget child, Animation<double> anim) {
                                  return FadeTransition(
                                    opacity: anim,
                                    child: child,
                                  );
                                },
                            child: _ready
                                ? KeyedSubtree(
                                    key: const ValueKey<String>('ready'),
                                    child: Column(
                                      children: [
                                        Text(
                                          AppTranslations.section(
                                            'onboarding',
                                            'plan_ready_title',
                                          ),
                                          textAlign: TextAlign.center,
                                          style:
                                              AppTextStyles.generatingPlanHeadline(),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          AppTranslations.section(
                                            'onboarding',
                                            'plan_ready_desc',
                                          ),
                                          textAlign: TextAlign.center,
                                          style:
                                              AppTextStyles.generatingPlanReadySubtitle(),
                                        ),
                                      ],
                                    ),
                                  )
                                : KeyedSubtree(
                                    key: const ValueKey<String>('loading'),
                                    child: Text(
                                      AppTranslations.section(
                                        'onboarding',
                                        'plan_title',
                                      ),
                                      textAlign: TextAlign.center,
                                      style:
                                          AppTextStyles.generatingPlanHeadline(),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 32),
                          ...List.generate(3, (index) {
                            final done = index < _completedSteps;
                            final label = AppTranslations.section(
                              'onboarding',
                              keys[index],
                            );
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index < 2 ? 20 : 0,
                              ),
                              child: _PlanCheckRow(
                                completed: done,
                                label: label,
                                checkAsset: GeneratingPlanView._checkIconAsset,
                                pendingAsset:
                                    GeneratingPlanView._pendingIconAsset,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  if (_ready) ...[
                    const SizedBox(height: 8),
                    AppPrimaryButton(
                      label: AppTranslations.section(
                        'onboarding',
                        'plan_ready_button',
                      ),
                      decorationGradient: AppColors.primaryCtaGradient,
                      foregroundColor: Colors.white,
                      labelStyle: AppTextStyles.onboardingCta(),
                      minimumHeight: 60,
                      icon: _ctaArrowIcon(),
                      onPressed: () {
                        ref
                            .read(callSessionControllerProvider.notifier)
                            .bindTutor('sophie');
                        Navigator.pushNamed(context, AppRoutes.callPreview);
                      },
                    ),
                  ],
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

class _PlanCheckRow extends StatelessWidget {
  const _PlanCheckRow({
    required this.completed,
    required this.label,
    required this.checkAsset,
    required this.pendingAsset,
  });

  final bool completed;
  final String label;
  final String checkAsset;
  final String pendingAsset;

  static const double _iconBox = 28;

  @override
  Widget build(BuildContext context) {
    final maxTextWidth = MediaQuery.sizeOf(context).width - 72;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxTextWidth),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: _iconBox,
              height: _iconBox,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                transitionBuilder: (child, anim) {
                  return ScaleTransition(scale: anim, child: child);
                },
                child: completed
                    ? SizedBox(
                        key: const ValueKey<String>('done'),
                        width: _iconBox,
                        height: _iconBox,
                        child: Center(
                          child: SvgPicture.asset(
                            checkAsset,
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                          ),
                        ),
                      )
                    : SizedBox(
                        key: const ValueKey<String>('pending'),
                        width: _iconBox,
                        height: _iconBox,
                        child: Center(
                          child: SvgPicture.asset(
                            pendingAsset,
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              AppColors.secondaryText.withValues(alpha: 0.65),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.generatingPlanCheckRow(
                  completed: completed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
