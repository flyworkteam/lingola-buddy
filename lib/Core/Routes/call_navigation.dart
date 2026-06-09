import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Core/Routes/app_routes.dart';
import 'package:lingola_buddy/Models/call_preview_args.dart';
import 'package:lingola_buddy/Riverpod/Providers/tutors_catalog_provider.dart';
import 'package:lingola_buddy/Services/premium_call_gate.dart';

/// Arama akışı kök [MaterialApp] navigator üzerinden açılır (alt sekme yığınında değil).
abstract final class CallNavigation {
  CallNavigation._();

  static Future<T?> _pushArgs<T>(BuildContext context, CallPreviewArgs args) {
    return Navigator.of(context, rootNavigator: true).pushNamed<T>(
      AppRoutes.callPreview,
      arguments: args,
    );
  }

  /// Onboarding / giriş öncesi — rastgele bir eğitmen.
  static Future<T?> pushGuestPreview<T>(
    BuildContext context,
    WidgetRef ref,
  ) {
    final catalog = ref.read(tutorsCatalogProvider);
    final tutorId = catalog.isEmpty
        ? 'sophie'
        : catalog[Random().nextInt(catalog.length)].id;
    return _pushArgs(context, CallPreviewArgs.guest(tutorId: tutorId));
  }

  /// Giriş sonrası — doğrudan görüntülü arama (önizleme ekranı yok).
  static Future<T?> pushSessionVideo<T>(
    BuildContext context,
    WidgetRef ref, {
    required String tutorId,
  }) async {
    T? result;
    await PremiumCallGate.runIfAllowed(context, ref, () async {
      result = await pushVideo<T>(context, tutorId);
    });
    return result;
  }

  static Future<T?> pushVideo<T>(BuildContext context, String tutorId) {
    return Navigator.of(context, rootNavigator: true).pushNamed<T>(
      AppRoutes.videoCall,
      arguments: tutorId,
    );
  }

  static void popPreview(BuildContext context) {
    final root = Navigator.of(context, rootNavigator: true);
    if (root.canPop()) {
      root.pop();
    }
  }
}
