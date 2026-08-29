import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Executive Weekly Marketing Momentum & Customer Reach Bar Chart
/// Visualizes weekly customer engagements, AI actions, and review responses with sleek rounded gradient bars.
class BespokeWeeklyMomentumBarChart extends StatefulWidget {
  final List<double> weeklyValues; // 7 days of customer engagement points
  final int totalWeeklyEngagements;
  final double weeklyGrowthPercent;
  final int completedActions;
  final int totalReviews;
  final int positiveReviews;

  const BespokeWeeklyMomentumBarChart({
    super.key,
    required this.weeklyValues,
    required this.totalWeeklyEngagements,
    this.weeklyGrowthPercent = 14.5,
    this.completedActions = 16,
    this.totalReviews = 8,
    this.positiveReviews = 6,
  });

  @override
  State<BespokeWeeklyMomentumBarChart> createState() => _BespokeWeeklyMomentumBarChartState();
}

class _BespokeWeeklyMomentumBarChartState extends State<BespokeWeeklyMomentumBarChart> {
  int? _touchedIndex;

  static const List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final values = widget.weeklyValues.length == 7
        ? widget.weeklyValues
        : const [24.0, 38.0, 31.0, 48.0, 52.0, 65.0, 59.0];

    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final maxY = ((maxVal + 15) / 10).ceil() * 10.0;

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
          // Header: Title & Total Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.bar_chart_rounded,
                          size: 15,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Weekly Customer Reach',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Direct customer views, calls & actions',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up_rounded, size: 12, color: Color(0xFF059669)),
                    const SizedBox(width: 3),
                    Text(
                      '+${widget.weeklyGrowthPercent.toStringAsFixed(0)}% this week',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Total Count Highlight
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${widget.totalWeeklyEngagements}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'interactions',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              if (_touchedIndex != null && _touchedIndex! < _weekdays.length)
                Text(
                  '${_weekdays[_touchedIndex!]}: ${values[_touchedIndex!].round()} actions',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2563EB),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Interactive FL Bar Chart
          SizedBox(
            height: 145,
            width: double.infinity,
            child: BarChart(
              BarChartData(
                maxY: maxY > 20 ? maxY : 50,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF0F172A),
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = _weekdays[group.x.toInt()];
                      return BarTooltipItem(
                        '$day\n${rod.toY.round()} reach',
                        GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    if (response?.spot != null) {
                      setState(() {
                        _touchedIndex = response!.spot!.touchedBarGroupIndex;
                      });
                    } else if (event is FlTapUpEvent || event is FlPanEndEvent) {
                      setState(() => _touchedIndex = null);
                    }
                  },
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
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < _weekdays.length) {
                          final isToday = idx == 6; // Sunday/latest day
                          final isTouched = _touchedIndex == idx;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _weekdays[idx],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                color: (isTouched || isToday)
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF94A3B8),
                                fontWeight: (isTouched || isToday) ? FontWeight.w800 : FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY / 3).clamp(10.0, 40.0),
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: Color(0xFFF1F5F9),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) {
                  final val = values[i];
                  final isTouched = _touchedIndex == i;
                  final isLatest = i == 6;

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: val,
                        width: 18,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: (isTouched || isLatest)
                              ? [const Color(0xFF2563EB), const Color(0xFF38BDF8)]
                              : [const Color(0xFF93C5FD), const Color(0xFFBFDBFE)],
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY > 20 ? maxY : 50,
                          color: const Color(0xFFF8FAFC),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Bottom Metric Highlights Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat('AI Actions', '${widget.completedActions} Done', const Color(0xFF2563EB)),
                Container(height: 20, width: 1, color: const Color(0xFFE2E8F0)),
                _buildMiniStat('5★ Reviews', '${widget.positiveReviews}/${widget.totalReviews}', const Color(0xFF059669)),
                Container(height: 20, width: 1, color: const Color(0xFFE2E8F0)),
                _buildMiniStat('Reach Rate', '94% Optimal', const Color(0xFF7C3AED)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
