import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Models/app_enums.dart';
import 'package:lingola_buddy/Models/chat_lesson_context.dart';
import 'package:lingola_buddy/Models/daily_conversation_model.dart';
import 'package:lingola_buddy/Models/lesson_model.dart';
import 'package:lingola_buddy/Riverpod/Controllers/CallSessionController/call_session_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/UserProfileController/user_profile_controller.dart';
import 'package:lingola_buddy/Riverpod/Providers/curriculum_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/daily_conversation_provider.dart';
import 'package:lingola_buddy/Services/realtime_call_engine.dart';

/// Açık [lessonId], aktif arama oturumu veya müfredatın güncel dersi.
String? resolveChatLessonId(
  Ref ref, {
  String? explicitLessonId,
  String? tutorId,
}) {
  return resolveChatLessonIdFromState(
    explicitLessonId: explicitLessonId,
    tutorId: tutorId,
    session: ref.read(callSessionControllerProvider),
    curriculum: ref.read(userCurriculumProvider).value,
    daily: ref.read(userDailyConversationProvider).value,
  );
}

String? resolveChatLessonIdFromState({
  String? explicitLessonId,
  String? tutorId,
  CallSessionState? session,
  UserCurriculumModel? curriculum,
  UserDailyConversationCurriculum? daily,
}) {
  if (explicitLessonId != null && explicitLessonId.isNotEmpty) {
    return explicitLessonId;
  }

  if (tutorId != null &&
      session?.activeTutorId == tutorId &&
      session?.activeLessonId != null &&
      session!.activeLessonId!.isNotEmpty) {
    return session.activeLessonId;
  }

  final currentLesson = curriculum?.currentLesson;
  if (currentLesson != null && currentLesson.id.isNotEmpty) {
    return currentLesson.id;
  }

  final currentDaily = daily?.currentConversation;
  if (currentDaily != null && currentDaily.id.isNotEmpty) {
    return currentDaily.id;
  }

  return null;
}

ChatLessonContext resolveChatLessonContext(Ref ref, {String? lessonId}) {
  if (lessonId == null || lessonId.isEmpty || RealtimeCallEngine.isFreeTalk(lessonId)) {
    final cefr = _resolveCefr(
      null,
      curriculum: ref.read(userCurriculumProvider).value,
      daily: ref.read(userDailyConversationProvider).value,
      proficiency: ref.read(userProfileControllerProvider).user?.proficiency,
    );
    return ChatLessonContext(cefrLevel: cefr, isFreeTalk: true);
  }

  final curriculum = ref.read(userCurriculumProvider).value;
  final daily = ref.read(userDailyConversationProvider).value;

  if (lessonId.startsWith('dc_')) {
    return _fromDailyConversation(lessonId, daily) ??
        ChatLessonContext(
          lessonId: lessonId,
          title: AppTranslations.dailyConversationField(
            lessonId,
            'title',
            fallback: lessonId,
          ),
          cefrLevel: _resolveCefr(
            lessonId,
            curriculum: curriculum,
            daily: daily,
            proficiency: ref.read(userProfileControllerProvider).user?.proficiency,
          ),
          isDailyConversation: true,
          isFreeTalk: false,
        );
  }

  return _fromLesson(lessonId, curriculum) ??
      ChatLessonContext(
        lessonId: lessonId,
        title: AppTranslations.lessonField(lessonId, 'title', fallback: lessonId),
        cefrLevel: _resolveCefr(
          lessonId,
          curriculum: curriculum,
          daily: daily,
          proficiency: ref.read(userProfileControllerProvider).user?.proficiency,
        ),
        isFreeTalk: false,
      );
}

String _resolveCefr(
  String? lessonId, {
  UserCurriculumModel? curriculum,
  UserDailyConversationCurriculum? daily,
  ProficiencyLevel? proficiency,
}) {
  if (lessonId != null && lessonId.startsWith('dc_')) {
    for (final c in daily?.conversations ?? const <DailyConversationModel>[]) {
      if (c.id == lessonId) return c.cefrLevel;
    }
    return daily?.cefrLevel ?? 'A1';
  }

  if (lessonId != null) {
    for (final l in curriculum?.lessons ?? const <LessonModel>[]) {
      if (l.id == lessonId) return l.cefrLevel;
    }
  }
  if (curriculum != null && curriculum.cefrLevel.isNotEmpty) {
    return curriculum.cefrLevel;
  }

  return CefrLevel.fromLegacyProficiency(proficiency?.name).code;
}

ChatLessonContext? _fromLesson(String lessonId, UserCurriculumModel? curriculum) {
  LessonModel? match;
  for (final l in curriculum?.lessons ?? const <LessonModel>[]) {
    if (l.id == lessonId) {
      match = l;
      break;
    }
  }
  match ??= curriculum?.currentLesson?.id == lessonId
      ? curriculum?.currentLesson
      : null;
  if (match == null) return null;

  return ChatLessonContext(
    lessonId: match.id,
    title: match.localizedTitle,
    scenario: match.description,
    learningGoals: match.learningGoals,
    cefrLevel: match.cefrLevel,
    isDailyConversation: false,
    isFreeTalk: false,
  );
}

ChatLessonContext? _fromDailyConversation(
  String lessonId,
  UserDailyConversationCurriculum? curriculum,
) {
  DailyConversationModel? match;
  for (final c in curriculum?.conversations ?? const <DailyConversationModel>[]) {
    if (c.id == lessonId) {
      match = c;
      break;
    }
  }
  match ??= curriculum?.currentConversation?.id == lessonId
      ? curriculum?.currentConversation
      : null;
  if (match == null) return null;

  return ChatLessonContext(
    lessonId: match.id,
    title: match.localizedTitle,
    scenario: match.description,
    learningGoals: match.learningGoals,
    cefrLevel: match.cefrLevel,
    isDailyConversation: true,
    isFreeTalk: false,
  );
}
