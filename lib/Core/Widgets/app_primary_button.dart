import 'package:flutter/material.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.labelStyle,
    this.minimumHeight = 56,
    this.decorationGradient,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final TextStyle? labelStyle;
  final double minimumHeight;

  /// Verildiğinde düz [FilledButton] yerine gradient dolgulu pill kullanılır.
  final Gradient? decorationGradient;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? scheme.primary;
    final fg = foregroundColor ?? scheme.onPrimary;

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: labelStyle),
        if (icon != null) ...[const SizedBox(width: 8), icon!],
      ],
    );

    if (decorationGradient != null) {
      final enabled = onPressed != null;
      return SizedBox(
        width: double.infinity,
        height: minimumHeight,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(999),
            splashColor: Colors.white24,
            highlightColor: Colors.white12,
            child: Ink(
              decoration: BoxDecoration(
                gradient: decorationGradient,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(
                child: Opacity(
                  opacity: enabled ? 1 : 0.45,
                  child: IconTheme.merge(
                    data: IconThemeData(color: fg),
                    child: DefaultTextStyle.merge(
                      style: TextStyle(color: fg),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: Size(double.infinity, minimumHeight),
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: 0.4),
        ),
        child: child,
      ),
    );
  }
}
