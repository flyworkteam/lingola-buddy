import 'package:lingola_buddy/Models/lesson_model.dart';
import 'package:lingola_buddy/Models/streak_model.dart';

/// Yerel bildirim metinleri için kullanıcıya özel özet.
class NotificationPersonalization {
  const NotificationPersonalization({
    required this.streakDays,
    required this.practicedToday,
    required this.completedCount,
    required this.totalCount,
    this.unfinishedLessonTitle,
  });

  final int streakDays;
  final bool practicedToday;
  final int completedCount;
  final int totalCount;
  final String? unfinishedLessonTitle;

  int get progressPercent {
    if (totalCount <= 0) return 0;
    return ((completedCount / totalCount) * 100).round().clamp(0, 100);
  }

  static NotificationPersonalization? fromData({
    UserCurriculumModel? curriculum,
    StreakDashboardModel? streak,
  }) {
    if (curriculum == null && streak == null) return null;

    final completed = curriculum?.completedCount ?? 0;
    final total = curriculum?.totalCount ?? 0;
    var practicedToday = false;
    for (final day in streak?.week ?? const <StreakDayModel>[]) {
      if (day.isToday) {
        practicedToday = day.practiced;
        break;
      }
    }

    String? unfinishedTitle;
    final current = curriculum?.currentLesson;
    if (current != null &&
        current.status == LessonProgressStatus.inProgress) {
      unfinishedTitle = current.localizedTitle;
    } else {
      for (final lesson in curriculum?.lessons ?? const <LessonModel>[]) {
        if (lesson.status == LessonProgressStatus.inProgress) {
          unfinishedTitle = lesson.localizedTitle;
          break;
        }
      }
    }

    return NotificationPersonalization(
      streakDays: streak?.streakDays ?? 0,
      practicedToday: practicedToday,
      completedCount: completed,
      totalCount: total,
      unfinishedLessonTitle: unfinishedTitle,
    );
  }
}
