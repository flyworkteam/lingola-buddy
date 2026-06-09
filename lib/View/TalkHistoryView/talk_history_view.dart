import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Utils/locale_time_format.dart';
import 'package:lingola_buddy/Core/Widgets/app_snackbar.dart';
import 'package:lingola_buddy/Core/Widgets/character_card.dart';
import 'package:lingola_buddy/Core/Widgets/delete_conversation_confirm_dialog.dart';
import 'package:lingola_buddy/Core/Widgets/tutor_avatar_image.dart';
import 'package:lingola_buddy/Models/chat_route_args.dart';
import 'package:lingola_buddy/Models/conversation_model.dart';
import 'package:lingola_buddy/Models/tutor_model.dart';
import 'package:lingola_buddy/Riverpod/Controllers/UserProfileController/user_profile_controller.dart';
import 'package:lingola_buddy/Riverpod/Providers/conversation_provider.dart';
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
    ref.watch(userProfileControllerProvider.select((s) => s.uiLanguageCode));
    final messagesAsync = ref.watch(talkHistoryProvider);
    final featured = ref.watch(talkFeaturedTutorsProvider);
    final catalog = ref.watch(tutorsCatalogProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: messagesAsync.when(
          skipLoadingOnReload: true,
          loading: () => _TalkHistoryBody(
            featured: featured,
            messages: const [],
            catalog: catalog,
            chatsLoading: true,
          ),
          error: (_, __) => _TalkHistoryBody(
            featured: featured,
            messages: const [],
            catalog: catalog,
          ),
          data: (messages) => _TalkHistoryBody(
            featured: featured,
            messages: messages,
            catalog: catalog,
          ),
        ),
      ),
    );
  }
}

class _TalkHistoryBody extends StatelessWidget {
  const _TalkHistoryBody({
    required this.featured,
    required this.messages,
    required this.catalog,
    this.chatsLoading = false,
  });

  final List<TutorModel> featured;
  final List<ConversationSummaryModel> messages;
  final List<TutorModel> catalog;
  final bool chatsLoading;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
          child: SizedBox(
            height: constraints.maxHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppTranslations.section('talk', 'history_title'),
                  style: AppTextStyles.homeWelcomeTitle(),
                ),
                if (featured.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _FeaturedTutorsPanel(tutors: featured),
                ],
                const SizedBox(height: 16),
                Text(
                  AppTranslations.section('talk', 'quick_messages'),
                  style: AppTextStyles.homeSectionTitle(),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: chatsLoading
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            color: TalkHistoryView._panelBackground,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : messages.isNotEmpty
                      ? SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: _QuickMessagesPanel(
                            messages: messages,
                            catalog: catalog,
                          ),
                        )
                      : _QuickMessagesEmptyPanel(),
                ),
              ],
            ),
          ),
        );
      },
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
                displayName: tutors[i].localizedDisplayName,
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

class _QuickMessagesPanel extends ConsumerWidget {
  const _QuickMessagesPanel({required this.messages, required this.catalog});

  final List<ConversationSummaryModel> messages;
  final List<TutorModel> catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              _DismissibleConversationTile(
                row: messages[i],
                tutor: _tutorFor(messages[i], catalog),
                onDelete: () async {
                  try {
                    await ref
                        .read(conversationRepositoryProvider)
                        .deleteConversation(messages[i].tutorId);
                    ref.invalidate(talkHistoryProvider);
                  } catch (e) {
                    if (context.mounted) {
                      AppSnackBar.error(e.toString(), context: context);
                    }
                  }
                },
                onTap: () => Navigator.pushNamed(
                  context,
                  '/chat',
                  arguments: ChatRouteArgs(
                    tutorId: messages[i].tutorId,
                    showHistoryShimmer: true,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  TutorModel? _tutorFor(
    ConversationSummaryModel row,
    List<TutorModel> catalog,
  ) {
    return catalog.where((t) => t.id == row.tutorId).firstOrNull;
  }
}

class _DismissibleConversationTile extends StatelessWidget {
  const _DismissibleConversationTile({
    required this.row,
    required this.tutor,
    required this.onTap,
    required this.onDelete,
  });

  final ConversationSummaryModel row;
  final TutorModel? tutor;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  String get _displayName =>
      tutor != null ? tutor!.localizedDisplayName : row.tutorName;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('talk-thread-${row.tutorId}'),
      direction: DismissDirection.endToStart,
      background: const _SwipeDeleteBackground(),
      confirmDismiss: (direction) async {
        final confirmed = await DeleteConversationConfirmDialog.show(
          context,
          tutorName: _displayName,
        );
        return confirmed ?? false;
      },
      onDismissed: (_) => unawaited(onDelete()),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [TalkHistoryView._cardShadow],
        ),
        child: _QuickMessageRow(row: row, tutor: tutor, onTap: onTap),
      ),
    );
  }
}

class _SwipeDeleteBackground extends StatelessWidget {
  const _SwipeDeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppTranslations.section('common', 'delete'),
            style: AppTextStyles.homeCharacterMeta().copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.delete_outline, color: Colors.white, size: 22),
        ],
      ),
    );
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
    required this.tutor,
    required this.onTap,
  });

  final ConversationSummaryModel row;
  final TutorModel? tutor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final timeLabel = LocaleTimeFormat.messageTimeLabel(row.updatedAtIso);
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
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: tutor != null
                      ? TutorAvatarImage(tutor: tutor!)
                      : const ColoredBox(
                          color: Color(0xFFF0F0F0),
                          child: Icon(Icons.person_rounded),
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
                            tutor != null
                                ? tutor!.localizedDisplayName
                                : row.tutorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.notificationCardTitle(),
                          ),
                        ),
                        if (timeLabel != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            timeLabel,
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

class _QuickMessagesEmptyPanel extends StatelessWidget {
  const _QuickMessagesEmptyPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TalkHistoryView._panelBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 72),
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
                style: AppTextStyles.notificationCardBody().copyWith(
                  color: const Color(0xFF96989C),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
