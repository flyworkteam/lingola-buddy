import 'package:lingola_buddy/Models/app_enums.dart';
import 'package:lingola_buddy/Models/lesson_model.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.nativeLanguageCode,
    this.learnLanguageCode,
    this.proficiency,
    this.cefrLevel,
    this.currentLessonId,
    this.dailyGoal,
  });

  final String id;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final String? nativeLanguageCode;
  final String? learnLanguageCode;
  final ProficiencyLevel? proficiency;
  final CefrLevel? cefrLevel;
  final String? currentLessonId;
  final DailyGoalBucket? dailyGoal;

  UserModel copyWith({
    String? id,
    String? displayName,
    String? email,
    String? avatarUrl,
    bool clearAvatar = false,
    String? nativeLanguageCode,
    String? learnLanguageCode,
    ProficiencyLevel? proficiency,
    CefrLevel? cefrLevel,
    String? currentLessonId,
    DailyGoalBucket? dailyGoal,
  }) {
    return UserModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
      nativeLanguageCode: nativeLanguageCode ?? this.nativeLanguageCode,
      learnLanguageCode: learnLanguageCode ?? this.learnLanguageCode,
      proficiency: proficiency ?? this.proficiency,
      cefrLevel: cefrLevel ?? this.cefrLevel,
      currentLessonId: currentLessonId ?? this.currentLessonId,
      dailyGoal: dailyGoal ?? this.dailyGoal,
    );
  }
}
