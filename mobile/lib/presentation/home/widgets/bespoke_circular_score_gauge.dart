import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bespoke Animated Circular Score Gauge for OptigoAI Business Health
/// Features smooth 60fps sweep arc, dynamic particle glow aura, and clean metric badges.
class BespokeCircularScoreGauge extends StatefulWidget {
  final int score; // 0 to 100
  final double size;
  final bool isDarkCard;

  const BespokeCircularScoreGauge({
    super.key,
    required this.score,
    this.size = 110,
    this.isDarkCard = true,
  });

  @override
  State<BespokeCircularScoreGauge> createState() =>
      _BespokeCircularScoreGaugeState();
}

class _BespokeCircularScoreGaugeState extends State<BespokeCircularScoreGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scoreAnimation = Tween<double>(
      begin: 0,
      end: widget.score.toDouble().clamp(0, 100),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant BespokeCircularScoreGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _scoreAnimation = Tween<double>(
        begin: _scoreAnimation.value,
        end: widget.score.toDouble().clamp(0, 100),
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getScoreColor(double val) {
    if (val >= 75) return const Color(0xFF10B981); // Emerald
    if (val >= 50) return const Color(0xFF3B82F6); // Azure
    return const Color(0xFFEF4444); // Coral
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scoreAnimation,
      builder: (context, child) {
        final currentVal = _scoreAnimation.value;
        final scoreColor = _getScoreColor(currentVal);

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Ambient Background Glow Aura (For dark cards)
              if (widget.isDarkCard)
                Container(
                  width: widget.size * 0.75,
                  height: widget.size * 0.75,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: scoreColor.withValues(alpha: 0.28),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),

              // 2. Custom Painted Circular Arc
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RadialScorePainter(
                  score: currentVal,
                  color: scoreColor,
                  isDark: widget.isDarkCard,
                ),
              ),

              // 3. Center Score Typography
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${currentVal.toInt()}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: widget.size * 0.32,
                      fontWeight: FontWeight.w900,
                      color:
                          widget.isDarkCard
                              ? Colors.white
                              : const Color(0xFF0F172A),
                      letterSpacing: -1.0,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'SCORE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: widget.size * 0.09,
                      fontWeight: FontWeight.w800,
                      color:
                          widget.isDarkCard
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RadialScorePainter extends CustomPainter {
  final double score; // 0 to 100
  final Color color;
  final bool isDark;

  _RadialScorePainter({
    required this.score,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    const strokeWidth = 8.0;

    // Start angle: bottom-left (-220 deg in radians), Sweep angle: 260 deg (4.537 rad)
    const startAngle = 135 * math.pi / 180;
    const totalSweep = 270 * math.pi / 180;
    final progressSweep = totalSweep * (score / 100);

    // Track Paint
    final trackPaint =
        Paint()
          ..color =
              isDark
                  ? const Color(0xFF334155).withValues(alpha: 0.45)
                  : const Color(0xFFE2E8F0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalSweep,
      false,
      trackPaint,
    );

    if (score > 0) {
      // Gradient Progress Arc
      final sweepRect = Rect.fromCircle(center: center, radius: radius);
      final gradient = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + totalSweep,
        colors: [color.withValues(alpha: 0.6), color],
      );

      final progressPaint =
          Paint()
            ..shader = gradient.createShader(sweepRect)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        sweepRect,
        startAngle,
        progressSweep,
        false,
        progressPaint,
      );

      // Endpoint Indicator Dot with subtle pulse
      final endAngle = startAngle + progressSweep;
      final dotX = center.dx + radius * math.cos(endAngle);
      final dotY = center.dy + radius * math.sin(endAngle);

      final outerDot =
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(dotX, dotY), 4.5, outerDot);

      final innerDot =
          Paint()
            ..color = color
            ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(dotX, dotY), 2.5, innerDot);
    }
  }

  @override
  bool shouldRepaint(covariant _RadialScorePainter oldDelegate) {
    return oldDelegate.score != score ||
        oldDelegate.color != color ||
        oldDelegate.isDark != isDark;
  }
}
