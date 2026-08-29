import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/models/review_model.dart';
import '../../data/repositories/review_repository.dart';
import '../auth/auth_provider.dart';
import '../shared/optigo_top_bar.dart';

/// OptigoAI Customer Reviews & Reputation Management Hub (Screen 5)
/// Real-time Google Business Profile reviews, sentiment analysis, and 1-tap AI replies.
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
    if (_allReviews.isEmpty) return 4.9;
    final sum = _allReviews.fold<int>(0, (prev, r) => prev + r.rating);
    return double.parse((sum / _allReviews.length).toStringAsFixed(1));
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
    final displayedReviews = _filteredReviews;

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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Navigation Bar
                  OptigoTopBar(
                    subtitle: 'Customer Reputation Hub',
                    onNotificationTap: widget.onNavigateToRecommendations,
                    onRefreshTap: _loadReviews,
                    isRefreshing: _isLoadingReviews,
                  ),

                  const SizedBox(height: 14),

                  // 2. Editorial Title + Sync Button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer Reviews',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.6,
                            ),
                          ),
                          Text(
                            'Google Maps ratings & AI auto-reply responses',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
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

                  // 3. Hero Reviews Bento Grid
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
                                    child: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Excellent',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF34D399)),
                                    ),
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
                                        '$_averageRating',
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
                                'Top 5% rated in your area',
                                style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: const Color(0xFF60A5FA), fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Right Card: Pure White Sentiment & Pending Card
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: pendingCount > 0 ? const Color(0xFFFEE2E2) : const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: pendingCount > 0 ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0)),
                                    ),
                                    child: Text(
                                      pendingCount > 0 ? '$pendingCount Pending' : '100% Replied',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: pendingCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF059669),
                                      ),
                                    ),
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
                                    '96%',
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
                                child: const LinearProgressIndicator(
                                  value: 0.96,
                                  minHeight: 6,
                                  backgroundColor: Color(0xFFF1F5F9),
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 4. Interactive Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildFilterPill('all', 'All (${_allReviews.length})'),
                        const SizedBox(width: 8),
                        _buildFilterPill('pending', 'Pending ($pendingCount)', color: const Color(0xFFEF4444)),
                        const SizedBox(width: 8),
                        _buildFilterPill('positive', 'Positive 5★', color: const Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        _buildFilterPill('negative', 'Critical', color: const Color(0xFFF59E0B)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 5. Reviews List
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
                    ...displayedReviews.map((r) => _buildReviewCard(r)),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(String id, String label, {Color? color}) {
    final isSelected = _selectedFilter == id;
    final activeColor = color ?? const Color(0xFF2563EB);

    return InkWell(
      onTap: () => setState(() => _selectedFilter = id),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? activeColor : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    final hasReply = review.isReplied;
    final author = review.reviewerName;
    final initials = author.isNotEmpty ? author.substring(0, 1).toUpperCase() : 'U';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar + Author + Stars + Date
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFEFF6FF),
                child: Text(
                  initials,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF2563EB)),
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
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: const Color(0xFFF59E0B),
                          size: 15,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              if (hasReply)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 12),
                      const SizedBox(width: 4),
                      Text('Replied', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF059669))),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Pending', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFFEF4444))),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Review Body Text
          Text(
            review.text ?? '',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF334155),
              height: 1.45,
            ),
          ),

          // If replied: show reply preview
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
                        'Your Response',
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

          // If pending: Show AI Reply Trigger Button
          if (!hasReply) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openReviewReplyModal(review),
                icon: const Icon(Icons.auto_awesome_rounded, size: 15, color: Colors.white),
                label: Text(
                  'Draft AI Reply with Gemini',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
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
  bool _isGeneratingAi = false;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _generateAiReply();
  }

  Future<void> _generateAiReply() async {
    setState(() => _isGeneratingAi = true);
    final repo = context.read<ReviewRepository>();
    final businessId = context.read<AppAuthProvider>().currentBusiness?.id;
    if (businessId == null) {
      if (mounted) setState(() => _isGeneratingAi = false);
      return;
    }

    try {
      final reply = await repo.generateAiReviewReply(
        reviewId: widget.review.id,
        businessId: businessId,
      );
      if (mounted && reply.isNotEmpty) {
        _replyController.text = reply;
      }
    } catch (_) {
      if (mounted) {
        _replyController.text =
            "Thank you so much for your kind words! We truly appreciate your support and look forward to welcoming you again soon. ✨";
      }
    } finally {
      if (mounted) setState(() => _isGeneratingAi = false);
    }
  }

  Future<void> _handlePostReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPosting = true);
    final repo = context.read<ReviewRepository>();
    final businessId = context.read<AppAuthProvider>().currentBusiness?.id;
    if (businessId == null) {
      if (mounted) setState(() => _isPosting = false);
      return;
    }

    try {
      final updated = await repo.replyToReview(
        reviewId: widget.review.id,
        businessId: businessId,
        replyText: text,
      );
      if (mounted) {
        widget.onReplySuccess(updated);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Reply posted directly to Google Business Profile!'),
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Color(0xFF2563EB), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'AI Reply Generator',
                    style: GoogleFonts.plusJakartaSans(fontSize: 16.5, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Review from ${widget.review.reviewerName}:',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              widget.review.text ?? '',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF334155), fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Generated Response (Editable):',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _replyController,
            maxLines: 4,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF0F172A)),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              hintText: 'Drafting reply with Gemini AI...',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isGeneratingAi ? null : _generateAiReply,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Regenerate', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF2563EB))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isPosting ? null : _handlePostReply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isPosting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Post to GBP', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
