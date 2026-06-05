import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingola_buddy/Core/Config/app_navigator.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';

enum AppSnackBarType { success, error, info }

/// Proje genelinde tek tip floating snackbar.
abstract final class AppSnackBar {
  AppSnackBar._();

  static const Duration _defaultDuration = Duration(seconds: 3);
  static const Duration _errorDuration = Duration(seconds: 4);

  static void show(
    String message, {
    BuildContext? context,
    AppSnackBarType type = AppSnackBarType.info,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = _resolveMessenger(context);
    if (messenger == null) return;

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          duration: duration ??
              (type == AppSnackBarType.error
                  ? _errorDuration
                  : _defaultDuration),
          content: _SnackBarCard(
            message: message,
            type: type,
            actionLabel: actionLabel,
            onAction: onAction,
          ),
        ),
      );
  }

  static void success(String message, {BuildContext? context}) {
    show(message, context: context, type: AppSnackBarType.success);
  }

  static void error(
    String message, {
    BuildContext? context,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      message,
      context: context,
      type: AppSnackBarType.error,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void info(String message, {BuildContext? context}) {
    show(message, context: context, type: AppSnackBarType.info);
  }

  static ScaffoldMessengerState? _resolveMessenger(BuildContext? context) {
    if (context != null) {
      return ScaffoldMessenger.maybeOf(context);
    }
    final rootContext = appNavigatorKey.currentContext;
    if (rootContext == null) return null;
    return ScaffoldMessenger.maybeOf(rootContext);
  }
}

class _SnackBarCard extends StatelessWidget {
  const _SnackBarCard({
    required this.message,
    required this.type,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final AppSnackBarType type;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final (icon, iconBg, iconColor) = switch (type) {
      AppSnackBarType.success => (
          Icons.check_circle_rounded,
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
        ),
      AppSnackBarType.error => (
          Icons.error_outline_rounded,
          const Color(0xFFFFEBEE),
          const Color(0xFFE53935),
        ),
      AppSnackBarType.info => (
          Icons.info_outline_rounded,
          AppColors.brandPrimary.withValues(alpha: 0.1),
          AppColors.brandPrimary,
        ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.14,
                  color: const Color(0xFF171717),
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.brandPrimary,
                ),
                child: Text(
                  actionLabel!,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
