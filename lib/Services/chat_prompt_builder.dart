import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Models/chat_lesson_context.dart';

abstract final class ChatPromptBuilder {
  ChatPromptBuilder._();

  static String uiLanguageLabel(String code) {
    return AppTranslations.sectionOr(
      'languages',
      code.trim().toLowerCase(),
      code,
    );
  }

  static String buildSystemPrompt({
    required String tutorName,
    required String tutorBio,
    required String uiLanguageCode,
    required ChatLessonContext lessonContext,
  }) {
    final appLangCode = uiLanguageCode.trim().toLowerCase();
    final appLangName = uiLanguageLabel(appLangCode);
    final cefr = lessonContext.cefrLevel.toUpperCase();

    final base =
        'You are $tutorName, a friendly English tutor in a text chat app. '
        'Keep replies short and natural (1–3 sentences). Stay in character. '
        'Bio: ${tutorBio.trim().isEmpty ? 'Experienced English tutor.' : tutorBio.trim()}\n'
        '- NEVER ask the learner for their name — you already have it from their profile.';

    if (appLangCode == 'en') {
      return _englishOnlyPrompt(base, lessonContext, cefr);
    }

    final bilingualBlock = _bilingualTeachingBlock(appLangName, appLangCode, cefr);
    final topicBlock = _topicBlock(lessonContext, appLangName, bilingual: true);

    if (lessonContext.isFreeTalk) {
      return '$base$bilingualBlock'
          '\n\nOPEN ENGLISH PRACTICE:\n'
          '- Phase 1: agree on a topic in $appLangName (hobbies, work, travel, daily life).\n'
          '- Phase 2: teach useful phrases with the explain-in-$appLangName + English-phrase pattern.\n'
          '- Match vocabulary and sentence length to CEFR $cefr.';
    }

    return '$base$bilingualBlock$topicBlock';
  }

  static String buildSeedGreeting({
    required String tutorName,
    required String uiLanguageCode,
    required ChatLessonContext lessonContext,
  }) {
    final isTr = uiLanguageCode.trim().toLowerCase() == 'tr';

    if (lessonContext.isFreeTalk) {
      if (isTr) {
        return AppTranslations.interpolate(
          AppTranslations.sectionOr(
            'chat',
            'seed_greeting_free',
            'Merhaba! Ben {tutor}. Birlikte İngilizce pratik yapalım. Hazır mısın?',
          ),
          {'tutor': tutorName},
        );
      }
      return "Hello! I'm $tutorName. Let's practice English together. Ready to start?";
    }

    final topic = lessonContext.title.trim();
    if (topic.isNotEmpty) {
      if (isTr) {
        return AppTranslations.interpolate(
          AppTranslations.sectionOr(
            'chat',
            'seed_greeting_topic',
            'Merhaba! Ben {tutor}. Bugün "{topic}" konusunda birlikte çalışalım. Hazır mısın?',
          ),
          {'tutor': tutorName, 'topic': topic},
        );
      }
      return "Hello! I'm $tutorName. Today let's work on \"$topic\". Ready?";
    }

    if (isTr) {
      return AppTranslations.interpolate(
        AppTranslations.sectionOr(
          'chat',
          'seed_greeting_generic',
          'Merhaba! Ben {tutor}. Tanıştığımıza memnun oldum. Hazır mısın?',
        ),
        {'tutor': tutorName},
      );
    }
    return "Hello! I'm $tutorName. Nice to meet you. Ready to get started?";
  }

  static String _englishOnlyPrompt(
    String base,
    ChatLessonContext lessonContext,
    String cefr,
  ) {
    if (lessonContext.isFreeTalk) {
      return '$base'
          '\n\nOPEN ENGLISH PRACTICE (mandatory — speak ONLY English):\n'
          '- Free conversation; the learner chooses the topic.\n'
          '- Match vocabulary, sentence length, and pace to CEFR $cefr.\n'
          '- Gently correct errors without breaking the flow.\n'
          '- If they use another language, warmly encourage English.';
    }

    final summary = lessonContext.tutorPromptSummary;
    final kind = lessonContext.isDailyConversation
        ? 'DAILY ENGLISH CONVERSATION'
        : 'ENGLISH LESSON';
    return '$base'
        '\n\n$kind (mandatory — speak ONLY English):\n$summary\n'
        '- Stay inside this scenario. Gently redirect off-topic chat.\n'
        '- If the learner uses another language, warmly encourage English.';
  }

  static String _bilingualTeachingBlock(
    String appLangName,
    String appLangCode,
    String cefr,
  ) {
    return '\n\nBILINGUAL ENGLISH TEACHING (mandatory — follow this exact flow):\n'
        'PHASE 1 — SETUP (speak ONLY in $appLangName, code: $appLangCode):\n'
        '- After the greeting, use 1–3 turns entirely in $appLangName.\n'
        '- Explain which topic or scenario you will work on and what phrases they will learn.\n'
        '- Check they are ready. Do NOT use English in Phase 1.\n'
        'PHASE 2 — TEACH (explain in $appLangName; English ONLY for the target phrase):\n'
        '- All explanations, transitions, praise, and corrections stay in $appLangName.\n'
        '- English appears ONLY as the phrase being taught — never a full English reply.\n'
        '- Pattern: [$appLangName explanation] … [English phrase]. Example for Turkish: '
        '"Merhaba! \'Bugün nasılsın?\' demek için: How are you?"\n'
        '- Teach ONE useful phrase per turn at CEFR $cefr; invite the learner to repeat it.\n'
        '- Do NOT jump into free English conversation — keep the teach-and-repeat pattern.';
  }

  static String _topicBlock(
    ChatLessonContext lessonContext,
    String appLangName, {
    required bool bilingual,
  }) {
    final summary = lessonContext.tutorPromptSummary;
    if (lessonContext.isDailyConversation) {
      return '\n\nDAILY ENGLISH CONVERSATION:\n$summary\n'
          '- Phase 1: in $appLangName, introduce this daily chat topic and what phrases they will learn.\n'
          '- Phase 2: teach phrases with the explain-in-$appLangName + English-phrase pattern.\n'
          '- Keep the vibe like everyday small talk, not a formal classroom.';
    }
    return '\n\nENGLISH LESSON:\n$summary\n'
        '- Phase 1: in $appLangName, introduce this lesson scenario and today\'s goal.\n'
        '- Phase 2: teach scenario phrases with the explain-in-$appLangName + English-phrase pattern.\n'
        '- Stay inside this scenario; gently redirect off-topic chat.';
  }
}
