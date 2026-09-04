import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A premium animated donut chart showing channel breakdown
/// (Google Search, Google Maps, Direct, etc.) with interactive segments.
class ChannelBreakdownDonut extends StatefulWidget {
  final Map<String, int> channelData; // e.g., {'Google Search': 420, 'Google Maps': 310, ...}

  const ChannelBreakdownDonut({super.key, required this.channelData});

  @override
  State<ChannelBreakdownDonut> createState() => _ChannelBreakdownDonutState();
}

class _ChannelBreakdownDonutState extends State<ChannelBreakdownDonut>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sweepAnimation;
  late Animation<double> _fadeAnimation;
  int? _selectedIndex;

  // Color palette for donut segments
  static const List<Color> _segmentColors = [
    Color(0xFF2563EB), // Blue
    Color(0xFF7C3AED), // Purple
    Color(0xFF059669), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF06B6D4), // Cyan
  ];

  static const List<Color> _segmentLightColors = [
    Color(0xFFEFF6FF),
    Color(0xFFF5F3FF),
    Color(0xFFECFDF5),
    Color(0xFFFFFBEB),
    Color(0xFFFEF2F2),
    Color(0xFFECFEFF),
  ];

  static const Map<String, IconData> _channelIcons = {
    'google_search': Icons.search_rounded,
    'google_maps': Icons.place_rounded,
    'direct': Icons.open_in_browser_rounded,
    'referral': Icons.share_rounded,
    'social': Icons.groups_rounded,
    'other': Icons.more_horiz_rounded,
  };

  static const Map<String, String> _channelLabels = {
    'google_search': 'Google Search',
    'google_maps': 'Google Maps',
    'direct': 'Direct',
    'referral': 'Referral',
    'social': 'Social',
    'other': 'Other',
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _sweepAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_ChannelSegment> get _segments {
    final data = widget.channelData;
    if (data.isEmpty) {
      return [
        _ChannelSegment('google_search', 'Google Search', 45, _segmentColors[0], _segmentLightColors[0], Icons.search_rounded),
        _ChannelSegment('google_maps', 'Google Maps', 30, _segmentColors[1], _segmentLightColors[1], Icons.place_rounded),
        _ChannelSegment('direct', 'Direct', 15, _segmentColors[2], _segmentLightColors[2], Icons.open_in_browser_rounded),
        _ChannelSegment('social', 'Social', 10, _segmentColors[3], _segmentLightColors[3], Icons.groups_rounded),
      ];
    }

    final total = data.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return [];

    final entries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries.asMap().entries.map((e) {
      final idx = e.key;
      final entry = e.value;
      final pct = (entry.value / total * 100).round();
      final label = _channelLabels[entry.key] ?? entry.key;
      final icon = _channelIcons[entry.key] ?? Icons.analytics_rounded;
      return _ChannelSegment(
        entry.key,
        label,
        pct,
        _segmentColors[idx % _segmentColors.length],
        _segmentLightColors[idx % _segmentLightColors.length],
        icon,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final segments = _segments;
    final total = widget.channelData.values.fold<int>(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.12)),
                ),
                child: const Icon(Icons.donut_large_rounded, size: 16, color: Color(0xFF7C3AED)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How Customers Find You',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Discovery source breakdown',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  total > 0 ? '$total total' : 'Sample data',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Donut Chart + Legend
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                children: [
                  // Donut Chart
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: GestureDetector(
                      onTapDown: (details) {
                        // Simple toggle for segments
                        setState(() {
                          _selectedIndex = _selectedIndex == null ? 0 : null;
                        });
                      },
                      child: CustomPaint(
                        painter: _DonutPainter(
                          segments: segments,
                          sweepProgress: _sweepAnimation.value,
                          selectedIndex: _selectedIndex,
                        ),
                        child: Center(
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  segments.isNotEmpty
                                      ? '${segments.first.percent}%'
                                      : '—',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  segments.isNotEmpty ? segments.first.label : '',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Legend
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: segments.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final seg = entry.value;
                          final isSelected = _selectedIndex == idx;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _selectedIndex = isSelected ? null : idx;
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected ? seg.lightColor : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: isSelected
                                      ? Border.all(color: seg.color.withValues(alpha: 0.2))
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: seg.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        seg.label,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: const Color(0xFF334155),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${seg.percent}%',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: seg.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ChannelSegment {
  final String key;
  final String label;
  final int percent;
  final Color color;
  final Color lightColor;
  final IconData icon;

  _ChannelSegment(this.key, this.label, this.percent, this.color, this.lightColor, this.icon);
}

class _DonutPainter extends CustomPainter {
  final List<_ChannelSegment> segments;
  final double sweepProgress;
  final int? selectedIndex;

  _DonutPainter({
    required this.segments,
    required this.sweepProgress,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 14.0;
    const gapAngle = 0.04; // Small gap between segments

    final totalPercent = segments.fold<int>(0, (a, b) => a + b.percent);
    if (totalPercent == 0) return;

    double startAngle = -math.pi / 2;

    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final sweepAngle = (seg.percent / totalPercent) * 2 * math.pi * sweepProgress - gapAngle;
      if (sweepAngle <= 0) {
        startAngle += (seg.percent / totalPercent) * 2 * math.pi * sweepProgress;
        continue;
      }

      final isSelected = selectedIndex == i;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? strokeWidth + 4 : strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          colors: [seg.color, seg.color.withValues(alpha: 0.75)],
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: isSelected ? radius + 2 : radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.sweepProgress != sweepProgress ||
      old.selectedIndex != selectedIndex;
}
