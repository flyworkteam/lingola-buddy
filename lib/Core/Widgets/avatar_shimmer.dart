import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Grid/liste gibi çoklu avatar yüklemelerinde tek zamanlayıcı ile shimmer.
final class AvatarShimmerDriver {
  AvatarShimmerDriver._();
  static final AvatarShimmerDriver instance = AvatarShimmerDriver._();

  final ValueNotifier<double> phase = ValueNotifier(0);
  Timer? _timer;
  int _refs = 0;

  void acquire() {
    _refs++;
    if (_timer != null) return;
    var t = 0.0;
    _timer = Timer.periodic(const Duration(milliseconds: 32), (_) {
      t += 0.032 / 1.1;
      if (t >= 1) t -= 1;
      phase.value = t;
    });
  }

  void release() {
    _refs = math.max(0, _refs - 1);
    if (_refs > 0 || _timer == null) return;
    _timer!.cancel();
    _timer = null;
    phase.value = 0;
  }
}

/// Eğitmen portresi yüklenirken hafif shimmer — paylaşımlı animasyon tick'i.
class AvatarShimmer extends StatefulWidget {
  const AvatarShimmer({
    super.key,
    this.width,
    this.height,
    this.baseColor = const Color(0xFFE8E8EC),
    this.highlightColor = const Color(0xFFF8F8FA),
    this.borderRadius = BorderRadius.zero,
  });

  final double? width;
  final double? height;
  final Color baseColor;
  final Color highlightColor;
  final BorderRadius borderRadius;

  @override
  State<AvatarShimmer> createState() => _AvatarShimmerState();
}

class _AvatarShimmerState extends State<AvatarShimmer> {
  @override
  void initState() {
    super.initState();
    AvatarShimmerDriver.instance.acquire();
  }

  @override
  void dispose() {
    AvatarShimmerDriver.instance.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: ValueListenableBuilder<double>(
          valueListenable: AvatarShimmerDriver.instance.phase,
          builder: (context, phase, _) {
            return ClipRRect(
              borderRadius: widget.borderRadius,
              child: ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (bounds) {
                  return LinearGradient(
                    begin: Alignment(-1 + phase * 2, 0),
                    end: Alignment(phase * 2, 0),
                    colors: [
                      widget.baseColor,
                      widget.highlightColor,
                      widget.baseColor,
                    ],
                    stops: const [0.25, 0.5, 0.75],
                  ).createShader(bounds);
                },
                child: ColoredBox(color: widget.baseColor),
              ),
            );
          },
        ),
      ),
    );
  }
}
