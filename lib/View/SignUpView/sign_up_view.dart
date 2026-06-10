import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Utils/legal_link_launcher.dart';
import 'package:lingola_buddy/Core/Widgets/brand_aura_backdrop.dart';
import 'package:lingola_buddy/Services/auth_flow_helper.dart';

const String _signUpAppIcon = 'assets/images/splash_app_icon.png';

const LinearGradient _signUpIconGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF8F56FF), AppColors.brandPrimary, Color(0xFF5A17D4)],
  stops: [0.0, 0.42, 1.0],
);

class SignUpView extends ConsumerStatefulWidget {
  const SignUpView({super.key});

  @override
  ConsumerState<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends ConsumerState<SignUpView> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;
  late final TapGestureRecognizer _cookiesRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = _onTermsTap;
    _privacyRecognizer = TapGestureRecognizer()..onTap = _onPrivacyTap;
    _cookiesRecognizer = TapGestureRecognizer()..onTap = _onCookiesTap;
  }

  void _onTermsTap() {
    if (!mounted) return;
    _openTerms(context);
  }

  void _onPrivacyTap() {
    if (!mounted) return;
    _openPrivacy(context);
  }

  void _onCookiesTap() {
    if (!mounted) return;
    _openCookies(context);
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _cookiesRecognizer.dispose();
    super.dispose();
  }

  void _openTerms(BuildContext context) {
    LegalLinkLauncher.openTermsOfService(context);
  }

  void _openPrivacy(BuildContext context) {
    LegalLinkLauncher.openPrivacyPolicy(context);
  }

  void _openCookies(BuildContext context) {
    LegalLinkLauncher.openCookiePolicy(context);
  }

  Future<void> _signInGoogle(BuildContext context) =>
      AuthFlowHelper.completeSignIn(
        context,
        ref,
        (repo) => repo.signInWithGoogle(),
      );

  Future<void> _signInApple(BuildContext context) =>
      AuthFlowHelper.completeSignIn(
        context,
        ref,
        (repo) => repo.signInWithApple(),
      );

  Future<void> _signInGuest(BuildContext context) =>
      AuthFlowHelper.completeSignIn(
        context,
        ref,
        (repo) => repo.signInAsGuest(),
      );

  @override
  Widget build(BuildContext context) {
    final isIOS = !kIsWeb && Platform.isIOS;
    final baseLegal = AppTextStyles.signUpLegalBody();
    final linkLegal = AppTextStyles.signUpLegalLink();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BrandAuraBackdrop(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(child: Center(child: _SignUpBrandHeader())),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        AppTranslations.section('sign_up', 'headline'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.signUpHeadline(),
                      ),
                      const SizedBox(height: 20),
                      if (isIOS) ...[
                        _AppleSignInButton(
                          label: AppTranslations.section(
                            'sign_up',
                            'continue_apple',
                          ),
                          onPressed: () => _signInApple(context),
                        ),
                        const SizedBox(height: 12),
                        _GoogleSignInButton(
                          label: AppTranslations.section(
                            'sign_up',
                            'continue_google',
                          ),
                          onPressed: () => _signInGoogle(context),
                        ),
                      ] else ...[
                        _GoogleSignInButton(
                          label: AppTranslations.section(
                            'sign_up',
                            'continue_google',
                          ),
                          onPressed: () => _signInGoogle(context),
                        ),
                        const SizedBox(height: 12),
                        _AppleSignInButton(
                          label: AppTranslations.section(
                            'sign_up',
                            'continue_apple',
                          ),
                          onPressed: () => _signInApple(context),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          onPressed: () => _signInGuest(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                          ),
                          child: Text(
                            AppTranslations.section(
                              'sign_up',
                              'continue_guest',
                            ),
                            style: AppTextStyles.signUpGuestLink(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text.rich(
                        TextSpan(
                          style: baseLegal,
                          children: [
                            TextSpan(
                              text: AppTranslations.section(
                                'sign_up',
                                'legal_part1',
                              ),
                            ),
                            TextSpan(
                              text: AppTranslations.section(
                                'sign_up',
                                'legal_terms',
                              ),
                              style: linkLegal,
                              recognizer: _termsRecognizer,
                            ),
                            TextSpan(
                              text: AppTranslations.section(
                                'sign_up',
                                'legal_part2',
                              ),
                            ),
                            TextSpan(
                              text: AppTranslations.section(
                                'sign_up',
                                'legal_privacy',
                              ),
                              style: linkLegal,
                              recognizer: _privacyRecognizer,
                            ),
                            TextSpan(
                              text: AppTranslations.section(
                                'sign_up',
                                'legal_part3',
                              ),
                            ),
                            TextSpan(
                              text: AppTranslations.section(
                                'sign_up',
                                'legal_cookies',
                              ),
                              style: linkLegal,
                              recognizer: _cookiesRecognizer,
                            ),
                            TextSpan(
                              text: AppTranslations.section(
                                'sign_up',
                                'legal_part4',
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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

class _SignUpBrandHeader extends StatelessWidget {
  const _SignUpBrandHeader();

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(gradient: _signUpIconGradient),
                ),
                Image.asset(
                  _signUpAppIcon,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -1.5),
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.high,
                  cacheWidth: (120 * dpr).round(),
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppTranslations.section('common', 'app_name'),
          textAlign: TextAlign.center,
          style: AppTextStyles.splashAppTitle().copyWith(
            fontSize: 28,
            height: 34 / 28,
          ),
        ),
      ],
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  static const double _height = 54;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          height: _height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.black.withValues(alpha: 0.2)),
            color: Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icons/google.svg',
                width: 22,
                height: 22,
              ),
              const SizedBox(width: 10),
              Text(label, style: AppTextStyles.signUpSocialLabel()),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppleSignInButton extends StatelessWidget {
  const _AppleSignInButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  static const double _height = 54;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: Ink(
          height: _height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.black,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset('assets/icons/apple.svg', width: 20, height: 24),
              const SizedBox(width: 10),
              Text(label, style: AppTextStyles.signUpSocialLabelOnDark()),
            ],
          ),
        ),
      ),
    );
  }
}
