import 'package:lingola_buddy/Core/Localization/app_translations.dart';

/// Günün saatine göre `home.greeting_*` çeviri anahtarını seçer.
abstract final class TimeOfDayGreeting {
  TimeOfDayGreeting._();

  /// 05:00–11:59 sabah, 12:00–16:59 öğleden sonra, 17:00–21:59 akşam, aksi gece.
  static String keyForHour(int hour) {
    if (hour >= 5 && hour < 12) return 'greeting_morning';
    if (hour >= 12 && hour < 17) return 'greeting_afternoon';
    if (hour >= 17 && hour < 22) return 'greeting_evening';
    return 'greeting_night';
  }

  static String key([DateTime? at]) => keyForHour((at ?? DateTime.now()).hour);

  static String emojiForHour(int hour) {
    if (hour >= 5 && hour < 12) return '🌅';
    if (hour >= 12 && hour < 17) return '☀️';
    if (hour >= 17 && hour < 22) return '🌆';
    return '🌙';
  }

  static String emoji([DateTime? at]) =>
      emojiForHour((at ?? DateTime.now()).hour);

  static String localized([DateTime? at]) =>
      AppTranslations.section('home', key(at));

  /// Selamlama satırı: saate göre emoji + çeviri.
  static String line([DateTime? at]) {
    final when = at ?? DateTime.now();
    return '${emojiForHour(when.hour)} ${localized(when)}';
  }
}
