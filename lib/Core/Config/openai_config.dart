/// OpenAI API anahtarı repoya yazılmaz.
///
/// Yerel çalıştırma:
/// `flutter run --dart-define=OPENAI_API_KEY=sk-...`
///
/// veya `.env` dosyasına yazıp aynı değişkeni build/run komutuna ekleyin.
abstract final class OpenAiConfig {
  OpenAiConfig._();

  static const String apiKey = String.fromEnvironment('OPENAI_API_KEY');

  static bool get isConfigured => apiKey.isNotEmpty;
}
