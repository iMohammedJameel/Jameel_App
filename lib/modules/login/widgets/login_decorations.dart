import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:jameel/shared/styles/app_design.dart';

class LoginMarblePainter extends CustomPainter {
  const LoginMarblePainter({this.isDark = false});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final veins = [
      Path()
        ..moveTo(size.width * 1.04, size.height * 0.37)
        ..cubicTo(
          size.width * 0.82,
          size.height * 0.43,
          size.width * 0.9,
          size.height * 0.48,
          size.width * 0.64,
          size.height * 0.54,
        )
        ..cubicTo(
          size.width * 0.46,
          size.height * 0.59,
          size.width * 0.79,
          size.height * 0.61,
          size.width * 1.03,
          size.height * 0.66,
        ),
      Path()
        ..moveTo(-size.width * 0.06, size.height * 0.63)
        ..cubicTo(
          size.width * 0.2,
          size.height * 0.6,
          size.width * 0.08,
          size.height * 0.72,
          size.width * 0.34,
          size.height * 0.69,
        )
        ..cubicTo(
          size.width * 0.57,
          size.height * 0.66,
          size.width * 0.55,
          size.height * 0.76,
          size.width * 0.9,
          size.height * 0.76,
        ),
      Path()
        ..moveTo(size.width * 0.98, size.height * 0.82)
        ..cubicTo(
          size.width * 0.74,
          size.height * 0.86,
          size.width * 0.82,
          size.height * 0.92,
          size.width * 0.58,
          size.height * 0.96,
        ),
      Path()
        ..moveTo(-size.width * 0.04, size.height * 0.8)
        ..cubicTo(
          size.width * 0.22,
          size.height * 0.83,
          size.width * 0.2,
          size.height * 0.75,
          size.width * 0.46,
          size.height * 0.81,
        )
        ..cubicTo(
          size.width * 0.7,
          size.height * 0.87,
          size.width * 0.82,
          size.height * 0.78,
          size.width * 1.04,
          size.height * 0.84,
        ),
      Path()
        ..moveTo(-size.width * 0.05, size.height * 0.92)
        ..cubicTo(
          size.width * 0.2,
          size.height * 0.88,
          size.width * 0.14,
          size.height * 0.98,
          size.width * 0.42,
          size.height * 0.93,
        )
        ..cubicTo(
          size.width * 0.66,
          size.height * 0.88,
          size.width * 0.8,
          size.height * 0.99,
          size.width * 1.05,
          size.height * 0.94,
        ),
      Path()
        ..moveTo(size.width * 0.43, size.height * 0.76)
        ..cubicTo(
          size.width * 0.55,
          size.height * 0.8,
          size.width * 0.48,
          size.height * 0.85,
          size.width * 0.68,
          size.height * 0.83,
        )
        ..cubicTo(
          size.width * 0.84,
          size.height * 0.81,
          size.width * 0.9,
          size.height * 0.87,
          size.width * 1.04,
          size.height * 0.88,
        ),
    ];

    final softPaint = Paint()
      ..color = (isDark ? const Color(0xFF4B5563) : const Color(0xFFB7BBC2))
          .withValues(alpha: isDark ? 0.08 : 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final veinPaint = Paint()
      ..color = (isDark ? const Color(0xFF6B7280) : const Color(0xFF9EA3AC))
          .withValues(alpha: isDark ? 0.14 : 0.17)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final vein in veins) {
      canvas.drawPath(vein, softPaint);
      canvas.drawPath(vein, veinPaint);
    }

    final branch = Path()
      ..moveTo(size.width * 0.64, size.height * 0.54)
      ..cubicTo(
        size.width * 0.61,
        size.height * 0.5,
        size.width * 0.68,
        size.height * 0.47,
        size.width * 0.7,
        size.height * 0.43,
      );
    canvas.drawPath(branch, veinPaint);
  }

  @override
  bool shouldRepaint(covariant LoginMarblePainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Opacity(
      opacity: onPressed == null && !loading ? 0.5 : 1,
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            backgroundColor: context.surfaceColor,
            foregroundColor: context.inkColor,
            side: BorderSide(color: context.borderColor, width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.primary,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CustomPaint(painter: _GoogleMarkPainter()),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: context.inkColor,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.2;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Blue right-side arc
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.05 * math.pi, 0.34 * math.pi, false, paint);

    // Green bottom arc
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.28 * math.pi, 0.52 * math.pi, false, paint);

    // Yellow left arc
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 0.79 * math.pi, 0.43 * math.pi, false, paint);

    // Red top arc
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 1.21 * math.pi, 0.56 * math.pi, false, paint);

    // Blue horizontal crossbar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    final cy = size.height / 2;
    canvas.drawLine(
      Offset(size.width * 0.5, cy),
      Offset(size.width * 0.95, cy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleMarkPainter oldDelegate) => false;
}
