import 'dart:async';
import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Core/Config/openai_config.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Utils/chat_lesson_resolver.dart';
import 'package:lingola_buddy/Models/chat_lesson_context.dart';
import 'package:lingola_buddy/Models/chat_message_model.dart';
import 'package:lingola_buddy/Models/tutor_model.dart';
import 'package:lingola_buddy/Repositories/conversation_repository.dart';
import 'package:lingola_buddy/Riverpod/Controllers/CallSessionController/call_session_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/UserProfileController/user_profile_controller.dart';
import 'package:lingola_buddy/Riverpod/Providers/conversation_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/talk_history_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/tutors_catalog_provider.dart';
import 'package:lingola_buddy/Models/chat_attachment_model.dart';
import 'package:path/path.dart' as p;
import 'package:lingola_buddy/Services/chat_attachment_service.dart';
import 'package:lingola_buddy/Services/chat_tts_service.dart';
import 'package:lingola_buddy/Services/chat_voice_playback_service.dart';
import 'package:lingola_buddy/Services/chat_voice_recorder_service.dart';
import 'package:lingola_buddy/Services/chat_prompt_builder.dart';
import 'package:lingola_buddy/Services/openai_chat_service.dart';

final openAiChatServiceProvider = Provider<OpenAiChatService>((ref) {
  final service = OpenAiChatService();
  ref.onDispose(service.dispose);
  return service;
});

final chatTtsServiceProvider = Provider<ChatTtsService>((ref) {
  final service = ChatTtsService();
  ref.onDispose(service.dispose);
  return service;
});

final chatVoiceRecorderProvider = Provider<ChatVoiceRecorderService>((ref) {
  final service = ChatVoiceRecorderService();
  ref.onDispose(service.dispose);
  return service;
});

final chatAttachmentServiceProvider = Provider<ChatAttachmentService>((ref) {
  return ChatAttachmentService();
});

class ChatSelection {
  const ChatSelection({
    required this.messageId,
    required this.word,
  });

  final String messageId;
  final String word;
}

/// Sohbet oturumu anahtarı — [showHistoryShimmer] geçmişten açılışta true.
typedef ChatSessionKey = ({
  String tutorId,
  bool showHistoryShimmer,
  String? lessonId,
});

class ChatState {
  const ChatState({
    required this.messages,
    this.isLoadingHistory = false,
    this.showHistoryShimmer = false,
    this.isTyping = false,
    this.selection,
    this.wordTranslation,
    this.isTranslating = false,
    this.isSpeaking = false,
    this.isRecording = false,
    this.isTranscribing = false,
    this.voiceLevel = 0,
    this.recordingDuration = Duration.zero,
    this.messageWordTranslations = const {},
    this.error,
    this.errorOpenSettings = false,
  });

  final List<ChatMessage> messages;
  final bool isLoadingHistory;
  final bool showHistoryShimmer;
  final bool isTyping;
  final ChatSelection? selection;
  final String? wordTranslation;
  final bool isTranslating;
  final bool isSpeaking;
  final bool isRecording;
  final bool isTranscribing;
  final double voiceLevel;
  final Duration recordingDuration;

  /// messageId → (orijinal kelime küçük harf → çeviri)
  final Map<String, Map<String, String>> messageWordTranslations;
  final String? error;
  final bool errorOpenSettings;

  Map<String, String>? translationsFor(String messageId) =>
      messageWordTranslations[messageId];

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoadingHistory,
    bool? showHistoryShimmer,
    bool? isTyping,
    ChatSelection? selection,
    String? wordTranslation,
    bool? isTranslating,
    bool? isSpeaking,
    bool? isRecording,
    bool? isTranscribing,
    double? voiceLevel,
    Duration? recordingDuration,
    Map<String, Map<String, String>>? messageWordTranslations,
    String? error,
    bool? errorOpenSettings,
    bool clearSelection = false,
    bool clearTranslation = false,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      showHistoryShimmer: showHistoryShimmer ?? this.showHistoryShimmer,
      isTyping: isTyping ?? this.isTyping,
      selection: clearSelection ? null : (selection ?? this.selection),
      wordTranslation:
          clearTranslation ? null : (wordTranslation ?? this.wordTranslation),
      isTranslating: isTranslating ?? this.isTranslating,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isRecording: isRecording ?? this.isRecording,
      isTranscribing: isTranscribing ?? this.isTranscribing,
      voiceLevel: voiceLevel ?? this.voiceLevel,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      messageWordTranslations:
          messageWordTranslations ?? this.messageWordTranslations,
      error: clearError ? null : (error ?? this.error),
      errorOpenSettings:
          clearError ? false : (errorOpenSettings ?? this.errorOpenSettings),
    );
  }
}

class ChatController extends StateNotifier<ChatState> {
  ChatController({
    required this.tutorId,
    required this.tutor,
    required this.uiLanguageCode,
    required this.lessonContext,
    required ConversationRepository conversationRepo,
    required OpenAiChatService openAi,
    required ChatTtsService tts,
    required ChatVoiceRecorderService voiceRecorder,
    required ChatAttachmentService attachments,
    this.showHistoryShimmer = false,
    this.onThreadUpdated,
  })  : _conversationRepo = conversationRepo,
        _openAi = openAi,
        _tts = tts,
        _voiceRecorder = voiceRecorder,
        _attachments = attachments,
        super(
          ChatState(
            messages: showHistoryShimmer
                ? const []
                : _seedMessages(
                    tutor: tutor,
                    uiLanguageCode: uiLanguageCode,
                    lessonContext: lessonContext,
                  ),
            isLoadingHistory: true,
            showHistoryShimmer: showHistoryShimmer,
          ),
        ) {
    _displayName = tutor.localizedDisplayName;
    unawaited(_restoreMessages());
  }

  final String tutorId;
  final TutorModel tutor;
  final String uiLanguageCode;
  final ChatLessonContext lessonContext;
  final ConversationRepository _conversationRepo;
  final bool showHistoryShimmer;
  final OpenAiChatService _openAi;
  final ChatTtsService _tts;
  final ChatVoiceRecorderService _voiceRecorder;
  final ChatAttachmentService _attachments;
  final Map<String, String> _translationCache = {};
  final Map<String, String> _englishSpeechCache = {};
  StreamSubscription<double>? _voiceLevelSub;
  Timer? _recordingTick;
  late final String _displayName;
  final VoidCallback? onThreadUpdated;

  Future<void> _restoreMessages() async {
    try {
      final hasHistory = await _conversationRepo.hasMessages(tutor.id);
      if (!hasHistory) {
        state = state.copyWith(
          messages: _seedMessages(
            tutor: tutor,
            uiLanguageCode: uiLanguageCode,
            lessonContext: lessonContext,
          ),
          isLoadingHistory: false,
        );
        return;
      }

      final saved = await _conversationRepo.fetchMessages(tutor.id);
      state = state.copyWith(
        messages: saved.isNotEmpty
            ? saved
            : _seedMessages(
                tutor: tutor,
                uiLanguageCode: uiLanguageCode,
                lessonContext: lessonContext,
              ),
        isLoadingHistory: false,
      );
    } catch (_) {
      state = state.copyWith(
        messages: state.messages.isEmpty
            ? _seedMessages(
                tutor: tutor,
                uiLanguageCode: uiLanguageCode,
                lessonContext: lessonContext,
              )
            : state.messages,
        isLoadingHistory: false,
      );
    }
  }

  Future<void> _persistMessage(ChatMessage message) async {
    if (message.id.startsWith('seed-')) return;
    try {
      await _conversationRepo.saveMessage(
        tutorId: tutor.id,
        message: message,
      );
    } catch (_) {}
  }

  /// Geri çıkmadan önce ses/TTS kaynaklarını bırak — await yok, pop'u bloklamaz.
  void prepareToLeave() {
    unawaited(_tts.stop());
    unawaited(ChatVoicePlaybackService.stopPlayback());
    _stopRecordingTick();
    unawaited(_voiceLevelSub?.cancel());
    _voiceLevelSub = null;
    unawaited(_voiceRecorder.cancel());
    if (state.isRecording ||
        state.isTranscribing ||
        state.isSpeaking ||
        state.selection != null) {
      state = state.copyWith(
        isRecording: false,
        isTranscribing: false,
        isSpeaking: false,
        clearSelection: true,
        clearTranslation: true,
      );
    }
  }

  void _startRecordingTick() {
    _recordingTick?.cancel();
    _recordingTick = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!state.isRecording) return;
      final elapsed = _voiceRecorder.elapsed;
      if (elapsed != null) {
        state = state.copyWith(recordingDuration: elapsed);
      }
    });
  }

  void _stopRecordingTick() {
    _recordingTick?.cancel();
    _recordingTick = null;
  }

  String get tutorDisplayName => _displayName;

  static List<ChatMessage> _seedMessages({
    required TutorModel tutor,
    required String uiLanguageCode,
    required ChatLessonContext lessonContext,
  }) {
    final name = tutor.localizedDisplayName;
    final text = ChatPromptBuilder.buildSeedGreeting(
      tutorName: name,
      uiLanguageCode: uiLanguageCode,
      lessonContext: lessonContext,
    );
    return [
      ChatMessage(
        id: 'seed-1',
        role: ChatMessageRole.assistant,
        text: text,
      ),
    ];
  }

  void selectWord({required String messageId, required String word}) {
    final cleaned = word.replaceAll(RegExp(r"[^\p{L}'\-]", unicode: true), '');
    if (cleaned.isEmpty) return;

    state = state.copyWith(
      selection: ChatSelection(messageId: messageId, word: cleaned),
      clearTranslation: true,
      isTranslating: false,
      clearError: true,
    );
  }

  void clearSelection() {
    unawaited(_tts.stop());
    state = state.copyWith(
      clearSelection: true,
      clearTranslation: true,
      isSpeaking: false,
    );
  }

  String get _wordTranslationTargetLabel =>
      ChatPromptBuilder.uiLanguageLabel(uiLanguageCode);

  void _applyWordTranslation(
    ChatSelection selection,
    String cacheKey,
    String translation,
  ) {
    final messageId = selection.messageId;
    final perMessage = Map<String, String>.from(
      state.messageWordTranslations[messageId] ?? {},
    );
    perMessage[cacheKey] = translation;
    final all = Map<String, Map<String, String>>.from(
      state.messageWordTranslations,
    );
    all[messageId] = perMessage;
    state = state.copyWith(
      wordTranslation: translation,
      messageWordTranslations: all,
    );
  }

  Future<String?> _fetchAndStoreTranslation(ChatSelection selection) async {
    final cacheKey = selection.word.toLowerCase();
    final inMessage =
        state.messageWordTranslations[selection.messageId]?[cacheKey];
    if (inMessage != null) return inMessage;

    final cached = _translationCache[cacheKey];
    if (cached != null) {
      if (state.selection?.word.toLowerCase() == cacheKey) {
        _applyWordTranslation(selection, cacheKey, cached);
      }
      return cached;
    }

    final translation = await _openAi.translateWord(
      word: selection.word,
      targetLanguageLabel: _wordTranslationTargetLabel,
    );
    _translationCache[cacheKey] = translation;
    if (state.selection?.word.toLowerCase() != cacheKey) return null;
    _applyWordTranslation(selection, cacheKey, translation);
    return translation;
  }

  Future<void> translateSelection() async {
    final selection = state.selection;
    if (selection == null || state.isTranslating) return;

    final cacheKey = selection.word.toLowerCase();
    if (state.messageWordTranslations[selection.messageId]?[cacheKey] !=
        null) {
      return;
    }

    final cached = _translationCache[cacheKey];
    if (cached != null) {
      _applyWordTranslation(selection, cacheKey, cached);
      return;
    }

    state = state.copyWith(isTranslating: true, clearError: true);
    try {
      await _fetchAndStoreTranslation(selection);
    } catch (e) {
      if (state.selection?.word.toLowerCase() != cacheKey) return;
      state = state.copyWith(error: e.toString());
    } finally {
      if (state.selection?.word.toLowerCase() == cacheKey) {
        state = state.copyWith(isTranslating: false);
      }
    }
  }

  /// Seslendirme metni: her zaman İngilizce kelime (çeviri haritası veya API).
  Future<String> _resolveEnglishWordForSpeech(ChatSelection selection) async {
    final token = selection.word.trim();
    if (token.isEmpty) return token;

    final key = token.toLowerCase();
    final perMessage = state.messageWordTranslations[selection.messageId];

    // Harita: İngilizce anahtar → yerel çeviri (ör. just → sadece)
    if (perMessage != null) {
      if (perMessage.containsKey(key)) {
        return token;
      }
      for (final entry in perMessage.entries) {
        if (entry.value.toLowerCase() == key) {
          return entry.key;
        }
      }
    }

    for (final entry in _translationCache.entries) {
      if (entry.value.toLowerCase() == key) {
        return entry.key;
      }
    }

    final cached = _englishSpeechCache[key];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    if (!OpenAiConfig.isConfigured) {
      return token;
    }

    try {
      final english = await _openAi.translateWordToEnglish(word: token);
      final trimmed = english.trim();
      if (trimmed.isNotEmpty) {
        _englishSpeechCache[key] = trimmed;
        return trimmed;
      }
    } catch (_) {}

    return token;
  }

  Future<void> speakSelection() async {
    final selection = state.selection;
    if (selection == null || state.isSpeaking) return;

    state = state.copyWith(isSpeaking: true, clearError: true);
    try {
      final englishWord = await _resolveEnglishWordForSpeech(selection);
      if (englishWord.isEmpty) return;
      if (state.selection?.messageId != selection.messageId ||
          state.selection?.word.toLowerCase() != selection.word.toLowerCase()) {
        return;
      }
      await _tts.speak(englishWord, languageCode: 'en');
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      if (state.selection?.messageId == selection.messageId &&
          state.selection?.word.toLowerCase() == selection.word.toLowerCase()) {
        state = state.copyWith(isSpeaking: false);
      }
    }
  }

  Future<void> startVoiceRecording() async {
    if (state.isTyping ||
        state.isRecording ||
        state.isTranscribing) {
      return;
    }

    if (!OpenAiConfig.isConfigured) {
      state = state.copyWith(
        error: AppTranslations.section('chat', 'api_missing'),
      );
      return;
    }

    try {
      await _tts.stop();
    } catch (_) {}

    try {
      await _voiceRecorder.start();
      if (!await _voiceRecorder.isRecordingActive) {
        state = state.copyWith(
          error: AppTranslations.section('chat', 'voice_record_failed'),
        );
        return;
      }
      _voiceLevelSub?.cancel();
      _voiceLevelSub = _voiceRecorder.amplitudeStream.listen((level) {
        if (state.isRecording) {
          state = state.copyWith(voiceLevel: level);
        }
      });
      _startRecordingTick();
      state = state.copyWith(
        isRecording: true,
        voiceLevel: 0.12,
        recordingDuration: Duration.zero,
        clearError: true,
        errorOpenSettings: false,
      );
    } on ChatVoiceRecorderException catch (e) {
      state = state.copyWith(
        error: e.message,
        errorOpenSettings: e.openSettings,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleVoiceRecording() async {
    if (state.isRecording) {
      await finishVoiceRecording();
    } else {
      await startVoiceRecording();
    }
  }

  Future<void> cancelVoiceRecording() async {
    if (!state.isRecording && !await _voiceRecorder.isRecordingActive) return;
    _stopRecordingTick();
    _voiceLevelSub?.cancel();
    _voiceLevelSub = null;
    await _voiceRecorder.cancel();
    state = state.copyWith(
      isRecording: false,
      isTranscribing: false,
      voiceLevel: 0,
      recordingDuration: Duration.zero,
    );
  }

  Future<void> finishVoiceRecording() async {
    if (!state.isRecording && !await _voiceRecorder.isRecordingActive) return;

    final recordedFor =
        _voiceRecorder.elapsed ?? state.recordingDuration;

    _stopRecordingTick();
    _voiceLevelSub?.cancel();
    _voiceLevelSub = null;
    state = state.copyWith(
      isRecording: false,
      voiceLevel: 0,
      recordingDuration: Duration.zero,
      clearError: true,
    );

    String? path;
    try {
      path = await _voiceRecorder.stop();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return;
    }

    if (path == null || path.isEmpty) {
      state = state.copyWith(
        error: AppTranslations.section('chat', 'voice_record_failed'),
      );
      return;
    }

    final file = File(path);
    if (!await file.exists() || await file.length() == 0) {
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
      state = state.copyWith(
        error: AppTranslations.section('chat', 'voice_record_failed'),
      );
      return;
    }

    try {
      final persisted = await _voiceRecorder.persistRecording(path);
      final duration = recordedFor.inMilliseconds > 0
          ? recordedFor
          : const Duration(seconds: 1);

      await _dispatchUserMessage(
        ChatMessage(
          id: 'u-${DateTime.now().microsecondsSinceEpoch}',
          role: ChatMessageRole.user,
          text: AppTranslations.section('chat', 'sent_voice'),
          attachment: ChatAttachment(
            kind: ChatAttachmentKind.voice,
            localPath: persisted,
            displayName: p.basename(persisted),
            duration: duration,
          ),
        ),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<ChatAttachmentPickResult?> pickImageAttachment() =>
      _attachments.pickImageFromGallery();

  Future<ChatAttachmentPickResult?> pickDocumentAttachment() =>
      _attachments.pickDocument();

  Future<void> sendAttachment(ChatAttachmentPickResult pick) async {
    final label = pick.kind == ChatAttachmentKind.image
        ? AppTranslations.section('chat', 'sent_photo')
        : AppTranslations.section('chat', 'sent_document_named')
            .replaceAll('{name}', pick.displayName);

    await _dispatchUserMessage(
      ChatMessage(
        id: 'u-${DateTime.now().microsecondsSinceEpoch}',
        role: ChatMessageRole.user,
        text: label,
        attachment: ChatAttachment(
          kind: pick.kind,
          localPath: pick.localPath,
          displayName: pick.displayName,
        ),
      ),
    );
  }

  Future<void> sendUserMessage(String raw) async {
    final text = raw.trim();
    if (text.isEmpty) return;

    await _dispatchUserMessage(
      ChatMessage(
        id: 'u-${DateTime.now().microsecondsSinceEpoch}',
        role: ChatMessageRole.user,
        text: text,
      ),
    );
  }

  Future<void> _dispatchUserMessage(ChatMessage userMsg) async {
    final historyWithUser = [...state.messages, userMsg];

    state = state.copyWith(
      messages: historyWithUser,
      isTyping: true,
      clearSelection: true,
      clearTranslation: true,
      isSpeaking: false,
      clearError: true,
    );

    unawaited(_persistMessage(userMsg));

    try {
      await _tts.stop();
    } catch (_) {}

    try {
      final reply = await _openAi
          .sendTutorReply(
            tutorName: _displayName,
            tutorBio: tutor.bio ?? '',
            history: historyWithUser,
            uiLanguageCode: uiLanguageCode,
            lessonContext: lessonContext,
          )
          .timeout(const Duration(seconds: 45));

      final assistantMsg = ChatMessage(
        id: 'a-${DateTime.now().microsecondsSinceEpoch}',
        role: ChatMessageRole.assistant,
        text: reply,
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMsg],
        isTyping: false,
      );
      unawaited(_persistMessage(assistantMsg));
    } on TimeoutException {
      state = state.copyWith(
        isTyping: false,
        error: 'Yanıt zaman aşımına uğradı. Tekrar deneyin.',
      );
    } catch (e) {
      state = state.copyWith(
        isTyping: false,
        error: e.toString(),
      );
    }
  }

  @override
  void dispose() {
    _stopRecordingTick();
    _voiceLevelSub?.cancel();
    unawaited(_tts.stop());
    unawaited(_voiceRecorder.cancel());
    unawaited(ChatVoicePlaybackService.stopPlayback());
    final refresh = onThreadUpdated;
    if (refresh != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) => refresh());
    }
    super.dispose();
  }
}

final chatControllerProvider = StateNotifierProvider.autoDispose
    .family<ChatController, ChatState, ChatSessionKey>((ref, key) {
      final tutors = ref.watch(tutorsCatalogProvider);
      if (tutors.isEmpty) {
        throw StateError('Tutor catalog is empty');
      }
      final tutor = tutors
          .where((t) => t.id == key.tutorId)
          .cast<TutorModel?>()
          .firstOrNull;
      final resolved = tutor ?? tutors.first;
      final uiLanguageCode = ref.watch(
        userProfileControllerProvider.select((s) => s.uiLanguageCode),
      );
      final resolvedLessonId = resolveChatLessonId(
        ref,
        explicitLessonId: key.lessonId,
        tutorId: key.tutorId,
      );
      final lessonContext = resolveChatLessonContext(
        ref,
        lessonId: resolvedLessonId,
      );
      final controller = ChatController(
        tutorId: key.tutorId,
        tutor: resolved,
        uiLanguageCode: uiLanguageCode,
        lessonContext: lessonContext,
        conversationRepo: ref.watch(conversationRepositoryProvider),
        showHistoryShimmer: key.showHistoryShimmer,
        openAi: ref.watch(openAiChatServiceProvider),
        tts: ref.watch(chatTtsServiceProvider),
        voiceRecorder: ref.watch(chatVoiceRecorderProvider),
        attachments: ref.watch(chatAttachmentServiceProvider),
        onThreadUpdated: () => ref.invalidate(talkHistoryProvider),
      );
      Future.microtask(() {
        ref.read(callSessionControllerProvider.notifier).bindTutor(
              key.tutorId,
              lessonId: resolvedLessonId,
            );
      });
      return controller;
    });

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final i = iterator;
    return i.moveNext() ? i.current : null;
  }
}
