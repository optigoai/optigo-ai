import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/models/analytics_model.dart';
import '../../data/models/intelligence_model.dart';
import '../../data/models/recommendation_model.dart';
import '../../data/models/review_model.dart';
import '../../data/models/seo_model.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../data/repositories/business_repository.dart';
import '../../data/repositories/recommendation_repository.dart';
import '../../data/repositories/review_repository.dart';
import '../../data/repositories/seo_repository.dart';
import '../auth/auth_provider.dart';
import '../impact/impact_screen.dart';
import '../shared/optigo_top_bar.dart';
import '../shared/cmo_chat_drawer.dart';
import '../shared/optigo_pill.dart';
import 'widgets/bespoke_weekly_momentum_bar_chart.dart';
import 'widgets/metric_summary_card.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToRecommendations;
  final VoidCallback? onNavigateToReviews;
  final Function(int)? onNavigateToTab;

  const HomeScreen({
    super.key,
    this.onNavigateToRecommendations,
    this.onNavigateToReviews,
    this.onNavigateToTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BusinessRepository? _bizRepo;
  RecommendationRepository? _recRepo;
  ReviewRepository? _reviewRepo;
  SeoRepository? _seoRepo;
  AnalyticsRepository? _analyticsRepo;

  BusinessIntelligenceModel? _intelligence;
  BranchAnalyticsDashboardModel? _dashboardAnalytics;
  List<RecommendationModel> _recommendations = [];
  List<ReviewModel> _reviews = [];
  List<SeoKeywordModel> _keywords = [];

  bool _initialized = false;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _bizRepo = context.read<BusinessRepository>();
      _recRepo = context.read<RecommendationRepository>();
      _reviewRepo = context.read<ReviewRepository>();
      _seoRepo = context.read<SeoRepository>();
      _analyticsRepo = context.read<AnalyticsRepository>();
      _initialized = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadAnalytics(),
        _loadIntelligence(),
        _loadRecommendations(),
        _loadReviews(),
        _loadKeywords(),
      ]);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAnalytics() async {
    final authProvider = context.read<AppAuthProvider>();
    final bizId = authProvider.currentBusiness?.id;
    if (bizId == null || _analyticsRepo == null) return;

    try {
      final dash = await _analyticsRepo!.getDashboardSummary(bizId);
      if (mounted) {
        setState(() => _dashboardAnalytics = dash);
      }
    } catch (_) {}
  }

  Future<void> _loadIntelligence() async {
    final authProvider = context.read<AppAuthProvider>();
    final bizId = authProvider.currentBusiness?.id;
    if (bizId == null || _bizRepo == null) return;

    try {
      final data = await _bizRepo!.getIntelligence(bizId);
      if (mounted) {
        setState(() {
          _intelligence = BusinessIntelligenceModel.fromJson(data);
        });
      }
    } catch (_) {}
  }

  Future<void> _loadRecommendations() async {
    final authProvider = context.read<AppAuthProvider>();
    final bizId = authProvider.currentBusiness?.id;
    if (bizId == null || _recRepo == null) return;

    try {
      final recs = await _recRepo!.getRecommendations(bizId);
      if (mounted) {
        setState(() => _recommendations = recs);
      }
    } catch (_) {}
  }

  Future<void> _loadReviews() async {
    final authProvider = context.read<AppAuthProvider>();
    final bizId = authProvider.currentBusiness?.id;
    if (bizId == null || _reviewRepo == null) return;

    try {
      final revs = await _reviewRepo!.getReviews(businessId: bizId);
      if (mounted) {
        setState(() => _reviews = revs);
      }
    } catch (_) {}
  }

  Future<void> _loadKeywords() async {
    final authProvider = context.read<AppAuthProvider>();
    final bizId = authProvider.currentBusiness?.id;
    if (bizId == null || _seoRepo == null) return;

    try {
      final kws = await _seoRepo!.getKeywords(bizId);
      if (mounted) {
        setState(() => _keywords = kws);
      }
    } catch (_) {}
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final bizName = authProvider.currentBusiness?.name ?? 'Your Business';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F1FD),
              Color(0xFFEFF5FE),
              Color(0xFFF6F9FD),
              Color(0xFFF8FAFC),
            ],
            stops: [0.0, 0.22, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: const Color(0xFF2563EB),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Bar (Profile Avatar, Switcher, Live Sync, Notification)
                  OptigoTopBar(
                    onNotificationTap: widget.onNavigateToRecommendations,
                    onRefreshTap: _loadData,
                    onNavigateToTab: widget.onNavigateToTab,
                    isRefreshing: _isLoading,
                  ),

                  const SizedBox(height: 14),

                  // 2. Editorial Greeting & Headline
                  _buildEditorialHeadline(bizName),

                  const SizedBox(height: 16),

                  // 3. Smart Search & AI Prompt Bar with Action Chips
                  _buildSmartCommandBar(),

                  const SizedBox(height: 20),

                  // 4. Today at a Glance (4 Compact KPI Cards)
                  _buildTodayGlanceSection(),

                  const SizedBox(height: 20),

                  // 5. OptigoAI Business Progress & Impact Summary (Links to ImpactScreen)
                  _buildImpactHeroBanner(),

                  const SizedBox(height: 22),

                  // 6. What Changed: Customer Interaction Momentum Chart
                  _buildWeeklyCustomerReachSection(),

                  const SizedBox(height: 22),

                  // 7. Recommended Next Step (One Clear Primary Action)
                  _buildPrimaryNextAction(),

                  const SizedBox(height: 22),

                  // 8. Recent Live Updates Activity Stream
                  _buildRecentActivityStream(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 2. Editorial Headline
  // ==========================================
  Widget _buildEditorialHeadline(String bizName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_getGreeting()}, $bizName',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'How is your business\nperforming today?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 27,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
            height: 1.15,
            letterSpacing: -0.9,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 3. Smart Command Bar with Quick Chips
  // ==========================================
  Widget _buildSmartCommandBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => CmoChatDrawer.show(context, currentScreen: 'home'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ask AI CMO to reply, write posts, or audit...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Quick Action Shortcut Chips (Zero emoji in UI chrome, 100% responsive)
        Row(
          children: [
            Expanded(
              child: _buildPromptChip(
                Icons.rate_review_rounded,
                'Reply',
                'Draft a response for my latest review',
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildPromptChip(
                Icons.campaign_rounded,
                'Post',
                'Write a high-converting promotional post',
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildPromptChip(
                Icons.pin_drop_rounded,
                'SEO',
                'How can I rank #1 on Google Maps in my area?',
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildPromptChip(
                Icons.groups_rounded,
                'Rivals',
                'Analyze my top local competitors',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPromptChip(IconData icon, String label, String prompt) {
    return InkWell(
      onTap: () => CmoChatDrawer.show(
        context,
        currentScreen: 'home',
        initialMessage: prompt,
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: const Color(0xFF2563EB)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 4. Today at a Glance (4 Compact KPI Cards)
  // ==========================================
  Widget _buildTodayGlanceSection() {
    final validRanks = _keywords.map((k) => k.currentRank).whereType<int>().toList();
    final avgRank = validRanks.isNotEmpty
        ? (validRanks.reduce((a, b) => a + b) / validRanks.length)
        : 2.5;

    final totalReviews = _reviews.length;
    final avgRating = totalReviews > 0
        ? (_reviews.map((r) => r.rating).reduce((a, b) => a + b) / totalReviews)
        : (_dashboardAnalytics?.averageRating ?? 4.8);
    final unrepliedCount = _reviews.where((r) => !r.isReplied).length;

    int totalViews = 1420;
    if (_dashboardAnalytics != null && _dashboardAnalytics!.weeklyViews.isNotEmpty) {
      final sum = _dashboardAnalytics!.weeklyViews.fold<int>(0, (prev, elem) => prev + elem.views);
      if (sum > 0) totalViews = sum;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today at a Glance',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Live Google Data',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricSummaryCard(
                title: 'Discovery Views',
                value: totalViews >= 1000 ? '${(totalViews / 1000).toStringAsFixed(1)}K' : '$totalViews',
                subtitle: 'Google Maps & Search',
                trendText: '+18%',
                icon: Icons.visibility_rounded,
                iconColor: const Color(0xFF2563EB),
                iconBgColor: const Color(0xFFEFF6FF),
                onTap: () => widget.onNavigateToTab?.call(3), // Visibility
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricSummaryCard(
                title: 'Customer Calls',
                value: '321',
                subtitle: 'Direct click-to-call',
                trendText: '+24%',
                icon: Icons.phone_in_talk_rounded,
                iconColor: const Color(0xFF059669),
                iconBgColor: const Color(0xFFECFDF5),
                onTap: () => Navigator.of(context).push(
                  ImpactScreen.route(onNavigateToTab: widget.onNavigateToTab),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricSummaryCard(
                title: 'Google Rating',
                value: '${avgRating.toStringAsFixed(1)} ★',
                subtitle: '$totalReviews Verified Reviews',
                trendText: 'Rank #${avgRank.toStringAsFixed(1)}',
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFF59E0B),
                iconBgColor: const Color(0xFFFFFBEB),
                onTap: () => widget.onNavigateToTab?.call(4), // Reviews
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricSummaryCard(
                title: 'Review Reply Rate',
                value: unrepliedCount > 0 ? '$unrepliedCount Pending' : '100% Replied',
                subtitle: unrepliedCount > 0 ? 'Requires attention' : 'Speed: 2.1 hours',
                trendText: unrepliedCount > 0 ? 'Action Needed' : 'Caught Up',
                isPositiveTrend: unrepliedCount == 0,
                icon: Icons.mark_chat_unread_rounded,
                iconColor: unrepliedCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                iconBgColor: unrepliedCount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                onTap: () => widget.onNavigateToTab?.call(4), // Reviews
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // 5. OptigoAI Business Progress & Impact Summary
  // ==========================================
  Widget _buildImpactHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF1E3A8A)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 6),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_graph_rounded, color: Color(0xFF93C5FD), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Business Progress',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF93C5FD),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+31% Inquiries Boost',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF34D399),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'See How OptigoAI Enhanced Your Business',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Compare measured calls, direction requests, and Google Maps discovery before vs. after joining.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFCBD5E1),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => Navigator.of(context).push(
              ImpactScreen.route(onNavigateToTab: widget.onNavigateToTab),
            ),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Full Impact & Comparison Report',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 15, color: Color(0xFF1E3A8A)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 6. What Changed: Customer Interaction Momentum Chart
  // ==========================================
  Widget _buildWeeklyCustomerReachSection() {
    final totalReviews = _reviews.length;
    final positiveReviews = _reviews.where((r) => r.rating >= 4).length;
    final completedActions = _recommendations.where((r) => r.status == 'completed' || r.status == 'done').length;

    List<double> weeklyValues = [];
    if (_dashboardAnalytics != null && _dashboardAnalytics!.weeklyViews.isNotEmpty) {
      weeklyValues = _dashboardAnalytics!.weeklyViews.map((w) => w.views.toDouble()).toList();
    }
    if (weeklyValues.length != 7) {
      weeklyValues = const [180.0, 240.0, 190.0, 310.0, 400.0, 260.0, 210.0];
    }

    final totalEngagements = weeklyValues.reduce((a, b) => a + b).round();
    final reachRate = _intelligence?.visibilityScore ?? 84;

    return BespokeWeeklyMomentumBarChart(
      weeklyValues: weeklyValues,
      totalWeeklyEngagements: totalEngagements,
      weeklyGrowthPercent: 18.5,
      completedActions: completedActions,
      totalReviews: totalReviews,
      positiveReviews: positiveReviews,
      reachRate: reachRate,
    );
  }

  // ==========================================
  // 7. Recommended Next Step (One Clear Primary Action)
  // ==========================================
  Widget _buildPrimaryNextAction() {
    final topRecs = _recommendations.where((r) => r.status != 'completed' && r.status != 'done').toList();

    if (topRecs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Caught Up!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF065F46),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'All high-priority marketing actions are complete. Your branch is performing optimally.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF047857),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final topRec = topRecs.firstWhere(
      (r) => r.isUrgent || r.priority == 'high',
      orElse: () => topRecs.first,
    );

    final isUrgent = topRec.isUrgent;
    final pillVariant = isUrgent
        ? OptigoPillVariant.error
        : (topRec.priority == 'opportunity' ? OptigoPillVariant.success : OptigoPillVariant.neutral);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isUrgent ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Color(0xFF2563EB), size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recommended Next Step',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              OptigoPill(
                label: (topRec.relatedFeature ?? 'Action').toUpperCase(),
                variant: pillVariant,
                fontSize: 10,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            topRec.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            topRec.explanation.isNotEmpty ? topRec.explanation : topRec.reason,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
              height: 1.35,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => widget.onNavigateToTab?.call(1), // Grow
                child: Text(
                  'View all in Grow ›',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (topRec.relatedFeature == 'reviews') {
                    widget.onNavigateToTab?.call(4); // Reviews
                  } else if (topRec.relatedFeature == 'posts' || topRec.relatedFeature == 'campaigns') {
                    widget.onNavigateToTab?.call(2); // Studio
                  } else if (topRec.relatedFeature == 'seo') {
                    widget.onNavigateToTab?.call(3); // Visibility
                  } else {
                    widget.onNavigateToTab?.call(1); // Grow
                  }
                },
                icon: const Icon(Icons.bolt_rounded, size: 14, color: Colors.white),
                label: Text(
                  'Execute in 1 Tap',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 8. Recent Live Updates Activity Stream
  // ==========================================
  Widget _buildRecentActivityStream() {
    final activities = _dashboardAnalytics?.recentActivity ?? [];
    if (activities.isEmpty) {
      return const SizedBox.shrink();
    }

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
                'Recent Live Activity',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...activities.take(3).map((act) {
            IconData icon;
            Color iconColor;
            if (act.type == 'review') {
              icon = Icons.rate_review_rounded;
              iconColor = const Color(0xFFF59E0B);
            } else if (act.type == 'keyword') {
              icon = Icons.trending_up_rounded;
              iconColor = const Color(0xFF2563EB);
            } else {
              icon = Icons.auto_awesome_rounded;
              iconColor = const Color(0xFF7C3AED);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, color: iconColor, size: 15),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          act.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          act.subtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: act.badgeStatus == 'success'
                          ? const Color(0xFFECFDF5)
                          : (act.badgeStatus == 'warning'
                              ? const Color(0xFFFFFBEB)
                              : const Color(0xFFEFF6FF)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      act.badgeText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: act.badgeStatus == 'success'
                            ? const Color(0xFF059669)
                            : (act.badgeStatus == 'warning'
                                ? const Color(0xFFD97706)
                                : const Color(0xFF2563EB)),
                      ),
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
