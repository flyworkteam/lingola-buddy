import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Routes/app_routes.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Widgets/app_primary_button.dart';
import 'package:lingola_buddy/Riverpod/Controllers/CallSessionController/call_session_controller.dart';

String _interp(String template, Map<String, String> vars) {
  var s = template;
  for (final e in vars.entries) {
    s = s.replaceAll('{${e.key}}', e.value);
  }
  return s;
}

/// Görüşme sonrası özet — Figma: başlık + kota rozeti, çift görüntü, istatistikler, skor, sonraki konu, CTA.
///
/// [Kota] şu an sabit demo (`1/3`); ileride API / provider ile beslenecek.
class CallSummaryView extends ConsumerWidget {
  const CallSummaryView({super.key});

  static const String _tutorImage = 'assets/images/avatar_4.png';
  static const String _userImage = 'assets/images/avatar_2.png';

  /// Ücretsiz görüşme kotası (demo; sonra dinamik yapılacak).
  static const int _freeUsed = 1;
  static const int _freeTotal = 3;

  /// Demo metrikler (API bağlanınca kaldırılacak).
  static const int _wordsDemo = 138;
  static const String _fluencyDemo = '+12%';
  static const int _sessionScorePercent = 65;

  static String _formatDurationMmSs(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seconds = ref.watch(callSessionControllerProvider).lastDurationSeconds;
    final tutorName = AppTranslations.section('call', 'title');
    final subject = AppTranslations.section('video_session', 'practice_subject');
    final topicPreview =
        AppTranslations.section('video_session', 'next_topic_preview');

    final feedback = _interp(
      AppTranslations.section('video_session', 'feedback_great'),
      {'name': tutorName},
    );
    final statusLine = _interp(
      AppTranslations.section('video_session', 'status_just_finished'),
      {'subject': subject},
    );
    final badgeText = _interp(
      AppTranslations.section('video_session', 'badge_free'),
      {
        'current': '$_freeUsed',
        'total': '$_freeTotal',
      },
    );

    final roleLabel =
        AppTranslations.section('video_session', 'role_label_teacher');
    final nextChosen = _interp(
      AppTranslations.section('video_session', 'next_topic_chosen'),
      {'name': tutorName},
    );
    final nextReady = _interp(
      AppTranslations.section('video_session', 'next_topic_ready'),
      {'topic': topicPreview},
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeaderRow(
                      tutorImage: _tutorImage,
                      feedback: feedback,
                      statusLine: statusLine,
                      badgeText: badgeText,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 200,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _SnapshotTile(
                                      imageAsset: _tutorImage,
                                      overlayAlignment: Alignment.bottomLeft,
                                      overlay: _TeacherOverlayRich(
                                        tutorName: tutorName,
                                        roleLabel: roleLabel,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _SnapshotTile(
                                      imageAsset: _userImage,
                                      overlayAlignment: Alignment.bottomCenter,
                                      overlay: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.5),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          AppTranslations.section(
                                            'video_session',
                                            'you',
                                          ),
                                          style: AppTextStyles
                                              .callSummarySnapshotName(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _StatTile(
                                    label: AppTranslations.section(
                                      'video_session',
                                      'stat_duration',
                                    ),
                                    value: _formatDurationMmSs(seconds),
                                    valueStyle:
                                        AppTextStyles.callSummaryStatValue(),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _StatTile(
                                    label: AppTranslations.section(
                                      'video_session',
                                      'stat_words',
                                    ),
                                    value: '$_wordsDemo',
                                    valueStyle:
                                        AppTextStyles.callSummaryStatValue(
                                      color: AppColors.brandPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _StatTile(
                                    label: AppTranslations.section(
                                      'video_session',
                                      'stat_fluency',
                                    ),
                                    value: _fluencyDemo,
                                    valueStyle:
                                        AppTextStyles.callSummaryStatValue(
                                      color: AppColors.callPreviewCtaGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: _SessionScoreCard(
                          percent: _sessionScorePercent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: _NextTopicCard(
                          title: nextChosen,
                          subtitle: nextReady,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppPrimaryButton(
                    label: AppTranslations.section(
                      'video_session',
                      'start_new_conversation',
                    ),
                    decorationGradient: AppColors.primaryCtaGradient,
                    foregroundColor: Colors.white,
                    labelStyle: AppTextStyles.callPreviewStartCta(),
                    minimumHeight: 60,
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.paywall),
                  ),
                  TextButton(
                    onPressed: () {
                      ref
                          .read(callSessionControllerProvider.notifier)
                          .clearActiveSession();
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.bottomNav,
                        (_) => false,
                      );
                    },
                    child: Text(
                      AppTranslations.section(
                        'video_session',
                        'another_time',
                      ),
                      style: AppTextStyles.callSummaryNextTitle().copyWith(
                        color: Colors.black.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.tutorImage,
    required this.feedback,
    required this.statusLine,
    required this.badgeText,
  });

  final String tutorImage;
  final String feedback;
  final String statusLine;
  final String badgeText;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: AppColors.brandPrimary,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  tutorImage,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -1.2),
                ),
              ),
            ),
            Positioned(
              right: 5,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.callPreviewCtaGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                feedback,
                style: AppTextStyles.callSummaryFeedbackTitle(),
              ),
              const SizedBox(height: 4),
              Text(
                statusLine,
                style: AppTextStyles.callSummaryStatusLine(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.brandPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.brandPrimary),
          ),
          child: Text(
            badgeText,
            style: AppTextStyles.callSummaryQuotaBadge(),
          ),
        ),
      ],
    );
  }
}

class _TeacherOverlayRich extends StatelessWidget {
  const _TeacherOverlayRich({
    required this.tutorName,
    required this.roleLabel,
  });

  final String tutorName;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.callSummarySnapshotName(),
          children: [
            TextSpan(
              text: tutorName,
              style: AppTextStyles.callSummarySnapshotName(),
            ),
            TextSpan(
              text: ' • ',
              style: AppTextStyles.callSummarySnapshotSep(),
            ),
            TextSpan(
              text: roleLabel,
              style: AppTextStyles.callSummarySnapshotName(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SnapshotTile extends StatelessWidget {
  const _SnapshotTile({
    required this.imageAsset,
    required this.overlay,
    this.overlayAlignment = Alignment.bottomLeft,
  });

  final String imageAsset;
  final Widget overlay;
  final AlignmentGeometry overlayAlignment;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: Colors.white,
            child: Image.asset(
              imageAsset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Align(
                alignment: overlayAlignment,
                child: overlay,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.callSummaryStatLabel()),
            Text(value, style: valueStyle),
          ],
        ),
      ),
    );
  }
}

/// Her iki uç da yuvarlak dolgu (LinearProgressIndicator kare uç verir).
class _SessionScoreProgressBar extends StatelessWidget {
  const _SessionScoreProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        const h = 12.0;
        final fill = (w * value).clamp(0.0, w);
        return SizedBox(
          height: h,
          width: w,
          child: Stack(
            children: [
              Container(
                width: w,
                height: h,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(h / 2),
                ),
              ),
              if (fill > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: fill,
                    height: h,
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary,
                      borderRadius: BorderRadius.circular(h / 2),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SessionScoreCard extends StatelessWidget {
  const _SessionScoreCard({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final p = (percent.clamp(0, 100)) / 100.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppTranslations.section('video_session', 'session_score'),
                  style: AppTextStyles.callSummaryScoreTitle(),
                ),
                Text(
                  '%$percent',
                  style: AppTextStyles.callSummaryScorePercent(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SessionScoreProgressBar(value: p),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppTranslations.section('video_session', 'level_beginner'),
                  style: AppTextStyles.callSummaryScoreFootMuted(),
                ),
                Flexible(
                  child: Text(
                    AppTranslations.section('video_session', 'cta_advanced'),
                    textAlign: TextAlign.end,
                    style: AppTextStyles.callSummaryScoreFootAccent(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NextTopicCard extends StatelessWidget {
  const _NextTopicCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/medal_star.svg',
                  width: 32,
                  height: 32,
                  colorFilter: const ColorFilter.mode(
                    AppColors.brandPrimary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.callSummaryQuotaBadge().copyWith(color: Colors.black)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.callSummaryNextSubtitle(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
