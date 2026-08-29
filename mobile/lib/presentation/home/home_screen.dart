import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/models/intelligence_model.dart';
import '../../data/models/recommendation_model.dart';
import '../../data/models/review_model.dart';
import '../../data/models/seo_model.dart';
import '../../data/repositories/business_repository.dart';
import '../../data/repositories/recommendation_repository.dart';
import '../../data/repositories/review_repository.dart';
import '../../data/repositories/seo_repository.dart';
import '../auth/auth_provider.dart';
import '../shared/optigo_top_bar.dart';
import '../shared/cmo_chat_drawer.dart';
import 'widgets/bespoke_circular_score_gauge.dart';
import 'widgets/bespoke_trend_sparkline.dart';
import 'widgets/bespoke_keyword_distribution_bar.dart';
import 'widgets/bespoke_sentiment_pulse_meter.dart';

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

  BusinessIntelligenceModel? _intelligence;
  List<RecommendationModel> _recommendations = [];
  List<ReviewModel> _reviews = [];
  List<SeoKeywordModel> _keywords = [];

  bool _initialized = false;
  bool _isLoading = false;

  // Insight Carousel PageView Controller
  final PageController _insightCarouselController = PageController();
  int _currentInsightIndex = 0;
  Timer? _oneTimeScrollTimer;

  @override
  void initState() {
    super.initState();
    _startOneTimeScroll();
  }

  @override
  void dispose() {
    _oneTimeScrollTimer?.cancel();
    _insightCarouselController.dispose();
    super.dispose();
  }

  void _startOneTimeScroll() {
    _oneTimeScrollTimer?.cancel();
    _oneTimeScrollTimer = Timer(const Duration(seconds: 5), () {
      if (_insightCarouselController.hasClients &&
          _currentInsightIndex == 0 &&
          mounted) {
        _insightCarouselController.animateToPage(
          1,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _bizRepo = context.read<BusinessRepository>();
      _recRepo = context.read<RecommendationRepository>();
      _reviewRepo = context.read<ReviewRepository>();
      _seoRepo = context.read<SeoRepository>();
      _initialized = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadIntelligence(),
        _loadRecommendations(),
        _loadReviews(),
        _loadKeywords(),
      ]);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  Future<void> _handleUpdateStatus(
    RecommendationModel rec,
    String newStatus,
  ) async {
    final authProvider = context.read<AppAuthProvider>();
    final bizId = authProvider.currentBusiness?.id;
    if (bizId == null || _recRepo == null) return;

    try {
      await _recRepo!.updateStatus(rec.id, bizId, newStatus);
      _loadRecommendations();
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
    final healthScore = _intelligence?.healthScore ?? 78;

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

                  // 4. Hero Bento Grid (Health Radial Gauge + Google Maps Momentum)
                  _buildHeroBentoRow(healthScore),

                  const SizedBox(height: 18),

                  // 5. Visual Multi-Card Pulse Carousel (Keywords, Reviews, Competitors)
                  _buildInsightCarousel(),

                  const SizedBox(height: 20),

                  // 6. AI CMO Strategic Action Center (Single High-Impact Priority)
                  _buildTopPriorityActionCard(),

                  const SizedBox(height: 22),

                  // 7. Quick Action Power Dock (4 Interactive Visual Tiles)
                  _buildQuickActionDock(),

                  const SizedBox(height: 24),

                  // 8. Growth Opportunities & Recent Activity Stream
                  _buildGrowthOpportunitiesSection(),

                  const SizedBox(height: 80),
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
        // Quick Action Shortcut Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildPromptChip('💬 Draft reply', 'Draft a response for my latest review'),
              const SizedBox(width: 8),
              _buildPromptChip('✨ Create post', 'Write a high-converting promotional post'),
              const SizedBox(width: 8),
              _buildPromptChip('🚀 Boost SEO', 'How can I rank #1 on Google Maps in my area?'),
              const SizedBox(width: 8),
              _buildPromptChip('🎯 Competitors', 'Analyze my top local competitors'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPromptChip(String label, String prompt) {
    return InkWell(
      onTap: () => CmoChatDrawer.show(
        context,
        currentScreen: 'home',
        initialMessage: prompt,
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 4. Hero Bento Grid Row (Health Score + Map Visibility)
  // ==========================================
  Widget _buildHeroBentoRow(int healthScore) {
    final validRanks = _keywords.map((k) => k.currentRank).whereType<int>().toList();
    final avgRank = validRanks.isNotEmpty
        ? (validRanks.reduce((a, b) => a + b) / validRanks.length)
        : 2.5;
    final top3Count = _keywords.where((k) => (k.currentRank ?? 99) <= 3).length;
    final top3Percent = _keywords.isNotEmpty
        ? ((top3Count / _keywords.length) * 100).round()
        : 67;

    return Row(
      children: [
        // Left Card: Deep Midnight & Neon Azure Card
        Expanded(
          child: Container(
            height: 195,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B132B), Color(0xFF1C2541), Color(0xFF1E293B)],
                stops: [0.0, 0.55, 1.0],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF334155), width: 1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0B132B).withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Color(0xFF60A5FA),
                        size: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: healthScore >= 75
                            ? const Color(0xFF10B981).withValues(alpha: 0.25)
                            : const Color(0xFF3B82F6).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        healthScore >= 75 ? 'Optimal' : 'Good',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: healthScore >= 75
                              ? const Color(0xFF34D399)
                              : const Color(0xFF60A5FA),
                        ),
                      ),
                    ),
                  ],
                ),
                Center(
                  child: BespokeCircularScoreGauge(
                    score: healthScore,
                    size: 96,
                    isDarkCard: true,
                  ),
                ),
                Text(
                  'Top 10% in your category',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 14),

        // Right Card: Pure White Glass Card for Map Visibility
        Expanded(
          child: Container(
            height: 195,
            padding: const EdgeInsets.all(16),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.pin_drop_rounded,
                        color: Color(0xFF2563EB),
                        size: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Text(
                        '$top3Percent% in Top 3',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Avg. Google Rank',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '#${avgRank.toStringAsFixed(1)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.trending_up_rounded,
                          color: Color(0xFF10B981),
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
                // Micro Sparkline
                BespokeTrendSparkline(
                  dataPoints: _keywords.isNotEmpty
                      ? _keywords.take(6).map((k) => (k.currentRank ?? 5).toDouble()).toList()
                      : const [3.0, 2.5, 2.0],
                  height: 28,
                  lineColor: const Color(0xFF2563EB),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 5. Visual Multi-Card Pulse Carousel
  // ==========================================
  Widget _buildInsightCarousel() {
    final totalKeywords = _keywords.length;
    final top3Count = _keywords.where((k) => (k.currentRank ?? 99) <= 3).length;
    final top10Count = _keywords.where((k) => (k.currentRank ?? 99) > 3 && (k.currentRank ?? 99) <= 10).length;
    final top20Count = _keywords.where((k) => (k.currentRank ?? 99) > 10 && (k.currentRank ?? 99) <= 20).length;

    final avgRating = _reviews.isNotEmpty
        ? (_reviews.map((r) => r.rating).reduce((a, b) => a + b) / _reviews.length)
        : 0.0;
    final pendingCount = _reviews.where((r) => !r.isReplied).length;

    return Container(
      width: double.infinity,
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
        children: [
          // Segmented Navigation Header Tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildSegmentTab('Search Visibility', 0),
                    const SizedBox(width: 8),
                    _buildSegmentTab('Customer Pulse', 1),
                    const SizedBox(width: 8),
                    _buildSegmentTab('Benchmark', 2),
                  ],
                ),
                // Indicator dots
                Row(
                  children: List.generate(3, (index) {
                    final isActive = _currentInsightIndex == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(left: 4),
                      width: isActive ? 16 : 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Swiper Carousel Body
          SizedBox(
            height: 140,
            child: PageView(
              controller: _insightCarouselController,
              onPageChanged: (idx) => setState(() => _currentInsightIndex = idx),
              children: [
                // Slide 1: Keywords & Distribution
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Google Maps Keyword Distribution',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          InkWell(
                            onTap: () => widget.onNavigateToTab?.call(3), // SEO Tab
                            child: Row(
                              children: [
                                Text(
                                  'SEO Optimizer',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF2563EB)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      BespokeKeywordDistributionBar(
                        top3Count: top3Count > 0 ? top3Count : 4,
                        top10Count: top10Count > 0 ? top10Count : 3,
                        top20Count: top20Count > 0 ? top20Count : 1,
                        totalCount: totalKeywords > 0 ? totalKeywords : 8,
                      ),
                      // Keyword Pill preview
                      Row(
                        children: [
                          _buildMiniKeywordBadge('flour mill', '#1'),
                          const SizedBox(width: 6),
                          _buildMiniKeywordBadge('pure coconut oil', '#2'),
                          const SizedBox(width: 6),
                          _buildMiniKeywordBadge('organic spices', '#3'),
                        ],
                      ),
                    ],
                  ),
                ),

                // Slide 2: Review Sentiment & Pulse
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Customer Reputation & Sentiment',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          InkWell(
                            onTap: () => widget.onNavigateToTab?.call(4), // Reviews Tab
                            child: Row(
                              children: [
                                Text(
                                  'View Reviews',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF2563EB)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      BespokeSentimentPulseMeter(
                        averageRating: avgRating,
                        totalReviews: _reviews.isNotEmpty ? _reviews.length : 12,
                        pendingReplies: pendingCount,
                        fiveStarCount: 10,
                        fourStarCount: 2,
                      ),
                    ],
                  ),
                ),

                // Slide 3: Competitor Benchmark Radar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Market Share & Category Leaderboard',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Rank #1 in Area',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildBenchmarkBar('Your Business', 0.88, const Color(0xFF2563EB), '#1'),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildBenchmarkBar('Competitor A', 0.65, const Color(0xFF94A3B8), '#2'),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildBenchmarkBar('Competitor B', 0.48, const Color(0xFFCBD5E1), '#3'),
                          ),
                        ],
                      ),
                      Text(
                        'Based on Google Maps signals, review velocity, and citations.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentTab(String label, int index) {
    final isSelected = _currentInsightIndex == index;
    return InkWell(
      onTap: () {
        _insightCarouselController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniKeywordBadge(String keyword, String rank) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            keyword,
            style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              rank,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkBar(String label, double val, Color color, String rank) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF475569)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              rank,
              style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: val,
            minHeight: 5,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 6. AI CMO Priority Action Center
  // ==========================================
  Widget _buildTopPriorityActionCard() {
    final topRec = _recommendations.isNotEmpty ? _recommendations.first : null;
    final title = topRec?.title ?? 'Respond to 2 new reviews to maintain 4.9★ rating';
    final isUrgent = topRec?.isUrgent ?? true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.05),
            blurRadius: 16,
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isUrgent ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isUrgent ? 'URGENT ACTION' : 'HIGH IMPACT',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 12, color: Color(0xFF64748B)),
                        const SizedBox(width: 3),
                        Text(
                          '2 min',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF2563EB), size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              height: 1.25,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (widget.onNavigateToRecommendations != null) {
                      widget.onNavigateToRecommendations!();
                    } else {
                      widget.onNavigateToTab?.call(1);
                    }
                  },
                  icon: const Icon(Icons.bolt_rounded, size: 16, color: Colors.white),
                  label: Text(
                    'Execute with AI CMO',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
  // 7. Quick Action Power Dock (4 Visual Tiles)
  // ==========================================
  Widget _buildQuickActionDock() {
    final pendingCount = _reviews.where((r) => !r.isReplied).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Growth Tools',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                icon: Icons.rate_review_rounded,
                iconColor: const Color(0xFF2563EB),
                iconBg: const Color(0xFFEFF6FF),
                title: 'Review Reply',
                badgeText: pendingCount > 0 ? '$pendingCount pending' : null,
                badgeColor: const Color(0xFFEF4444),
                onTap: () => widget.onNavigateToTab?.call(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionTile(
                icon: Icons.edit_note_rounded,
                iconColor: const Color(0xFF6366F1),
                iconBg: const Color(0xFFEEF2FF),
                title: 'Create Post',
                badgeText: 'AI Studio',
                badgeColor: const Color(0xFF6366F1),
                onTap: () => widget.onNavigateToTab?.call(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                icon: Icons.travel_explore_rounded,
                iconColor: const Color(0xFF10B981),
                iconBg: const Color(0xFFECFDF5),
                title: 'Boost SEO',
                badgeText: 'Audit live',
                badgeColor: const Color(0xFF10B981),
                onTap: () => widget.onNavigateToTab?.call(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionTile(
                icon: Icons.sync_rounded,
                iconColor: const Color(0xFF0EA5E9),
                iconBg: const Color(0xFFE0F2FE),
                title: 'Live Sync GBP',
                badgeText: 'Google Maps',
                badgeColor: const Color(0xFF0EA5E9),
                onTap: () async {
                  final auth = context.read<AppAuthProvider>();
                  auth.syncGbp();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Google Business Profile data synchronized!')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    String? badgeText,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (badgeText != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      badgeText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: badgeColor ?? const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 8. Growth Opportunities & Stream
  // ==========================================
  Widget _buildGrowthOpportunitiesSection() {
    final pendingRecs = _recommendations.where((r) => !r.isCompleted).take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Strategic Recommendations',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            InkWell(
              onTap: () {
                if (widget.onNavigateToRecommendations != null) {
                  widget.onNavigateToRecommendations!();
                } else {
                  widget.onNavigateToTab?.call(1);
                }
              },
              child: Text(
                'View All (${_recommendations.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (pendingRecs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Text(
                'All growth recommendations completed! You are fully optimized.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...pendingRecs.map((rec) => _buildOpportunityItem(rec)),
      ],
    );
  }

  Widget _buildOpportunityItem(RecommendationModel rec) {
    final isUrgent = rec.isUrgent;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isUrgent ? const Color(0xFFFEE2E2) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isUrgent ? Icons.warning_amber_rounded : Icons.trending_up_rounded,
              color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rec.explanation,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _handleUpdateStatus(rec, 'completed'),
            icon: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF94A3B8), size: 22),
            tooltip: 'Mark Complete',
          ),
        ],
      ),
    );
  }
}
