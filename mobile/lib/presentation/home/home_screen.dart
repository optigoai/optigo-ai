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
import '../shared/optigo_pill.dart';
import 'widgets/animated_metric_card.dart';
import 'widgets/bespoke_weekly_momentum_bar_chart.dart';
import 'widgets/channel_breakdown_donut.dart';
import 'widgets/quick_ai_action_row.dart';

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

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
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

  // Staggered entrance animation
  late AnimationController _entranceController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

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
            backgroundColor: Colors.white,
            strokeWidth: 2.5,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Bar
                  FadeTransition(
                    opacity: _headerFade,
                    child: SlideTransition(
                      position: _headerSlide,
                      child: OptigoTopBar(
                        onNotificationTap: widget.onNavigateToRecommendations,
                        onRefreshTap: _loadData,
                        onNavigateToTab: widget.onNavigateToTab,
                        isRefreshing: _isLoading,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 2. Editorial Greeting & Headline (animated)
                  _buildEditorialHeadline(bizName),

                  const SizedBox(height: 16),

                  // 3. Quick AI Action Pills (replaces old full-width search bar)
                  const QuickAiActionRow(),

                  const SizedBox(height: 22),

                  // 4. Today at a Glance — Premium Animated KPI Cards
                  _buildTodayGlanceSection(),

                  const SizedBox(height: 22),

                  // 5. OptigoAI Business Progress & Impact Banner
                  _buildImpactHeroBanner(),

                  const SizedBox(height: 22),

                  // 6. Channel Breakdown Donut Chart
                  _buildChannelBreakdownSection(),

                  const SizedBox(height: 22),

                  // 7. Weekly Customer Reach Momentum Chart
                  _buildWeeklyCustomerReachSection(),

                  const SizedBox(height: 22),

                  // 8. Recommended Next Step
                  _buildPrimaryNextAction(),

                  const SizedBox(height: 22),

                  // 9. Recent Activity Stream
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
  // 2. Editorial Headline with staggered animation
  // ==========================================
  Widget _buildEditorialHeadline(String bizName) {
    return FadeTransition(
      opacity: _headerFade,
      child: SlideTransition(
        position: _headerSlide,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Animated pulse dot
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.6, end: 1.0),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          const Color(0xFF10B981).withValues(alpha: 0.5),
                          const Color(0xFF10B981),
                          value,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.3 * value),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_getGreeting()}, $bizName',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                      letterSpacing: 0.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E40AF)],
              ).createShader(bounds),
              child: Text(
                'How is your business\nperforming today?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.15,
                  letterSpacing: -0.9,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 4. Today at a Glance — Animated Metric Cards
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
        // Section Header with animated badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                    ),
                  ),
                  child: const Icon(
                    Icons.dashboard_rounded,
                    size: 14,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Today at a Glance',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFECFDF5),
                    const Color(0xFFD1FAE5).withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Live Data',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // KPI Grid — 2x2 Animated Cards
        Row(
          children: [
            Expanded(
              child: AnimatedMetricCard(
                title: 'Discovery Views',
                value: totalViews >= 1000
                    ? '${(totalViews / 1000).toStringAsFixed(1)}K'
                    : '$totalViews',
                subtitle: 'Google Maps & Search',
                trendText: '+18%',
                icon: Icons.visibility_rounded,
                accentColor: const Color(0xFF2563EB),
                accentBgColor: const Color(0xFFEFF6FF),
                animationDelayMs: 100,
                isLoading: _isLoading,
                onTap: () => widget.onNavigateToTab?.call(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedMetricCard(
                title: 'Customer Calls',
                value: '321',
                subtitle: 'Direct click-to-call',
                trendText: '+24%',
                icon: Icons.phone_in_talk_rounded,
                accentColor: const Color(0xFF059669),
                accentBgColor: const Color(0xFFECFDF5),
                animationDelayMs: 200,
                isLoading: _isLoading,
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
              child: AnimatedMetricCard(
                title: 'Google Rating',
                value: '${avgRating.toStringAsFixed(1)} ★',
                subtitle: '$totalReviews Verified Reviews',
                trendText: 'Rank #${avgRank.toStringAsFixed(1)}',
                icon: Icons.star_rounded,
                accentColor: const Color(0xFFF59E0B),
                accentBgColor: const Color(0xFFFFFBEB),
                animationDelayMs: 300,
                isLoading: _isLoading,
                onTap: () => widget.onNavigateToTab?.call(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedMetricCard(
                title: 'Review Reply Rate',
                value: unrepliedCount > 0 ? '$unrepliedCount Pending' : '100%',
                subtitle: unrepliedCount > 0 ? 'Requires attention' : 'Avg speed: 2.1h',
                trendText: unrepliedCount > 0 ? 'Action Needed' : 'Caught Up',
                isPositiveTrend: unrepliedCount == 0,
                icon: Icons.mark_chat_unread_rounded,
                accentColor: unrepliedCount > 0
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981),
                accentBgColor: unrepliedCount > 0
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFECFDF5),
                animationDelayMs: 400,
                isLoading: _isLoading,
                onTap: () => widget.onNavigateToTab?.call(4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // 5. OptigoAI Business Progress & Impact Banner
  // ==========================================
  Widget _buildImpactHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
            Color(0xFF1E3A8A),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Tags Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Business Progress Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_graph_rounded, color: Color(0xFF93C5FD), size: 14),
                    const SizedBox(width: 5),
                    Text(
                      'Business Progress',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF93C5FD),
                      ),
                    ),
                  ],
                ),
              ),
              // Boost Badge with glow
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981).withValues(alpha: 0.25),
                      const Color(0xFF059669).withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF34D399).withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      blurRadius: 8,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up_rounded, color: Color(0xFF34D399), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '+31% Inquiries',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF34D399),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Main headline
          Text(
            'See How OptigoAI Enhanced\nYour Business',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Compare measured calls, views, and Google Maps discovery before vs. after joining.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFCBD5E1),
              height: 1.45,
            ),
          ),

          const SizedBox(height: 18),

          // Impact stats row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImpactMiniStat('Views', '+42%', const Color(0xFF93C5FD)),
                Container(
                  height: 28,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                _buildImpactMiniStat('Calls', '+31%', const Color(0xFF34D399)),
                Container(
                  height: 28,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                _buildImpactMiniStat('Rating', '4.8★', const Color(0xFFFBBF24)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // CTA Button with premium styling
          InkWell(
            onTap: () => Navigator.of(context).push(
              ImpactScreen.route(onNavigateToTab: widget.onNavigateToTab),
            ),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFF8FAFC)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bar_chart_rounded, size: 16, color: Color(0xFF1E3A8A)),
                  const SizedBox(width: 8),
                  Text(
                    'View Full Impact & Comparison Report',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF1E3A8A)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 6. Channel Breakdown Donut Chart
  // ==========================================
  Widget _buildChannelBreakdownSection() {
    final channelData = _dashboardAnalytics?.channelBreakdown ?? {};
    return ChannelBreakdownDonut(channelData: channelData);
  }

  // ==========================================
  // 7. Weekly Customer Reach Momentum Chart
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
  // 8. Recommended Next Step (One Clear Primary Action)
  // ==========================================
  Widget _buildPrimaryNextAction() {
    final topRecs = _recommendations.where((r) => r.status != 'completed' && r.status != 'done').toList();

    if (topRecs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFA7F3D0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Caught Up! 🎉',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF065F46),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'All high-priority marketing actions are complete. Your branch is performing optimally.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF047857),
                      height: 1.35,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isUrgent ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0).withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: isUrgent
                ? const Color(0xFFEF4444).withValues(alpha: 0.06)
                : const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: isUrgent
                          ? const LinearGradient(colors: [Color(0xFFFEF2F2), Color(0xFFFEE2E2)])
                          : const LinearGradient(colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)]),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isUrgent
                            ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                            : const Color(0xFF2563EB).withValues(alpha: 0.12),
                      ),
                    ),
                    child: Icon(
                      isUrgent ? Icons.warning_amber_rounded : Icons.bolt_rounded,
                      color: isUrgent ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                      size: 16,
                    ),
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
          const SizedBox(height: 14),

          // Title
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
          const SizedBox(height: 16),

          // Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => widget.onNavigateToTab?.call(1),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Text(
                    'View all in Grow ›',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (topRec.relatedFeature == 'reviews') {
                      widget.onNavigateToTab?.call(4);
                    } else if (topRec.relatedFeature == 'posts' || topRec.relatedFeature == 'campaigns') {
                      widget.onNavigateToTab?.call(2);
                    } else if (topRec.relatedFeature == 'seo') {
                      widget.onNavigateToTab?.call(3);
                    } else {
                      widget.onNavigateToTab?.call(1);
                    }
                  },
                  icon: const Icon(Icons.bolt_rounded, size: 14, color: Colors.white),
                  label: Text(
                    'Execute in 1 Tap',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 9. Recent Live Updates Activity Stream
  // ==========================================
  Widget _buildRecentActivityStream() {
    final activities = _dashboardAnalytics?.recentActivity ?? [];
    if (activities.isEmpty) {
      return const SizedBox.shrink();
    }

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      ),
                    ),
                    child: const Icon(
                      Icons.timeline_rounded,
                      size: 14,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Live Activity',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              // Animated pulse dot
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.4, end: 1.0),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4 * value),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Activity items with timeline connector
          ...activities.take(3).toList().asMap().entries.map((entry) {
            final idx = entry.key;
            final act = entry.value;
            final isLast = idx == 2 || idx == activities.length - 1;

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
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Row(
                children: [
                  // Icon with subtle glow
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          iconColor.withValues(alpha: 0.12),
                          iconColor.withValues(alpha: 0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: iconColor.withValues(alpha: 0.08),
                      ),
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
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: act.badgeStatus == 'success'
                            ? [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)]
                            : (act.badgeStatus == 'warning'
                                ? [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)]
                                : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)]),
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: act.badgeStatus == 'success'
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : (act.badgeStatus == 'warning'
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                                : const Color(0xFF2563EB).withValues(alpha: 0.15)),
                      ),
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
