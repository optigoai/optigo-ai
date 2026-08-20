import 'dart:math' as math;
import 'package:flutter/material.dart';

class GaugeWavePainter extends CustomPainter {
  final double score; // 0 to 100
  final Color trackColor;
  final Color progressColor;

  GaugeWavePainter({
    required this.score,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85);
    final radius = size.width * 0.42;

    // 1. Background Arc (Track)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      trackPaint,
    );

    // 2. Progress Gradient Arc
    final progressSweep = math.pi * (score.clamp(0, 100) / 100);
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [progressColor.withValues(alpha: 0.7), progressColor],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      progressSweep,
      false,
      progressPaint,
    );

    // 3. Indicator Thumb Dot
    final thumbAngle = math.pi + progressSweep;
    final thumbX = center.dx + radius * math.cos(thumbAngle);
    final thumbY = center.dy + radius * math.sin(thumbAngle);

    final thumbOuterPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(thumbX, thumbY), 6.0, thumbOuterPaint);

    final thumbInnerPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(thumbX, thumbY), 3.5, thumbInnerPaint);

    // 4. Sparkline Wave inside the gauge
    final wavePaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final wavePath = Path();
    final startX = center.dx - radius * 0.65;
    final startY = center.dy - 6;
    wavePath.moveTo(startX, startY);

    wavePath.cubicTo(
      startX + 14, startY - 12,
      startX + 22, startY + 8,
      startX + 34, startY - 14,
    );
    wavePath.cubicTo(
      startX + 44, startY + 16,
      startX + 56, startY - 8,
      startX + 68, startY - 2,
    );

    canvas.drawPath(wavePath, wavePaint);
  }

  @override
  bool shouldRepaint(covariant GaugeWavePainter oldDelegate) {
    return oldDelegate.score != score ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}
