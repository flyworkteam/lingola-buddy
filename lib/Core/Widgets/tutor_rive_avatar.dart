import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:lingola_buddy/Core/Widgets/avatar_shimmer.dart';
import 'package:lingola_buddy/Core/Widgets/tutor_avatar_image.dart';
import 'package:lingola_buddy/Models/tutor_model.dart';
import 'package:lingola_buddy/Services/rive_preload_service.dart';
import 'package:rive/rive.dart' as rive;

/// CDN .riv — yüklenene kadar shimmer; Rive hazır olunca animasyon gösterilir.
class TutorRiveAvatar extends StatefulWidget {
  const TutorRiveAvatar({
    super.key,
    required this.tutor,
    this.isTalking = false,
    this.fit = BoxFit.cover,
    this.alignment = const Alignment(0, -1.05),
    this.cacheWidth,
    this.cacheHeight,
    this.shimmerBaseColor,
    this.shimmerHighlightColor,
  });

  final TutorModel tutor;
  final bool isTalking;
  final BoxFit fit;
  final Alignment alignment;
  final int? cacheWidth;
  final int? cacheHeight;
  final Color? shimmerBaseColor;
  final Color? shimmerHighlightColor;

  @override
  State<TutorRiveAvatar> createState() => _TutorRiveAvatarState();
}

class _TutorRiveAvatarState extends State<TutorRiveAvatar> {
  rive.FileLoader? _loader;
  rive.RiveWidgetController? _controller;
  rive.ViewModelInstance? _viewModel;
  rive.BooleanInput? _smTalk;
  bool _riveVisible = false;
  bool _riveFailed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_resolveLoader());
  }

  Future<void> _resolveLoader() async {
    final loader =
        await RivePreloadService.instance.ensureLoader(widget.tutor.rivUrl);
    if (!mounted) return;
    setState(() {
      _loader = loader;
      _riveFailed = loader == null;
      if (_riveFailed) _riveVisible = false;
    });
  }

  @override
  void didUpdateWidget(covariant TutorRiveAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tutor.rivUrl != widget.tutor.rivUrl) {
      _riveVisible = false;
      _loader = null;
      _riveFailed = false;
      unawaited(_resolveLoader());
    }
    if (oldWidget.isTalking != widget.isTalking) {
      _syncTalk();
    }
  }

  void _onLoaded(rive.RiveLoaded loaded) {
    _controller = loaded.controller;
    try {
      _viewModel = _controller?.dataBind(rive.DataBind.auto());
    } catch (_) {
      _viewModel = null;
    }
    if (_viewModel == null) {
      try {
        final wc = _controller as rive.RiveWidgetController;
        _smTalk = wc.stateMachine.boolean('talk');
      } catch (_) {}
    }
    if (!_riveVisible && mounted) {
      setState(() => _riveVisible = true);
    }
    _syncTalk();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncTalk();
    });
  }

  void _syncTalk() {
    final talk = widget.isTalking;
    final vm = _viewModel;
    if (vm != null) {
      try {
        vm.boolean('talk')?.value = talk;
        if (!talk) vm.number('visemeNum')?.value = 0;
      } catch (_) {}
      return;
    }
    try {
      _smTalk?.value = talk;
    } catch (_) {}
  }

  Widget _loadingPlaceholder() {
    return AvatarShimmer(
      baseColor: widget.shimmerBaseColor ?? const Color(0xFFE8E8EC),
      highlightColor: widget.shimmerHighlightColor ?? const Color(0xFFF8F8FA),
    );
  }

  Widget _photoFallback() {
    return TutorAvatarImage(
      tutor: widget.tutor,
      fit: widget.fit,
      alignment: widget.alignment,
      cacheWidth: widget.cacheWidth,
      cacheHeight: widget.cacheHeight,
      shimmerBaseColor: widget.shimmerBaseColor,
      shimmerHighlightColor: widget.shimmerHighlightColor,
    );
  }

  rive.Fit _toRiveFit(BoxFit fit) {
    switch (fit) {
      case BoxFit.contain:
        return rive.Fit.contain;
      case BoxFit.fill:
        return rive.Fit.fill;
      case BoxFit.fitWidth:
        return rive.Fit.fitWidth;
      case BoxFit.fitHeight:
        return rive.Fit.fitHeight;
      case BoxFit.none:
        return rive.Fit.none;
      case BoxFit.scaleDown:
        return rive.Fit.scaleDown;
      case BoxFit.cover:
        return rive.Fit.cover;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_riveFailed) {
      return _photoFallback();
    }

    final loader = _loader;
    if (loader == null) {
      return _loadingPlaceholder();
    }

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!_riveVisible) _loadingPlaceholder(),
          rive.RiveWidgetBuilder(
            fileLoader: loader,
            onLoaded: _onLoaded,
            builder: (context, state) {
              return switch (state) {
                rive.RiveLoading() => const SizedBox.shrink(),
                rive.RiveFailed() => _photoFallback(),
                rive.RiveLoaded() => rive.RiveWidget(
                  controller: state.controller,
                  fit: _toRiveFit(widget.fit),
                  alignment: widget.alignment,
                ),
              };
            },
          ),
        ],
      ),
    );
  }
}
