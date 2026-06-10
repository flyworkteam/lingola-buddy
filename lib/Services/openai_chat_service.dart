import 'dart:io';

import 'package:dio/dio.dart';
import 'package:lingola_buddy/Core/Config/openai_config.dart';
import 'package:lingola_buddy/Models/chat_lesson_context.dart';
import 'package:lingola_buddy/Models/chat_message_model.dart';
import 'package:lingola_buddy/Services/chat_prompt_builder.dart';

class OpenAiChatService {
  OpenAiChatService({Dio? dio}) : _dio = dio ?? _createDio();

  final Dio _dio;

  static const _model = 'gpt-4o-mini';

  static Dio _createDio() {
    return Dio(
      BaseOptions(
        baseUrl: 'https://api.openai.com/v1',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Authorization': 'Bearer ${OpenAiConfig.apiKey}',
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  Future<String> sendTutorReply({
    required String tutorName,
    required String tutorBio,
    required List<ChatMessage> history,
    required String uiLanguageCode,
    required ChatLessonContext lessonContext,
  }) async {
    final systemPrompt = ChatPromptBuilder.buildSystemPrompt(
      tutorName: tutorName,
      tutorBio: tutorBio,
      uiLanguageCode: uiLanguageCode,
      lessonContext: lessonContext,
    );

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': systemPrompt,
      },
      ..._historyToApiMessages(history),
    ];

    var reply = await _complete(messages);

    final lastUserText = history
        .where((m) => m.isUser && m.apiText.trim().isNotEmpty)
        .map((m) => m.apiText)
        .lastOrNull;
    if (lastUserText != null &&
        ChatPromptBuilder.isVoiceDeliveryRequest(lastUserText) &&
        ChatPromptBuilder.looksLikeVoiceRefusal(reply)) {
      reply = await _complete([
        ...messages,
        {'role': 'assistant', 'content': reply},
        {
          'role': 'user',
          'content':
              'Wrong: when the learner asks for voice, reply with a short helpful teaching line only. '
              'The app attaches voice separately. No refusal, no meta talk.',
        },
      ]);
    }

    return reply;
  }

  static List<Map<String, String>> _historyToApiMessages(
    List<ChatMessage> history,
  ) {
    return [
      for (final m in history)
        if (!m.isTyping && m.apiText.isNotEmpty)
          {
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.isUser
                ? ChatPromptBuilder.normalizeUserMessageForApi(m.apiText)
                : m.apiText,
          },
    ];
  }

  Future<String> transcribeAudio(
    String filePath, {
    String? languageCode,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw OpenAiApiException('Ses dosyası bulunamadı');
    }

    final ext = filePath.toLowerCase().endsWith('.wav') ? 'wav' : 'm4a';
    final uploadName = 'voice.$ext';

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/audio/transcriptions',
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(
            filePath,
            filename: uploadName,
          ),
          'model': 'whisper-1',
          if (languageCode != null && languageCode.trim().isNotEmpty)
            'language': languageCode.trim().toLowerCase(),
        }),
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 45),
        ),
      );

      final text = response.data?['text'];
      if (text is! String || text.trim().isEmpty) {
        throw OpenAiApiException('Ses metne çevrilemedi');
      }
      return text.trim();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      throw OpenAiApiException(
        'Transkripsiyon hatası${status != null ? ' ($status)' : ''}: $body',
      );
    }
  }

  Future<String> translateWord({
    required String word,
    required String targetLanguageLabel,
  }) async {
    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content':
            'Translate English words to $targetLanguageLabel for learners. '
            'Reply with only the translation, no punctuation or quotes.',
      },
      {'role': 'user', 'content': word},
    ];
    return _complete(
      messages,
      temperature: 0,
      maxTokens: 24,
      receiveTimeout: const Duration(seconds: 8),
    );
  }

  /// Herhangi bir dildeki kelimeyi İngilizce karşılığına çevirir (TTS için).
  Future<String> translateWordToEnglish({required String word}) async {
    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content':
            'Translate the given word or short phrase into English for language learners. '
            'If it is already English, return the same word in natural English. '
            'Reply with only the English word or phrase, no punctuation or quotes.',
      },
      {'role': 'user', 'content': word},
    ];
    return _complete(
      messages,
      temperature: 0,
      maxTokens: 24,
      receiveTimeout: const Duration(seconds: 8),
    );
  }

  Future<String> _complete(
    List<Map<String, String>> messages, {
    double temperature = 0.7,
    int? maxTokens,
    Duration? receiveTimeout,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/chat/completions',
        data: {
          'model': _model,
          'messages': messages,
          'temperature': temperature,
          if (maxTokens != null) 'max_tokens': maxTokens,
        },
        options: Options(
          receiveTimeout: receiveTimeout ?? const Duration(seconds: 60),
        ),
      );

      final json = response.data;
      final choices = json?['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw OpenAiApiException('Boş yanıt');
      }

      final content =
          (choices.first as Map<String, dynamic>)['message']?['content'];
      if (content is! String || content.trim().isEmpty) {
        throw OpenAiApiException('Geçersiz yanıt');
      }
      return content.trim();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      throw OpenAiApiException(
        'OpenAI hatası${status != null ? ' ($status)' : ''}: $body',
      );
    }
  }

  void dispose() => _dio.close();
}

class OpenAiApiException implements Exception {
  OpenAiApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
