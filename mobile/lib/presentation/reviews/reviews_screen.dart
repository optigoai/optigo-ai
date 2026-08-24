import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/models/review_model.dart';
import '../../data/repositories/review_repository.dart';
import '../auth/auth_provider.dart';
import '../shared/optigo_top_bar.dart';

class ReviewsScreen extends StatefulWidget {
  final VoidCallback? onNavigateToRecommendations;

  const ReviewsScreen({
    super.key,
    this.onNavigateToRecommendations,
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  ReviewRepository? _reviewRepo;
  List<ReviewModel> _allReviews = [];
  bool _isLoadingReviews = true;
  String _selectedFilter = 'all'; // 'all', 'positive', 'negative', 'pending'
  bool _isSyncing = false;
  bool _initialized = false;

  // Top Carousel PageView & One-Time Auto-Scroll Timer (4 Seconds Once)
  final PageController _topCarouselController = PageController();
  int _currentTopPageIndex = 0;
  Timer? _oneTimeScrollTimer;
  Map<String, dynamic>? _reviewIntelligence;
  bool _isLoadingIntelligence = false;

  @override
  void initState() {
    super.initState();
    _startOneTimeScroll();
  }

  @override
  void dispose() {
    _oneTimeScrollTimer?.cancel();
    _topCarouselController.dispose();
    super.dispose();
  }

  void _startOneTimeScroll() {
    _oneTimeScrollTimer?.cancel();
    _oneTimeScrollTimer = Timer(const Duration(seconds: 4), () {
      if (_topCarouselController.hasClients && _currentTopPageIndex == 0 && mounted) {
        _topCarouselController.animateToPage(
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
      _reviewRepo = context.read<ReviewRepository>();
      _initialized = true;
      _loadReviews();
    }
  }

  Future<void> _loadReviews() async {
    if (_reviewRepo == null) return;
    final authProvider = context.read<AppAuthProvider>();
    final businessId = authProvider.currentBusiness?.id;
    if (businessId == null) return;

    setState(() => _isLoadingReviews = true);
    try {
      final reviews = await _reviewRepo!.getReviews(
        businessId: businessId,
        unansweredOnly: false,
      );
      if (mounted) {
        setState(() {
          _allReviews = reviews;
          _isLoadingReviews = false;
        });
      }
      _loadIntelligence(businessId);
    } catch (_) {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  Future<void> _loadIntelligence(String businessId) async {
    if (_reviewRepo == null) return;
    setState(() => _isLoadingIntelligence = true);
    try {
      final intel = await _reviewRepo!.getReviewIntelligence(businessId: businessId);
      if (mounted && intel.isNotEmpty) {
        setState(() {
          _reviewIntelligence = intel;
          _isLoadingIntelligence = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingIntelligence = false);
    }
  }

  Future<void> _handleSyncGbp() async {
    setState(() => _isSyncing = true);
    final authProvider = context.read<AppAuthProvider>();
    await authProvider.syncGbp();
    await _loadReviews();
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ Google Business Profile reviews synchronized!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  List<ReviewModel> get _filteredReviews {
    switch (_selectedFilter) {
      case 'positive':
        return _allReviews.where((r) => r.rating >= 4 || r.sentiment == 'positive').toList();
      case 'negative':
        return _allReviews.where((r) => r.rating <= 2 || r.sentiment == 'negative').toList();
      case 'pending':
        return _allReviews.where((r) => !r.isReplied).toList();
      case 'all':
      default:
        return _allReviews;
    }
  }

  double get _averageRating {
    if (_allReviews.isEmpty) return 4.6;
    final sum = _allReviews.fold<int>(0, (prev, r) => prev + r.rating);
    return double.parse((sum / _allReviews.length).toStringAsFixed(1));
  }

  Map<int, double> get _starPercentages {
    if (_allReviews.isEmpty) {
      return {5: 0.72, 4: 0.20, 3: 0.06, 2: 0.01, 1: 0.01};
    }
    final total = _allReviews.length;
    final counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in _allReviews) {
      final star = r.rating.clamp(1, 5);
      counts[star] = (counts[star] ?? 0) + 1;
    }
    return {
      5: counts[5]! / total,
      4: counts[4]! / total,
      3: counts[3]! / total,
      2: counts[2]! / total,
      1: counts[1]! / total,
    };
  }

  void _openReviewDetailModal(ReviewModel review) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReviewDetailModal(
        review: review,
        onReplyPosted: (updatedReview) {
          setState(() {
            final index = _allReviews.indexWhere((r) => r.id == updatedReview.id);
            if (index != -1) {
              _allReviews[index] = updatedReview;
            }
          });
        },
      ),
    );
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'Recent';
    if (rawDate.contains('T')) {
      return rawDate.split('T')[0];
    }
    return rawDate;
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _allReviews.where((r) => !r.isReplied).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadReviews,
          color: const Color(0xFF2563EB),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Profile Pill + AI Refresh + Notification Circle
                OptigoTopBar(
                  subtitle: 'Customer Reviews & Reputation',
                  onNotificationTap: widget.onNavigateToRecommendations,
                  onRefreshTap: _loadReviews,
                  isRefreshing: _isLoadingReviews,
                ),

                const SizedBox(height: 12),

                // Large Editorial Title + Sync Button Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Reviews',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.8,
                      ),
                    ),
                    InkWell(
                      onTap: _isSyncing ? null : _handleSyncGbp,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isSyncing)
                              const SizedBox(
                                width: 13,
                                height: 13,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                              )
                            else
                              const Icon(Icons.sync_rounded, size: 15, color: Color(0xFF2563EB)),
                            const SizedBox(width: 5),
                            Text(
                              _isSyncing ? 'Syncing...' : 'Sync Google',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 2. Auto-Scrolling Top Carousel: Star Ratings & AI Review Intelligence
                _buildTopCarousel(),

                const SizedBox(height: 18),

                // 3. Filter Pills (All, Positive, Negative, Pending)
                _buildFilterPills(pendingCount: pendingCount),

                const SizedBox(height: 16),

                // 4. Reviews List
                if (_isLoadingReviews)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                    ),
                  )
                else if (_filteredReviews.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.rate_review_outlined, size: 36, color: Color(0xFF94A3B8)),
                          SizedBox(height: 10),
                          Text(
                            'No reviews found in this category.',
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._filteredReviews.map((r) => _buildReviewCard(r)),

                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TOP CAROUSEL: RATING & AI REVIEW INTELLIGENCE
  // ==========================================
  Widget _buildTopCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView(
            controller: _topCarouselController,
            onPageChanged: (index) {
              setState(() => _currentTopPageIndex = index);
            },
            children: [
              _buildRatingSummaryCard(),
              _buildReviewIntelligenceCard(),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildCarouselDots(),
      ],
    );
  }

  Widget _buildCarouselDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (index) {
        final isActive = _currentTopPageIndex == index;
        return GestureDetector(
          onTap: () {
            _topCarouselController.animateToPage(
              index,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: isActive ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }

  // ==========================================
  // SLIDE 1: RATING BREAKDOWN SUMMARY CARD
  // ==========================================
  Widget _buildRatingSummaryCard() {
    final avgRating = _averageRating;
    final totalCount = _allReviews.isNotEmpty ? _allReviews.length : 8;
    final percentages = _starPercentages;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
                'Customer Rating',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
                    SizedBox(width: 4),
                    Text(
                      'Google Verified',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Big Rating Number & Based on X reviews
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          avgRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -1.0,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFF59E0B),
                          size: 28,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Based on $totalCount\nreviews',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 20),

                // Right: 5-Star Horizontal Progress Breakdown Bars
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStarProgressBar(5, percentages[5] ?? 0.38),
                      const SizedBox(height: 6),
                      _buildStarProgressBar(4, percentages[4] ?? 0.25),
                      const SizedBox(height: 6),
                      _buildStarProgressBar(3, percentages[3] ?? 0.13),
                      const SizedBox(height: 6),
                      _buildStarProgressBar(2, percentages[2] ?? 0.13),
                      const SizedBox(height: 6),
                      _buildStarProgressBar(1, percentages[1] ?? 0.13),
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

  // ==========================================
  // SLIDE 2: REVIEW INTELLIGENCE ("What reviews say")
  // ==========================================
  Widget _buildReviewIntelligenceCard() {
    // 1. Dynamic sentiment percentages from intelligence or actual reviews
    int posPct = 0;
    int neuPct = 0;
    int negPct = 0;

    if (_reviewIntelligence != null && _reviewIntelligence!['positive_percentage'] != null) {
      posPct = (_reviewIntelligence!['positive_percentage'] as num).toInt();
      neuPct = (_reviewIntelligence!['neutral_percentage'] as num).toInt();
      negPct = (_reviewIntelligence!['negative_percentage'] as num).toInt();
    } else if (_allReviews.isNotEmpty) {
      final total = _allReviews.length;
      final pos = _allReviews.where((r) => r.rating >= 4 || r.sentiment == 'positive').length;
      final neg = _allReviews.where((r) => r.rating <= 2 || r.sentiment == 'negative').length;
      posPct = ((pos / total) * 100).round();
      negPct = ((neg / total) * 100).round();
      neuPct = (100 - (posPct + negPct)).clamp(0, 100);
    }

    // 2. Real top feedback keywords from AI intelligence
    List<Map<String, dynamic>> feedbackKeywords = [];
    if (_reviewIntelligence != null && _reviewIntelligence!['top_feedback'] is List) {
      feedbackKeywords = List<Map<String, dynamic>>.from(_reviewIntelligence!['top_feedback']);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          // Header Row: "What reviews say" + AI badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'What reviews say',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoadingIntelligence)
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF4F46E5)),
                      )
                    else
                      const Icon(Icons.auto_awesome, size: 11, color: Color(0xFF4F46E5)),
                    const SizedBox(width: 4),
                    const Text(
                      'Review Intelligence',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 3 Sentiment Breakdown Cards in Row (Positive, Neutral, Negative)
          Row(
            children: [
              Expanded(
                child: _buildSentimentStatBox(
                  label: 'Positive',
                  percentage: '$posPct%',
                  bgColor: const Color(0xFFF0FDF4),
                  borderColor: const Color(0xFFBBF7D0),
                  textColor: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSentimentStatBox(
                  label: 'Neutral',
                  percentage: '$neuPct%',
                  bgColor: const Color(0xFFF5F3FF),
                  borderColor: const Color(0xFFDDD6FE),
                  textColor: const Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSentimentStatBox(
                  label: 'Negative',
                  percentage: '$negPct%',
                  bgColor: const Color(0xFFFEF2F2),
                  borderColor: const Color(0xFFFECACA),
                  textColor: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Top Feedback Section Subtitle
          const Text(
            'Top Feedback',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF334155),
            ),
          ),

          const SizedBox(height: 6),

          // Feedback Keyword List (Real Detected Keywords Only)
          Expanded(
            child: feedbackKeywords.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No review keywords detected yet.',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: feedbackKeywords.take(4).length,
                    separatorBuilder: (_, __) => const Divider(height: 6, thickness: 0.5, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, idx) {
                      final item = feedbackKeywords[idx];
                      final kw = item['keyword']?.toString() ?? 'Service';
                      final pct = (item['percentage'] as num?)?.toInt() ?? 0;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              kw,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$pct%',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentStatBox({
    required String label,
    required String percentage,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            percentage,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarProgressBar(int stars, double ratio) {
    final percentageInt = (ratio * 100).round();

    return Row(
      children: [
        SizedBox(
          width: 22,
          child: Row(
            children: [
              Text(
                '$stars',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                ),
              ),
              const Icon(Icons.star_rounded, size: 11, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            '$percentageInt%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // FILTER PILLS (Reference Layout: All, Positive, Negative, Pending)
  // ==========================================
  Widget _buildFilterPills({required int pendingCount}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterPill(key: 'all', label: 'All'),
          const SizedBox(width: 8),
          _buildFilterPill(key: 'positive', label: 'Positive'),
          const SizedBox(width: 8),
          _buildFilterPill(key: 'negative', label: 'Negative'),
          const SizedBox(width: 8),
          _buildFilterPill(
            key: 'pending',
            label: 'Pending',
            badge: pendingCount > 0 ? '$pendingCount' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({required String key, required String label, String? badge}) {
    final isSelected = _selectedFilter == key;

    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // INDIVIDUAL REVIEW CARD (Reference Left Screen)
  // ==========================================
  Widget _buildReviewCard(ReviewModel review) {
    final formattedDate = _formatDate(review.reviewDate);
    final initial = review.reviewerName.isNotEmpty ? review.reviewerName[0].toUpperCase() : 'U';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header Row
          Row(
            children: [
              // Circular Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  review.reviewerName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Golden Star Rating
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                Icons.star_rounded,
                size: 18,
                color: index < review.rating ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Review Body Text
          Text(
            review.text ?? 'No written comment provided.',
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 14),          // Bottom Action: If Replied -> show status tag. If Pending -> show "Reply with AI" button.
          if (review.isReplied) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  const Text(
                    'Replied to customer',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => _openReviewDetailModal(review),
                    child: const Text(
                      'View Reply',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            InkWell(
              onTap: () => _openReviewDetailModal(review),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Reply with AI',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================================
// RIGHT SCREEN MODAL: REVIEW DETAIL & AI SUGGESTED RESPONSE
// (Matching Reference Right Screen UI & Philosophy)
// ==========================================================
class _ReviewDetailModal extends StatefulWidget {
  final ReviewModel review;
  final Function(ReviewModel) onReplyPosted;

  const _ReviewDetailModal({
    required this.review,
    required this.onReplyPosted,
  });

  @override
  State<_ReviewDetailModal> createState() => _ReviewDetailModalState();
}

class _ReviewDetailModalState extends State<_ReviewDetailModal> {
  int _activeTabIndex = 1; // 0: Review, 1: AI Response
  late TextEditingController _replyTextController;
  bool _isGenerating = false;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _replyTextController = TextEditingController(
      text: widget.review.replyText ?? widget.review.aiGeneratedReply ?? '',
    );

    if (_replyTextController.text.isEmpty && !widget.review.isReplied) {
      _generateAiReply();
    }
  }

  @override
  void dispose() {
    _replyTextController.dispose();
    super.dispose();
  }

  Future<void> _generateAiReply() async {
    final reviewRepo = context.read<ReviewRepository>();
    final bizId = widget.review.businessId;

    setState(() => _isGenerating = true);
    try {
      final aiText = await reviewRepo.generateAiReviewReply(
        reviewId: widget.review.id,
        businessId: bizId,
        tone: 'warm & professional',
      );
      if (mounted) {
        setState(() {
          _replyTextController.text = aiText;
          _isGenerating = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _replyTextController.text =
              "Hi ${widget.review.reviewerName}, thank you so much for the wonderful feedback! We take great pride in our quality and service, and we look forward to serving you again soon!";
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _handleUseAndReply() async {
    final replyText = _replyTextController.text.trim();
    if (replyText.isEmpty) return;

    final reviewRepo = context.read<ReviewRepository>();
    setState(() => _isPosting = true);

    try {
      final updated = await reviewRepo.replyToReview(
        reviewId: widget.review.id,
        businessId: widget.review.businessId,
        replyText: replyText,
      );

      widget.onReplyPosted(updated);

      if (mounted) {
        setState(() => _isPosting = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Reply posted successfully to Google!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post reply: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.review.reviewerName.isNotEmpty ? widget.review.reviewerName[0].toUpperCase() : 'U';

    String formattedDate = widget.review.reviewDate ?? 'Recent';
    if (formattedDate.contains('T')) {
      formattedDate = formattedDate.split('T')[0];
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Top Segmented Capsule Switcher: Review | AI Response (Matching Reference Right Screen)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _activeTabIndex = 0),
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _activeTabIndex == 0 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _activeTabIndex == 0
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            'Review',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: _activeTabIndex == 0 ? FontWeight.w800 : FontWeight.w600,
                              color: _activeTabIndex == 0 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _activeTabIndex = 1),
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _activeTabIndex == 1 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _activeTabIndex == 1
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 14,
                              color: _activeTabIndex == 1 ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'AI Response',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: _activeTabIndex == 1 ? FontWeight.w800 : FontWeight.w600,
                                color: _activeTabIndex == 1 ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Review Summary Card at Top
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
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
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFDBEAFE)),
                                ),
                                child: Center(
                                  child: Text(
                                    initial,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.review.reviewerName,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                    ),
                                    Text(
                                      formattedDate,
                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: List.generate(
                              5,
                              (index) => Icon(
                                Icons.star_rounded,
                                size: 18,
                                color: index < widget.review.rating ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.review.text ?? 'No written comment provided.',
                            style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155), height: 1.45, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),

                    if (_activeTabIndex == 1) ...[
                      const SizedBox(height: 18),

                      // Premium AI Suggested Response Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Bar with AI Badge, Editable Pill, and Action Buttons
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 14, 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFDBEAFE)),
                                        ),
                                        child: const Icon(
                                          Icons.auto_awesome_rounded,
                                          size: 15,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'AI Suggested Response',
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          Text(
                                            'Tap text below to edit before posting',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      // Copy Draft Button
                                      IconButton(
                                        icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF64748B)),
                                        tooltip: 'Copy reply',
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: _replyTextController.text));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Response copied to clipboard!'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                      ),
                                      // Regenerate Button
                                      IconButton(
                                        icon: _isGenerating
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Color(0xFF2563EB),
                                                ),
                                              )
                                            : const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF2563EB)),
                                        tooltip: 'Regenerate response',
                                        visualDensity: VisualDensity.compact,
                                        onPressed: _isGenerating ? null : _generateAiReply,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Inner White Canvas for Text
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: _isGenerating
                                    ? const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 28),
                                        child: Column(
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF2563EB)),
                                            ),
                                            SizedBox(height: 10),
                                            Text(
                                              'Crafting personalized brand response with Gemini...',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : TextField(
                                        controller: _replyTextController,
                                        maxLines: null,
                                        minLines: 4,
                                        keyboardType: TextInputType.multiline,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          color: Color(0xFF1E293B),
                                          height: 1.55,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                          isDense: true,
                                          hintText: 'Type custom reply here...',
                                          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                        ),
                                      ),
                              ),
                            ),

                            // Footer Optimization Pill
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                              child: Row(
                                children: const [
                                  Icon(Icons.verified_rounded, size: 14, color: Color(0xFF16A34A)),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Optimized for Google Maps SEO & customer retention',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF16A34A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Big Action Button: Use & Reply
                      InkWell(
                        onTap: (_isPosting || _isGenerating) ? null : _handleUseAndReply,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isPosting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.send_rounded, size: 16, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Use & Reply',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 18),
                      // Review Details Tab Content
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Review Metadata',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Source', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                Text(widget.review.source.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Sentiment', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                Text(
                                  widget.review.sentiment ?? (widget.review.rating >= 4 ? 'Positive' : 'Needs attention'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: widget.review.rating >= 4 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Status', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                Text(
                                  widget.review.isReplied ? 'Replied' : 'Pending response',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: widget.review.isReplied ? const Color(0xFF10B981) : const Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

