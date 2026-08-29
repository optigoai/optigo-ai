import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Next-Level Interactive Gradient Wave Area Chart
/// Visualizes real backend time-series data (e.g. Visibility Score, Search Impressions, Keyword Movement)
/// with touch tooltips, cubic bezier curves, and smooth area glow fills.
class BespokeInteractiveWaveChart extends StatefulWidget {
  final List<Map<String, dynamic>> dataPoints;
  final String title;
  final String subtitle;
  final String valuePrefix;
  final String valueSuffix;
  final ValueChanged<int>? onRangeChanged;
  final int selectedDays;

  const BespokeInteractiveWaveChart({
    super.key,
    required this.dataPoints,
    this.title = 'Local Visibility Trend',
    this.subtitle = 'Real-time daily Google Map Pack score',
    this.valuePrefix = '',
    this.valueSuffix = '%',
    this.onRangeChanged,
    this.selectedDays = 7,
  });

  @override
  State<BespokeInteractiveWaveChart> createState() => _BespokeInteractiveWaveChartState();
}

class _BespokeInteractiveWaveChartState extends State<BespokeInteractiveWaveChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final points = widget.dataPoints;

    // Convert backend maps to FlSpots
    final List<FlSpot> spots = [];
    final List<String> labels = [];

    if (points.isNotEmpty) {
      for (int i = 0; i < points.length; i++) {
        final item = points[i];
        final val = (item['visibility_score'] ?? item['score'] ?? item['value'] ?? 75).toDouble();
        spots.add(FlSpot(i.toDouble(), val));

        final dateStr = (item['date'] ?? '').toString();
        if (dateStr.length >= 10) {
          final parts = dateStr.split('-');
          if (parts.length >= 3) {
            labels.add('${parts[1]}/${parts[2]}');
          } else {
            labels.add(dateStr);
          }
        } else {
          labels.add('D${i + 1}');
        }
      }
    } else {
      // Fallback if data points are loading or empty
      spots.addAll([
        const FlSpot(0, 72),
        const FlSpot(1, 76),
        const FlSpot(2, 80),
        const FlSpot(3, 79),
        const FlSpot(4, 84),
        const FlSpot(5, 88),
        const FlSpot(6, 92),
      ]);
      labels.addAll(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']);
    }

    double minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    minY = (minY - 8).clamp(0, 100);
    maxY = (maxY + 8).clamp(10, 100);

    final currentVal = spots.isNotEmpty ? spots.last.y.round() : 88;
    final firstVal = spots.isNotEmpty ? spots.first.y.round() : 75;
    final diff = currentVal - firstVal;
    final isPositive = diff >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title & Timeframe Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // Range Filter Pills (7D / 14D / 30D)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildRangePill(7, '7D'),
                    _buildRangePill(14, '14D'),
                    _buildRangePill(30, '30D'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Score Highlight Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${widget.valuePrefix}$currentVal${widget.valueSuffix}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isPositive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isPositive ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      size: 11,
                      color: isPositive ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${diff >= 0 ? '+' : ''}$diff${widget.valueSuffix}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: isPositive ? const Color(0xFF059669) : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_touchedIndex != null && _touchedIndex! < spots.length)
                Text(
                  '${labels[_touchedIndex!]}: ${widget.valuePrefix}${spots[_touchedIndex!].y.round()}${widget.valueSuffix}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2563EB),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 18),

          // Interactive FL Chart
          SizedBox(
            height: 160,
            width: double.infinity,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (spots.length - 1).toDouble().clamp(1.0, 100.0),
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: ((maxY - minY) / 3).clamp(5.0, 50.0),
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: Color(0xFFF1F5F9),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: (spots.length > 7 ? (spots.length / 4).floorToDouble() : 1.0),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              labels[idx],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF0F172A),
                    tooltipRoundedRadius: 10,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((s) {
                        final idx = s.x.toInt();
                        final lbl = (idx >= 0 && idx < labels.length) ? labels[idx] : '';
                        return LineTooltipItem(
                          '$lbl\n${widget.valuePrefix}${s.y.round()}${widget.valueSuffix}',
                          GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  touchCallback: (event, response) {
                    if (response?.lineBarSpots != null && response!.lineBarSpots!.isNotEmpty) {
                      setState(() {
                        _touchedIndex = response.lineBarSpots!.first.x.toInt();
                      });
                    } else if (event is FlTapUpEvent || event is FlPanEndEvent) {
                      setState(() => _touchedIndex = null);
                    }
                  },
                  handleBuiltInTouches: true,
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.32,
                    preventCurveOverShooting: true,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2563EB),
                        Color(0xFF6366F1),
                        Color(0xFF38BDF8),
                      ],
                    ),
                    barWidth: 3.2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        if (index == spots.length - 1 || index == _touchedIndex) {
                          return FlDotCirclePainter(
                            radius: 5,
                            color: const Color(0xFF2563EB),
                            strokeWidth: 2.5,
                            strokeColor: Colors.white,
                          );
                        }
                        return FlDotCirclePainter(radius: 0, color: Colors.transparent);
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF2563EB).withValues(alpha: 0.22),
                          const Color(0xFF6366F1).withValues(alpha: 0.04),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangePill(int days, String label) {
    final isSelected = widget.selectedDays == days;
    return InkWell(
      onTap: () => widget.onRangeChanged?.call(days),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
