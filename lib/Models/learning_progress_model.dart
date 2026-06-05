class LearningProgressModel {
  const LearningProgressModel({
    required this.wordsLearned,
    required this.accuracyPercent,
    required this.weekMinutes,
    required this.cefrLevel,
    required this.todayDayKey,
    this.lessonsCompleted = 0,
  });

  final int wordsLearned;
  final int accuracyPercent;
  final int weekMinutes;
  final String cefrLevel;
  final String todayDayKey;
  final int lessonsCompleted;

  factory LearningProgressModel.fromJson(Map<String, dynamic> json) {
    return LearningProgressModel(
      wordsLearned: (json['wordsLearned'] as num?)?.toInt() ?? 0,
      accuracyPercent: (json['accuracyPercent'] as num?)?.toInt() ?? 0,
      weekMinutes: (json['weekMinutes'] as num?)?.toInt() ?? 0,
      cefrLevel: json['cefrLevel'] as String? ?? 'A1',
      todayDayKey: json['todayDayKey'] as String? ?? 'mon',
      lessonsCompleted: (json['lessonsCompleted'] as num?)?.toInt() ?? 0,
    );
  }
}
