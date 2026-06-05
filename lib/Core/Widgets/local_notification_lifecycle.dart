import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Riverpod/Controllers/SessionController/session_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/UserProfileController/user_profile_controller.dart';
import 'package:lingola_buddy/Riverpod/Providers/curriculum_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/streak_provider.dart';
import 'package:lingola_buddy/Services/local_notification_scheduler.dart';
import 'package:lingola_buddy/Services/notification_inbox_store.dart';
import 'package:lingola_buddy/Services/notification_personalization.dart';

/// Uygulama ön plan / arka plan geçişlerinde bildirim planını günceller.
class LocalNotificationLifecycle extends ConsumerStatefulWidget {
  const LocalNotificationLifecycle({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<LocalNotificationLifecycle> createState() =>
      _LocalNotificationLifecycleState();
}

class _LocalNotificationLifecycleState extends ConsumerState<LocalNotificationLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromProviders());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncFromProviders();
    } else if (state == AppLifecycleState.paused) {
      _syncFromProviders();
    }
  }

  Future<void> _syncFromProviders() async {
    await NotificationInboxStore.flushDueDeliveries();

    final enabled = ref.read(userProfileControllerProvider).notificationsEnabled;
    if (!enabled || !ref.read(sessionControllerProvider).isAuthenticated) {
      if (!enabled) {
        await LocalNotificationScheduler.instance.cancelAll();
      }
      return;
    }

    final curriculum = ref.read(userCurriculumProvider).valueOrNull;
    final streak = ref.read(userStreakProvider).valueOrNull;
    final data = NotificationPersonalization.fromData(
      curriculum: curriculum,
      streak: streak,
    );
    await LocalNotificationScheduler.instance.syncWithPersonalization(
      data: data,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
