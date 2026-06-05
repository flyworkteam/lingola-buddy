import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Riverpod/Controllers/PremiumController/premium_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/SessionController/session_controller.dart';
import 'package:lingola_buddy/Services/revenuecat_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat entitlement değişikliklerini dinler; ön plana dönüşte (seyrek) yeniler.
/// Yalnızca RevenueCat SDK — Lingola API çağrısı yok.
class PremiumLifecycle extends ConsumerStatefulWidget {
  const PremiumLifecycle({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PremiumLifecycle> createState() => _PremiumLifecycleState();
}

class _PremiumLifecycleState extends ConsumerState<PremiumLifecycle>
    with WidgetsBindingObserver {
  /// Arka arkaya resume'larda RC'yi yormamak için minimum aralık.
  static const _resumeRefreshMinInterval = Duration(minutes: 5);

  DateTime? _lastResumeRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _registerListener());
  }

  void _registerListener() {
    if (!mounted) return;
    if (!RevenueCatService.instance.isConfigured) return;
    Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _refreshOnResumeIfNeeded();
  }

  void _onCustomerInfoUpdated(CustomerInfo info) {
    if (!mounted) return;
    final isPro = RevenueCatService.instance.isProFromCustomerInfo(info);
    _schedulePremiumUpdate(() {
      ref.read(premiumControllerProvider.notifier).applyCustomerInfo(
            isPro: isPro,
          );
    });
  }

  void _schedulePremiumUpdate(VoidCallback update) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      update();
    });
  }

  Future<void> _refreshOnResumeIfNeeded() async {
    if (!mounted) return;
    if (!RevenueCatService.instance.isConfigured) return;
    if (!ref.read(sessionControllerProvider).isAuthenticated) return;

    final now = DateTime.now();
    final last = _lastResumeRefresh;
    if (last != null && now.difference(last) < _resumeRefreshMinInterval) {
      return;
    }
    _lastResumeRefresh = now;

    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    await ref.read(premiumControllerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
