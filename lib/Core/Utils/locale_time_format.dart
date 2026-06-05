import 'package:lingola_buddy/Core/Localization/app_translations.dart';

/// Sohbet / bildirim satırları için yerel saat metni.
abstract final class LocaleTimeFormat {
  LocaleTimeFormat._();

  /// 12 saat ve çevrilmiş AM/PM kullanan diller.
  static const _twelveHourLocales = {'en'};

  static String? messageTimeLabel(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final dt = DateTime.tryParse(iso);
    if (dt == null) return null;
    final local = dt.toLocal();
    final minute = local.minute.toString().padLeft(2, '0');

    if (!_twelveHourLocales.contains(AppTranslations.locale)) {
      final hour = local.hour.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final period = local.hour >= 12
        ? AppTranslations.section('talk', 'time_pm')
        : AppTranslations.section('talk', 'time_am');
    return '$hour12:$minute $period';
  }
}
