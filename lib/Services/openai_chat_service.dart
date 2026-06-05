import 'dart:io';

import 'package:dio/dio.dart';
import 'package:lingola_buddy/Core/Config/openai_config.dart';
import 'package:lingola_buddy/Models/chat_message_model.dart';

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
  }) async {
    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content':
            'You are $tutorName, a friendly English conversation tutor. '
            'Help the learner practice spoken English in short, natural messages (1-3 sentences). '
            'Gently correct mistakes when needed. Mix English; you may use occasional Turkish '
            'only if the learner seems stuck. Stay in character. Bio: $tutorBio',
      },
      for (final m in history)
        if (!m.isTyping && m.apiText.isNotEmpty)
          {'role': m.isUser ? 'user' : 'assistant', 'content': m.apiText},
    ];

    return _complete(messages);
  }

  Future<String> transcribeAudio(String filePath) async {
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
          'language': 'en',
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
