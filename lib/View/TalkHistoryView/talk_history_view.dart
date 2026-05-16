import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Widgets/character_card.dart';
import 'package:lingola_buddy/Models/conversation_model.dart';
import 'package:lingola_buddy/Models/tutor_model.dart';
import 'package:lingola_buddy/Riverpod/Providers/talk_history_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/tutors_catalog_provider.dart';

class TalkHistoryView extends ConsumerWidget {
  const TalkHistoryView({super.key});

  static const Color _panelBackground = Color(0xFFF6F6F6);

  static final BoxShadow _cardShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.06),
    blurRadius: 8,
    offset: const Offset(0, 2),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(talkHistoryProvider);
    final featured = ref.watch(talkFeaturedTutorsProvider);
    final catalog = ref.watch(tutorsCatalogProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: messages.isEmpty && featured.isEmpty
            ? _TalkHistoryEmptyState()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                children: [
                  Text(
                    AppTranslations.section('talk', 'history_title'),
                    style: AppTextStyles.homeWelcomeTitle(),
                  ),
                  if (featured.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _FeaturedTutorsPanel(tutors: featured),
                  ],
                  if (messages.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      AppTranslations.section('talk', 'quick_messages'),
                      style: AppTextStyles.homeSectionTitle(),
                    ),
                    const SizedBox(height: 8),
                    _QuickMessagesPanel(
                      messages: messages.take(2).toList(),
                      catalog: catalog,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _FeaturedTutorsPanel extends StatelessWidget {
  const _FeaturedTutorsPanel({required this.tutors});

  final List<TutorModel> tutors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: CharacterCard.designHeight,
      child: Row(
        children: [
          for (var i = 0; i < tutors.length && i < 2; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: CharacterCard(
                tutor: tutors[i],
                displayName: AppTranslations.section('tudor', tutors[i].id),
                buttonLabel: AppTranslations.section('tudor', 'start_talking'),
                width: null,
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/tutor',
                  arguments: tutors[i].id,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickMessagesPanel extends StatelessWidget {
  const _QuickMessagesPanel({required this.messages, required this.catalog});

  final List<ConversationSummaryModel> messages;
  final List<TutorModel> catalog;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TalkHistoryView._panelBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < messages.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [TalkHistoryView._cardShadow],
                ),
                child: _QuickMessageRow(
                  row: messages[i],
                  avatarPath: _avatarFor(messages[i], catalog),
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/chat',
                    arguments: messages[i].tutorId,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _avatarFor(ConversationSummaryModel row, List<TutorModel> catalog) {
    final tutor = catalog.where((t) => t.id == row.tutorId).firstOrNull;
    return tutor?.avatarAssetPath ?? 'assets/images/avatar_1.png';
  }
}

extension _CatalogFirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final i = iterator;
    return i.moveNext() ? i.current : null;
  }
}

class _QuickMessageRow extends StatelessWidget {
  const _QuickMessageRow({
    required this.row,
    required this.avatarPath,
    required this.onTap,
  });

  final ConversationSummaryModel row;
  final String avatarPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  avatarPath,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) => ColoredBox(
                    color: const Color(0xFFF0F0F0),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.person, color: Colors.grey.shade400),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            row.tutorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.notificationCardTitle(),
                          ),
                        ),
                        if (row.timeLabel != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            row.timeLabel!,
                            style: AppTextStyles.homeCharacterMeta().copyWith(
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF96989C),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (row.lastMessagePreview != null &&
                        row.lastMessagePreview!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        row.lastMessagePreview!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.notificationCardBody().copyWith(
                          color: const Color(0xFF96989C),
                          height: 20 / 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TalkHistoryEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppTranslations.section('talk', 'empty_title'),
              style: AppTextStyles.notificationCardTitle(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppTranslations.section('talk', 'empty_desc'),
              style: AppTextStyles.notificationCardBody(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
