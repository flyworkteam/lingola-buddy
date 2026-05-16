import 'package:flutter/material.dart';

/// Her sekmenin bağımsız geri-yığını için ince Navigator sarmalı
class TabNavigatorShell extends StatelessWidget {
  const TabNavigatorShell({
    super.key,
    required this.navigatorKey,
    required this.onGenerateRoute,
    this.initialRoute = '/',
    this.observers = const [],
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Route<dynamic>? Function(RouteSettings settings) onGenerateRoute;
  final String initialRoute;
  final List<NavigatorObserver> observers;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      initialRoute: initialRoute,
      observers: observers,
      onGenerateRoute: (settings) =>
          onGenerateRoute(settings) ??
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              extendBody: true,
              body: Center(
                child: Text(
                  'Tanımlanmayan sekme rotası:\n${settings.name}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            settings: settings,
          ),
    );
  }
}
