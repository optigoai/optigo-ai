import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bespoke Keyword Distribution Bar
/// Multi-segment proportional ranking bar for Google Maps visibility tiers.
class BespokeKeywordDistributionBar extends StatelessWidget {
  final int top3Count;
  final int top10Count;
  final int top20Count;
  final int totalCount;

  const BespokeKeywordDistributionBar({
    super.key,
    required this.top3Count,
    required this.top10Count,
    required this.top20Count,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final otherCount = (totalCount - top3Count - top10Count - top20Count).clamp(0, totalCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Proportional Segment Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 9,
            child: Row(
              children: [
                if (top3Count > 0)
                  Expanded(
                    flex: top3Count,
                    child: Container(
                      color: const Color(0xFF10B981), // Emerald
                    ),
                  ),
                if (top10Count > 0)
                  Expanded(
                    flex: top10Count,
                    child: Container(
                      color: const Color(0xFF2563EB), // Azure
                    ),
                  ),
                if (top20Count > 0)
                  Expanded(
                    flex: top20Count,
                    child: Container(
                      color: const Color(0xFFF59E0B), // Amber
                    ),
                  ),
                if (otherCount > 0 || totalCount == 0)
                  Expanded(
                    flex: otherCount > 0 ? otherCount : 1,
                    child: Container(
                      color: const Color(0xFFE2E8F0), // Slate
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // 2. Legend Tags Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLegendItem('Top 3', top3Count, const Color(0xFF10B981)),
            _buildLegendItem('Top 10', top10Count, const Color(0xFF2563EB)),
            _buildLegendItem('11-20', top20Count, const Color(0xFFF59E0B)),
            _buildLegendItem('Tracked', totalCount, const Color(0xFF64748B)),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          '$count',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
