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
  String _selectedFilter = 'all';
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
        sentiment: _selectedFilter == 'positive' || _selectedFilter == 'negative'
            ? _selectedFilter
            : null,
        unansweredOnly: _selectedFilter == 'unanswered',
      );
      if (mounted) {
        setState(() {
          _reviews = reviews;
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

  Future<void> _showReplyDialog(ReviewModel review) async {
    final controller = TextEditingController(text: review.replyText ?? '');
    final formKey = GlobalKey<FormState>();
    bool isGenerating = false;
    String selectedTone = 'warm & professional';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(OptigoTheme.radiusLG)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: OptigoTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.reply_rounded, color: OptigoTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reply to ${review.reviewerName}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: i < review.rating ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                        )),
                        const SizedBox(width: 6),
                        Text('${review.rating}/5 Rating', style: const TextStyle(fontSize: 11, color: OptigoTheme.textSecondary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: OptigoTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(OptigoTheme.radiusMD),
                      border: Border.all(color: OptigoTheme.divider),
                    ),
                    child: Text(
                      '"${review.text ?? "No review comment provided."}"',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                        color: OptigoTheme.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // AI Gemini Quick Action Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEFF6FF), Color(0xFFF0FDF4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Color(0xFF2563EB), size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'AI Gemini Auto-Draft',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E40AF)),
                          ),
                        ),
                        if (isGenerating)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                          )
                        else
                          InkWell(
                            onTap: () async {
                              final authProvider = context.read<AppAuthProvider>();
                              final bizId = authProvider.currentBusiness?.id;
                              if (bizId == null || _reviewRepo == null) return;

                              setDialogState(() => isGenerating = true);
                              try {
                                final aiText = await _reviewRepo!.generateAiReviewReply(
                                  reviewId: review.id,
                                  businessId: bizId,
                                  tone: selectedTone,
                                );
                                controller.text = aiText;
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('AI Generation Error: $e'), backgroundColor: OptigoTheme.error),
                                  );
                                }
                              } finally {
                                setDialogState(() => isGenerating = false);
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.flash_on, size: 12, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Generate',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Your Response',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: OptigoTheme.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: controller,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                    decoration: InputDecoration(
                      hintText: 'Type or generate your response with Gemini...',
                      hintStyle: const TextStyle(color: OptigoTheme.textTertiary, fontSize: 12),
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(OptigoTheme.radiusMD),
                        borderSide: const BorderSide(color: OptigoTheme.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(OptigoTheme.radiusMD),
                        borderSide: const BorderSide(color: OptigoTheme.divider),
                      ),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a reply' : null,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(OptigoTheme.radiusMD)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700, color: OptigoTheme.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final authProvider = context.read<AppAuthProvider>();
                      final bizId = authProvider.currentBusiness?.id;
                      if (bizId == null) return;

                      final nav = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(context);

                      try {
                        if (_reviewRepo != null) {
                          await _reviewRepo!.replyToReview(
                            reviewId: review.id,
                            businessId: bizId,
                            replyText: controller.text.trim(),
                          );
                        }
                        nav.pop();
                        _loadReviews();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Reply posted successfully!'),
                            backgroundColor: OptigoTheme.success,
                          ),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Failed: $e'), backgroundColor: OptigoTheme.error),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: OptigoTheme.primary,
                      elevation: 0,
                    ),
                    child: const Text('Post Reply', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avgRating = _reviews.isNotEmpty
        ? (_reviews.map((r) => r.rating).reduce((a, b) => a + b) / _reviews.length).toStringAsFixed(1)
        : '4.4';

    return Scaffold(
      backgroundColor: OptigoTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadReviews,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(OptigoTheme.spacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Universal Top App Bar
                Row(
                  children: [
                    const Expanded(
                      child: OptigoTopBar(
                        subtitle: 'Reviews & Reputation',
                      ),
                    ),
                    IconButton(
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: OptigoTheme.primary),
                            )
                          : const Icon(Icons.sync_rounded, color: OptigoTheme.primary),
                      onPressed: _isSyncing ? null : _handleSyncGbp,
                      tooltip: 'Sync Google Reviews',
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // GBP Connected Status Card with 4 Metrics
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(OptigoTheme.spacingMD),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(OptigoTheme.radiusMD),
                    border: Border.all(color: OptigoTheme.divider),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: OptigoTheme.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(OptigoTheme.radiusSM),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle, size: 14, color: OptigoTheme.success),
                                SizedBox(width: 4),
                                Text(
                                  'Google Profile Connected',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: OptigoTheme.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _isSyncing ? null : _handleSyncGbp,
                            icon: const Icon(Icons.sync, size: 16),
                            label: Text(_isSyncing ? 'Syncing...' : 'Sync Data'),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: OptigoTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: OptigoTheme.spacingMD),
                      Row(
                        children: [
                          _buildMetricBox('Average Rating', '⭐ $avgRating', 'Based on ${_reviews.length} reviews'),
                          const SizedBox(width: OptigoTheme.spacingSM),
                          _buildMetricBox('Total Reviews', '${_reviews.length}', 'Synced from Google'),
                        ],
                      ),
                      const SizedBox(height: OptigoTheme.spacingSM),
                      Row(
                        children: [
                          _buildMetricBox('Profile Views', '1,420', '+18% this month'),
                          const SizedBox(width: OptigoTheme.spacingSM),
                          _buildMetricBox('Customer Calls', '84', 'Direct leads'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: OptigoTheme.spacingLG),

                // Customer Reviews Section Header
                Row(
                  children: [
                    Text(
                      'Customer Reviews (${_reviews.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const Spacer(),
                    if (_isLoadingReviews)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: OptigoTheme.spacingSM),

                // Sentiment Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All Reviews'),
                      const SizedBox(width: OptigoTheme.spacingSM),
                      _buildFilterChip('positive', 'Positive (4-5 ⭐)'),
                      const SizedBox(width: OptigoTheme.spacingSM),
                      _buildFilterChip('negative', 'Negative (1-2 ⭐)'),
                      const SizedBox(width: OptigoTheme.spacingSM),
                      _buildFilterChip('unanswered', 'Needs Reply'),
                    ],
                  ),
                ),

                const SizedBox(height: OptigoTheme.spacingMD),

                // Reviews List
                if (_reviews.isEmpty && !_isLoadingReviews)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(OptigoTheme.spacingXL),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(OptigoTheme.radiusMD),
                      border: Border.all(color: OptigoTheme.divider),
                    ),
                    child: const Center(
                      child: Text(
                        'No reviews found for this filter.',
                        style: TextStyle(color: OptigoTheme.textSecondary),
                      ),
                    ),
                  )
                else
                  ..._reviews.map((r) => _buildReviewCard(r)),

                const SizedBox(height: OptigoTheme.spacingXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricBox(String title, String value, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(OptigoTheme.spacingSM + 2),
        decoration: BoxDecoration(
          color: OptigoTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(OptigoTheme.radiusSM),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: OptigoTheme.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: OptigoTheme.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: OptigoTheme.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedFilter = key);
        _loadReviews();
      },
      selectedColor: OptigoTheme.primary,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: isSelected ? Colors.white : OptigoTheme.textSecondary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OptigoTheme.radiusSM),
        side: BorderSide(
          color: isSelected ? OptigoTheme.primary : OptigoTheme.divider,
        ),
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    Color sentimentColor = OptigoTheme.success;
    String sentimentLabel = 'Positive';
    if (review.rating <= 2 || review.sentiment == 'negative') {
      sentimentColor = OptigoTheme.error;
      sentimentLabel = 'Negative';
    } else if (review.rating == 3 || review.sentiment == 'neutral') {
      sentimentColor = OptigoTheme.warning;
      sentimentLabel = 'Neutral';
    }

    String formattedDate = review.reviewDate ?? '';
    if (formattedDate.contains('T')) {
      formattedDate = formattedDate.split('T')[0];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: OptigoTheme.spacingMD),
      padding: const EdgeInsets.all(OptigoTheme.spacingLG),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(OptigoTheme.radiusLG),
        border: Border.all(
          color: review.rating <= 2 && !review.isReplied
              ? OptigoTheme.error.withValues(alpha: 0.3)
              : OptigoTheme.divider.withValues(alpha: 0.5),
          width: review.rating <= 2 && !review.isReplied ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: OptigoTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              index < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 16,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formattedDate,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: OptigoTheme.textTertiary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: sentimentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(OptigoTheme.radiusMD),
                ),
                child: Text(
                  sentimentLabel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: sentimentColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: OptigoTheme.spacingMD),
          Text(
            review.text ?? 'No text provided',
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: OptigoTheme.textPrimary,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (review.isReplied && review.replyText != null) ...[
            const SizedBox(height: OptigoTheme.spacingMD),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(OptigoTheme.spacingMD),
              decoration: BoxDecoration(
                color: OptigoTheme.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(OptigoTheme.radiusMD),
                border: Border.all(color: OptigoTheme.primary.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.reply_all_rounded, size: 16, color: OptigoTheme.primary.withValues(alpha: 0.7)),
                      const SizedBox(width: 8),
                      const Text(
                        'YOUR BUSINESS REPLY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: OptigoTheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review.replyText!,
                    style: const TextStyle(fontSize: 13, color: OptigoTheme.textPrimary, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: OptigoTheme.spacingLG),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showReplyDialog(review),
              icon: Icon(review.isReplied ? Icons.edit_note_rounded : Icons.reply_rounded, size: 18),
              label: Text(
                review.isReplied ? 'Update Response' : 'Draft AI Reply',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: OptigoTheme.primary,
                side: BorderSide(color: OptigoTheme.primary.withValues(alpha: 0.5), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(OptigoTheme.radiusMD)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
