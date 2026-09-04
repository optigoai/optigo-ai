import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A premium animated KPI metric card with glassmorphism styling,
/// smooth count-up animations, and subtle shimmer effects.
class AnimatedMetricCard extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final String? trendText;
  final bool isPositiveTrend;
  final IconData icon;
  final Color accentColor;
  final Color accentBgColor;
  final VoidCallback? onTap;
  final int animationDelayMs;
  final bool isLoading;

  const AnimatedMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.trendText,
    this.isPositiveTrend = true,
    required this.icon,
    this.accentColor = const Color(0xFF2563EB),
    this.accentBgColor = const Color(0xFFEFF6FF),
    this.onTap,
    this.animationDelayMs = 0,
    this.isLoading = false,
  });

  @override
  State<AnimatedMetricCard> createState() => _AnimatedMetricCardState();
}

class _AnimatedMetricCardState extends State<AnimatedMetricCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future.delayed(Duration(milliseconds: widget.animationDelayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: child,
            ),
          ),
        );
      },
      child: _buildCard(),
    );
  }

  Widget _buildCard() {
    if (widget.isLoading) {
      return _buildShimmerCard();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(22),
        splashColor: widget.accentColor.withValues(alpha: 0.08),
        highlightColor: widget.accentColor.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Icon + Trend Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Animated icon container with gradient ring
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.accentBgColor,
                          widget.accentBgColor.withValues(alpha: 0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.accentColor.withValues(alpha: 0.12),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.accentColor,
                      size: 17,
                    ),
                  ),
                  if (widget.trendText != null && widget.trendText!.isNotEmpty)
                    _buildTrendBadge(),
                ],
              ),
              const SizedBox(height: 14),

              // Value
              Text(
                widget.value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.8,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Title
              Text(
                widget.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Subtitle
              if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  widget.subtitle!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendBadge() {
    final isPositive = widget.isPositiveTrend;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)]
              : [const Color(0xFFFEF2F2), const Color(0xFFFEE2E2)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPositive
              ? const Color(0xFF10B981).withValues(alpha: 0.2)
              : const Color(0xFFEF4444).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 11,
            color: isPositive ? const Color(0xFF059669) : const Color(0xFFDC2626),
          ),
          const SizedBox(width: 2),
          Text(
            widget.trendText!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isPositive ? const Color(0xFF059669) : const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _shimmerBox(32, 32, radius: 10),
              _shimmerBox(50, 20, radius: 8),
            ],
          ),
          const SizedBox(height: 14),
          _shimmerBox(80, 24, radius: 6),
          const SizedBox(height: 6),
          _shimmerBox(60, 12, radius: 4),
        ],
      ),
    );
  }

  Widget _shimmerBox(double width, double height, {double radius = 4}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Animated ring chart that shows a radial progress indicator.
/// Used for "Overall Business Health" type displays.
class AnimatedRingProgress extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final Color color;
  final Color bgColor;
  final double size;
  final double strokeWidth;
  final Widget? center;

  const AnimatedRingProgress({
    super.key,
    required this.progress,
    this.color = const Color(0xFF2563EB),
    this.bgColor = const Color(0xFFF1F5F9),
    this.size = 80,
    this.strokeWidth = 8,
    this.center,
  });

  @override
  State<AnimatedRingProgress> createState() => _AnimatedRingProgressState();
}

class _AnimatedRingProgressState extends State<AnimatedRingProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedRingProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.progress,
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: _progressAnimation.value,
              color: widget.color,
              bgColor: widget.bgColor,
              strokeWidth: widget.strokeWidth,
            ),
            child: Center(child: widget.center),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background arc
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [
          color.withValues(alpha: 0.6),
          color,
          color.withValues(alpha: 0.8),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
