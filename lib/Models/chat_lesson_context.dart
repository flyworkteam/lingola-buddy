/// Chat oturumunda AI'ya iletilen ders / konu bağlamı.
class ChatLessonContext {
  const ChatLessonContext({
    this.lessonId,
    this.title = '',
    this.scenario = '',
    this.learningGoals = const [],
    this.cefrLevel = 'A1',
    this.isDailyConversation = false,
    this.isFreeTalk = true,
  });

  final String? lessonId;
  final String title;
  final String scenario;
  final List<String> learningGoals;
  final String cefrLevel;
  final bool isDailyConversation;
  final bool isFreeTalk;

  String get tutorPromptSummary {
    if (isFreeTalk) return '';
    final goals = learningGoals.isEmpty
        ? ''
        : '\nLearning goals: ${learningGoals.join('; ')}';
    final kind = isDailyConversation
        ? 'DAILY ENGLISH CONVERSATION'
        : 'ENGLISH LESSON';
    return '$kind (${cefrLevel.toUpperCase()}): "$title"\n'
        'Scenario: $scenario$goals';
  }
}
