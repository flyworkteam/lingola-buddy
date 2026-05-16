import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Routes/app_routes.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Widgets/brand_aura_backdrop.dart';
import 'package:lingola_buddy/Riverpod/Controllers/SessionController/session_controller.dart';
import 'package:lingola_buddy/View/ProfilePrivacyView/profile_privacy_view.dart';
import 'package:lingola_buddy/View/ProfileTermsView/profile_terms_view.dart';

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
    _openPrivacy(context);
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _cookiesRecognizer.dispose();
    super.dispose();
  }

  void _openTerms(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const ProfileTermsView(),
      ),
    );
  }

  void _openPrivacy(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const ProfilePrivacyView(),
      ),
    );
  }

  Future<void> _finish(BuildContext context) async {
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
    final baseLegal = AppTextStyles.signUpLegalBody();
    final linkLegal = AppTextStyles.signUpLegalLink();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BrandAuraBackdrop(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      AppTranslations.section('sign_up', 'headline'),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.signUpHeadline(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _GoogleSignInButton(
                    label: AppTranslations.section('sign_up', 'continue_google'),
                    onPressed: () => _finish(context),
                  ),
                  const SizedBox(height: 12),
                  _AppleSignInButton(
                    label: AppTranslations.section('sign_up', 'continue_apple'),
                    onPressed: () => _finish(context),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () => _finish(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                      ),
                      child: Text(
                        AppTranslations.section('sign_up', 'continue_guest'),
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
                          text: AppTranslations.section('sign_up', 'legal_part1'),
                        ),
                        TextSpan(
                          text: AppTranslations.section('sign_up', 'legal_terms'),
                          style: linkLegal,
                          recognizer: _termsRecognizer,
                        ),
                        TextSpan(
                          text: AppTranslations.section('sign_up', 'legal_part2'),
                        ),
                        TextSpan(
                          text: AppTranslations.section('sign_up', 'legal_privacy'),
                          style: linkLegal,
                          recognizer: _privacyRecognizer,
                        ),
                        TextSpan(
                          text: AppTranslations.section('sign_up', 'legal_part3'),
                        ),
                        TextSpan(
                          text: AppTranslations.section('sign_up', 'legal_cookies'),
                          style: linkLegal,
                          recognizer: _cookiesRecognizer,
                        ),
                        TextSpan(
                          text: AppTranslations.section('sign_up', 'legal_part4'),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({
    required this.label,
    required this.onPressed,
  });

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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
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
      ),
    );
  }
}

class _AppleSignInButton extends StatelessWidget {
  const _AppleSignInButton({
    required this.label,
    required this.onPressed,
  });

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
              SvgPicture.asset(
                'assets/icons/apple.svg',
                width: 20,
                height: 24,
              ),
              const SizedBox(width: 10),
              Text(label, style: AppTextStyles.signUpSocialLabelOnDark()),
            ],
          ),
        ),
      ),
    );
  }
}
