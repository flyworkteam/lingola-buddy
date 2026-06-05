import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Yerel kamera önizlemesi — kart boyutunu değiştirmeden [BoxFit.cover] ile doldurur.
class LocalCameraPreview extends StatelessWidget {
  const LocalCameraPreview({
    super.key,
    required this.controller,
  });

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const ColoredBox(color: Color(0xFFF6F6F6));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _previewWidth(controller),
                height: _previewHeight(controller),
                child: CameraPreview(controller),
              ),
            ),
          ),
        );
      },
    );
  }

  double _previewWidth(CameraController c) {
    final s = c.value.previewSize;
    if (s == null) return 1;
    return s.height;
  }

  double _previewHeight(CameraController c) {
    final s = c.value.previewSize;
    if (s == null) return 1;
    return s.width;
  }
}
