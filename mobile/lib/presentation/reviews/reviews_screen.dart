import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../data/models/review_model.dart';
import '../../data/repositories/review_repository.dart';
import '../auth/auth_provider.dart';
import '../shared/optigo_top_bar.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  ReviewRepository? _reviewRepo;
  List<ReviewModel> _reviews = [];
  bool _isLoadingReviews = true;
  String _selectedFilter = 'all'; // 'all', 'pending', 'replied'
  bool _isSyncing = false;
  bool _initialized = false;

  // In-line interactive reply state management
  final Map<String, bool> _expandedReplies = {};
  final Map<String, TextEditingController> _replyControllers = {};
  final Map<String, bool> _isGenerating = {};
  final Map<String, bool> _isPosting = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _reviewRepo = context.read<ReviewRepository>();
      _initialized = true;
      _loadReviews();
    }
  }

  @override
  void dispose() {
    for (final controller in _replyControllers.values) {
      controller.dispose();
    }
    super.dispose();
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
        unansweredOnly: _selectedFilter == 'pending',
      );
      if (mounted) {
        setState(() {
          if (_selectedFilter == 'replied') {
            _reviews = reviews.where((r) => r.isReplied).toList();
          } else {
            _reviews = reviews;
          }
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
          content: Text('Google Business Profile data synchronized successfully!'),
          backgroundColor: OptigoTheme.success,
        ),
      );
    }
  }

  Future<void> _handleGenerateAiReply(ReviewModel review) async {
    final authProvider = context.read<AppAuthProvider>();
    final bizId = authProvider.currentBusiness?.id;
    final bizName = authProvider.currentBusiness?.name ?? 'Panekkatt Oil & Flour Mill';
    if (bizId == null || _reviewRepo == null) return;

    setState(() {
      _expandedReplies[review.id] = true;
      _isGenerating[review.id] = true;
    });

    try {
      final aiText = await _reviewRepo!.generateAiReviewReply(
        reviewId: review.id,
        businessId: bizId,
        tone: 'warm & professional',
      );

      final controller = _replyControllers.putIfAbsent(
        review.id,
        () => TextEditingController(),
      );
      controller.text = aiText.isNotEmpty
          ? aiText
          : "Dear ${review.reviewerName},\n\nWe're delighted to hear that you had an excellent experience with us! We take pride in delivering top quality service.\n\nBest regards,\nTeam $bizName";
    } catch (_) {
      final controller = _replyControllers.putIfAbsent(
        review.id,
        () => TextEditingController(),
      );
      controller.text =
          "Dear ${review.reviewerName},\n\nThank you so much for your kind words! We appreciate your support.\n\nBest regards,\nTeam $bizName";
    } finally {
      if (mounted) {
        setState(() => _isGenerating[review.id] = false);
      }
    }
  }

  Future<void> _handlePostReply(ReviewModel review) async {
    final controller = _replyControllers[review.id];
    final replyText = controller?.text.trim();
    if (replyText == null || replyText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reply before posting.')),
      );
      return;
    }

    final authProvider = context.read<AppAuthProvider>();
    final bizId = authProvider.currentBusiness?.id;
    if (bizId == null || _reviewRepo == null) return;

    setState(() => _isPosting[review.id] = true);
    try {
      await _reviewRepo!.replyToReview(
        reviewId: review.id,
        businessId: bizId,
        replyText: replyText,
      );

      if (mounted) {
        setState(() {
          _expandedReplies[review.id] = false;
          _isPosting[review.id] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reply published to Google Profile successfully!'),
            backgroundColor: OptigoTheme.success,
          ),
        );
        _loadReviews();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting[review.id] = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post reply: $e'), backgroundColor: OptigoTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _reviews.where((r) => !r.isReplied).length;
    final repliedCount = _reviews.where((r) => r.isReplied).length;
    final totalCount = _reviews.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadReviews,
          color: const Color(0xFF2563EB),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Profile Pill + Notification Circle
                OptigoTopBar(
                  subtitle: 'Review Replies',
                ),

                const SizedBox(height: 12),

                // Large Editorial Headline (Reference Philosophy)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'What are customers\nsaying about you?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        height: 1.15,
                        letterSpacing: -0.8,
                      ),
                    ),
                    IconButton(
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF2563EB),
                              ),
                            )
                          : const Icon(
                              Icons.sync_rounded,
                              color: Color(0xFF2563EB),
                            ),
                      onPressed: _isSyncing ? null : _handleSyncGbp,
                      tooltip: 'Sync Google Reviews',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 2. Reviews Trend Card (Inspired by reference design)
                _buildReviewsTrendCard(),

                const SizedBox(height: 16),

                // 3. Segmented Filter Tabs (All, Pending with red badge, Replied)
                _buildSegmentedFilterBar(
                  total: totalCount,
                  pending: pendingCount,
                  replied: repliedCount,
                ),

                const SizedBox(height: 16),

                // 4. Reviews List with In-Line Interactive AI Reply Cards
                if (_reviews.isEmpty && !_isLoadingReviews)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Text(
                        'No reviews found for this filter.',
                        style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ),
                  )
                else
                  ..._reviews.map((r) => _buildReviewCard(r)),

                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 2. Reviews Trend Line Chart Card
  // ==========================================
  Widget _buildReviewsTrendCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reviews Trend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.filter_list_rounded, size: 13, color: Color(0xFF2563EB)),
                    SizedBox(width: 4),
                    Text(
                      'This Month',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Custom Reviews Line Chart Painter
          SizedBox(
            height: 110,
            width: double.infinity,
            child: CustomPaint(
              painter: _ReviewsTrendLinePainter(),
            ),
          ),
          const SizedBox(height: 8),

          // Pagination Dots Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Color(0xFFCBD5E1),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Color(0xFFCBD5E1),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. Segmented Filter Tabs
  // ==========================================
  Widget _buildSegmentedFilterBar({
    required int total,
    required int pending,
    required int replied,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildFilterTab(
            key: 'all',
            label: 'All ($total)',
            isSelected: _selectedFilter == 'all',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterTab(
            key: 'pending',
            label: 'Pending',
            badgeCount: pending,
            isSelected: _selectedFilter == 'pending',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterTab(
            key: 'replied',
            label: 'Replied ($replied)',
            isSelected: _selectedFilter == 'replied',
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTab({
    required String key,
    required String label,
    int? badgeCount,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        setState(() => _selectedFilter = key);
        _loadReviews();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
            if (badgeCount != null && badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEF4444) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? Colors.white : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 4. Review Card with In-Line AI Composer
  // ==========================================
  Widget _buildReviewCard(ReviewModel review) {
    final isExpanded = _expandedReplies[review.id] ?? false;
    final isGenerating = _isGenerating[review.id] ?? false;
    final isPosting = _isPosting[review.id] ?? false;
    final controller = _replyControllers[review.id] ?? TextEditingController(text: review.replyText ?? '');

    String formattedDate = review.reviewDate ?? '1y ago';
    if (formattedDate.contains('T')) {
      formattedDate = formattedDate.split('T')[0];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
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
          // Reviewer Info Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
                ),
                child: Center(
                  child: Text(
                    review.reviewerName.isNotEmpty ? review.reviewerName[0].toUpperCase() : 'U',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: i < review.rating ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Review Comment Text
          Text(
            review.text ?? 'No text provided',
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 14),

          // Action State: Already Replied VS Reply with AI Trigger VS In-Line AI Composer
          if (review.isReplied) ...[
            // Already Replied Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.reply_rounded, color: Colors.white, size: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Owner Response',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review.replyText ?? '',
                    style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF334155)),
                  ),
                ],
              ),
            ),
          ] else if (isExpanded) ...[
            // In-Line Expandable AI Draft Composer (Inspired by reference screenshot)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Avatar + Owner + AI Generated Reply + Collapse
                  Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'O',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Owner',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            'AI Generated Reply',
                            style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => _expandedReplies[review.id] = false),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // SEO Keywords Injected Table
                  _buildSeoKeywordsTable(),

                  const SizedBox(height: 12),

                  // Drafted AI Message Area
                  if (isGenerating)
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 10),
                            Text('Drafting SEO-optimized response with Gemini...', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    )
                  else
                    TextFormField(
                      controller: controller,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF1E293B)),
                      decoration: InputDecoration(
                        hintText: 'Drafted response will appear here...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Action Buttons Row (Regenerate & Reply Now 💬)
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: OutlinedButton(
                          onPressed: isGenerating || isPosting ? null : () => _handleGenerateAiReply(review),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text(
                            'Regenerate',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 6,
                        child: ElevatedButton.icon(
                          onPressed: isGenerating || isPosting ? null : () => _handlePostReply(review),
                          icon: isPosting
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send_rounded, size: 14),
                          label: Text(
                            isPosting ? 'Posting...' : 'Reply Now',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // Direct "Reply with AI" Action Button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _handleGenerateAiReply(review),
                icon: const Icon(Icons.auto_awesome, size: 14),
                label: const Text(
                  'Reply with AI',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // SEO Keywords Used In-Line Table
  // ==========================================
  Widget _buildSeoKeywordsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Keyword Used',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                ),
                Text(
                  'Search Volume',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          _buildKeywordTableRow('flour mill machine', '500 ↗'),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _buildKeywordTableRow('wheat mill', '500 ↗'),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _buildKeywordTableRow('mill flour machine', '500 ↗'),
        ],
      ),
    );
  }

  Widget _buildKeywordTableRow(String keyword, String volume) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.search_rounded, size: 13, color: Color(0xFF2563EB)),
              const SizedBox(width: 6),
              Text(
                keyword,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          Text(
            volume,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// Custom Painter for Reviews Trend Line Chart
// ==========================================
class _ReviewsTrendLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const weeks = ['W1', 'W2', 'W3', 'W4'];
    final points = [
      Offset(size.width * 0.12, size.height * 0.70),
      Offset(size.width * 0.38, size.height * 0.65),
      Offset(size.width * 0.64, size.height * 0.50),
      Offset(size.width * 0.90, size.height * 0.25),
    ];

    // 1. Draw horizontal dashed level lines
    final dashPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      final y = (size.height * 0.75) * (i / 3);
      canvas.drawLine(Offset(size.width * 0.05, y), Offset(size.width * 0.95, y), dashPaint);
    }

    // 2. Draw Trend Curve Path
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    // Shaded gradient fill
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height * 0.78)
      ..lineTo(points.first.dx, size.height * 0.78)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF2563EB).withValues(alpha: 0.15),
          const Color(0xFF2563EB).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Stroke line
    final linePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // 3. Draw Week Nodes & Labels
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];

      // Blue Node Circle
      final nodeOuter = Paint()
        ..color = const Color(0xFF2563EB).withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt, 6.0, nodeOuter);

      final nodeInner = Paint()
        ..color = const Color(0xFF2563EB)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt, 4.0, nodeInner);

      final nodeCenter = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt, 1.5, nodeCenter);

      // Week Label (W1, W2, W3, W4)
      final textSpan = TextSpan(
        text: weeks[i],
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(pt.dx - (textPainter.width / 2), size.height - 18));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
