import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ComparisonItemData {
  final String label;
  final double beforeVal;
  final double afterVal;
  final String unit;

  const ComparisonItemData({
    required this.label,
    required this.beforeVal,
    required this.afterVal,
    this.unit = '',
  });

  double get growthPct {
    if (beforeVal <= 0) return 100.0;
    return ((afterVal - beforeVal) / beforeVal) * 100.0;
  }
}

class PeriodComparisonChart extends StatefulWidget {
  final List<ComparisonItemData> items;
  final String beforeLabel;
  final String afterLabel;
  final String title;
  final String? subtitle;

  const PeriodComparisonChart({
    super.key,
    required this.items,
    this.beforeLabel = 'Before OptigoAI',
    this.afterLabel = 'With OptigoAI',
    this.title = 'Business Impact Comparison',
    this.subtitle = 'Measured growth before vs. after activating OptigoAI',
  });

  @override
  State<PeriodComparisonChart> createState() => _PeriodComparisonChartState();
}

class _PeriodComparisonChartState extends State<PeriodComparisonChart> {
  int? _touchedGroupIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    double maxVal = 10.0;
    for (final it in widget.items) {
      if (it.beforeVal > maxVal) maxVal = it.beforeVal;
      if (it.afterVal > maxVal) maxVal = it.afterVal;
    }
    final maxY = ((maxVal * 1.25) / 10).ceil() * 10.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Legend
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        widget.subtitle!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Legend Chips
          Row(
            children: [
              _buildLegendChip(
                label: widget.beforeLabel,
                color: const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 14),
              _buildLegendChip(
                label: widget.afterLabel,
                color: const Color(0xFF2563EB),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Bar Chart
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF0F172A),
                    tooltipRoundedRadius: 12,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = widget.items[groupIndex];
                      final isAfter = rodIndex == 1;
                      final label = isAfter ? widget.afterLabel : widget.beforeLabel;
                      final val = rod.toY.round();
                      return BarTooltipItem(
                        '$label\n',
                        GoogleFonts.plusJakartaSans(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(
                            text: '$val ${item.unit}',
                            style: GoogleFonts.plusJakartaSans(
                              color: isAfter ? const Color(0xFF60A5FA) : Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    setState(() {
                      if (event.isInterestedForInteractions && response?.spot != null) {
                        _touchedGroupIndex = response!.spot!.touchedBarGroupIndex;
                      } else {
                        _touchedGroupIndex = null;
                      }
                    });
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value == maxY) return const SizedBox.shrink();
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= widget.items.length) {
                          return const SizedBox.shrink();
                        }
                        final item = widget.items[index];
                        final isTouched = _touchedGroupIndex == index;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            item.label,
                            style: GoogleFonts.plusJakartaSans(
                              color: isTouched ? const Color(0xFF2563EB) : const Color(0xFF475569),
                              fontSize: 11,
                              fontWeight: isTouched ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4 > 0 ? maxY / 4 : 10,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: const Color(0xFFF1F5F9),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(widget.items.length, (idx) {
                  final item = widget.items[idx];
                  return BarChartGroupData(
                    x: idx,
                    barsSpace: 7,
                    barRods: [
                      // Before Bar
                      BarChartRodData(
                        toY: item.beforeVal,
                        color: const Color(0xFFCBD5E1),
                        width: 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                      ),
                      // After Bar
                      BarChartRodData(
                        toY: item.afterVal,
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                        ),
                        width: 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Growth Badges Row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.items.map((item) {
              final growth = item.growthPct;
              final isPositive = growth >= 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: isPositive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isPositive ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      size: 12,
                      color: isPositive ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${item.label}: ${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(0)}%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isPositive ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendChip({required String label, required Color color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}
