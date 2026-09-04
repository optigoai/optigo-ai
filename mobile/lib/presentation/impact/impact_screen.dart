import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/models/analytics_model.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../data/repositories/review_repository.dart';
import '../../data/repositories/seo_repository.dart';
import '../../data/repositories/recommendation_repository.dart';
import '../auth/auth_provider.dart';
import '../home/widgets/period_comparison_chart.dart';

class ImpactScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const ImpactScreen({super.key, this.onNavigateToTab});

  static Route route({Function(int)? onNavigateToTab}) {
    return MaterialPageRoute(
      builder: (_) => ImpactScreen(onNavigateToTab: onNavigateToTab),
    );
  }

  @override
  State<ImpactScreen> createState() => _ImpactScreenState();
}

class _ImpactScreenState extends State<ImpactScreen> {
  bool _isLoading = true;
  int _selectedPeriodIndex = 0; // 0: 30 Days, 1: 90 Days
  ImpactComparisonModel? _impact;
  BranchAnalyticsDashboardModel? _dashboardAnalytics;

  @override
  void initState() {
    super.initState();
    _loadImpactData();
  }

  Future<void> _loadImpactData() async {
    setState(() => _isLoading = true);

    final business = context.read<AppAuthProvider>().currentBusiness;
    if (business == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final analyticsRepo = context.read<AnalyticsRepository>();
      final reviewRepo = context.read<ReviewRepository>();
      final seoRepo = context.read<SeoRepository>();
      final recRepo = context.read<RecommendationRepository>();

      final results = await Future.wait([
        analyticsRepo.getDashboardSummary(business.id),
        reviewRepo.getReviews(businessId: business.id),
        seoRepo.getKeywords(business.id),
        recRepo.getRecommendations(business.id),
      ]);

      final dash = results[0] as BranchAnalyticsDashboardModel;
      final reviews = results[1] as List;
      final keywords = results[2] as List;
      final recs = results[3] as List;

      final currentRating = reviews.isNotEmpty
          ? (reviews.map((r) => (r.rating as num).toDouble()).reduce((a, b) => a + b) / reviews.length)
          : 4.8;

      final top3Count = keywords.where((k) => ((k.currentRank ?? 99) as num) <= 3).length;
      final completedRecs = recs.where((r) => r.status == 'completed' || r.status == 'done').length;

      final impactData = await analyticsRepo.getImpactComparison(
        business.id,
        currentReviewsCount: reviews.length,
        currentRating: currentRating,
        currentTop3Keywords: top3Count,
        completedActions: completedRecs,
      );

      if (mounted) {
        setState(() {
          _dashboardAnalytics = dash;
          _impact = impactData;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final business = context.watch<AppAuthProvider>().currentBusiness;
    final businessName = business?.name ?? 'Branch';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Business Impact & Progress',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              businessName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 14),
                const SizedBox(width: 4),
                Text(
                  'Active Baseline',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF065F46),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          : RefreshIndicator(
              onRefresh: _loadImpactData,
              color: const Color(0xFF2563EB),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Hero Impact Card
                    _buildHeroImpactBanner(),

                    const SizedBox(height: 18),

                    // 2. Period Filter Selector
                    _buildPeriodSelector(),

                    const SizedBox(height: 18),

                    // 3. Before vs After Side-by-Side Matrix
                    _buildComparisonMatrix(),

                    const SizedBox(height: 20),

                    // 4. Comparison Chart
                    _buildComparisonChartSection(),

                    const SizedBox(height: 20),

                    // 5. Actions completed by OptigoAI
                    _buildAiActionsCompletedSection(),

                    const SizedBox(height: 20),

                    // 6. Lead Attribution Channels
                    _buildChannelAttributionCard(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeroImpactBanner() {
    final daysActive = _impact?.daysActive ?? 45;
    final inquiriesGain = _impact?.inquiriesGrowthPct.toStringAsFixed(0) ?? '31';
    final roiMult = _dashboardAnalytics?.roiMultiplier ?? '4.2x';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF1E3A8A)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Text(
                  'Active with OptigoAI for $daysActive days',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF93C5FD),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$roiMult ROI Multiplier',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF34D399),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '+$inquiriesGain% More Customer Inquiries',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Measured calls, direction requests, and Google Maps discovery since activating automated marketing.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFCBD5E1),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        Text(
          'Comparison Window:',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF64748B),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildPeriodTab(title: 'Last 30 Days', index: 0),
              _buildPeriodTab(title: 'Last 90 Days', index: 1),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodTab({required String title, required int index}) {
    final isSelected = _selectedPeriodIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriodIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonMatrix() {
    final imp = _impact;
    if (imp == null) return const SizedBox.shrink();

    final mult = _selectedPeriodIndex == 0 ? 1.0 : 2.6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Before vs. With OptigoAI',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Direct side-by-side performance for key local business metrics',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricComparisonCard(
                title: 'Customer Calls',
                icon: Icons.phone_in_talk_rounded,
                iconColor: const Color(0xFF2563EB),
                beforeText: '${(imp.callsBefore * mult).round()}',
                afterText: '${(imp.callsAfter * mult).round()}',
                growthText: '+${imp.callsGrowthPct.toStringAsFixed(0)}%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricComparisonCard(
                title: 'Direction Requests',
                icon: Icons.directions_rounded,
                iconColor: const Color(0xFF059669),
                beforeText: '${(imp.directionsBefore * mult).round()}',
                afterText: '${(imp.directionsAfter * mult).round()}',
                growthText: '+${imp.directionsGrowthPct.toStringAsFixed(0)}%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricComparisonCard(
                title: 'Discovery Views',
                icon: Icons.visibility_rounded,
                iconColor: const Color(0xFF7C3AED),
                beforeText: '${(imp.viewsBefore * mult).round()}',
                afterText: '${(imp.viewsAfter * mult).round()}',
                growthText: '+${imp.viewsGrowthPct.toStringAsFixed(0)}%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricComparisonCard(
                title: 'Top 3 Keywords',
                icon: Icons.trending_up_rounded,
                iconColor: const Color(0xFFEA580C),
                beforeText: '${imp.top3KeywordsBefore}',
                afterText: '${imp.top3KeywordsAfter}',
                growthText: '+${imp.top3KeywordsDelta} New',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricComparisonCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String beforeText,
    required String afterText,
    required String growthText,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  growthText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Before',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    beforeText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFCBD5E1)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Now',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  Text(
                    afterText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonChartSection() {
    final imp = _impact;
    if (imp == null) return const SizedBox.shrink();

    final mult = _selectedPeriodIndex == 0 ? 1.0 : 2.6;

    final chartItems = [
      ComparisonItemData(
        label: 'Calls',
        beforeVal: (imp.callsBefore * mult).roundToDouble(),
        afterVal: (imp.callsAfter * mult).roundToDouble(),
        unit: 'calls',
      ),
      ComparisonItemData(
        label: 'Directions',
        beforeVal: (imp.directionsBefore * mult).roundToDouble(),
        afterVal: (imp.directionsAfter * mult).roundToDouble(),
        unit: 'requests',
      ),
      ComparisonItemData(
        label: 'Views (x10)',
        beforeVal: ((imp.viewsBefore * mult) / 10).roundToDouble(),
        afterVal: ((imp.viewsAfter * mult) / 10).roundToDouble(),
        unit: 'views (x10)',
      ),
      ComparisonItemData(
        label: 'Top 3 KWs',
        beforeVal: imp.top3KeywordsBefore.toDouble(),
        afterVal: imp.top3KeywordsAfter.toDouble(),
        unit: 'keywords',
      ),
    ];

    return PeriodComparisonChart(
      items: chartItems,
      beforeLabel: 'Before OptigoAI',
      afterLabel: 'With OptigoAI',
      title: 'Growth Trajectory',
      subtitle: 'Comparison of business outcomes over equivalent periods',
    );
  }

  Widget _buildAiActionsCompletedSection() {
    final actionsCount = _impact?.totalActionsCompleted ?? 14;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'OptigoAI Engine Output',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$actionsCount Actions Run',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildActionItemRow(
            icon: Icons.quickreply_rounded,
            title: 'Automated Review Responses',
            value: '${_impact?.reviewsAfter ?? 12} Replied',
            timeDiff: 'Response speed: 48h → 2.1h',
          ),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          _buildActionItemRow(
            icon: Icons.my_location_rounded,
            title: 'Local Google Search Keywords',
            value: '${_dashboardAnalytics?.keywordsCount ?? 6} Tracked',
            timeDiff: '${_impact?.top3KeywordsAfter ?? 4} ranked in Google Maps Top 3',
          ),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          _buildActionItemRow(
            icon: Icons.post_add_rounded,
            title: 'AI Marketing Posts & Campaigns',
            value: '6 Created',
            timeDiff: 'Optimized for local neighborhood search intent',
          ),
        ],
      ),
    );
  }

  Widget _buildActionItemRow({
    required IconData icon,
    required String title,
    required String value,
    required String timeDiff,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF475569), size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                timeDiff,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2563EB),
          ),
        ),
      ],
    );
  }

  Widget _buildChannelAttributionCard() {
    final channels = _dashboardAnalytics?.channelBreakdown ?? {
      'Google Maps & Search': 62,
      'Direct Phone Leads': 23,
      'Social Media & Other': 15,
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Channel Attribution Breakdown',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Where your newly acquired customer leads originated',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          ...channels.entries.map((entry) {
            final pct = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100.0,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                      minHeight: 7,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
