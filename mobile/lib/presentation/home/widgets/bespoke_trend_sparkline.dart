import 'package:flutter/material.dart';

/// Bespoke Smooth Bezier Sparkline Chart
/// Paints a liquid smooth waveform with an ambient gradient fill under the curve.
class BespokeTrendSparkline extends StatelessWidget {
  final List<double> dataPoints;
  final double height;
  final double width;
  final Color lineColor;
  final bool showFill;
  final bool isDark;

  const BespokeTrendSparkline({
    super.key,
    required this.dataPoints,
    this.height = 42,
    this.width = double.infinity,
    this.lineColor = const Color(0xFF2563EB),
    this.showFill = true,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: CustomPaint(
        painter: _SparklinePainter(
          points: dataPoints.isEmpty ? [30, 45, 40, 60, 55, 75, 80] : dataPoints,
          lineColor: lineColor,
          showFill: showFill,
          isDark: isDark,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color lineColor;
  final bool showFill;
  final bool isDark;

  _SparklinePainter({
    required this.points,
    required this.lineColor,
    required this.showFill,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final minVal = points.reduce((a, b) => a < b ? a : b);
    final maxVal = points.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final stepX = size.width / (points.length - 1);
    final mappedPoints = <Offset>[];

    for (int i = 0; i < points.length; i++) {
      final normalizedY = (points[i] - minVal) / range;
      // Invert Y for canvas coordinate system, pad top & bottom
      final y = size.height - (normalizedY * (size.height - 10)) - 5;
      final x = i * stepX;
      mappedPoints.add(Offset(x, y));
    }

    final path = Path();
    path.moveTo(mappedPoints[0].dx, mappedPoints[0].dy);

    for (int i = 0; i < mappedPoints.length - 1; i++) {
      final p0 = mappedPoints[i];
      final p1 = mappedPoints[i + 1];
      final midX = (p0.dx + p1.dx) / 2;

      path.cubicTo(
        midX, p0.dy,
        midX, p1.dy,
        p1.dx, p1.dy,
      );
    }

    // 1. Ambient Gradient Area Fill
    if (showFill) {
      final fillPath = Path.from(path);
      fillPath.lineTo(size.width, size.height);
      fillPath.lineTo(0, size.height);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: isDark ? 0.35 : 0.18),
            lineColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }

    // 2. Stroke Line
    final strokePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);

    // 3. Endpoint Pulse Dot
    final lastPoint = mappedPoints.last;
    final dotOuter = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(lastPoint, 3.8, dotOuter);

    final dotInner = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(lastPoint, 2.2, dotInner);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.showFill != showFill;
  }
}
