import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
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

  // Insight Carousel PageView Controller & One-Time Auto-Scroll Timer (4s)
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
    _oneTimeScrollTimer = Timer(const Duration(seconds: 4), () {
      if (_insightCarouselController.hasClients && _currentInsightIndex == 0 && mounted) {
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

  @override
  Widget build(BuildContext context) {
    final healthScore = _intelligence?.healthScore ?? 78;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF2563EB),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Profile Pill + AI Refresh + Notification Circle
                OptigoTopBar(
                  onNotificationTap: widget.onNavigateToRecommendations,
                  onRefreshTap: _loadData,
                  isRefreshing: _isLoading,
                ),

                const SizedBox(height: 12),

                // 2. Large Editorial Headline (Inspired by reference)
                const Text(
                  'How is your business\nperforming today?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    height: 1.15,
                    letterSpacing: -0.8,
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Search / AI Prompt Pill Bar
                InkWell(
                  onTap: () => CmoChatDrawer.show(context, currentScreen: 'home'),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Search actions, keywords, reviews...',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 4. Hero Bento Grid Metrics (Dark Contrast Card + Clean White Card)
                _buildHeroBentoRow(healthScore),

                const SizedBox(height: 18),

                // 5. Multi-Card Insight Visualizer Carousel (Horizontal Scroll)
                _buildInsightCarousel(),

                const SizedBox(height: 18),

                // 6. Segmented Radial Gauge Performance Card (Reference Inspired)
                _buildSegmentedPerformanceCard(healthScore),

                const SizedBox(height: 24),

                // 7. Top Priority Action Card
                _buildTopPrioritySection(),

                const SizedBox(height: 24),

                // 8. Quick Actions Section
                _buildQuickActionsSection(),

                const SizedBox(height: 24),

                // 9. Growth Opportunities & Recent Activity Section
                _buildGrowthOpportunitiesSection(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 4. Hero Bento Grid Row (Dark Contrast Card + Pure White Card)
  // ==========================================
  Widget _buildHeroBentoRow(int healthScore) {
    return Row(
      children: [
        // Left Card: Dark Charcoal Hero Card (#0F172A)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
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
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Color(0xFF60A5FA),
                        size: 18,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Good',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF34D399),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Business Health',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$healthScore/100',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Right Card: Clean Pure White Card (#FFFFFF)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
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
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.travel_explore_rounded,
                        color: Color(0xFF2563EB),
                        size: 18,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Top 10%',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Avg Google Rank',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '#1.9 Rank',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 5. Multi-Card Insight Visualizer Carousel (Horizontal Scroll)
  // ==========================================
  Widget _buildInsightCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView(
            controller: _insightCarouselController,
            onPageChanged: (index) {
              setState(() {
                _currentInsightIndex = index;
              });
            },
            children: [
              _buildSlideCustomerViews(),
              _buildSlideReviewsTrend(),
              _buildSlideKeywordVisibility(),
              _buildSlideCompetitorComparison(),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildCarouselDots(),
      ],
    );
  }

  // ----------------------------------------------------
  // Slide 1: Customer Views & Weekly Activity Pill Chart
  // ----------------------------------------------------
  Widget _buildSlideCustomerViews() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      color: Color(0xFF2563EB),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Customer Views',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Google Search & Maps interactions',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '+24% vs last wk',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Custom Pill Bar Chart Painter
          const SizedBox(
            height: 100,
            width: double.infinity,
            child: CustomPaint(
              painter: _PillBarChartPainter(),
            ),
          ),

          const SizedBox(height: 12),

          // Glanceable bottom pill tags
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetricChip('⭐ 4.8 Rating', const Color(0xFFFEF3C7), const Color(0xFFD97706)),
              _buildMiniMetricChip('📞 1,280 Calls', const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
              _buildMiniMetricChip('📍 94% Direction', const Color(0xFFF3E8FF), const Color(0xFF7E22CE)),
              _buildMiniMetricChip('🌐 450 Clicks', const Color(0xFFECFDF5), const Color(0xFF059669)),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // Slide 2: Customer Reviews Trend & 1-5 Star Distribution
  // ----------------------------------------------------
  Widget _buildSlideReviewsTrend() {
    int totalReviews = 124;
    double avgRating = 4.8;
    int star5 = 78;
    int star4 = 14;
    int star3 = 5;
    int star2 = 2;
    int star1 = 1;

    if (_reviews.isNotEmpty) {
      totalReviews = _reviews.length;
      avgRating = _reviews.fold<double>(0, (sum, r) => sum + r.rating) / totalReviews;
      star5 = ((_reviews.where((r) => r.rating >= 4.5).length / totalReviews) * 100).round();
      star4 = ((_reviews.where((r) => r.rating >= 3.5 && r.rating < 4.5).length / totalReviews) * 100).round();
      star3 = ((_reviews.where((r) => r.rating >= 2.5 && r.rating < 3.5).length / totalReviews) * 100).round();
      star2 = ((_reviews.where((r) => r.rating >= 1.5 && r.rating < 2.5).length / totalReviews) * 100).round();
      star1 = ((_reviews.where((r) => r.rating < 1.5).length / totalReviews) * 100).round();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFD97706),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Reviews Trend',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Reviews received over time',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${avgRating.toStringAsFixed(1)} ★ ($totalReviews)',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              children: [
                // Left: Big Rating + Sparkline
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            avgRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 20),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '+18 this mo',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Weekly Inflow Trend',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Sparkline line chart
                      const SizedBox(
                        height: 38,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _SparklinePainter(
                            values: [14, 22, 31, 54],
                            lineColor: Color(0xFF2563EB),
                            fillColor: Color(0xFFEFF6FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Vertical divider
                Container(
                  width: 1,
                  height: 90,
                  color: const Color(0xFFF1F5F9),
                ),
                const SizedBox(width: 14),
                // Right: Rating Distribution ⭐1-5 Bars
                Expanded(
                  flex: 6,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStarDistributionRow(5, star5),
                      const SizedBox(height: 3),
                      _buildStarDistributionRow(4, star4),
                      const SizedBox(height: 3),
                      _buildStarDistributionRow(3, star3),
                      const SizedBox(height: 3),
                      _buildStarDistributionRow(2, star2),
                      const SizedBox(height: 3),
                      _buildStarDistributionRow(1, star1),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetricChip('🟢 94% Positive Sentiment', const Color(0xFFF0FDF4), const Color(0xFF16A34A)),
              _buildMiniMetricChip('⚡ 100% Google Replied', const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // Slide 3: Visibility by Keyword
  // ----------------------------------------------------
  Widget _buildSlideKeywordVisibility() {
    final keywords = _keywords.isNotEmpty
        ? _keywords.take(4).toList()
        : [
            SeoKeywordModel(
              id: '1',
              businessId: '',
              keyword: 'oil mill near me',
              searchVolume: '1.2k / mo',
              currentRank: 2,
              previousRank: 4,
              difficulty: 'Medium',
              intent: 'Local Intent',
              isTracked: true,
            ),
            SeoKeywordModel(
              id: '2',
              businessId: '',
              keyword: 'fresh cold pressed oil',
              searchVolume: '850 / mo',
              currentRank: 1,
              previousRank: 5,
              difficulty: 'Low',
              intent: 'Commercial',
              isTracked: true,
            ),
            SeoKeywordModel(
              id: '3',
              businessId: '',
              keyword: 'wholesale flour mill',
              searchVolume: '640 / mo',
              currentRank: 2,
              previousRank: 3,
              difficulty: 'Low',
              intent: 'B2B Intent',
              isTracked: true,
            ),
            SeoKeywordModel(
              id: '4',
              businessId: '',
              keyword: 'pure coconut oil',
              searchVolume: '420 / mo',
              currentRank: 3,
              previousRank: 2,
              difficulty: 'Medium',
              intent: 'Product Intent',
              isTracked: true,
            ),
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.travel_explore_rounded,
                      color: Color(0xFF4F46E5),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Visibility by Keyword',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Google Maps & Local Pack tracking',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Avg #1.9 Rank',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: keywords.map((k) => _buildKeywordRankRow(k)).toList(),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF059669)),
                SizedBox(width: 5),
                Text(
                  '4 of 5 keywords in Top 3 Google Map Pack',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // Slide 4: Competitor Visibility Comparison
  // ----------------------------------------------------
  Widget _buildSlideCompetitorComparison() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Color(0xFFD97706),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Competitor Comparison',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Your business vs local competitors',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '🏆 You Rank #1',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCompetitorRowHeader(),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildCompetitorMetricRow('Avg Google Rank', '#1.9', '#3.4', '#5.8', isRank: true),
                _buildCompetitorMetricRow('Keyword Coverage', '94%', '68%', '45%'),
                _buildCompetitorMetricRow('Reviews / Rating', '4.8★ (124)', '4.6★ (142)', '4.1★ (88)'),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Market Share Segmented Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Visibility Share', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                  Text('44% Lead Share', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 6,
                  child: Row(
                    children: [
                      Expanded(flex: 44, child: Container(color: const Color(0xFF2563EB))),
                      const SizedBox(width: 2),
                      Expanded(flex: 32, child: Container(color: const Color(0xFF8B5CF6))),
                      const SizedBox(width: 2),
                      Expanded(flex: 24, child: Container(color: const Color(0xFFCBD5E1))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // Carousel Dots Indicator (Interactive)
  // ----------------------------------------------------
  Widget _buildCarouselDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isSelected = _currentInsightIndex == index;
        return GestureDetector(
          onTap: () {
            _insightCarouselController.animateToPage(
              index,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: isSelected ? 22 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      }),
    );
  }

  // ----------------------------------------------------
  // Sub-widgets & helper rows
  // ----------------------------------------------------
  Widget _buildMiniMetricChip(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textCol,
        ),
      ),
    );
  }

  Widget _buildStarDistributionRow(int stars, int percentage) {
    return Row(
      children: [
        Text(
          '$stars★',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100.0,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(
                stars >= 4 ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8),
              ),
              minHeight: 5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 26,
          child: Text(
            '$percentage%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeywordRankRow(SeoKeywordModel keyword) {
    final curr = keyword.currentRank ?? 1;
    final prev = keyword.previousRank ?? 1;
    final isGain = prev > curr; // lower rank number is better (e.g. 4 -> 2 is gain)
    final delta = (prev - curr).abs();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    keyword.keyword,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    keyword.searchVolume,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '#$prev → #$curr',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isGain ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isGain ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 10,
                  color: isGain ? const Color(0xFF059669) : const Color(0xFFE11D48),
                ),
                const SizedBox(width: 1),
                Text(
                  '$delta',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isGain ? const Color(0xFF059669) : const Color(0xFFE11D48),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitorRowHeader() {
    return const Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            'METRIC',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            'YOU',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2563EB),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            'CITY HUB',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            'NATL MART',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompetitorMetricRow(String metric, String you, String comp1, String comp2, {bool isRank = false}) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            metric,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            you,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: isRank ? const Color(0xFF059669) : const Color(0xFF2563EB),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            comp1,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            comp2,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 6. Segmented Radial Gauge Performance Card (Reference Inspired)
  // ==========================================
  Widget _buildSegmentedPerformanceCard(int healthScore) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              const Text(
                'Marketing Optimization',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Segmented Arc Meter
          Center(
            child: SizedBox(
              width: 240,
              height: 120,
              child: CustomPaint(
                painter: _SegmentedRadialGaugePainter(score: healthScore),
                child: Align(
                  alignment: const Alignment(0, 0.5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$healthScore%',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'From last week',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Full-width pill action button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: widget.onNavigateToRecommendations,
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF8FAFC),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'See Detail Information',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }




  // ==========================================
  // 6. Top Priority Action Card
  // ==========================================
  Widget _buildTopPrioritySection() {
    final pendingRecs = _recommendations.where((r) => r.isPending).toList();
    RecommendationModel? topRec;
    if (pendingRecs.isNotEmpty) {
      topRec = pendingRecs.firstWhere(
        (r) => r.isUrgent,
        orElse: () => pendingRecs.first,
      );
    }

    final title = topRec?.title ?? 'Reply to 6 unanswered reviews';
    final desc =
        topRec?.explanation ??
        'Customers are waiting for your response. This can directly impact your reputation.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Top Priority',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            InkWell(
              onTap: widget.onNavigateToRecommendations,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Color(0xFF2563EB),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFEE2E2), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Red Rounded Box with Message Icon and Badge Count
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: Color(0xFFEF4444),
                            size: 24,
                          ),
                        ),
                      ),
                      Positioned(
                        top: -3,
                        right: -3,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFDC2626),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: const Center(
                            child: Text(
                              '6',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Title, URGENT badge & explanation
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'URGENT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFDC2626),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          desc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Action Buttons Row (Take Action + Mark Done)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (topRec?.relatedFeature == 'reviews' &&
                            widget.onNavigateToReviews != null) {
                          widget.onNavigateToReviews!();
                        } else if (topRec?.relatedFeature == 'posts' &&
                            widget.onNavigateToTab != null) {
                          widget.onNavigateToTab!(2);
                        } else if (topRec?.relatedFeature == 'seo' &&
                            widget.onNavigateToTab != null) {
                          widget.onNavigateToTab!(3);
                        } else if (widget.onNavigateToReviews != null) {
                          widget.onNavigateToReviews!();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Take Action',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          topRec != null
                              ? () => _handleUpdateStatus(topRec!, 'completed')
                              : () {},
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                        color: Color(0xFF475569),
                      ),
                      label: const Text(
                        'Mark Done',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 6. Quick Actions Section
  // ==========================================
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 14),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildQuickActionItem(
                icon: Icons.auto_awesome,
                iconColor: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
                label: 'Today\'s\nActions',
                onTap: () {
                  if (widget.onNavigateToRecommendations != null) {
                    widget.onNavigateToRecommendations!();
                  }
                },
              ),
              const SizedBox(width: 12),
              _buildQuickActionItem(
                icon: Icons.edit_note_rounded,
                iconColor: const Color(0xFF8B5CF6),
                bgColor: const Color(0xFFF5F3FF),
                label: 'Create\nContent',
                onTap: () {
                  if (widget.onNavigateToTab != null) {
                    widget.onNavigateToTab!(2);
                  }
                },
              ),
              const SizedBox(width: 12),
              _buildQuickActionItem(
                icon: Icons.travel_explore_rounded,
                iconColor: const Color(0xFF10B981),
                bgColor: const Color(0xFFECFDF5),
                label: 'Optimize\nSEO',
                onTap: () {
                  if (widget.onNavigateToTab != null) {
                    widget.onNavigateToTab!(3);
                  }
                },
              ),
              const SizedBox(width: 12),
              _buildQuickActionItem(
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: const Color(0xFF0EA5E9),
                bgColor: const Color(0xFFE0F2FE),
                label: 'Manage\nReviews',
                onTap: () {
                  if (widget.onNavigateToReviews != null) {
                    widget.onNavigateToReviews!();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 90,
        height: 96,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Icon(icon, size: 22, color: iconColor)),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 7. Growth Opportunities Section
  // ==========================================
  Widget _buildGrowthOpportunitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Growth Opportunities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            InkWell(
              onTap: widget.onNavigateToRecommendations,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Color(0xFF2563EB),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildGrowthCard(
                icon: Icons.bolt_rounded,
                iconColor: const Color(0xFFD97706),
                iconBg: const Color(0xFFFEF3C7),
                title: 'Improve Local SEO',
                impactTag: 'Medium Impact',
                impactColor: const Color(0xFFD97706),
                impactBg: const Color(0xFFFEF3C7),
                highlight: 'Boost visibility',
                subtitle: 'Rank higher on Maps',
                onTap: () {
                  if (widget.onNavigateToTab != null) {
                    widget.onNavigateToTab!(3);
                  }
                },
              ),
              const SizedBox(width: 14),
              _buildGrowthCard(
                icon: Icons.article_outlined,
                iconColor: const Color(0xFF10B981),
                iconBg: const Color(0xFFECFDF5),
                title: 'Post Regular Updates',
                impactTag: 'Low Effort',
                impactColor: const Color(0xFF10B981),
                impactBg: const Color(0xFFECFDF5),
                highlight: 'Stay active',
                subtitle: 'Engage customers',
                onTap: () {
                  if (widget.onNavigateToTab != null) {
                    widget.onNavigateToTab!(2);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Recent Activity Stream (Inspired by reference design screen 3)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Activity & Updates',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              _buildActivityRow(
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFF59E0B),
                iconBg: const Color(0xFFFEF3C7),
                title: 'New 5-Star Google Review',
                subtitle: 'Aarav Sharma • 2h ago',
                badgeText: 'Replied',
                badgeColor: const Color(0xFF10B981),
                badgeBg: const Color(0xFFECFDF5),
              ),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              _buildActivityRow(
                icon: Icons.search_rounded,
                iconColor: const Color(0xFF2563EB),
                iconBg: const Color(0xFFEFF6FF),
                title: '"cold pressed oil near me"',
                subtitle: 'Ranked #2 on Google Maps',
                badgeText: '+3 Ranks',
                badgeColor: const Color(0xFF2563EB),
                badgeBg: const Color(0xFFEFF6FF),
              ),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              _buildActivityRow(
                icon: Icons.edit_note_rounded,
                iconColor: const Color(0xFF8B5CF6),
                iconBg: const Color(0xFFF5F3FF),
                title: 'Multi-Channel Promo Draft',
                subtitle: 'Instagram & Facebook post ready',
                badgeText: 'Draft',
                badgeColor: const Color(0xFF8B5CF6),
                badgeBg: const Color(0xFFF5F3FF),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBg,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Center(child: Icon(icon, size: 18, color: iconColor)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            badgeText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: badgeColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrowthCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String impactTag,
    required Color impactColor,
    required Color impactBg,
    required String highlight,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Icon(icon, size: 18, color: iconColor)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: impactBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                impactTag,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: impactColor,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Text(
              highlight,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: impactColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



// ==========================================
// PILL BAR CHART PAINTER (Reference Inspired)
// ==========================================
class _PillBarChartPainter extends CustomPainter {
  const _PillBarChartPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const values = [0.35, 0.50, 0.40, 0.65, 0.95, 0.45, 0.30];
    const activeIndex = 4; // Friday highlighted

    final barWidth = (size.width / 7) - 18;
    final maxBarHeight = size.height - 24;

    for (int i = 0; i < 7; i++) {
      final xCenter = (size.width / 7) * i + (size.width / 14);
      final left = xCenter - (barWidth / 2);
      final top = 0.0;
      final height = maxBarHeight;

      final isSelected = i == activeIndex;

      // 1. Soft Track Pillar
      final trackPaint = Paint()
        ..color = isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC)
        ..style = PaintingStyle.fill;
      final trackRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, height),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(trackRect, trackPaint);

      // 2. Active Filled Pill Value
      final filledHeight = height * values[i];
      final filledTop = top + (height - filledHeight);

      final fillPaint = Paint()
        ..color = isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)
        ..style = PaintingStyle.fill;

      final fillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, filledTop, barWidth, filledHeight),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(fillRect, fillPaint);

      // 3. Day Label
      final daySpan = TextSpan(
        text: days[i],
        style: TextStyle(
          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
          fontSize: 10.5,
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          fontFamily: 'Inter',
        ),
      );
      final dayPainter = TextPainter(
        text: daySpan,
        textDirection: TextDirection.ltr,
      )..layout();
      dayPainter.paint(
        canvas,
        Offset(xCenter - (dayPainter.width / 2), top + height + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==========================================
// SEGMENTED RADIAL GAUGE PAINTER (Reference Inspired)
// ==========================================
class _SegmentedRadialGaugePainter extends CustomPainter {
  final int score;

  const _SegmentedRadialGaugePainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final outerRadius = size.width / 2 - 12;
    final innerRadius = outerRadius - 18;

    const totalSegments = 26;
    final activeSegments = ((score / 100) * totalSegments).round();

    const startAngle = pi;
    const totalAngle = pi;
    final stepAngle = totalAngle / totalSegments;
    const gapAngle = 0.035;

    for (int i = 0; i < totalSegments; i++) {
      final segStart = startAngle + (i * stepAngle) + (gapAngle / 2);
      final segSweep = stepAngle - gapAngle;

      final isActive = i < activeSegments;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14.0
        ..strokeCap = StrokeCap.round;

      if (isActive) {
        // Gradient color transition from amber/gold to primary blue
        final t = i / totalSegments;
        final color = Color.lerp(
          const Color(0xFFF59E0B),
          const Color(0xFF2563EB),
          t,
        )!;
        paint.color = color;
      } else {
        paint.color = const Color(0xFFF1F5F9);
      }

      final midRadius = (innerRadius + outerRadius) / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: midRadius),
        segStart,
        segSweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedRadialGaugePainter oldDelegate) =>
      oldDelegate.score != score;
}

// ==========================================
// SPARKLINE LINE CHART PAINTER (Mini Reviews Growth)
// ==========================================
class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final Color fillColor;

  const _SparklinePainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final maxVal = values.reduce(max);
    final minVal = values.reduce(min);
    final range = maxVal - minVal > 0 ? maxVal - minVal : 1.0;

    final points = <Offset>[];
    final stepX = size.width / (values.length - 1);

    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      // Invert Y because canvas origin (0,0) is top-left
      final normY = (values[i] - minVal) / range;
      final y = size.height - (normY * (size.height - 8)) - 4;
      points.add(Offset(x, y));
    }

    // 1. Draw smooth gradient/fill under the line
    final fillPath = Path();
    fillPath.moveTo(points.first.dx, size.height);
    fillPath.lineTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final cx = (p0.dx + p1.dx) / 2;
      fillPath.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }

    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.25),
          fillColor.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 2. Draw smooth stroke line
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final cx = (p0.dx + p1.dx) / 2;
      linePath.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }

    final strokePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, strokePaint);

    // 3. Draw endpoint indicator dot
    final lastPoint = points.last;
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawCircle(lastPoint, 4, dotPaint);
    canvas.drawCircle(lastPoint, 4, dotBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => true;
}

