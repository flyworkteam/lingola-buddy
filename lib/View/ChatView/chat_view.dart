import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';
import 'package:lingola_buddy/Core/Utils/duration_format.dart';
import 'package:lingola_buddy/Core/Widgets/app_snackbar.dart';
import 'package:lingola_buddy/Core/Widgets/chat_attachment_sheet.dart';
import 'package:lingola_buddy/Core/Widgets/chat_messages_shimmer.dart';
import 'package:lingola_buddy/Core/Widgets/chat_voice_message_bubble.dart';
import 'package:lingola_buddy/Core/Widgets/tutor_avatar_image.dart';
import 'package:lingola_buddy/Core/Widgets/voice_waveform_bars.dart';
import 'package:lingola_buddy/Core/Widgets/word_shimmer.dart';
import 'package:lingola_buddy/Models/chat_message_model.dart';
import 'package:lingola_buddy/Models/tutor_model.dart';
import 'package:lingola_buddy/Riverpod/Controllers/ChatController/chat_controller.dart';
import 'package:lingola_buddy/Riverpod/Providers/tutors_catalog_provider.dart';
import 'package:lingola_buddy/Services/chat_attachment_service.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatView extends ConsumerStatefulWidget {
  const ChatView({
    super.key,
    required this.tutorId,
    this.showHistoryShimmer = false,
    this.lessonId,
  });

  final String tutorId;
  final bool showHistoryShimmer;
  final String? lessonId;

  ChatSessionKey get _sessionKey => (
        tutorId: tutorId,
        showHistoryShimmer: showHistoryShimmer,
        lessonId: lessonId,
      );

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  ProviderSubscription<ChatState>? _chatSubscription;

  @override
  void initState() {
    super.initState();
    _chatSubscription = ref.listenManual(
      chatControllerProvider(widget._sessionKey),
      (prev, next) {
        if (prev?.messages.length != next.messages.length ||
            prev?.isTyping != next.isTyping) {
          _scrollToBottom();
        }
        if (next.error != null && next.error != prev?.error) {
          AppSnackBar.error(
            next.error!,
            context: context,
            actionLabel: next.errorOpenSettings
                ? AppTranslations.section('chat', 'open_settings')
                : null,
            onAction: next.errorOpenSettings ? openAppSettings : null,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _chatSubscription?.close();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _leaveChat() {
    ref
        .read(chatControllerProvider(widget._sessionKey).notifier)
        .prepareToLeave();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    ref
        .read(chatControllerProvider(widget._sessionKey).notifier)
        .sendUserMessage(text);
    _scrollToBottom();
  }

  Future<void> _pickAndSendAttachment({
    required Future<ChatAttachmentPickResult?> Function() pick,
  }) async {
    final controller = ref.read(
      chatControllerProvider(widget._sessionKey).notifier,
    );
    try {
      final pickResult = await pick();
      if (pickResult == null || !mounted) return;
      await controller.sendAttachment(pickResult);
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(
        AppTranslations.section('chat', 'attach_error'),
        context: context,
      );
    }
  }

  void _openAttachmentSheet() {
    final controller = ref.read(
      chatControllerProvider(widget._sessionKey).notifier,
    );
    ChatAttachmentSheet.show(
      context,
      onPhoto: () =>
          _pickAndSendAttachment(pick: controller.pickImageAttachment),
      onDocument: () =>
          _pickAndSendAttachment(pick: controller.pickDocumentAttachment),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatControllerProvider(widget._sessionKey));
    final controller = ref.read(
      chatControllerProvider(widget._sessionKey).notifier,
    );
    final tutor =
        ref.watch(tutorByIdProvider(widget.tutorId)) ??
        ref.watch(tutorsCatalogProvider).firstOrNull;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          ref
              .read(chatControllerProvider(widget._sessionKey).notifier)
              .prepareToLeave();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _ChatHeader(
                title: controller.tutorDisplayName,
                onBack: _leaveChat,
              ),
              Expanded(
                child: chat.isLoadingHistory && chat.showHistoryShimmer
                    ? const ChatMessagesShimmerList()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        addAutomaticKeepAlives: false,
                        addRepaintBoundaries: true,
                        itemCount:
                            chat.messages.length + (chat.isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= chat.messages.length) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _TypingIndicatorRow(tutor: tutor),
                            );
                          }
                          final message = chat.messages[index];
                          if (message.isUser) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _UserMessageRow(message: message),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TutorMessageRow(
                              message: message,
                              tutor: tutor,
                              selection: chat.selection,
                              wordTranslations:
                                  chat.translationsFor(message.id) ?? const {},
                              isTranslating: chat.isTranslating,
                              onWordTap: (word) => controller.selectWord(
                                messageId: message.id,
                                word: word,
                              ),
                              onTranslate: controller.translateSelection,
                              onSpeak: controller.speakSelection,
                            ),
                          );
                        },
                      ),
              ),
              if (chat.isRecording)
                _VoiceStatusBar(
                  voiceLevel: chat.voiceLevel,
                  recordingDuration: chat.recordingDuration,
                  onCancel: () => controller.cancelVoiceRecording(),
                ),
              _ChatInputBar(
                controller: _inputController,
                sendEnabled: !chat.isTyping && !chat.isTranscribing,
                isRecording: chat.isRecording,
                isTranscribing: chat.isTranscribing,
                isTyping: chat.isTyping,
                onSend: chat.isRecording
                    ? () => controller.finishVoiceRecording()
                    : _send,
                onPlusTap: _openAttachmentSheet,
                onMicTap: () => controller.toggleVoiceRecording(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _IterableFirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 48),
            icon: SvgPicture.asset(
              'assets/icons/arrow_left.svg',
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.chatTitle(),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _TutorMessageRow extends StatelessWidget {
  const _TutorMessageRow({
    required this.message,
    required this.tutor,
    required this.selection,
    required this.wordTranslations,
    required this.isTranslating,
    required this.onWordTap,
    required this.onTranslate,
    required this.onSpeak,
  });

  final ChatMessage message;
  final TutorModel? tutor;
  final ChatSelection? selection;
  final Map<String, String> wordTranslations;
  final bool isTranslating;
  final ValueChanged<String> onWordTap;
  final VoidCallback onTranslate;
  final VoidCallback onSpeak;

  bool get _hasSelection =>
      selection != null && selection!.messageId == message.id;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChatAvatar(tutor: tutor),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: _TutorBubble(
                  messageId: message.id,
                  text: message.text,
                  selection: selection,
                  wordTranslations: wordTranslations,
                  isTranslating: isTranslating,
                  onWordTap: onWordTap,
                ),
              ),
              if (_hasSelection) ...[
                const SizedBox(width: 8),
                _ChatActionButton(
                  iconAsset: 'assets/icons/translate.svg',
                  onTap: onTranslate,
                  iconColor: AppColors.brandPrimary,
                  showBorder: false,
                ),
                const SizedBox(width: 8),
                _ChatActionButton(
                  iconAsset: 'assets/icons/ic_voice.svg',
                  onTap: onSpeak,
                  iconColor: const Color(0xFFA1A4B7),
                  borderColor: const Color(0xFFA1A4B7),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _UserMessageRow extends StatelessWidget {
  const _UserMessageRow({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final attachment = message.attachment;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.brandPrimary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: attachment == null
                    ? Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          message.text,
                          style: AppTextStyles.chatUserMessage(),
                        ),
                      )
                    : attachment.isVoice
                    ? ChatVoiceMessageBubble(
                        path: attachment.localPath,
                        duration:
                            attachment.duration ?? const Duration(seconds: 1),
                      )
                    : attachment.isImage
                    ? _UserImageAttachment(path: attachment.localPath)
                    : _UserDocumentAttachment(
                        name: attachment.displayName,
                        caption: message.text,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UserImageAttachment extends StatelessWidget {
  const _UserImageAttachment({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220, maxHeight: 260),
      child: file.existsSync()
          ? Image.file(file, fit: BoxFit.cover)
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                AppTranslations.section('chat', 'attach_error'),
                style: AppTextStyles.chatUserMessage(),
              ),
            ),
    );
  }
}

class _UserDocumentAttachment extends StatelessWidget {
  const _UserDocumentAttachment({required this.name, required this.caption});

  final String name;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.chatUserMessage().copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.chatUserMessage().copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorBubble extends StatelessWidget {
  const _TutorBubble({
    required this.messageId,
    required this.text,
    required this.selection,
    required this.wordTranslations,
    required this.isTranslating,
    required this.onWordTap,
  });

  final String messageId;
  final String text;
  final ChatSelection? selection;
  final Map<String, String> wordTranslations;
  final bool isTranslating;
  final ValueChanged<String> onWordTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _SelectableTutorText(
          text: text,
          messageId: messageId,
          selection: selection,
          wordTranslations: wordTranslations,
          isTranslating: isTranslating,
          onWordTap: onWordTap,
        ),
      ),
    );
  }
}

class _SelectableTutorText extends StatelessWidget {
  const _SelectableTutorText({
    required this.text,
    required this.messageId,
    required this.selection,
    required this.wordTranslations,
    required this.isTranslating,
    required this.onWordTap,
  });

  final String text;
  final String messageId;
  final ChatSelection? selection;
  final Map<String, String> wordTranslations;
  final bool isTranslating;
  final ValueChanged<String> onWordTap;

  static final _tokenPattern = RegExp(r'\S+|\s+');

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppTextStyles.chatTutorMessage();
    final children = <Widget>[];

    for (final match in _tokenPattern.allMatches(text)) {
      final part = match.group(0)!;
      if (RegExp(r'^\s+$').hasMatch(part)) {
        children.add(Text(part, style: baseStyle));
        continue;
      }

      final cleaned = part.replaceAll(
        RegExp(r"[^\p{L}'\-]", unicode: true),
        '',
      );
      if (cleaned.isEmpty) {
        children.add(Text(part, style: baseStyle));
        continue;
      }

      final key = cleaned.toLowerCase();
      final applied = wordTranslations[key];
      final isThisMessage = selection?.messageId == messageId;
      final isThisWord = isThisMessage && selection!.word.toLowerCase() == key;
      final isTranslatingThis = isTranslating && isThisWord;

      if (applied != null) {
        final display = inlineTranslatedPart(part, applied);
        children.add(
          TranslatedWordChip(text: display, onTap: () => onWordTap(cleaned)),
        );
        continue;
      }

      if (isTranslatingThis) {
        children.add(WordShimmer(child: Text(part, style: baseStyle)));
        continue;
      }

      final isSelected = isThisWord;

      children.add(
        GestureDetector(
          onTap: () => onWordTap(cleaned),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            decoration: isSelected
                ? BoxDecoration(
                    color: AppColors.brandPrimary,
                    borderRadius: BorderRadius.circular(4),
                  )
                : null,
            child: Text(
              part,
              style: baseStyle.copyWith(
                color: isSelected ? Colors.white : const Color(0xFF96989C),
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({this.tutor});

  final TutorModel? tutor;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFFF0F0F0),
      child: tutor != null
          ? ClipOval(
              child: TutorAvatarImage(tutor: tutor!, width: 36, height: 36),
            )
          : const Icon(Icons.person_rounded, size: 20),
    );
  }
}

class _ChatActionButton extends StatelessWidget {
  const _ChatActionButton({
    required this.iconAsset,
    required this.onTap,
    required this.iconColor,
    this.borderColor = const Color(0xFFA1A4B7),
    this.showBorder = true,
    this.size = 40,
    this.iconSize = 24,
  });

  final String iconAsset;
  final VoidCallback onTap;
  final Color iconColor;
  final Color borderColor;
  final bool showBorder;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onTap,
        child: Center(
          child: SvgPicture.asset(
            iconAsset,
            width: iconSize,
            height: iconSize,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}

class _TypingIndicatorRow extends StatelessWidget {
  const _TypingIndicatorRow({required this.tutor});

  final TutorModel? tutor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChatAvatar(tutor: tutor),
        const SizedBox(width: 8),
        const _TypingBubble(),
      ],
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  static const Color _dotLarge = Color(0xFF96989C);
  static const Color _dotSmall = Color(0x8096989C);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final t = (_controller.value + i * 0.2) % 1.0;
                final scale = 0.6 + (t < 0.5 ? t * 0.8 : (1 - t) * 0.8);
                final scaleNorm = ((scale - 0.6) / 0.4).clamp(0.0, 1.0);
                final color = Color.lerp(_dotSmall, _dotLarge, scaleNorm)!;
                return Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class _VoiceStatusBar extends StatelessWidget {
  const _VoiceStatusBar({
    required this.voiceLevel,
    required this.recordingDuration,
    required this.onCancel,
  });

  final double voiceLevel;
  final Duration recordingDuration;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final timerLabel = DurationFormat.mmSs(recordingDuration);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: AppColors.brandPrimary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.brandPrimary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFE53935),
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: VoiceWaveformBars(
                    level: voiceLevel,
                    height: 32,
                    barCount: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 48,
              child: Text(
                timerLabel,
                textAlign: TextAlign.right,
                style: AppTextStyles.chatUserMessage().copyWith(
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Material(
              color: Colors.white,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onCancel,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    Icons.close_rounded,
                    size: 22,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.onSend,
    required this.sendEnabled,
    required this.isRecording,
    required this.isTranscribing,
    required this.isTyping,
    required this.onPlusTap,
    required this.onMicTap,
  });

  static const _barBorder = Color(0x1A000000);
  static const _iconMuted = Color(0xFF96989C);
  static const _barHeight = 48.0;
  static const _sendSize = 36.0;

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool sendEnabled;
  final bool isRecording;
  final bool isTranscribing;
  final bool isTyping;
  final VoidCallback onPlusTap;
  final VoidCallback onMicTap;

  bool get _micEnabled => isRecording || (!isTranscribing && !isTyping);
  bool get _plusEnabled => sendEnabled && !isRecording;
  bool get _sendActive => sendEnabled || isRecording;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _InputPlusButton(
              onTap: _plusEnabled ? onPlusTap : null,
              enabled: _plusEnabled,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: _barHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _barBorder),
                ),
                padding: const EdgeInsets.only(left: 16, right: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        enabled: sendEnabled,
                        style: AppTextStyles.chatUserMessage().copyWith(
                          color: const Color(0xFF171717),
                        ),
                        cursorColor: AppColors.brandPrimary,
                        decoration: InputDecoration(
                          hintText: AppTranslations.section(
                            'chat',
                            'type_message',
                          ),
                          hintStyle: AppTextStyles.chatInputHint(),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        textAlignVertical: TextAlignVertical.center,
                        textInputAction: TextInputAction.send,
                        onSubmitted: sendEnabled ? (_) => onSend() : null,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _micEnabled
                            ? () {
                                HapticFeedback.mediumImpact();
                                onMicTap();
                              }
                            : null,
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(
                            child: _MicIcon(
                              active: isRecording,
                              muted: !_micEnabled,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CircleIconButton(
                      color: AppColors.brandPrimary,
                      size: _sendSize,
                      iconAsset: 'assets/icons/up_arrow.svg',
                      iconColor: Colors.white,
                      iconSizeFactor: 0.5,
                      onTap: _sendActive ? onSend : null,
                      dimmed: !_sendActive,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputPlusButton extends StatelessWidget {
  const _InputPlusButton({required this.onTap, this.enabled = true});

  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: Container(
            width: _ChatInputBar._barHeight,
            height: _ChatInputBar._barHeight,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: _ChatInputBar._barBorder),
            ),
            child: const Icon(
              Icons.add_rounded,
              color: AppColors.brandPrimary,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _MicIcon extends StatelessWidget {
  const _MicIcon({this.active = false, this.muted = false});

  final bool active;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? AppColors.brandPrimary
        : muted
        ? _ChatInputBar._iconMuted.withValues(alpha: 0.45)
        : _ChatInputBar._iconMuted;

    return SvgPicture.asset(
      'assets/icons/microphone.svg',
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.color,
    required this.onTap,
    this.size = 48,
    this.icon,
    this.iconAsset,
    this.iconColor,
    this.iconSizeFactor = 0.6,
    this.dimmed = false,
  }) : assert(icon != null || iconAsset != null);

  final Color color;
  final double size;
  final VoidCallback? onTap;
  final IconData? icon;
  final String? iconAsset;
  final Color? iconColor;
  final double iconSizeFactor;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final iconSize = size * iconSizeFactor;
    final button = Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: icon != null
                ? Icon(icon, color: iconColor ?? Colors.white, size: iconSize)
                : SvgPicture.asset(
                    iconAsset!,
                    width: iconSize,
                    height: iconSize,
                    colorFilter: ColorFilter.mode(
                      iconColor ?? Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
          ),
        ),
      ),
    );
    return Opacity(opacity: dimmed ? 0.45 : 1, child: button);
  }
}
