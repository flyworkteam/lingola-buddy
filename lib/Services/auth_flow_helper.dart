import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingola_buddy/Core/Localization/app_translations.dart';
import 'package:lingola_buddy/Core/Routes/app_routes.dart';
import 'package:lingola_buddy/Core/Widgets/app_snackbar.dart';
import 'package:lingola_buddy/Core/Widgets/future_extensions_dialog.dart';
import 'package:lingola_buddy/Repositories/auth_repository.dart';
import 'package:lingola_buddy/Riverpod/Controllers/SessionController/session_controller.dart';
import 'package:lingola_buddy/Riverpod/Controllers/UserProfileController/user_profile_controller.dart';
import 'package:lingola_buddy/Riverpod/Providers/auth_repository_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/post_login_paywall_provider.dart';
import 'package:lingola_buddy/Riverpod/Providers/user_scoped_providers.dart';
import 'package:lingola_buddy/Services/local_notification_scheduler.dart';
import 'package:lingola_buddy/Services/session_local_storage.dart';
import 'package:lingola_buddy/Riverpod/Controllers/PremiumController/premium_controller.dart';
import 'package:lingola_buddy/Services/call_session_post_sync.dart';
import 'package:lingola_buddy/Services/http_api_service.dart';

/// Giriş sonrası ortak akış (UI değişmeden SignUp / Paywall tarafından kullanılır).
class AuthFlowHelper {
  AuthFlowHelper._();

  static Future<void> completeSignIn(
    BuildContext context,
    WidgetRef ref,
    Future<dynamic> Function(AuthRepository repo) signIn,
  ) async {
    try {
      await FutureExtensionsDialog.guard<void>(context, (() async {
        final result = await signIn(ref.read(authRepositoryProvider));
        resetUserScopedAppState(ref);
        ref.read(userProfileControllerProvider.notifier).setAuthenticatedUser(
              result.user,
            );
        ref.read(sessionControllerProvider.notifier).markAuthenticated(true);
        final notifOn = await SessionLocalStorage.getNotificationsEnabled();
        if (notifOn) {
          await LocalNotificationScheduler.instance.syncEnabled(enabled: true);
        }
        await ref.read(premiumControllerProvider.notifier).refresh();
        ref.read(postLoginPaywallPendingProvider.notifier).state = true;
        await CallSessionPostSync.flushPendingAfterLogin(ref);
        if (!context.mounted) return;
        await Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.bottomNav,
          (route) => false,
        );
      })());
    } on ApiException catch (e) {
      if (!context.mounted) return;
      AppSnackBar.error(e.message, context: context);
    } catch (_) {
      if (!context.mounted) return;
      AppSnackBar.error(
        AppTranslations.section('auth', 'sign_in_failed'),
        context: context,
      );
    }
  }
}
