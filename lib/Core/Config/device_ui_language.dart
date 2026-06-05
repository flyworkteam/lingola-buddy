import 'dart:ui';

import 'package:lingola_buddy/Core/Config/app_ui_languages.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';

/// Sistem / cihaz dilinden desteklenen uygulama dil kodu.
abstract final class DeviceUiLanguage {
  DeviceUiLanguage._();

  static String resolve() {
    final locale = PlatformDispatcher.instance.locale;
    final code = locale.languageCode.toLowerCase();

    if (AppTranslations.supportedLocaleCodes.contains(code)) {
      return code;
    }

    // zh-Hans / zh-Hant → zh
    if (code == 'zh' || locale.scriptCode?.toLowerCase() == 'hans') {
      return 'zh';
    }

    // pt-BR, pt-PT → pt
    if (code == 'pt') {
      return 'pt';
    }

    return AppUiLanguages.defaultCode;
  }
}
