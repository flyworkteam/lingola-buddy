import 'package:flutter/material.dart';
import 'package:lingola_buddy/Core/Theme/app_colors.dart';

/// Sohbet geçmişi yüklenirken mesaj balonu iskeleti.
class ChatMessagesShimmerList extends StatefulWidget {
  const ChatMessagesShimmerList({super.key});

  @override
  State<ChatMessagesShimmerList> createState() => _ChatMessagesShimmerListState();
}

class _ChatMessagesShimmerListState extends State<ChatMessagesShimmerList>
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      children: [
        _ShimmerBubble(
          controller: _controller,
          align: Alignment.centerLeft,
          widthFactor: 0.72,
          tint: const Color(0xFFF0F0F0),
        ),
        const SizedBox(height: 12),
        _ShimmerBubble(
          controller: _controller,
          align: Alignment.centerRight,
          widthFactor: 0.45,
          tint: AppColors.brandPrimary.withValues(alpha: 0.15),
        ),
        const SizedBox(height: 12),
        _ShimmerBubble(
          controller: _controller,
          align: Alignment.centerLeft,
          widthFactor: 0.58,
          tint: const Color(0xFFF0F0F0),
        ),
        const SizedBox(height: 12),
        _ShimmerBubble(
          controller: _controller,
          align: Alignment.centerRight,
          widthFactor: 0.52,
          tint: AppColors.brandPrimary.withValues(alpha: 0.15),
        ),
      ],
    );
  }
}

class _ShimmerBubble extends StatelessWidget {
  const _ShimmerBubble({
    required this.controller,
    required this.align,
    required this.widthFactor,
    required this.tint,
  });

  final AnimationController controller;
  final Alignment align;
  final double widthFactor;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.sizeOf(context).width - 32;
    return Align(
      alignment: align,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment(-1 + controller.value * 2, 0),
                end: Alignment(controller.value * 2, 0),
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
          width: maxW * widthFactor,
          height: 52,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
