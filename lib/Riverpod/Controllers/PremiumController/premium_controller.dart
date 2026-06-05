import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Core/Config/premium_config.dart';
import 'package:lingola_buddy/Riverpod/Controllers/UserProfileController/user_profile_controller.dart';
import 'package:lingola_buddy/Services/revenuecat_service.dart';
import 'package:lingola_buddy/Services/session_local_storage.dart';

class PremiumState {
  const PremiumState({
    this.isPro = false,
    this.freeCallsUsed = 0,
    this.freeCallsTotal = PremiumConfig.freeCallsTotal,
    this.isRefreshing = false,
  });

  final bool isPro;
  final int freeCallsUsed;
  final int freeCallsTotal;
  final bool isRefreshing;

  int get freeCallsRemaining =>
      (freeCallsTotal - freeCallsUsed).clamp(0, freeCallsTotal);

  bool get canStartCall => isPro || freeCallsUsed < freeCallsTotal;

  PremiumState copyWith({
    bool? isPro,
    int? freeCallsUsed,
    int? freeCallsTotal,
    bool? isRefreshing,
  }) {
    return PremiumState(
      isPro: isPro ?? this.isPro,
      freeCallsUsed: freeCallsUsed ?? this.freeCallsUsed,
      freeCallsTotal: freeCallsTotal ?? this.freeCallsTotal,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class PremiumController extends Notifier<PremiumState> {
  @override
  PremiumState build() {
    ref.listen(userProfileControllerProvider, (previous, next) {
      final prevId = previous?.user?.id;
      final nextId = next.user?.id;
      if (prevId != nextId) {
        unawaited(_loadForUser(nextId));
      }
    });
    return const PremiumState();
  }

  String? get _userId {
    final id = ref.read(userProfileControllerProvider).user?.id;
    return _isBillableUserId(id) ? id : null;
  }

  Future<void> refresh() => _loadForUser(_userId);

  Future<void> applyCustomerInfo({required bool isPro}) async {
    final userId = _userId;
    final used = userId == null
        ? 0
        : await SessionLocalStorage.getFreeCallsUsed(userId!);
    state = state.copyWith(
      isPro: isPro,
      freeCallsUsed: used,
      isRefreshing: false,
    );
  }

  static bool _isBillableUserId(String? userId) {
    if (userId == null || userId.isEmpty || userId == 'local') return false;
    return true;
  }

  Future<void> _loadForUser(String? userId) async {
    state = state.copyWith(isRefreshing: true);

    final used = !_isBillableUserId(userId)
        ? 0
        : await SessionLocalStorage.getFreeCallsUsed(userId!);
    final isPro = await RevenueCatService.instance.hasProEntitlement();

    state = PremiumState(
      isPro: isPro,
      freeCallsUsed: used,
      freeCallsTotal: PremiumConfig.freeCallsTotal,
      isRefreshing: false,
    );
  }

  /// Tamamlanan görüşmeyi kotaya işler (Pro değilse).
  Future<void> recordCompletedCall({required int durationSeconds}) async {
    if (durationSeconds < PremiumConfig.minDurationToCountSeconds) return;

    final userId = _userId;
    if (userId == null) return;

    await refresh();
    if (state.isPro || state.freeCallsUsed >= state.freeCallsTotal) return;

    final next = await SessionLocalStorage.incrementFreeCallsUsed(userId);
    state = state.copyWith(freeCallsUsed: next);
  }
}

final premiumControllerProvider =
    NotifierProvider<PremiumController, PremiumState>(PremiumController.new);
