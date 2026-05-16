import 'package:flutter/material.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.labelStyle,
    this.minimumHeight,
    this.decorationGradient,
    this.fullWidth = true,
    this.iconLeading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final TextStyle? labelStyle;
  final double? minimumHeight;
  final Gradient? decorationGradient;
  final bool fullWidth;
  final bool iconLeading;

  static const double _fullWidthHeight = 60;
  static const double _compactHeight = 56;
  static const double _contentGap = 10;
  static const BorderRadius _pillRadius = BorderRadius.all(
    Radius.circular(9999),
  );

  double get _resolvedHeight =>
      minimumHeight ?? (fullWidth ? _fullWidthHeight : _compactHeight);

  bool get _usesGradientFill => decorationGradient != null || fullWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = foregroundColor ?? scheme.onPrimary;

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null && iconLeading) ...[
          icon!,
          const SizedBox(width: _contentGap),
        ],
        Text(label, style: labelStyle),
        if (icon != null && !iconLeading) ...[
          const SizedBox(width: _contentGap),
          icon!,
        ],
      ],
    );

    if (_usesGradientFill) {
      return _GradientPrimaryButton(
        onPressed: onPressed,
        foregroundColor: fg,
        minimumHeight: _resolvedHeight,
        fullWidth: fullWidth,
        gradient: decorationGradient ?? AppColors.primaryButtonGradient,
        child: child,
      );
    }

    final bg = backgroundColor ?? scheme.primary;
    final filled = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: Size(fullWidth ? double.infinity : 0, _resolvedHeight),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: const StadiumBorder(),
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: bg.withValues(alpha: 0.4),
      ),
      child: child,
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: filled);
    }
    return filled;
  }
}

class _GradientPrimaryButton extends StatelessWidget {
  const _GradientPrimaryButton({
    required this.onPressed,
    required this.foregroundColor,
    required this.minimumHeight,
    required this.fullWidth,
    required this.gradient,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Color foregroundColor;
  final double minimumHeight;
  final bool fullWidth;
  final Gradient gradient;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    final label = Padding(
      padding: const EdgeInsets.all(10),
      child: Center(
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: IconTheme.merge(
            data: IconThemeData(color: foregroundColor),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: foregroundColor),
              child: child,
            ),
          ),
        ),
      ),
    );

    final pill = ClipRRect(
      borderRadius: AppPrimaryButton._pillRadius,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          splashColor: Colors.white24,
          highlightColor: Colors.white12,
          child: Ink(
            decoration: BoxDecoration(gradient: gradient),
            child: SizedBox(
              height: minimumHeight,
              width: fullWidth ? double.infinity : null,
              child: label,
            ),
          ),
        ),
      ),
    );

    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        height: minimumHeight,
        child: pill,
      );
    }
    return SizedBox(height: minimumHeight, child: pill);
  }
}
