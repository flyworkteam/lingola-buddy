import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingola_buddy/Core/Config/api_config.dart';
import 'package:lingola_buddy/Core/Config/app_config.dart';
import 'package:lingola_buddy/Core/Config/app_navigator.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Routes/app_routes.dart';
import 'package:lingola_buddy/Core/Theme/app_theme.dart';
import 'package:lingola_buddy/Riverpod/Providers/notifications_initial_enabled_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/session_initial_state_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/ui_language_initial_code_provider.dart';
import 'package:lingola_buddy/Core/Widgets/local_notification_lifecycle.dart';
import 'package:lingola_buddy/Core/Widgets/premium_lifecycle.dart';
import 'package:lingola_buddy/Core/Widgets/ui_language_sync.dart';
import 'package:lingola_buddy/Services/local_notification_scheduler.dart';
import 'package:lingola_buddy/Services/notification_permission_service.dart';
import 'package:lingola_buddy/Services/revenuecat_service.dart';
import 'package:lingola_buddy/Services/session_local_storage.dart';
import 'package:lingola_buddy/firebase_options.dart';
import 'package:rive/rive.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RiveNative.init();
  await dotenv.load(fileName: '.env');
  if (kDebugMode) {
    debugPrint(
      '[ApiConfig] ${ApiConfig.resolvedKind} → ${ApiConfig.baseUrl}',
    );
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await RevenueCatService.instance.initialize();

  final uiLanguageCode = await SessionLocalStorage.resolveUiLanguageCode();
  await AppTranslations.load(locale: uiLanguageCode);

  // Ağ çağrısı yok — debugger hızlı bağlansın; oturum doğrulama SplashView'da.
  final sessionState = await SessionLocalStorage.loadSessionState();
  final notificationsPref = await SessionLocalStorage.getNotificationsEnabled();
  final notificationsEnabled =
      await NotificationPermissionService.resolveEnabledPreference(
        notificationsPref,
      );

  await LocalNotificationScheduler.instance.initialize();
  if (notificationsEnabled) {
    await LocalNotificationScheduler.instance.syncEnabled(enabled: true);
  }

  runApp(
    ProviderScope(
      overrides: [
        sessionInitialStateProvider.overrideWithValue(sessionState),
        uiLanguageInitialCodeProvider.overrideWithValue(uiLanguageCode),
        notificationsInitialEnabledProvider.overrideWithValue(
          notificationsEnabled,
        ),
      ],
      child: const LingolaBuddyApp(),
    ),
  );
}

class LingolaBuddyApp extends StatelessWidget {
  const LingolaBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) {
        return UiLanguageSync(
          child: PremiumLifecycle(
            child: LocalNotificationLifecycle(
              child: MaterialApp(
                navigatorKey: appNavigatorKey,
                title: AppConfig.appName,
                theme: AppTheme.light(),
                initialRoute: AppRoutes.splash,
                routes: AppRoutes.routes,
                onGenerateRoute: AppRoutes.onGenerateRoute,
                debugShowCheckedModeBanner: false,
              ),
            ),
          ),
        );
      },
    );
  }
}
