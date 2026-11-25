import 'package:flutter/material.dart';

import 'package:jameel/shared/styles/app_design.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = 20,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    final resolvedColor = color ?? context.surfaceColor;
    final resolvedBorder = borderColor ?? context.borderColor;
    return Container(
      decoration: BoxDecoration(
        color: resolvedColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: resolvedBorder),
        boxShadow: (shadow && !context.isDark) ? AppShadows.soft : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

/// Red gradient header with soft decorative circles. Used on Login, Home and
/// Profile so the app has one consistent "hero" moment per main screen.
class HeroBackground extends StatelessWidget {
  const HeroBackground({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 28),
    this.radius = 32,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  Widget _circle(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: Stack(
          children: [
            Positioned(top: -70, right: -50, child: _circle(210, 0.08)),
            Positioned(bottom: -60, left: -40, child: _circle(160, 0.06)),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// Subtle architectural marble & geometric background ornament shared across
/// main and secondary screens so light/white pages feel cohesive and refined
/// without reducing card or typography legibility.
class PageOrnamentBackground extends StatelessWidget {
  const PageOrnamentBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _PageOrnamentPainter(isDark: context.isDark),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _PageOrnamentPainter extends CustomPainter {
  const _PageOrnamentPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // 1. Subtle ambient corner washes.
    final topGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withValues(alpha: isDark ? 0.06 : 0.035),
          AppColors.primary.withValues(alpha: 0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.92, size.height * 0.10),
          radius: size.width * 0.65,
        ),
      );
    canvas.drawRect(Offset.zero & size, topGlow);

    final bottomGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.info.withValues(alpha: isDark ? 0.045 : 0.025),
          AppColors.info.withValues(alpha: 0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.08, size.height * 0.88),
          radius: size.width * 0.58,
        ),
      );
    canvas.drawRect(Offset.zero & size, bottomGlow);

    // 2. Delicate concentric architectural rings in opposite corners.
    final ringPaint = Paint()
      ..color = (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF94A3B8))
          .withValues(alpha: isDark ? 0.065 : 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final topOrigin = Offset(size.width * 1.02, size.height * 0.06);
    for (final r in [110.0, 155.0, 200.0]) {
      canvas.drawCircle(topOrigin, r, ringPaint);
    }

    final bottomOrigin = Offset(-size.width * 0.04, size.height * 0.94);
    for (final r in [120.0, 170.0]) {
      canvas.drawCircle(bottomOrigin, r, ringPaint);
    }

    // 3. Flowing silk marble veins matching Jameel's brand motif.
    final softVein = Paint()
      ..color = (isDark ? const Color(0xFF4B5563) : const Color(0xFFB7BBC2))
          .withValues(alpha: isDark ? 0.055 : 0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fineVein = Paint()
      ..color = (isDark ? const Color(0xFF6B7280) : const Color(0xFF9EA3AC))
          .withValues(alpha: isDark ? 0.095 : 0.105)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final veins = [
      Path()
        ..moveTo(-size.width * 0.05, size.height * 0.34)
        ..cubicTo(
          size.width * 0.24,
          size.height * 0.30,
          size.width * 0.34,
          size.height * 0.42,
          size.width * 0.66,
          size.height * 0.37,
        )
        ..cubicTo(
          size.width * 0.85,
          size.height * 0.34,
          size.width * 0.92,
          size.height * 0.41,
          size.width * 1.06,
          size.height * 0.39,
        ),
      Path()
        ..moveTo(size.width * 1.05, size.height * 0.62)
        ..cubicTo(
          size.width * 0.76,
          size.height * 0.67,
          size.width * 0.62,
          size.height * 0.56,
          size.width * 0.34,
          size.height * 0.64,
        )
        ..cubicTo(
          size.width * 0.15,
          size.height * 0.69,
          size.width * 0.08,
          size.height * 0.62,
          -size.width * 0.04,
          size.height * 0.66,
        ),
      Path()
        ..moveTo(-size.width * 0.04, size.height * 0.84)
        ..cubicTo(
          size.width * 0.28,
          size.height * 0.80,
          size.width * 0.48,
          size.height * 0.91,
          size.width * 1.04,
          size.height * 0.85,
        ),
    ];

    for (final path in veins) {
      canvas.drawPath(path, softVein);
      canvas.drawPath(path, fineVein);
    }

    // 4. Minimal geometric dot accents at outer corners.
    final dotPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: isDark ? 0.09 : 0.065)
      ..style = PaintingStyle.fill;

    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 4; col++) {
        canvas.drawCircle(
          Offset(20 + col * 12.0, size.height * 0.24 + row * 12.0),
          1.35,
          dotPaint,
        );
        canvas.drawCircle(
          Offset(
            size.width - 20 - col * 12.0,
            size.height * 0.76 - row * 12.0,
          ),
          1.35,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PageOrnamentPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
