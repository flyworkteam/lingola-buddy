/// Uygulama arayüz dilleri ve bayrak ikonları.
abstract final class AppUiLanguages {
  AppUiLanguages._();

  static const String defaultCode = 'tr';

  static const List<AppUiLanguage> entries = [
    AppUiLanguage(code: 'en', flagAsset: 'assets/icons/english.svg'),
    AppUiLanguage(code: 'de', flagAsset: 'assets/icons/german.svg'),
    AppUiLanguage(code: 'it', flagAsset: 'assets/icons/italian.svg'),
    AppUiLanguage(code: 'fr', flagAsset: 'assets/icons/french.svg'),
    AppUiLanguage(code: 'tr', flagAsset: 'assets/icons/turkish.svg'),
    AppUiLanguage(code: 'ja', flagAsset: 'assets/icons/japanese.svg'),
    AppUiLanguage(code: 'es', flagAsset: 'assets/icons/spain.svg'),
    AppUiLanguage(code: 'ru', flagAsset: 'assets/icons/russian.svg'),
    AppUiLanguage(code: 'ko', flagAsset: 'assets/icons/korean.svg'),
    AppUiLanguage(code: 'hi', flagAsset: 'assets/icons/hindi.svg'),
    AppUiLanguage(code: 'pt', flagAsset: 'assets/icons/portuguese.svg'),
    AppUiLanguage(code: 'zh', flagAsset: 'assets/icons/chinese.svg'),
  ];

  static String flagAssetFor(String code) {
    final normalized = code.trim().toLowerCase();
    for (final lang in entries) {
      if (lang.code == normalized) return lang.flagAsset;
    }
    return entries.firstWhere((l) => l.code == 'en').flagAsset;
  }
}

final class AppUiLanguage {
  const AppUiLanguage({required this.code, required this.flagAsset});

  final String code;
  final String flagAsset;
}
