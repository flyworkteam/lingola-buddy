import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingola_buddy/Core/Config/app_config.dart';
import 'package:lingola_buddy/Core/Config/app_navigator.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Routes/app_routes.dart';
import 'package:lingola_buddy/Core/Theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppTranslations.load();
  runApp(const ProviderScope(child: LingolaBuddyApp()));
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
        return MaterialApp(
          navigatorKey: appNavigatorKey,
          title: AppConfig.appName,
          theme: AppTheme.light(),
          initialRoute: AppRoutes.bottomNav,
          routes: AppRoutes.routes,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
