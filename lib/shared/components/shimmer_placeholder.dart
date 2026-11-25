import 'package:flutter/material.dart';

import 'package:jameel/shared/components/app_surfaces.dart';
import 'package:jameel/shared/styles/app_design.dart';

class ShimmerListPlaceholder extends StatefulWidget {
  const ShimmerListPlaceholder({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  State<ShimmerListPlaceholder> createState() => _ShimmerListPlaceholderState();
}

class _ShimmerListPlaceholderState extends State<ShimmerListPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = context.isDark
        ? const Color(0xFF222736)
        : const Color(0xFFE9ECF4);
    final highlightColor = context.isDark
        ? const Color(0xFF2D3347)
        : const Color(0xFFF6F7FB);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 2 - 1;
        return Column(
          children: List.generate(widget.itemCount, (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < widget.itemCount - 1 ? 10 : 0,
              ),
              child: AppCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    _shimmerBlock(44, 44, 14, baseColor, highlightColor, t),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _shimmerBlock(
                              140, 14, 7, baseColor, highlightColor, t),
                          const SizedBox(height: 8),
                          _shimmerBlock(
                              90, 11, 6, baseColor, highlightColor, t),
                        ],
                      ),
                    ),
                    _shimmerBlock(56, 22, 11, baseColor, highlightColor, t),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _shimmerBlock(
    double width,
    double height,
    double radius,
    Color baseColor,
    Color highlightColor,
    double slide,
  ) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(-1 + slide, 0),
          end: Alignment(1 + slide, 0),
          colors: [baseColor, highlightColor, baseColor],
        ),
      ),
    );
  }
}
