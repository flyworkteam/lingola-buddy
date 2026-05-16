import 'package:flutter/material.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';
import 'package:lingola_buddy/Core/Theme/app_text_styles.dart';

/// Kelime alanı boyutunda yükleniyor shimmer’ı.
class WordShimmer extends StatefulWidget {
  const WordShimmer({
    super.key,
    required this.child,
    this.borderRadius = 4,
  });

  /// Boyut için görünmez metin (orijinal kelime).
  final Widget child;
  final double borderRadius;

  @override
  State<WordShimmer> createState() => _WordShimmerState();
}

class _WordShimmerState extends State<WordShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1 + _controller.value * 2, 0),
              end: Alignment(_controller.value * 2, 0),
              colors: const [
                Color(0xFFE4E4E7),
                Color(0xFFF8F8FA),
                Color(0xFFE4E4E7),
              ],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE4E4E7),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.transparent),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Mor kapsül içinde çevrilmiş kelime.
class TranslatedWordChip extends StatelessWidget {
  const TranslatedWordChip({
    super.key,
    required this.text,
    required this.onTap,
  });

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: AppColors.brandPrimary,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: AppTextStyles.chatTutorMessage().copyWith(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

String inlineTranslatedPart(String originalToken, String translation) {
  final cleaned =
      originalToken.replaceAll(RegExp(r"[^\p{L}'\-]", unicode: true), '');
  if (cleaned.isEmpty) return translation;
  final start = originalToken.toLowerCase().indexOf(cleaned.toLowerCase());
  if (start < 0) return translation;
  return originalToken.substring(0, start) +
      translation +
      originalToken.substring(start + cleaned.length);
}
