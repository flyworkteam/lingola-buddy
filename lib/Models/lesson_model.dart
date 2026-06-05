import 'package:lingola_buddy/Core/Localization/app_translations.dart';

enum LessonProgressStatus {
  locked,
  available,
  inProgress,
  completed,
}

enum CefrLevel {
  a1,
  a2,
  b1,
  b2,
  c1,
  c2;

  String get code {
    switch (this) {
      case CefrLevel.a1:
        return 'A1';
      case CefrLevel.a2:
        return 'A2';
      case CefrLevel.b1:
        return 'B1';
      case CefrLevel.b2:
        return 'B2';
      case CefrLevel.c1:
        return 'C1';
      case CefrLevel.c2:
        return 'C2';
    }
  }

  static CefrLevel? fromCode(String? raw) {
    switch ((raw ?? '').trim().toUpperCase()) {
      case 'A1':
        return CefrLevel.a1;
      case 'A2':
        return CefrLevel.a2;
      case 'B1':
        return CefrLevel.b1;
      case 'B2':
        return CefrLevel.b2;
      case 'C1':
        return CefrLevel.c1;
      case 'C2':
        return CefrLevel.c2;
      default:
        return null;
    }
  }

  /// Eski onboarding değerleri → CEFR
  static CefrLevel fromLegacyProficiency(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'simple':
        return CefrLevel.a2;
      case 'fluent':
        return CefrLevel.b1;
      case 'none':
      default:
        return CefrLevel.a1;
    }
  }
}

class LessonModel {
  const LessonModel({
    required this.id,
    required this.cefrLevel,
    required this.sortOrder,
    required this.title,
    required this.scenarioEmoji,
    required this.subtitle,
    required this.description,
    required this.learningGoals,
    this.status = LessonProgressStatus.locked,
  });

  final String id;
  final String cefrLevel;
  final int sortOrder;
  final String title;
  final String scenarioEmoji;
  final String subtitle;
  final String description;
  final List<String> learningGoals;
  final LessonProgressStatus status;

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    final goalsRaw = json['learningGoals'];
    final goals = goalsRaw is List
        ? goalsRaw.map((e) => e.toString()).toList()
        : <String>[];

    return LessonModel(
      id: json['id'] as String? ?? '',
      cefrLevel: json['cefrLevel'] as String? ?? 'A1',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      scenarioEmoji: json['scenarioEmoji'] as String? ?? '📘',
      subtitle: json['subtitle'] as String? ?? '',
      description: json['description'] as String? ?? '',
      learningGoals: goals,
      status: _statusFrom(json['status'] as String?),
    );
  }

  static LessonProgressStatus _statusFrom(String? s) {
    switch (s) {
      case 'available':
        return LessonProgressStatus.available;
      case 'in_progress':
        return LessonProgressStatus.inProgress;
      case 'completed':
        return LessonProgressStatus.completed;
      default:
        return LessonProgressStatus.locked;
    }
  }

  String get localizedTitle =>
      AppTranslations.lessonField(id, 'title', fallback: title);

  String get localizedSubtitle =>
      AppTranslations.lessonField(id, 'subtitle', fallback: subtitle);
}

class UserCurriculumModel {
  const UserCurriculumModel({
    required this.cefrLevel,
    required this.currentLesson,
    required this.lessons,
    required this.completedCount,
    required this.totalCount,
    required this.progressFraction,
    this.levelAdvanced = false,
    this.previousLevel,
    this.newLevel,
  });

  final String cefrLevel;
  final LessonModel? currentLesson;
  final List<LessonModel> lessons;
  final int completedCount;
  final int totalCount;
  final double progressFraction;
  final bool levelAdvanced;
  final String? previousLevel;
  final String? newLevel;

  factory UserCurriculumModel.fromJson(Map<String, dynamic> json) {
    final lessonsRaw = json['lessons'] as List<dynamic>? ?? [];
    final current = json['currentLesson'];
    return UserCurriculumModel(
      cefrLevel: json['cefrLevel'] as String? ?? 'A1',
      currentLesson: current is Map<String, dynamic>
          ? LessonModel.fromJson(current)
          : null,
      lessons: lessonsRaw
          .whereType<Map<String, dynamic>>()
          .map(LessonModel.fromJson)
          .toList(),
      completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      progressFraction: (json['progressFraction'] as num?)?.toDouble() ?? 0,
      levelAdvanced: json['levelAdvanced'] == true,
      previousLevel: json['previousLevel'] as String?,
      newLevel: json['newLevel'] as String?,
    );
  }
}
