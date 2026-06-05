import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lingola_buddy/Core/Config/revenuecat_config.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat SDK başlatma, entitlement ve satın alma işlemleri.
final class RevenueCatService {
  RevenueCatService._();

  static final RevenueCatService instance = RevenueCatService._();

  bool _configured = false;

  bool get isConfigured => _configured;

  Future<void> initialize() async {
    if (_configured) return;

    try {
      final apiKey = _apiKeyForPlatform();
      if (apiKey == null || apiKey.isEmpty) {
        debugPrint('RevenueCat: API anahtarı eksik (.env)');
        return;
      }

      await Purchases.setLogLevel(
        kDebugMode ? LogLevel.debug : LogLevel.info,
      );
      await Purchases.configure(PurchasesConfiguration(apiKey));
      _configured = true;
      debugPrint('RevenueCat yapılandırıldı');
    } catch (e, st) {
      debugPrint('RevenueCat başlatılamadı: $e\n$st');
    }
  }

  String? _apiKeyForPlatform() {
    if (Platform.isIOS) {
      return dotenv.env['REVENUECAT_IOS_API_KEY'];
    }
    if (Platform.isAndroid) {
      return dotenv.env['REVENUECAT_ANDROID_API_KEY'];
    }
    return null;
  }

  Future<void> syncUserIdentity(String userId) async {
    if (!_configured || userId.isEmpty) return;

    try {
      await Purchases.logIn(userId);
    } catch (e, st) {
      debugPrint('RevenueCat logIn: $e\n$st');
    }
  }

  Future<void> logOut() async {
    if (!_configured) return;

    try {
      await Purchases.logOut();
    } catch (e, st) {
      debugPrint('RevenueCat logOut: $e\n$st');
    }
  }

  Future<CustomerInfo?> fetchCustomerInfo() async {
    if (!_configured) return null;

    try {
      return await Purchases.getCustomerInfo();
    } catch (e, st) {
      debugPrint('RevenueCat getCustomerInfo: $e\n$st');
      return null;
    }
  }

  bool isProFromCustomerInfo(CustomerInfo? info) {
    if (info == null) return false;
    return info.entitlements.active
        .containsKey(RevenueCatConfig.proEntitlementId);
  }

  Future<bool> hasProEntitlement() async {
    final info = await fetchCustomerInfo();
    return isProFromCustomerInfo(info);
  }

  Future<bool> restorePurchases() async {
    if (!_configured) return false;

    try {
      final info = await Purchases.restorePurchases();
      return isProFromCustomerInfo(info);
    } catch (e, st) {
      debugPrint('RevenueCat restorePurchases: $e\n$st');
      rethrow;
    }
  }
}
