import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Widgets/app_snackbar.dart';
import 'package:lingola_buddy/Core/Widgets/future_extensions_dialog.dart';
import 'package:lingola_buddy/Riverpod/Controllers/PremiumController/premium_controller.dart';
import 'package:lingola_buddy/Services/revenuecat_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

/// RevenueCat dashboard paywall'ını sheet (iOS) / tam ekran (Android) olarak açar.
abstract final class LingolaRevenueCatPaywall {
  LingolaRevenueCatPaywall._();

  static Future<PaywallResult?> presentSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (!RevenueCatService.instance.isConfigured) {
      if (context.mounted) {
        AppSnackBar.error(
          AppTranslations.sectionOr('premium', 'not_configured', 'Subscriptions unavailable'),
          context: context,
        );
      }
      return null;
    }

    Offering? offering;

    try {
      offering = await FutureExtensionsDialog.guard(
        context,
        _loadCurrentOffering(),
      );
    } catch (e, st) {
      debugPrint('LingolaRevenueCatPaywall offerings: $e\n$st');
      if (context.mounted) {
        AppSnackBar.error(
          AppTranslations.sectionOr('premium', 'offerings_failed', 'Could not load subscriptions'),
          context: context,
        );
      }
      return null;
    }

    if (!context.mounted) return null;

    PaywallResult? result;
    try {
      result = await RevenueCatUI.presentPaywall(offering: offering);
    } catch (e, st) {
      debugPrint('LingolaRevenueCatPaywall present: $e\n$st');
      if (!context.mounted) return null;
      try {
        result = await RevenueCatUI.presentPaywall();
      } catch (e2, st2) {
        debugPrint('LingolaRevenueCatPaywall fallback: $e2\n$st2');
        if (context.mounted) {
          AppSnackBar.error(
            AppTranslations.sectionOr('premium', 'paywall_failed', 'Could not open paywall'),
            context: context,
          );
        }
        return null;
      }
    }

    if (!context.mounted) return result;
    await _handlePaywallResult(context, ref, result);
    return result;
  }

  static Future<void> restorePurchases(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (!RevenueCatService.instance.isConfigured) {
      if (context.mounted) {
        AppSnackBar.error(
          AppTranslations.sectionOr('premium', 'not_configured', 'Subscriptions unavailable'),
          context: context,
        );
      }
      return;
    }

    try {
      await FutureExtensionsDialog.guard(context, () async {
        final restored = await RevenueCatService.instance.restorePurchases();
        await ref.read(premiumControllerProvider.notifier).refresh();
        if (!context.mounted) return;
        if (restored) {
          AppSnackBar.success(
            AppTranslations.sectionOr('premium', 'restored_success', 'Subscription restored'),
            context: context,
          );
        } else {
          AppSnackBar.error(
            AppTranslations.sectionOr('premium', 'restore_none', 'No active subscription'),
            context: context,
          );
        }
      }());
    } catch (e, st) {
      debugPrint('LingolaRevenueCatPaywall restore: $e\n$st');
      if (context.mounted) {
        AppSnackBar.error(
          AppTranslations.sectionOr('premium', 'restore_failed', 'Could not restore purchases'),
          context: context,
        );
      }
    }
  }

  static Future<void> _handlePaywallResult(
    BuildContext context,
    WidgetRef ref,
    PaywallResult? result,
  ) async {
    if (result == null || result == PaywallResult.cancelled) return;

    await ref.read(premiumControllerProvider.notifier).refresh();
    if (!context.mounted) return;

    switch (result) {
      case PaywallResult.purchased:
        AppSnackBar.success(
          AppTranslations.sectionOr('premium', 'purchased_success', 'Welcome to Pro!'),
          context: context,
        );
      case PaywallResult.restored:
        AppSnackBar.success(
          AppTranslations.sectionOr('premium', 'restored_success', 'Subscription restored'),
          context: context,
        );
      case PaywallResult.notPresented:
      case PaywallResult.error:
        AppSnackBar.error(
          AppTranslations.sectionOr('premium', 'paywall_failed', 'Could not open paywall'),
          context: context,
        );
      case PaywallResult.cancelled:
        break;
    }
  }

  static Future<Offering?> _loadCurrentOffering() async {
    final offerings = await Purchases.getOfferings();
    return offerings.current;
  }
}
