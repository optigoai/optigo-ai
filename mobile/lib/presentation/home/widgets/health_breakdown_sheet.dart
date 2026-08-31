import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/optigo_pill.dart';
import 'bespoke_circular_score_gauge.dart';

/// "Why X?" Marketing Health Breakdown Bottom Sheet
/// Plain-language, visual breakdown of the single Marketing Health Score across key pillars.
class HealthBreakdownSheet extends StatelessWidget {
  final int overallScore;
  final int googleScore;
  final int reviewScore;
  final int visibilityScore;
  final int contentScore;
  final Function(int)? onNavigateToTab;

  const HealthBreakdownSheet({
    super.key,
    required this.overallScore,
    required this.googleScore,
    required this.reviewScore,
    required this.visibilityScore,
    required this.contentScore,
    this.onNavigateToTab,
  });

  static void show(
    BuildContext context, {
    required int overallScore,
    required int googleScore,
    required int reviewScore,
    required int visibilityScore,
    required int contentScore,
    Function(int)? onNavigateToTab,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HealthBreakdownSheet(
        overallScore: overallScore,
        googleScore: googleScore,
        reviewScore: reviewScore,
        visibilityScore: visibilityScore,
        contentScore: contentScore,
        onNavigateToTab: onNavigateToTab,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGood = overallScore >= 75;
    final isModerate = overallScore >= 50;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Marketing Health Score',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'How your overall score is calculated',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              OptigoPill(
                label: isGood ? 'Optimal' : (isModerate ? 'Good' : 'Needs Boost'),
                variant: isGood ? OptigoPillVariant.success : (isModerate ? OptigoPillVariant.neutral : OptigoPillVariant.warning),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Score Gauge Hero Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E1B4B), Color(0xFF1E3A8A), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                BespokeCircularScoreGauge(
                  score: overallScore,
                  size: 78,
                  isDarkCard: true,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        overallScore >= 75
                            ? 'High Market Authority'
                            : (overallScore >= 50 ? 'Solid Local Footprint' : 'Immediate Growth Potential'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Combining Google Maps rank, review velocity, and active promotions.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: const Color(0xFF93C5FD),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          Text(
            'Score Contributing Factors',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 14),

          // Factor 1: Local Search Visibility (Map Pack)
          _buildFactorRow(
            icon: Icons.pin_drop_rounded,
            title: 'Local Search Visibility',
            score: visibilityScore,
            color: const Color(0xFF2563EB),
            onAction: () {
              Navigator.pop(context);
              onNavigateToTab?.call(3); // Visibility
            },
            actionLabel: 'Boost SEO',
          ),

          const SizedBox(height: 12),

          // Factor 2: Customer Reviews & Reputation
          _buildFactorRow(
            icon: Icons.star_rounded,
            title: 'Reviews & Reputation',
            score: reviewScore,
            color: const Color(0xFFF59E0B),
            onAction: () {
              Navigator.pop(context);
              onNavigateToTab?.call(4); // Reviews
            },
            actionLabel: 'Reply',
          ),

          const SizedBox(height: 12),

          // Factor 3: Google Profile Presence
          _buildFactorRow(
            icon: Icons.store_rounded,
            title: 'Google Profile Completeness',
            score: googleScore,
            color: const Color(0xFF10B981),
            onAction: () {
              Navigator.pop(context);
              onNavigateToTab?.call(1); // Grow
            },
            actionLabel: 'Optimize',
          ),

          const SizedBox(height: 12),

          // Factor 4: Content & Campaigns
          _buildFactorRow(
            icon: Icons.campaign_rounded,
            title: 'Marketing & Campaigns',
            score: contentScore,
            color: const Color(0xFF6366F1),
            onAction: () {
              Navigator.pop(context);
              onNavigateToTab?.call(2); // Studio
            },
            actionLabel: 'Create',
          ),

          const SizedBox(height: 24),

          // Primary Done Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Got It',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorRow({
    required IconData icon,
    required String title,
    required int score,
    required Color color,
    required VoidCallback onAction,
    required String actionLabel,
  }) {
    final double ratio = (score / 100.0).clamp(0.1, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              Text(
                '$score/100',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 9, color: Color(0xFF2563EB)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 5,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
