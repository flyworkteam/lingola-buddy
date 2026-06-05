import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Core/Config/device_ui_language.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Riverpod/Controllers/UserProfileController/user_profile_controller.dart';
import 'package:lingola_buddy/Riverpod/Providers/tutors_catalog_provider.dart';
import 'package:lingola_buddy/Services/session_local_storage.dart';

/// Cihaz dili değişince (profilde elle seçim yoksa) çevirileri yeniler.
class UiLanguageSync extends ConsumerStatefulWidget {
  const UiLanguageSync({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<UiLanguageSync> createState() => _UiLanguageSyncState();
}

class _UiLanguageSyncState extends ConsumerState<UiLanguageSync>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncDeviceLanguage());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncDeviceLanguage();
    }
  }

  Future<void> _syncDeviceLanguage() async {
    if (await SessionLocalStorage.isUiLanguageManual()) return;

    final deviceCode = DeviceUiLanguage.resolve();
    if (deviceCode == AppTranslations.locale &&
        deviceCode == ref.read(userProfileControllerProvider).uiLanguageCode) {
      return;
    }

    await AppTranslations.setLocale(deviceCode);
    await SessionLocalStorage.setUiLanguageCode(deviceCode);
    if (!mounted) return;
    ref.read(userProfileControllerProvider.notifier).setUiLanguageCode(deviceCode);
    ref.invalidate(tutorsCatalogAsyncProvider);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
