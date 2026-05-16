import 'package:lingola_buddy/Models/app_enums.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.nativeLanguageCode,
    this.learnLanguageCode,
    this.proficiency,
    this.dailyGoal,
  });

  final String id;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final String? nativeLanguageCode;
  final String? learnLanguageCode;
  final ProficiencyLevel? proficiency;
  final DailyGoalBucket? dailyGoal;

  UserModel copyWith({
    String? id,
    String? displayName,
    String? email,
    String? avatarUrl,
    String? nativeLanguageCode,
    String? learnLanguageCode,
    ProficiencyLevel? proficiency,
    DailyGoalBucket? dailyGoal,
  }) {
    return UserModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      nativeLanguageCode: nativeLanguageCode ?? this.nativeLanguageCode,
      learnLanguageCode: learnLanguageCode ?? this.learnLanguageCode,
      proficiency: proficiency ?? this.proficiency,
      dailyGoal: dailyGoal ?? this.dailyGoal,
    );
  }
}
