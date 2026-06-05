import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Widgets/app_primary_button.dart';
import 'package:lingola_buddy/Core/Widgets/app_snackbar.dart';
import 'package:lingola_buddy/Core/Widgets/weekly_progress_panel.dart';
import 'package:lingola_buddy/Riverpod/Providers/streak_provider.dart';
import 'package:lingola_buddy/Services/progress_share_service.dart';

/// Profil ilerleme — ana sayfadaki haftalık panel + paylaş CTA.
class ProfileProgressView extends ConsumerWidget {
  const ProfileProgressView({super.key});

  Future<void> _shareProgress(BuildContext context, WidgetRef ref) async {
    final streakAsync = ref.read(userStreakProvider);
    final data = streakAsync.valueOrNull;
    if (streakAsync.isLoading) {
      AppSnackBar.error(
        AppTranslations.section('profile_progress', 'share_loading'),
        context: context,
      );
      return;
    }

    try {
      await ProgressShareService.share(context: context, dashboard: data);
    } catch (_) {
      if (!context.mounted) return;
      AppSnackBar.error(
        AppTranslations.section('profile_progress', 'share_failed'),
        context: context,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(userStreakProvider);
    final shareEnabled = !streakAsync.isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _ProgressHeader(),
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  const WeeklyProgressPanel(
                    translationChapter: 'profile_progress',
                    stats: WeeklyProgressPanel.profileProgressStats,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Builder(
                builder: (buttonContext) => AppPrimaryButton(
                  label: AppTranslations.section(
                    'profile_progress',
                    'share_progress',
                  ),
                  foregroundColor: Colors.white,
                  labelStyle: AppTextStyles.homeCharacterCta().copyWith(
                    color: Colors.white,
                  ),
                  onPressed: shareEnabled
                      ? () => _shareProgress(buttonContext, ref)
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader();

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
                AppTranslations.section('profile_progress', 'title'),
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
