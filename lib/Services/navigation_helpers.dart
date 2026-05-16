import 'package:flutter/material.dart';

/// Yerel Navigator içinde güvenli yönlendirme yardımcıları
class NavigationHelpers {
  NavigationHelpers._();

  static Future<T?> push<T>(
    BuildContext context,
    Widget page, {
    bool rootNavigator = false,
  }) {
    final nav = Navigator.of(context, rootNavigator: rootNavigator);
    return nav.push<T>(MaterialPageRoute<T>(builder: (_) => page));
  }

  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop<T>(result);
  }
}
