import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/models/review_model.dart';
import '../../data/repositories/review_repository.dart';
import '../auth/auth_provider.dart';
import '../shared/optigo_top_bar.dart';
import '../shared/optigo_pill.dart';

/// OptigoAI Customer Reviews & Reputation Management Hub (Screen 5)
/// Real-time Google Business Profile reviews, star distribution, sentiment split, and 1-tap AI replies.
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
  String _selectedFilter = 'all'; // 'all', 'pending', 'positive', 'negative'
  bool _isSyncing = false;
  bool _initialized = false;

  // Track manually expanded/collapsed review cards
  final Set<String> _manuallyToggledReviewIds = {};

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
    } catch (_) {
      if (mounted) setState(() => _isLoadingReviews = false);
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
          content: Text('Google Business Profile reviews synchronized!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  List<ReviewModel> get _filteredReviews {
    switch (_selectedFilter) {
      case 'positive':
        return _allReviews.where((r) => r.rating >= 4 || (r.sentiment?.toLowerCase() == 'positive')).toList();
      case 'negative':
        return _allReviews.where((r) => r.rating <= 2 || (r.sentiment?.toLowerCase() == 'negative')).toList();
      case 'pending':
        return _allReviews.where((r) => !r.isReplied).toList();
      case 'all':
      default:
        return _allReviews;
    }
  }

  double get _averageRating {
    if (_allReviews.isEmpty) return 0.0;
    final sum = _allReviews.fold<int>(0, (prev, r) => prev + r.rating);
    return double.parse((sum / _allReviews.length).toStringAsFixed(1));
  }

  int get _positiveSentimentPercentage {
    if (_allReviews.isEmpty) return 100;
    final positiveCount = _allReviews.where((r) => r.rating >= 4 || (r.sentiment?.toLowerCase() == 'positive')).length;
    return ((positiveCount / _allReviews.length) * 100).round();
  }

  void _openReviewReplyModal(ReviewModel review) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReviewReplyBottomSheet(
        review: review,
        onReplySuccess: (updated) {
          setState(() {
            final index = _allReviews.indexWhere((r) => r.id == updated.id);
            if (index != -1) {
              _allReviews[index] = updated;
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _allReviews.where((r) => !r.isReplied).length;
    final positiveCount = _allReviews.where((r) => r.rating >= 4).length;
    final negativeCount = _allReviews.where((r) => r.rating <= 2).length;
    final displayedReviews = _filteredReviews;

    final avgRating = _averageRating;

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
            onRefresh: _loadReviews,
            color: const Color(0xFF2563EB),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Navigation Bar
                  OptigoTopBar(
                    subtitle: 'Customer Reviews & Reputation',
                    onNotificationTap: widget.onNavigateToRecommendations,
                    onRefreshTap: _handleSyncGbp,
                    isRefreshing: _isSyncing,
                  ),

                  const SizedBox(height: 14),

                  // 2. Editorial Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer Reviews',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.6,
                            ),
                          ),
                          Text(
                            'Google Maps ratings & 1-tap AI responses',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: _isSyncing ? null : _handleSyncGbp,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isSyncing)
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                                )
                              else
                                const Icon(Icons.sync_rounded, size: 16, color: Color(0xFF2563EB)),
                              const SizedBox(width: 6),
                              Text(
                                _isSyncing ? 'Syncing...' : 'Sync GBP',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 3. Hero Reviews Bento Grid (Rating Score + Reply Rate)
                  Row(
                    children: [
                      // Left Card: Deep Midnight Rating Score
                      Expanded(
                        child: Container(
                          height: 185,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
                              stops: [0.0, 0.55, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFF334155), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.25),
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
                                    child: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                                  ),
                                  OptigoPill(
                                    label: avgRating >= 4.5
                                        ? 'Excellent'
                                        : (avgRating >= 4.0
                                            ? 'Great'
                                            : (avgRating >= 3.0 ? 'Moderate' : 'Needs Work')),
                                    variant: avgRating >= 4.0
                                        ? OptigoPillVariant.success
                                        : (avgRating >= 3.0 ? OptigoPillVariant.warning : OptigoPillVariant.error),
                                    fontSize: 10,
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '$avgRating',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: -1.0,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 24),
                                    ],
                                  ),
                                  Text(
                                    '${_allReviews.length} Total Google Reviews',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              Text(
                                avgRating >= 4.5
                                    ? 'Top 5% rated in area'
                                    : (avgRating >= 4.0
                                        ? 'Above local market average'
                                        : (avgRating >= 3.0 ? 'Room to boost rating' : 'Immediate attention required')),
                                style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: const Color(0xFF60A5FA), fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Right Card: Reply Rate & Pending
                      Expanded(
                        child: Container(
                          height: 185,
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
                                    child: const Icon(Icons.mark_chat_read_rounded, color: Color(0xFF2563EB), size: 16),
                                  ),
                                  OptigoPill(
                                    label: pendingCount > 0 ? '$pendingCount Pending' : '100% Replied',
                                    variant: pendingCount > 0 ? OptigoPillVariant.error : OptigoPillVariant.success,
                                    fontSize: 10,
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Positive Sentiment',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$_positiveSentimentPercentage%',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF0F172A),
                                      letterSpacing: -0.8,
                                    ),
                                  ),
                                ],
                              ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: (_positiveSentimentPercentage / 100.0).clamp(0.1, 1.0),
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 3.5 Star Rating Distribution & Sentiment Breakdown
                  _buildStarDistributionCard(),

                  const SizedBox(height: 18),

                  // 4. Interactive Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildFilterPill('all', 'All (${_allReviews.length})', OptigoPillVariant.neutral),
                        const SizedBox(width: 8),
                        _buildFilterPill('pending', 'Pending ($pendingCount)', OptigoPillVariant.error),
                        const SizedBox(width: 8),
                        _buildFilterPill('positive', 'Positive ($positiveCount)', OptigoPillVariant.success),
                        const SizedBox(width: 8),
                        _buildFilterPill('negative', 'Critical ($negativeCount)', OptigoPillVariant.warning),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 5. Smart Collapsible Reviews List
                  if (_isLoadingReviews)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
                    )
                  else if (displayedReviews.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Center(
                        child: Text(
                          'No reviews found in this category.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF64748B)),
                        ),
                      ),
                    )
                  else
                    ...displayedReviews.map((r) => _buildCollapsibleReviewCard(r)),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(String id, String label, OptigoPillVariant variant) {
    final isSelected = _selectedFilter == id;
    return OptigoPill(
      label: label,
      variant: variant,
      isSelected: isSelected,
      onTap: () => setState(() => _selectedFilter = id),
      fontSize: 11.5,
    );
  }

  Widget _buildStarDistributionCard() {
    final total = _allReviews.isNotEmpty ? _allReviews.length : 1;
    final r5 = _allReviews.where((r) => r.rating == 5).length;
    final r4 = _allReviews.where((r) => r.rating == 4).length;
    final r3 = _allReviews.where((r) => r.rating == 3).length;
    final r2 = _allReviews.where((r) => r.rating == 2).length;
    final r1 = _allReviews.where((r) => r.rating == 1).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 3),
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
                'Star Rating Breakdown',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                '${((r5 + r4) / total * 100).round()}% 4★ & 5★',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStarBar(5, r5, r5 / total),
          const SizedBox(height: 6),
          _buildStarBar(4, r4, r4 / total),
          const SizedBox(height: 6),
          _buildStarBar(3, r3, r3 / total),
          const SizedBox(height: 6),
          _buildStarBar(2, r2, r2 / total),
          const SizedBox(height: 6),
          _buildStarBar(1, r1, r1 / total),
        ],
      ),
    );
  }

  Widget _buildStarBar(int stars, int count, double ratio) {
    return Row(
      children: [
        SizedBox(
          width: 32,
          child: Row(
            children: [
              Text(
                '$stars',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF475569)),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(
                stars >= 4 ? const Color(0xFF10B981) : (stars == 3 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 22,
          child: Text(
            '$count',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B)),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsibleReviewCard(ReviewModel review) {
    final hasReply = review.isReplied;
    final isCritical = review.rating <= 2;
    final isManuallyToggled = _manuallyToggledReviewIds.contains(review.id);

    // 4★/5★ replied are collapsed by default; critical or pending are expanded by default
    final isExpanded = isManuallyToggled ? (review.rating >= 4 && hasReply) : (!hasReply || isCritical);

    final author = review.reviewerName;
    final initials = author.isNotEmpty ? author.substring(0, 1).toUpperCase() : 'U';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCritical ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Avatar, Author, Stars, Status Pill, Expand Arrow
          InkWell(
            onTap: () {
              setState(() {
                if (_manuallyToggledReviewIds.contains(review.id)) {
                  _manuallyToggledReviewIds.remove(review.id);
                } else {
                  _manuallyToggledReviewIds.add(review.id);
                }
              });
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Text(
                    initials,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: const Color(0xFF2563EB)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: const Color(0xFFF59E0B),
                            size: 14,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                OptigoPill(
                  label: hasReply ? 'Replied' : 'Pending',
                  variant: hasReply ? OptigoPillVariant.success : OptigoPillVariant.error,
                  fontSize: 10,
                ),
                const SizedBox(width: 6),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),

          // Expanded Content
          if (isExpanded) ...[
            const SizedBox(height: 12),
            Text(
              review.text ?? '',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: const Color(0xFF334155),
                height: 1.45,
              ),
            ),
            if (hasReply && review.replyText != null && review.replyText!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.reply_rounded, size: 13, color: Color(0xFF2563EB)),
                        const SizedBox(width: 4),
                        Text(
                          'Your Published Response',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      review.replyText!,
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF475569), height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
            if (!hasReply) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openReviewReplyModal(review),
                  icon: const Icon(Icons.bolt_rounded, size: 15, color: Colors.white),
                  label: Text(
                    'Draft AI Reply with Gemini',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ReviewReplyBottomSheet extends StatefulWidget {
  final ReviewModel review;
  final Function(ReviewModel) onReplySuccess;

  const _ReviewReplyBottomSheet({
    required this.review,
    required this.onReplySuccess,
  });

  @override
  State<_ReviewReplyBottomSheet> createState() => _ReviewReplyBottomSheetState();
}

class _ReviewReplyBottomSheetState extends State<_ReviewReplyBottomSheet> {
  final TextEditingController _replyController = TextEditingController();
  bool _isGenerating = true;
  bool _isPublishing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _generateAiDraft();
  }

  Future<void> _generateAiDraft() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    final reviewRepo = context.read<ReviewRepository>();
    final authProvider = context.read<AppAuthProvider>();
    final businessId = authProvider.currentBusiness?.id;

    if (businessId == null) return;

    try {
      final draft = await reviewRepo.generateAiReviewReply(
        reviewId: widget.review.id,
        businessId: businessId,
      );
      if (mounted) {
        setState(() {
          _replyController.text = draft;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _errorMessage = 'Failed to generate AI response: $e';
        });
      }
    }
  }

  Future<void> _handlePublishReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPublishing = true);

    final reviewRepo = context.read<ReviewRepository>();
    final authProvider = context.read<AppAuthProvider>();
    final businessId = authProvider.currentBusiness?.id;

    if (businessId == null) return;

    try {
      final updated = await reviewRepo.replyToReview(
        reviewId: widget.review.id,
        businessId: businessId,
        replyText: text,
      );
      if (mounted) {
        widget.onReplySuccess(updated);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reply published to Google Maps!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPublishing = false;
          _errorMessage = 'Failed to publish: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(22, 16, 22, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bolt_rounded, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Generated Response',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Review by ${widget.review.reviewerName} (${widget.review.rating}★)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                _errorMessage!,
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFFEF4444)),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (_isGenerating)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFF2563EB)),
                    SizedBox(height: 12),
                    Text('Gemini AI is crafting the perfect brand reply...'),
                  ],
                ),
              ),
            )
          else ...[
            TextField(
              controller: _replyController,
              maxLines: 4,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF1E293B)),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _generateAiDraft,
                  icon: const Icon(Icons.refresh_rounded, size: 15),
                  label: const Text('Regenerate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isPublishing ? null : _handlePublishReply,
                    icon: _isPublishing
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, size: 15, color: Colors.white),
                    label: Text(
                      _isPublishing ? 'Publishing...' : 'Approve & Publish',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
