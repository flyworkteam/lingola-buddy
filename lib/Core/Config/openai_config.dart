import 'package:flutter_dotenv/flutter_dotenv.dart';

/// OpenAI anahtarı `.env` dosyasından okunur (git'e eklenmez).
abstract final class OpenAiConfig {
  OpenAiConfig._();

  static String get apiKey {
    final fromDotEnv = dotenv.env['OPENAI_API_KEY']?.trim();
    if (fromDotEnv != null && fromDotEnv.isNotEmpty) return fromDotEnv;

    const fromDefine = String.fromEnvironment('OPENAI_API_KEY');
    return fromDefine;
  }

  static bool get isConfigured => apiKey.isNotEmpty;
}
