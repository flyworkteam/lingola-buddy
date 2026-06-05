import 'package:flutter/material.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Models/streak_model.dart';
import 'package:lingola_buddy/View/ProfileShareView/profile_share_view.dart';
import 'package:share_plus/share_plus.dart';

/// Haftalık ilerleme metnini oluşturup sistem paylaşım sayfasını açar.
abstract final class ProgressShareService {
  static String buildMessage(StreakDashboardModel? dashboard) {
    final progress = dashboard?.progress;
    final week = dashboard?.week ?? const <StreakDayModel>[];

    final streak = dashboard?.streakDays ?? 0;
    final level = progress?.cefrLevel ?? 'A1';
    final weekWords =
        week.fold<int>(0, (sum, d) => sum + d.wordsLearned);
    final weekMinutes = progress?.weekMinutes ??
        week.fold<int>(0, (sum, d) => sum + d.minutes);

    final practicedAccuracies = week
        .where((d) => d.practiced && d.accuracyPercent > 0)
        .map((d) => d.accuracyPercent)
        .toList();
    final accuracy = practicedAccuracies.isNotEmpty
        ? (practicedAccuracies.reduce((a, b) => a + b) /
                practicedAccuracies.length)
            .round()
        : (progress?.accuracyPercent ?? 0);

    final timeLabel = AppTranslations.interpolate(
      AppTranslations.section('profile_progress', 'minutes_fmt'),
      {'n': '$weekMinutes'},
    );
    final accuracyLabel = AppTranslations.interpolate(
      AppTranslations.section('profile_progress', 'accuracy_fmt'),
      {'n': '$accuracy'},
    );

    return AppTranslations.interpolate(
      AppTranslations.section('profile_progress', 'share_message_fmt'),
      {
        'streak': '$streak',
        'level': level,
        'words': '$weekWords',
        'accuracy': accuracyLabel,
        'time': timeLabel,
        'link': ProfileShareView.inviteUrl,
      },
    );
  }

  static Future<void> share({
    required BuildContext context,
    StreakDashboardModel? dashboard,
  }) async {
    final message = buildMessage(dashboard);
    final subject =
        AppTranslations.section('profile_progress', 'share_subject');

    Rect? origin;
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      origin = box.localToGlobal(Offset.zero) & box.size;
    }

    await Share.share(
      message,
      subject: subject,
      sharePositionOrigin: origin,
    );
  }
}
