import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bespoke Customer Sentiment & Rating Pulse Meter
/// Displays average rating, star distribution micro-bars, and response status indicator.
class BespokeSentimentPulseMeter extends StatelessWidget {
  final double averageRating;
  final int totalReviews;
  final int pendingReplies;
  final int fiveStarCount;
  final int fourStarCount;
  final int otherStarCount;

  const BespokeSentimentPulseMeter({
    super.key,
    required this.averageRating,
    required this.totalReviews,
    required this.pendingReplies,
    this.fiveStarCount = 0,
    this.fourStarCount = 0,
    this.otherStarCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTotal = totalReviews > 0 ? totalReviews : 1;
    final positivePct = totalReviews > 0
        ? (((fiveStarCount + fourStarCount) / effectiveTotal) * 100).round()
        : 95;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Big Rating Number & Stars
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFF59E0B),
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '$totalReviews Total Reviews',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),

        const SizedBox(width: 18),

        // 2. Micro Rating Sentiment Gauge
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Positive Sentiment',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Text(
                      '$positivePct%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (positivePct / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    pendingReplies > 0 ? '$pendingReplies replies pending' : 'All replied!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: pendingReplies > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    ),
                  ),
                  const Text(
                    'Google Maps GBP',
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
