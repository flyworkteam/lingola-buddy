import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Routes/call_navigation.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Models/lesson_model.dart';
import 'package:lingola_buddy/Riverpod/Controllers/CallSessionController/call_session_controller.dart';
import 'package:lingola_buddy/Riverpod/Providers/curriculum_provider.dart';

class LessonsListView extends ConsumerWidget {
  const LessonsListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(userCurriculumProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text(
          AppTranslations.section('home', 'lessons_title'),
          style: AppTextStyles.homeSectionTitle(),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(AppTranslations.section('home', 'lessons_empty')),
        ),
        data: (curriculum) {
          if (curriculum.lessons.isEmpty) {
            return Center(
              child: Text(AppTranslations.section('home', 'lessons_empty')),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: curriculum.lessons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final lesson = curriculum.lessons[index];
              final isCurrent = curriculum.currentLesson?.id == lesson.id;
              return _LessonTile(
                lesson: lesson,
                isCurrent: isCurrent,
                onTap: lesson.status == LessonProgressStatus.locked
                    ? null
                    : () => _openLesson(context, ref, lesson),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openLesson(
    BuildContext context,
    WidgetRef ref,
    LessonModel lesson,
  ) async {
    try {
      await ref.read(lessonRepositoryProvider).setCurrentLesson(lesson.id);
      ref.invalidate(userCurriculumProvider);
    } catch (_) {
      // continue with local selection
    }
    final tutorId =
        ref.read(callSessionControllerProvider).activeTutorId ?? 'annie';
    ref.read(callSessionControllerProvider.notifier).bindTutor(
          tutorId,
          lessonId: lesson.id,
        );
    if (!context.mounted) return;
    await CallNavigation.pushSessionPreview(
      context,
      ref,
      tutorId: tutorId,
      lessonId: lesson.id,
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.isCurrent,
    required this.onTap,
  });

  final LessonModel lesson;
  final bool isCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (lesson.status) {
      LessonProgressStatus.completed =>
        AppTranslations.section('home', 'lesson_completed'),
      LessonProgressStatus.inProgress =>
        AppTranslations.section('home', 'lesson_in_progress'),
      LessonProgressStatus.available =>
        AppTranslations.section('home', 'lesson_in_progress'),
      LessonProgressStatus.locked =>
        AppTranslations.section('home', 'lesson_locked'),
    };

    return Material(
      color: isCurrent
          ? AppColors.brandPrimary.withValues(alpha: 0.08)
          : const Color(0xFFF6F6F6),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(lesson.scenarioEmoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.localizedTitle,
                      style: AppTextStyles.homeScenarioTitle(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${lesson.cefrLevel} • ${lesson.localizedSubtitle}',
                      style: AppTextStyles.homeScenarioSubtitle(),
                    ),
                  ],
                ),
              ),
              Text(statusLabel, style: AppTextStyles.homeLessonProgress()),
            ],
          ),
        ),
      ),
    );
  }
}
