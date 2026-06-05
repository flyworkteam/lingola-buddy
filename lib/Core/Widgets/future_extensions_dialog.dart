import 'dart:async';

import 'package:flutter/material.dart';

/// Uzun süren [Future] işlemleri sırasında metinsiz yükleme göstergesi.
abstract final class FutureExtensionsDialog {
  FutureExtensionsDialog._();

  static Future<T> guard<T>(
    BuildContext context,
    Future<T> future, {
    bool useRootNavigator = true,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: useRootNavigator);

    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        useRootNavigator: useRootNavigator,
        barrierColor: Colors.black.withValues(alpha: 0.35),
        builder: (_) => const PopScope(
          canPop: false,
          child: Center(
            child: CircularProgressIndicator.adaptive(),
          ),
        ),
      ),
    );

    await Future<void>.delayed(Duration.zero);

    try {
      return await future;
    } finally {
      if (context.mounted && navigator.canPop()) {
        navigator.pop();
      }
    }
  }
}

extension FutureExtensionsDialogX<T> on Future<T> {
  Future<T> withFutureExtensionsDialog(
    BuildContext context, {
    bool useRootNavigator = true,
  }) {
    return FutureExtensionsDialog.guard(
      context,
      this,
      useRootNavigator: useRootNavigator,
    );
  }
}
