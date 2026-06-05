import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Riverpod/Controllers/PremiumController/premium_controller.dart';
import 'package:lingola_buddy/Services/revenuecat_paywall.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

/// Yalnızca **görüntülü görüşme** başlatmadan önce premium / kota kontrolü.
///
/// Metin sohbeti ([PremiumConfig.textChatRequiresPremium] = false) bu kapıdan geçmez.
/// Doğrulama RevenueCat istemci SDK ile yapılır — sunucu / webhook çağrısı yok.
abstract final class PremiumCallGate {
  PremiumCallGate._();

  static Future<bool> runIfAllowed(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() onAllowed,
  ) async {
    await ref.read(premiumControllerProvider.notifier).refresh();
    if (!context.mounted) return false;

    if (ref.read(premiumControllerProvider).canStartCall) {
      await onAllowed();
      return true;
    }

    final result = await LingolaRevenueCatPaywall.presentSheet(context, ref);
    if (!context.mounted) return false;

    if (result == PaywallResult.purchased ||
        result == PaywallResult.restored) {
      await ref.read(premiumControllerProvider.notifier).refresh();
      if (!context.mounted) return false;
      if (ref.read(premiumControllerProvider).canStartCall) {
        await onAllowed();
        return true;
      }
    }

    return false;
  }
}
