import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Routes/call_navigation.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Models/daily_conversation_model.dart';
import 'package:lingola_buddy/Models/lesson_model.dart';
import 'package:lingola_buddy/Riverpod/Controllers/CallSessionController/call_session_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/UserProfileController/user_profile_controller.dart';
import 'package:lingola_buddy/Riverpod/Providers/daily_conversation_provider.dart';

class DailyConversationsListView extends ConsumerWidget {
  const DailyConversationsListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(userProfileControllerProvider.select((s) => s.uiLanguageCode));
    final async = ref.watch(userDailyConversationProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          style: IconButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(40, 48),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
          icon: SvgPicture.asset(
            'assets/icons/arrow_left.svg',
            width: 24,
            height: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text(
          AppTranslations.section('home', 'daily_conversation'),
          style: AppTextStyles.homeSectionTitle(),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(AppTranslations.section('home', 'lessons_empty')),
        ),
        data: (curriculum) {
          if (curriculum.conversations.isEmpty) {
            return Center(
              child: Text(AppTranslations.section('home', 'lessons_empty')),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: curriculum.conversations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final topic = curriculum.conversations[index];
              final isCurrent = curriculum.currentConversation?.id == topic.id;
              return _DailyConversationTile(
                topic: topic,
                isCurrent: isCurrent,
                onTap: topic.status == LessonProgressStatus.locked
                    ? null
                    : () => _openConversation(context, ref, topic),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openConversation(
    BuildContext context,
    WidgetRef ref,
    DailyConversationModel topic,
  ) async {
    try {
      await ref.read(dailyConversationRepositoryProvider).setCurrent(topic.id);
      ref.invalidate(userDailyConversationProvider);
    } catch (_) {}

    final tutorId =
        ref.read(callSessionControllerProvider).activeTutorId ?? 'annie';
    ref
        .read(callSessionControllerProvider.notifier)
        .bindTutor(tutorId, lessonId: topic.id);
    if (!context.mounted) return;
    await CallNavigation.pushSessionPreview(
      context,
      ref,
      tutorId: tutorId,
      lessonId: topic.id,
    );
  }
}

class _DailyConversationTile extends StatelessWidget {
  const _DailyConversationTile({
    required this.topic,
    required this.isCurrent,
    required this.onTap,
  });

  final DailyConversationModel topic;
  final bool isCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (topic.status) {
      LessonProgressStatus.completed => AppTranslations.section(
        'home',
        'lesson_completed',
      ),
      LessonProgressStatus.inProgress => AppTranslations.section(
        'home',
        'lesson_in_progress',
      ),
      LessonProgressStatus.available => AppTranslations.section(
        'home',
        'lesson_in_progress',
      ),
      LessonProgressStatus.locked => AppTranslations.section(
        'home',
        'lesson_locked',
      ),
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
              Text(topic.scenarioEmoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.localizedTitle,
                      style: AppTextStyles.homeScenarioTitle(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${topic.cefrLevel} • ${topic.localizedSubtitle}',
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
