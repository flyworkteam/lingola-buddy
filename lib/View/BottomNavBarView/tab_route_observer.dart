import 'package:flutter/material.dart';

/// Alt gezinme çubuğunun gizleneceği sekme içi rotalar.
abstract final class TabRoutesHideNavBar {
  TabRoutesHideNavBar._();

  static const Set<String> hidden = {
    '/tutor',
    '/chat',
    '/voice',
    '/video',
    '/settings',
    '/language',
    '/share',
    '/faq',
    '/progress',
  };

  static bool shouldHide(String? routeName) =>
      routeName != null && hidden.contains(routeName);
}

/// Sekme Navigator'ındaki üst rotayı izler.
class TabRouteObserver extends NavigatorObserver {
  TabRouteObserver({
    required this.tabIndex,
    required this.onRouteChanged,
  });

  final int tabIndex;
  final void Function(int tabIndex, String? routeName) onRouteChanged;

  void _emit(Route<dynamic>? route) {
    final name = route?.settings.name;
    onRouteChanged(tabIndex, name == null || name.isEmpty ? '/' : name);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _emit(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _emit(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _emit(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _emit(previousRoute);
  }
}
