import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:lingola_buddy/Core/Config/openai_config.dart';
import 'package:lingola_buddy/Models/chat_attachment_model.dart';
import 'package:lingola_buddy/Models/tutor_model.dart';
import 'package:lingola_buddy/Services/http_api_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ChatTutorVoiceService {
  ChatTutorVoiceService({HttpApiService? http})
      : _http = http ?? HttpApiService();

  final HttpApiService _http;

  Future<ChatAttachment?> synthesizeVoice({
    required String tutorId,
    required TutorModel tutor,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    final fromApi = await _synthesizeViaApi(tutorId: tutorId, text: trimmed);
    if (fromApi != null) return fromApi;

    return _synthesizeViaOpenAi(tutor: tutor, text: trimmed);
  }

  Future<ChatAttachment?> _synthesizeViaApi({
    required String tutorId,
    required String text,
  }) async {
    try {
      final envelope = await _http.post(
        '/conversations/tutor/$tutorId/synthesize-voice',
        body: {'text': text},
        authenticated: true,
        receiveTimeout: const Duration(seconds: 45),
      );
      final data = envelope['data'] as Map<String, dynamic>? ?? {};
      final b64 = data['audioBase64'] as String?;
      if (b64 == null || b64.isEmpty) return null;

      final bytes = base64Decode(b64);
      final path = await _persist(bytes, ext: '.mp3');
      final ms = data['durationMs'];
      final duration = ms is num
          ? Duration(milliseconds: ms.toInt())
          : await _probeDuration(path);
      return ChatAttachment(
        kind: ChatAttachmentKind.voice,
        localPath: path,
        displayName: p.basename(path),
        duration: duration,
      );
    } catch (_) {
      return null;
    }
  }

  Future<ChatAttachment?> _synthesizeViaOpenAi({
    required TutorModel tutor,
    required String text,
  }) async {
    if (!OpenAiConfig.isConfigured) return null;
    try {
      final voice = _openAiVoiceForTutor(tutor);
      final bytes = await _fetchOpenAiSpeechMp3(text, voice: voice);
      if (bytes == null || bytes.isEmpty) return null;

      final path = await _persist(bytes, ext: '.mp3');
      final duration = await _probeDuration(path);
      return ChatAttachment(
        kind: ChatAttachmentKind.voice,
        localPath: path,
        displayName: p.basename(path),
        duration: duration,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _fetchOpenAiSpeechMp3(
    String text, {
    required String voice,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.openai.com/v1',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 45),
        headers: {
          'Authorization': 'Bearer ${OpenAiConfig.apiKey}',
          'Content-Type': 'application/json',
        },
      ),
    );

    try {
      final response = await dio.post<List<int>>(
        '/audio/speech',
        data: {
          'model': 'tts-1',
          'input': trimmed,
          'voice': voice,
          'response_format': 'mp3',
        },
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) return null;
      return Uint8List.fromList(bytes);
    } finally {
      dio.close();
    }
  }

  static String _openAiVoiceForTutor(TutorModel tutor) {
    final gender = tutor.gender.toLowerCase();
    if (gender == 'male') return 'onyx';
    if (gender == 'female') return 'nova';
    return 'alloy';
  }

  Future<String> _persist(Uint8List bytes, {required String ext}) async {
    final dir = await getApplicationDocumentsDirectory();
    final voiceDir = Directory(p.join(dir.path, 'chat_attachments', 'voice'));
    if (!await voiceDir.exists()) {
      await voiceDir.create(recursive: true);
    }
    final path = p.join(
      voiceDir.path,
      'tutor_voice_${DateTime.now().microsecondsSinceEpoch}$ext',
    );
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }

  Future<Duration> _probeDuration(String path) async {
    final player = AudioPlayer();
    try {
      await player.setSource(DeviceFileSource(path));
      return await player.getDuration() ?? const Duration(seconds: 1);
    } catch (_) {
      return const Duration(seconds: 1);
    } finally {
      await player.dispose();
    }
  }
}
