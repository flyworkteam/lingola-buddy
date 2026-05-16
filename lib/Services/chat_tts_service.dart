import 'package:flutter_tts/flutter_tts.dart';

class ChatTtsService {
  ChatTtsService() : _tts = FlutterTts();

  final FlutterTts _tts;
  bool _initialized = false;

  Future<void> _ensureReady() async {
    if (_initialized) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1);
    await _tts.setPitch(1);
    _initialized = true;
  }

  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _ensureReady();
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
