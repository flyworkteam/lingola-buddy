import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';

/// Kayıt sırasında ses seviyesine tepki veren dalga çubukları.
class VoiceWaveformBars extends StatefulWidget {
  const VoiceWaveformBars({
    super.key,
    required this.level,
    this.barCount = 28,
    this.height = 32,
    this.color = AppColors.brandPrimary,
  });

  /// 0.0 – 1.0 arası normalize ses seviyesi.
  final double level;
  final int barCount;
  final double height;
  final Color color;

  @override
  State<VoiceWaveformBars> createState() => _VoiceWaveformBarsState();
}

class _VoiceWaveformBarsState extends State<VoiceWaveformBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.level.clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = _pulse.value * math.pi * 2;
        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (i) {
              final phase = (i / widget.barCount) * math.pi * 2;
              final wave = (math.sin(t + phase) + 1) / 2;
              final barH = (4 + level * (widget.height - 4) * (0.25 + 0.75 * wave))
                  .clamp(4.0, widget.height);
              return Padding(
                padding: EdgeInsets.only(
                  right: i < widget.barCount - 1 ? 3 : 0,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 60),
                  curve: Curves.easeOut,
                  width: 3,
                  height: barH,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(
                      alpha: 0.45 + level * 0.55,
                    ),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
