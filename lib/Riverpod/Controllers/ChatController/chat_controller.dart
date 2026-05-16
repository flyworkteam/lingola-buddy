import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Core/Config/openai_config.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Models/chat_message_model.dart';
import 'package:lingola_buddy/Models/tutor_model.dart';
import 'package:lingola_buddy/Riverpod/Providers/tutors_catalog_provider.dart';
import 'package:lingola_buddy/Models/chat_attachment_model.dart';
import 'package:path/path.dart' as p;
import 'package:lingola_buddy/Services/chat_attachment_service.dart';
import 'package:lingola_buddy/Services/chat_tts_service.dart';
import 'package:lingola_buddy/Services/chat_voice_recorder_service.dart';
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

class ChatState {
  const ChatState({
    required this.messages,
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
    required OpenAiChatService openAi,
    required ChatTtsService tts,
    required ChatVoiceRecorderService voiceRecorder,
    required ChatAttachmentService attachments,
  })  : _openAi = openAi,
        _tts = tts,
        _voiceRecorder = voiceRecorder,
        _attachments = attachments,
        super(ChatState(messages: _seedMessages(tutor))) {
    _displayName = AppTranslations.section('tudor', tutor.id);
  }

  final String tutorId;
  final TutorModel tutor;
  final OpenAiChatService _openAi;
  final ChatTtsService _tts;
  final ChatVoiceRecorderService _voiceRecorder;
  final ChatAttachmentService _attachments;
  final Map<String, String> _translationCache = {};
  StreamSubscription<double>? _voiceLevelSub;
  Timer? _recordingTick;
  late final String _displayName;

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

  static List<ChatMessage> _seedMessages(TutorModel tutor) {
    final name = tutor.name;
    return [
      ChatMessage(
        id: 'seed-1',
        role: ChatMessageRole.assistant,
        text:
            'Hello! I\'m $name. It was a pleasure meeting you. Could you tell me a little about yourself?',
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
      final messageId = selection.messageId;
      final perMessage = Map<String, String>.from(
        state.messageWordTranslations[messageId] ?? {},
      );
      perMessage[cacheKey] = cached;
      final all = Map<String, Map<String, String>>.from(
        state.messageWordTranslations,
      );
      all[messageId] = perMessage;

      state = state.copyWith(
        isTranslating: false,
        wordTranslation: cached,
        messageWordTranslations: all,
      );
      return;
    }

    state = state.copyWith(isTranslating: true, clearError: true);
    try {
      final translation = await _openAi.translateWord(
        word: selection.word,
        targetLanguageLabel: 'Turkish',
      );
      _translationCache[cacheKey] = translation;
      if (state.selection?.word.toLowerCase() != cacheKey) return;

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
        isTranslating: false,
        wordTranslation: translation,
        messageWordTranslations: all,
      );
    } catch (e) {
      if (state.selection?.word.toLowerCase() != cacheKey) return;
      state = state.copyWith(
        isTranslating: false,
        error: e.toString(),
      );
    }
  }

  Future<void> speakSelection() async {
    final selection = state.selection;
    if (selection == null || state.isSpeaking) return;

    state = state.copyWith(isSpeaking: true, clearError: true);
    try {
      await _tts.speak(selection.word);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isSpeaking: false);
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

    try {
      await _tts.stop();
    } catch (_) {}

    try {
      final reply = await _openAi
          .sendTutorReply(
            tutorName: _displayName,
            tutorBio: tutor.bio ?? '',
            history: historyWithUser,
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
    _tts.stop();
    _voiceRecorder.cancel();
    super.dispose();
  }
}

final chatControllerProvider = StateNotifierProvider.autoDispose
    .family<ChatController, ChatState, String>((ref, tutorId) {
      final tutors = ref.watch(tutorsCatalogProvider);
      if (tutors.isEmpty) {
        throw StateError('Tutor catalog is empty');
      }
      final tutor = tutors
          .where((t) => t.id == tutorId)
          .cast<TutorModel?>()
          .firstOrNull;
      final resolved = tutor ?? tutors.first;
      return ChatController(
        tutorId: tutorId,
        tutor: resolved,
        openAi: ref.watch(openAiChatServiceProvider),
        tts: ref.watch(chatTtsServiceProvider),
        voiceRecorder: ref.watch(chatVoiceRecorderProvider),
        attachments: ref.watch(chatAttachmentServiceProvider),
      );
    });

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final i = iterator;
    return i.moveNext() ? i.current : null;
  }
}
