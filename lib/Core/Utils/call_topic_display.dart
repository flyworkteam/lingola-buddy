import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Models/daily_conversation_model.dart';
import 'package:lingola_buddy/Models/lesson_model.dart';
import 'package:lingola_buddy/Riverpod/Providers/curriculum_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/daily_conversation_provider.dart';

/// Arama önizlemesi / özet için ders veya günlük konuşma başlığı.
class CallTopicDisplay {
  const CallTopicDisplay({
    required this.emoji,
    required this.title,
    required this.isDailyConversation,
  });

  final String emoji;
  final String title;
  final bool isDailyConversation;

  String get emojiTitle => '$emoji $title';
}

CallTopicDisplay? resolveCallTopicDisplay(WidgetRef ref, String? topicId) {
  if (topicId == null || topicId.isEmpty) return null;

  if (topicId.startsWith('dc_')) {
    final curriculum = ref.watch(userDailyConversationProvider).value;
    DailyConversationModel? match;
    for (final c in curriculum?.conversations ?? const <DailyConversationModel>[]) {
      if (c.id == topicId) {
        match = c;
        break;
      }
    }
    match ??= curriculum?.currentConversation?.id == topicId
        ? curriculum?.currentConversation
        : null;
    if (match != null) {
      return CallTopicDisplay(
        emoji: match.scenarioEmoji,
        title: match.localizedTitle,
        isDailyConversation: true,
      );
    }
    final title = AppTranslations.dailyConversationField(
      topicId,
      'title',
      fallback: topicId,
    );
    return CallTopicDisplay(
      emoji: '💬',
      title: title,
      isDailyConversation: true,
    );
  }

  final curriculum = ref.watch(userCurriculumProvider).value;
  LessonModel? lesson;
  for (final l in curriculum?.lessons ?? const <LessonModel>[]) {
    if (l.id == topicId) {
      lesson = l;
      break;
    }
  }
  lesson ??= curriculum?.currentLesson?.id == topicId
      ? curriculum?.currentLesson
      : null;
  if (lesson != null) {
    return CallTopicDisplay(
      emoji: lesson.scenarioEmoji,
      title: lesson.localizedTitle,
      isDailyConversation: false,
    );
  }
  return null;
}
