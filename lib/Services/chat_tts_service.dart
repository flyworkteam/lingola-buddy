import 'package:flutter_tts/flutter_tts.dart';

class ChatTtsService {
  ChatTtsService() : _tts = FlutterTts();

  final FlutterTts _tts;
  bool _initialized = false;
  String? _currentLocale;

  static String localeForLanguageCode(String code) {
    switch (code) {
      case 'tr':
        return 'tr-TR';
      case 'de':
        return 'de-DE';
      case 'fr':
        return 'fr-FR';
      case 'es':
        return 'es-ES';
      case 'it':
        return 'it-IT';
      case 'pt':
        return 'pt-PT';
      case 'ru':
        return 'ru-RU';
      case 'ja':
        return 'ja-JP';
      case 'ko':
        return 'ko-KR';
      case 'hi':
        return 'hi-IN';
      case 'zh':
        return 'zh-CN';
      case 'en':
      default:
        return 'en-US';
    }
  }

  Future<void> _ensureReady({required String languageCode}) async {
    final locale = localeForLanguageCode(languageCode);
    if (!_initialized || _currentLocale != locale) {
      await _tts.setLanguage(locale);
      await _tts.setSpeechRate(0.48);
      await _tts.setVolume(1);
      await _tts.setPitch(1);
      _initialized = true;
      _currentLocale = locale;
    }
  }

  Future<void> speak(
    String text, {
    String languageCode = 'en',
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _ensureReady(languageCode: languageCode);
    await _tts.stop();
    await _tts.speak(trimmed);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  void dispose() {
    _tts.stop();
  }
}
