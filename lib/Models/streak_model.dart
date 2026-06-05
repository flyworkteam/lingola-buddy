import 'package:lingola_buddy/Models/learning_progress_model.dart';

class StreakDayModel {
  const StreakDayModel({
    required this.dayKey,
    required this.date,
    required this.practiced,
    required this.isToday,
    this.minutes = 0,
    this.wordsLearned = 0,
    this.accuracyPercent = 0,
  });

  final String dayKey;
  final String date;
  final bool practiced;
  final bool isToday;
  final int minutes;
  final int wordsLearned;
  final int accuracyPercent;

  factory StreakDayModel.fromJson(Map<String, dynamic> json) {
    return StreakDayModel(
      dayKey: json['dayKey'] as String? ?? 'mon',
      date: json['date'] as String? ?? '',
      practiced: json['practiced'] as bool? ?? false,
      isToday: json['isToday'] as bool? ?? false,
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      wordsLearned: (json['wordsLearned'] as num?)?.toInt() ?? 0,
      accuracyPercent: (json['accuracyPercent'] as num?)?.toInt() ?? 0,
    );
  }
}

class StreakDashboardModel {
  const StreakDashboardModel({
    required this.streakDays,
    required this.week,
    this.totalPracticeMinutes = 0,
    this.lastPracticeDate,
    this.progress,
  });

  final int streakDays;
  final List<StreakDayModel> week;
  final int totalPracticeMinutes;
  final String? lastPracticeDate;
  final LearningProgressModel? progress;

  factory StreakDashboardModel.fromJson(Map<String, dynamic> json) {
    final weekRaw = json['week'] as List<dynamic>? ?? [];
    final progressRaw = json['progress'];
    return StreakDashboardModel(
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
      totalPracticeMinutes: (json['totalPracticeMinutes'] as num?)?.toInt() ?? 0,
      lastPracticeDate: json['lastPracticeDate'] as String?,
      week: weekRaw
          .whereType<Map<String, dynamic>>()
          .map(StreakDayModel.fromJson)
          .toList(),
      progress: progressRaw is Map<String, dynamic>
          ? LearningProgressModel.fromJson(progressRaw)
          : null,
    );
  }
}
