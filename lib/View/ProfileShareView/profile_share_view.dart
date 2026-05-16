import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Widgets/app_primary_button.dart';

/// Arkadaşına paylaş — Figma: illüstrasyon, gri panel + beyaz pill link, CTA.
class ProfileShareView extends StatelessWidget {
  const ProfileShareView({super.key});

  static const String inviteUrl = 'https://fly-work.com/lingolabuddy/download/';
  static const Color _panelBackground = Color(0xFFF6F6F6);

  static const String _heroAsset = 'assets/icons/premuim_man.svg';
  static const double _heroAspectRatio = 398 / 219;

  void _copyLink(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: inviteUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppTranslations.section('profile_share', 'copy_success')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        left: false,
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _ShareHeader(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),

                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 48),
                          _ShareHeroIllustration(
                            maxWidth: constraints.maxWidth,
                          ),
                          const SizedBox(height: 32),
                          const _InviteLinkPanel(url: inviteUrl),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: AppPrimaryButton(
                label: AppTranslations.section('profile_share', 'copy_link'),
                foregroundColor: Colors.white,
                labelStyle: AppTextStyles.homeCharacterCta().copyWith(
                  color: Colors.white,
                ),
                onPressed: () => _copyLink(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareHeader extends StatelessWidget {
  const _ShareHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            IconButton(
              style: IconButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(40, 48),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
              icon: SvgPicture.asset(
                'assets/icons/arrow_left.svg',
                width: 24,
                height: 24,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                AppTranslations.section('profile_share', 'title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.homeWelcomeTitle().copyWith(
                  fontSize: 20,
                  height: 28 / 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: const Color(0xFF171717),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareHeroIllustration extends StatelessWidget {
  const _ShareHeroIllustration({required this.maxWidth});

  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final height = maxWidth / ProfileShareView._heroAspectRatio;

    return SvgPicture.asset(
      ProfileShareView._heroAsset,
      width: maxWidth,
      height: height,
      fit: BoxFit.contain,
      alignment: Alignment.center,
    );
  }
}

/// Figma: gri panel (16px radius) → 10px padding → beyaz pill → link metni.
class _InviteLinkPanel extends StatelessWidget {
  const _InviteLinkPanel({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ProfileShareView._panelBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text(
              url,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.profileShareInviteLink(),
            ),
          ),
        ),
      ),
    );
  }
}
