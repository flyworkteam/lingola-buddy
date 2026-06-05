import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Models/lesson_model.dart';

/// Günlük konuşma konusu (ders müfredatından ayrı).
class DailyConversationModel {
  const DailyConversationModel({
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

  factory DailyConversationModel.fromJson(Map<String, dynamic> json) {
    final goalsRaw = json['learningGoals'];
    final goals = goalsRaw is List
        ? goalsRaw.map((e) => e.toString()).toList()
        : <String>[];

    return DailyConversationModel(
      id: json['id'] as String? ?? '',
      cefrLevel: json['cefrLevel'] as String? ?? 'A1',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      scenarioEmoji: json['scenarioEmoji'] as String? ?? '💬',
      subtitle: json['subtitle'] as String? ?? '',
      description: json['description'] as String? ?? '',
      learningGoals: goals,
      status: _statusFrom(json['status'] as String?),
    );
  }

  String get localizedTitle =>
      AppTranslations.dailyConversationField(id, 'title', fallback: title);

  String get localizedSubtitle =>
      AppTranslations.dailyConversationField(id, 'subtitle', fallback: subtitle);

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
}

class UserDailyConversationCurriculum {
  const UserDailyConversationCurriculum({
    required this.cefrLevel,
    required this.currentConversation,
    required this.conversations,
    required this.completedCount,
    required this.totalCount,
    required this.progressFraction,
  });

  final String cefrLevel;
  final DailyConversationModel? currentConversation;
  final List<DailyConversationModel> conversations;
  final int completedCount;
  final int totalCount;
  final double progressFraction;

  factory UserDailyConversationCurriculum.fromJson(Map<String, dynamic> json) {
    final raw = json['conversations'] as List<dynamic>? ?? [];
    final current = json['currentConversation'];
    return UserDailyConversationCurriculum(
      cefrLevel: json['cefrLevel'] as String? ?? 'A1',
      currentConversation: current is Map<String, dynamic>
          ? DailyConversationModel.fromJson(current)
          : null,
      conversations: raw
          .whereType<Map<String, dynamic>>()
          .map(DailyConversationModel.fromJson)
          .toList(),
      completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      progressFraction: (json['progressFraction'] as num?)?.toDouble() ?? 0,
    );
  }
}
