import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/models/review_model.dart';
import '../../data/repositories/review_repository.dart';
import '../auth/auth_provider.dart';
import '../shared/optigo_top_bar.dart';

/// OptigoAI Customer Reviews & Reputation Management Hub
/// Two Separate Tabs: 1. Dashboard & Sentiment Analysis (Keyword Intelligence) & 2. Review Management Feed
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
  Map<String, dynamic> _managementAnalytics = {};
  bool _isLoading = true;
  int _activeTabIndex = 0; // 0: Dashboard & Sentiment Analysis, 1: Review Management
  String _selectedFilter = 'all'; // 'all', 'pending', 'positive', 'critical'
  String _selectedTimeframe = 'All time'; // '1M', '6M', '1Y', 'All time'
  String _keywordSearch = '';
  bool _isSyncing = false;
  bool _initialized = false;

  final Set<String> _expandedReviewIds = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _reviewRepo = context.read<ReviewRepository>();
      _initialized = true;
      _loadReviewsAndAnalytics();
    }
  }

  Future<void> _loadReviewsAndAnalytics() async {
    if (_reviewRepo == null) return;
    final authProvider = context.read<AppAuthProvider>();
    final businessId = authProvider.currentBusiness?.id;
    if (businessId == null) return;

    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _reviewRepo!.getReviews(businessId: businessId, unansweredOnly: false),
        _reviewRepo!.getReviewManagementAnalytics(businessId: businessId),
      ]);

      if (mounted) {
        setState(() {
          _allReviews = results[0] as List<ReviewModel>;
          _managementAnalytics = results[1] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSyncGbp() async {
    setState(() => _isSyncing = true);
    final authProvider = context.read<AppAuthProvider>();
    await authProvider.syncGbp();
    await _loadReviewsAndAnalytics();
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
      case 'critical':
        return _allReviews.where((r) => r.rating <= 2 || (r.sentiment?.toLowerCase() == 'negative')).toList();
      case 'pending':
        return _allReviews.where((r) => !r.isReplied).toList();
      case 'all':
      default:
        return _allReviews;
    }
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
          _loadReviewsAndAnalytics();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = _allReviews.length;
    final pendingCount = _allReviews.where((r) => !r.isReplied).length;
    final repliedCount = totalCount - pendingCount;
    final repliedPct = totalCount > 0 ? ((repliedCount / totalCount) * 100).toStringAsFixed(1) : '0.0';
    final notRepliedPct = totalCount > 0 ? ((pendingCount / totalCount) * 100).toStringAsFixed(1) : '0.0';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadReviewsAndAnalytics,
          color: const Color(0xFF4F46E5),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Navigation Bar
                OptigoTopBar(
                  subtitle: 'Reviews & Reputation Center',
                  onNotificationTap: widget.onNavigateToRecommendations,
                  onRefreshTap: _handleSyncGbp,
                  isRefreshing: _isSyncing,
                ),

                const SizedBox(height: 14),

                // Main Navigation Tabs
                Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
                  ),
                  child: Row(
                    children: [
                      // Tab 0: Overview
                      InkWell(
                        onTap: () => setState(() => _activeTabIndex = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _activeTabIndex == 0 ? const Color(0xFF4F46E5) : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Text(
                            'Overview',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: _activeTabIndex == 0 ? FontWeight.w800 : FontWeight.w600,
                              color: _activeTabIndex == 0 ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Tab 1: Manage Reviews
                      InkWell(
                        onTap: () => setState(() => _activeTabIndex = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _activeTabIndex == 1 ? const Color(0xFF4F46E5) : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Manage Reviews',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: _activeTabIndex == 1 ? FontWeight.w800 : FontWeight.w600,
                                  color: _activeTabIndex == 1 ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4F46E5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  totalCount > 1000 ? '${(totalCount / 1000).toStringAsFixed(1)}K' : '$totalCount',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                    ),
                  )
                else if (_allReviews.isEmpty)
                  _buildEmptyReviewsState()
                else if (_activeTabIndex == 0)
                  _buildDashboardSentimentTab(repliedPct, notRepliedPct, repliedCount, pendingCount)
                else
                  _buildReviewManagementTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========================================================
  // EMPTY REVIEWS STATE
  // ========================================================
  Widget _buildEmptyReviewsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.rate_review_outlined,
              size: 36,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Reviews Recorded Yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect and sync your Google Business Profile to monitor live reviews, generate AI responses, and track customer sentiment trends.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isSyncing ? null : _handleSyncGbp,
            icon: _isSyncing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.sync_rounded, size: 18),
            label: Text(
              _isSyncing ? 'Syncing...' : 'Sync Google Reviews',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // TAB 1: OVERVIEW & SENTIMENT ANALYSIS
  // ========================================================
  Widget _buildDashboardSentimentTab(String repliedPct, String notRepliedPct, int repliedCount, int pendingCount) {
    final posKw = (_managementAnalytics['positive_keywords'] as List?) ?? [];
    final negKw = (_managementAnalytics['negative_keywords'] as List?) ?? [];
    final trendingKw = (_managementAnalytics['trending_keywords_7d'] as List?) ?? [];

    final monthlyData = (_managementAnalytics['monthly_rating_analysis'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Replied vs Not Replied Donut Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Replied vs Not Replied',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Donut Ring
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 9,
                          color: Color(0xFFEF4444),
                        ),
                        CircularProgressIndicator(
                          value: (double.tryParse(repliedPct) ?? 0.0) / 100.0,
                          strokeWidth: 9,
                          color: const Color(0xFF22C55E),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Stats
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.circle, color: Color(0xFF22C55E), size: 10),
                                const SizedBox(width: 6),
                                Text(
                                  'Replied',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            Text(
                              '$repliedPct%',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF2563EB)),
                            ),
                            Text(
                              '$repliedCount Reviews',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.circle, color: Color(0xFFEF4444), size: 10),
                                const SizedBox(width: 6),
                                Text(
                                  'Not Replied',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            Text(
                              '$notRepliedPct%',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF2563EB)),
                            ),
                            Text(
                              '$pendingCount Reviews',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (pendingCount > 0) ...[
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _activeTabIndex = 1;
                        _selectedFilter = 'pending';
                      });
                    },
                    icon: const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF4F46E5)),
                    label: Text(
                      'Reply to $pendingCount Pending Review${pendingCount > 1 ? 's' : ''}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4F46E5),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFC7D2FE)),
                      backgroundColor: const Color(0xFFEEF2FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 2. Monthly Reviews & Rating Analysis Dual Chart
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Reviews & Rating Analysis',
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              // Timeframe Buttons
              Row(
                children: ['1M', '6M', '1Y', 'All time'].map((tf) {
                  final isSelected = _selectedTimeframe == tf;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () => setState(() => _selectedTimeframe = tf),
                      child: Text(
                        tf,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? const Color(0xFF6D28D9) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              if (monthlyData.isEmpty)
                Container(
                  height: 100,
                  alignment: Alignment.center,
                  child: Text(
                    'Monthly review trends will appear as customer ratings accumulate.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                SizedBox(
                  height: 160,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: monthlyData.map((d) {
                      final rating = d['rating'] ?? 5.0;
                      final count = d['reviews_count'] ?? 1;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF6D28D9),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$rating',
                              style: GoogleFonts.plusJakartaSans(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('$count', style: GoogleFonts.plusJakartaSans(fontSize: 9, color: const Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Container(
                            width: 24,
                            height: ((count as num) / 50).clamp(0.1, 1.0) * 80 + 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF16A34A),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            d['month'] ?? 'Mo',
                            style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 3. Customer Themes & Mention Share
        Text(
          'Customer Themes & Mention Share',
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 12),

        // Search Keyword Field
        TextField(
          onChanged: (val) => setState(() => _keywordSearch = val),
          decoration: InputDecoration(
            hintText: 'Search Mentions & Themes',
            prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
        const SizedBox(height: 12),

        // Trending Sentiment For Last 7 days
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDDD6FE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trending Themes (Last 7 Days)',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 10),
              if (trendingKw.isEmpty)
                Text(
                  'No specific spike in themes over the past 7 days.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: trendingKw.map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6D28D9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${item['keyword']} • ${item['count']}',
                        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // What Customers Love About You (Positive Real Keywords)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What Customers Love About You',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 10),
              if (posKw.isEmpty)
                Text(
                  'Positive customer themes will appear here once identified.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF15803D)),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: posKw
                      .where((item) => _keywordSearch.isEmpty || item['keyword'].toString().toLowerCase().contains(_keywordSearch.toLowerCase()))
                      .map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15803D),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${item['keyword']} • ${item['count']}',
                        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // What Can Be Improved (Negative Keywords)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What Can Be Improved',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 10),
              if (negKw.isEmpty)
                Text(
                  'No recurring negative themes detected.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF991B1B)),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: negKw
                      .where((item) => _keywordSearch.isEmpty || item['keyword'].toString().toLowerCase().contains(_keywordSearch.toLowerCase()))
                      .map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${item['keyword']} • ${item['count']}',
                        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ========================================================
  // TAB 2: REVIEW MANAGEMENT (FEED)
  // ========================================================
  Widget _buildReviewManagementTab() {
    final reviews = _filteredReviews;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterPill('All (${_allReviews.length})', 'all'),
              _buildFilterPill('Pending Reply', 'pending'),
              _buildFilterPill('Positive (4-5★)', 'positive'),
              _buildFilterPill('Critical (1-2★)', 'critical'),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (reviews.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            alignment: Alignment.center,
            child: Text(
              'No reviews match the selected filter.',
              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 13),
            ),
          )
        else
          ...reviews.map((r) => _buildReviewCard(r)),
      ],
    );
  }

  Widget _buildFilterPill(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel rev) {
    final isExpanded = _expandedReviewIds.contains(rev.id);
    final isPos = rev.rating >= 4 || rev.sentiment?.toLowerCase() == 'positive';
    final isNeu = rev.rating == 3 || rev.sentiment?.toLowerCase() == 'neutral';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar + Name + Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFEFF6FF),
                    child: Text(
                      rev.reviewerName.isNotEmpty ? rev.reviewerName[0].toUpperCase() : 'C',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: const Color(0xFF2563EB)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            rev.reviewerName,
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13.5, color: const Color(0xFF0F172A)),
                          ),
                          const SizedBox(width: 6),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: i < rev.rating ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Builder(
                        builder: (context) {
                          String dateStr = rev.reviewDate ?? 'Recent';
                          if (dateStr.contains('T')) {
                            try {
                              final dt = DateTime.parse(dateStr);
                              const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                              dateStr = '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
                            } catch (_) {
                              dateStr = dateStr.split('T')[0];
                            }
                          }
                          return Text(
                            dateStr,
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF94A3B8)),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '${rev.rating}/5',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: const Color(0xFF0F172A)),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Review Text Content
          Text(
            (rev.text != null && rev.text!.isNotEmpty)
                ? rev.text!
                : 'Rating left without written review text.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF334155), height: 1.5),
          ),

          const SizedBox(height: 10),

          // More Details Accordion
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedReviewIds.remove(rev.id);
                } else {
                  _expandedReviewIds.add(rev.id);
                }
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'More Details',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
                Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16, color: const Color(0xFF64748B)),
              ],
            ),
          ),

          if (isExpanded) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Source: Google Business Profile', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B))),
                  if (rev.replyText != null && rev.replyText!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Your Reply: "${rev.replyText}"', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Action Buttons Bar matching user screenshot
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _openReviewReplyModal(rev),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6D28D9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      rev.isReplied ? 'Edit Reply' : 'Add Reply',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 4),
                    const Text('↵', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isPos ? const Color(0xFFF0FDF4) : (isNeu ? const Color(0xFFFFFBEB) : const Color(0xFFFEF2F2)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isPos ? const Color(0xFFBBF7D0) : (isNeu ? const Color(0xFFFDE68A) : const Color(0xFFFECACA))),
                ),
                child: Text(
                  'Sentiment : ${isPos ? 'Positive' : (isNeu ? 'Neutral' : 'Negative')}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isPos ? const Color(0xFF16A34A) : (isNeu ? const Color(0xFFD97706) : const Color(0xFFDC2626)),
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  rev.isReplied ? 'Replied' : 'Review Reply Not Set',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: rev.isReplied ? const Color(0xFF15803D) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// BottomSheet for AI review replies
class _ReviewReplyBottomSheet extends StatefulWidget {
  final ReviewModel review;
  final ValueChanged<ReviewModel> onReplySuccess;

  const _ReviewReplyBottomSheet({
    required this.review,
    required this.onReplySuccess,
  });

  @override
  State<_ReviewReplyBottomSheet> createState() => _ReviewReplyBottomSheetState();
}

class _ReviewReplyBottomSheetState extends State<_ReviewReplyBottomSheet> {
  final TextEditingController _replyController = TextEditingController();
  bool _isGenerating = false;
  bool _isPublishing = false;
  String _selectedTone = 'Professional';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.review.replyText != null && widget.review.replyText!.isNotEmpty) {
      _replyController.text = widget.review.replyText!;
    } else {
      _generateAiDraft();
    }
  }

  Future<void> _generateAiDraft() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final repo = context.read<ReviewRepository>();
      final authProvider = context.read<AppAuthProvider>();
      final businessId = authProvider.currentBusiness?.id ?? '';

      final reply = await repo.generateAiReviewReply(
        reviewId: widget.review.id,
        businessId: businessId,
        tone: _selectedTone,
      );

      if (mounted) {
        setState(() {
          _replyController.text = reply.isNotEmpty ? reply : 'Thank you for your valuable feedback!';
          _isGenerating = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _replyController.text = 'Thank you for visiting us! We appreciate your support and look forward to seeing you again.';
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _handlePublishReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPublishing = true);
    try {
      final repo = context.read<ReviewRepository>();
      final authProvider = context.read<AppAuthProvider>();
      final businessId = authProvider.currentBusiness?.id ?? '';

      final updated = await repo.replyToReview(
        reviewId: widget.review.id,
        businessId: businessId,
        replyText: text,
      );

      if (mounted) {
        widget.onReplySuccess(updated);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPublishing = false;
          _errorMessage = 'Failed to post reply. Please check your connection.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.bolt_rounded, color: Color(0xFF6D28D9), size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Review Reply', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
                  Text('${widget.review.reviewerName} (${widget.review.rating}★)', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(_errorMessage!, style: GoogleFonts.plusJakartaSans(color: const Color(0xFFDC2626), fontSize: 12)),
          ],
          const SizedBox(height: 12),
          // Tone selector
          Row(
            children: ['Professional', 'Warm', 'Empathetic', 'Promotional'].map((tone) {
              final isSel = _selectedTone == tone;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedTone = tone);
                    _generateAiDraft();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFFF5F3FF) : const Color(0xFFF1F5F9),
                      border: Border.all(color: isSel ? const Color(0xFF6D28D9) : Colors.transparent),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tone,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSel ? const Color(0xFF6D28D9) : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          if (_isGenerating)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6D28D9))),
            )
          else ...[
            TextField(
              controller: _replyController,
              maxLines: 4,
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _generateAiDraft,
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text('Regenerate'),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF475569)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isPublishing ? null : _handlePublishReply,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6D28D9), foregroundColor: Colors.white),
                    child: Text(_isPublishing ? 'Publishing...' : 'Approve & Post'),
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
