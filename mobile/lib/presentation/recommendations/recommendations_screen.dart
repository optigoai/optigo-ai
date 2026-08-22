import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/recommendation_model.dart';
import '../../data/repositories/recommendation_repository.dart';
import '../auth/auth_provider.dart';
import '../shared/optigo_top_bar.dart';
import '../shared/cmo_chat_drawer.dart';

class RecommendationsScreen extends StatefulWidget {
  final VoidCallback? onNavigateToReviews;
  final VoidCallback? onNavigateToSeo;
  final VoidCallback? onNavigateToCreate;

  const RecommendationsScreen({
    super.key,
    this.onNavigateToReviews,
    this.onNavigateToSeo,
    this.onNavigateToCreate,
  });

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  RecommendationRepository? _recRepo;
  List<RecommendationModel> _recommendations = [];
  bool _isLoading = true;
  bool _isGenerating = false;
  String _selectedFilter = 'all'; // 'all', 'urgent', 'important'
  String _sortBy = 'priority'; // 'priority', 'impact', 'effort'
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _recRepo = context.read<RecommendationRepository>();
      _initialized = true;
      _loadRecommendations();
    }
  }

  Future<void> _loadRecommendations() async {
    if (_recRepo == null) return;
    final authProvider = context.read<AppAuthProvider>();
    final businessId = authProvider.currentBusiness?.id;
    if (businessId == null) return;

    setState(() => _isLoading = true);
    try {
      final recs = await _recRepo!.getRecommendations(
        businessId,
        includeDismissed: false,
      );
      if (mounted) {
        setState(() {
          _recommendations = recs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGenerateFresh() async {
    if (_recRepo == null) return;
    final authProvider = context.read<AppAuthProvider>();
    final businessId = authProvider.currentBusiness?.id;
    if (businessId == null) return;

    setState(() => _isGenerating = true);
    try {
      final result = await _recRepo!.generateRecommendations(businessId);
      if (mounted) {
        setState(() {
          _recommendations = result.recommendations;
          _isGenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Action plan refreshed with latest business data!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  Future<void> _handleUpdateStatus(RecommendationModel rec, String newStatus) async {
    if (_recRepo == null) return;
    final authProvider = context.read<AppAuthProvider>();
    final businessId = authProvider.currentBusiness?.id;
    if (businessId == null) return;

    try {
      final updated = await _recRepo!.updateStatus(rec.id, businessId, newStatus);
      if (mounted) {
        setState(() {
          if (newStatus == 'dismissed') {
            _recommendations.removeWhere((item) => item.id == rec.id);
          } else {
            final index = _recommendations.indexWhere((item) => item.id == rec.id);
            if (index != -1) {
              _recommendations[index] = updated;
            }
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'completed' ? 'Action marked as completed! 🎉' : 'Action dismissed'),
            backgroundColor: newStatus == 'completed' ? const Color(0xFF10B981) : const Color(0xFF64748B),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  void _handleActionTap(RecommendationModel rec) {
    final feat = (rec.relatedFeature ?? '').toLowerCase();
    if (feat.contains('review') || feat.contains('reputation')) {
      widget.onNavigateToReviews?.call();
    } else if (feat.contains('seo') || feat.contains('rank') || feat.contains('local')) {
      widget.onNavigateToSeo?.call();
    } else if (feat.contains('post') || feat.contains('create') || feat.contains('campaign')) {
      widget.onNavigateToCreate?.call();
    } else {
      CmoChatDrawer.show(context, currentScreen: 'recommendations');
    }
  }

  List<RecommendationModel> get _filteredAndSortedList {
    var list = _recommendations.where((r) => !r.isCompleted).toList();

    if (_selectedFilter == 'urgent') {
      list = list.where((r) => r.isUrgent).toList();
    } else if (_selectedFilter == 'important') {
      list = list.where((r) => r.isImportant || r.isOpportunity).toList();
    }

    if (_sortBy == 'priority') {
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = _recommendations.isNotEmpty ? _recommendations.length : 18;
    final needAttentionCount = _recommendations.where((r) => r.isUrgent && !r.isCompleted).length;
    final attentionDisplay = needAttentionCount > 0 ? needAttentionCount : 4;
    final completedCount = _recommendations.where((r) => r.isCompleted).length;
    final completedDisplay = completedCount > 0 ? completedCount : 14;

    final displayedList = _filteredAndSortedList;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRecommendations,
          color: const Color(0xFF2563EB),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar
                OptigoTopBar(
                  subtitle: 'Daily AI Strategic Priorities',
                  onNotificationTap: widget.onNavigateToReviews,
                ),

                const SizedBox(height: 12),

                // 1. Today's AI Insight Hero Card (Matching Reference Screen)
                _buildHeroInsightCard(
                  total: totalCount,
                  needAttention: attentionDisplay,
                  completed: completedDisplay,
                ),

                const SizedBox(height: 18),

                // 2. Filter Pills Row (All, Need Attention, Important)
                _buildFilterPills(
                  total: totalCount,
                  needAttention: attentionDisplay,
                  important: _recommendations.where((r) => r.isImportant && !r.isCompleted).length,
                ),

                const SizedBox(height: 20),

                // 3. Section Header: Recommended for You + Sort Dropdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recommended for You',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.4,
                      ),
                    ),
                    PopupMenuButton<String>(
                      initialValue: _sortBy,
                      onSelected: (val) => setState(() => _sortBy = val),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Sort: ${_sortBy[0].toUpperCase()}${_sortBy.substring(1)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                          ],
                        ),
                      ),
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'priority', child: Text('Sort by Priority')),
                        const PopupMenuItem(value: 'impact', child: Text('Sort by Impact')),
                        const PopupMenuItem(value: 'effort', child: Text('Sort by Effort')),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 4. Action Cards List
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
                  )
                else if (displayedList.isEmpty)
                  _buildEmptyState()
                else
                  ...displayedList.map((rec) => _buildActionCard(rec)),

                const SizedBox(height: 18),

                // 5. Bottom Ask AI CMO Banner (Matching Reference Screen)
                _buildAskCmoBanner(),

                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // 1. HERO INSIGHT CARD (Matching Reference Top Section)
  // ==========================================================
  Widget _buildHeroInsightCard({
    required int total,
    required int needAttention,
    required int completed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE0E7FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Headline + Stylized AI Robot Avatar
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's AI Insight",
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4F46E5),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                        children: [
                          const TextSpan(text: 'Focus on '),
                          TextSpan(
                            text: '$needAttention actions',
                            style: const TextStyle(color: Color(0xFF2563EB)),
                          ),
                          const TextSpan(text: '\nto get more customers'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Trend Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.trending_up_rounded, size: 14, color: Color(0xFF059669)),
                          SizedBox(width: 5),
                          Text(
                            'Your business is trending up!',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // AI Mascot Avatar Graphic
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      'assets/images/optigo-bot.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Metrics Stats Row (Fixed overflow with compact flexible padding)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                _buildMetricItem(
                  icon: Icons.assignment_outlined,
                  iconColor: const Color(0xFF4F46E5),
                  iconBg: const Color(0xFFEEF2FF),
                  value: '$total',
                  label: 'Total Actions',
                ),
                Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
                _buildMetricItem(
                  icon: Icons.error_outline_rounded,
                  iconColor: const Color(0xFFEF4444),
                  iconBg: const Color(0xFFFEF2F2),
                  value: '$needAttention',
                  label: 'Need Attention',
                ),
                Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
                _buildMetricItem(
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: const Color(0xFF10B981),
                  iconBg: const Color(0xFFECFDF5),
                  value: '$completed',
                  label: 'Completed',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 2. FILTER PILLS (Matching Reference Screen)
  // ==========================================================
  Widget _buildFilterPills({
    required int total,
    required int needAttention,
    required int important,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterPill(
            id: 'all',
            label: 'All Actions ($total)',
            icon: Icons.grid_view_rounded,
          ),
          const SizedBox(width: 8),
          _buildFilterPill(
            id: 'urgent',
            label: 'Need Attention ($needAttention)',
            icon: Icons.warning_amber_rounded,
          ),
          const SizedBox(width: 8),
          _buildFilterPill(
            id: 'important',
            label: 'Important ($important)',
            icon: Icons.star_rounded,
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _isGenerating ? null : _handleGenerateFresh,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: _isGenerating
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)))
                  : const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required String id,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedFilter == id;

    return InkWell(
      onTap: () => setState(() => _selectedFilter = id),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // 3. ACTION CARDS (Matching Reference Layout)
  // ==========================================================
  Widget _buildActionCard(RecommendationModel rec) {
    final feat = (rec.relatedFeature ?? '').toLowerCase();

    // Determine visual style based on category
    Color iconBg;
    Color iconColor;
    IconData iconData;
    String tagLabel;
    Color tagBg;
    Color tagColor;
    String impactLabel;
    Color impactBg;
    Color impactColor;
    String actionBtnLabel;

    if (feat.contains('review')) {
      iconBg = const Color(0xFFFEF2F2);
      iconColor = const Color(0xFFEF4444);
      iconData = Icons.chat_bubble_outline_rounded;
      tagLabel = '⚠️ NEEDS ATTENTION';
      tagBg = const Color(0xFFFEF2F2);
      tagColor = const Color(0xFFEF4444);
      impactLabel = '🔥 High Priority';
      impactBg = const Color(0xFFFEF2F2);
      impactColor = const Color(0xFFDC2626);
      actionBtnLabel = 'Open Reviews';
    } else if (feat.contains('seo') || feat.contains('local') || feat.contains('rank')) {
      iconBg = const Color(0xFFECFDF5);
      iconColor = const Color(0xFF059669);
      iconData = Icons.travel_explore_rounded;
      tagLabel = '📈 HIGH IMPACT';
      tagBg = const Color(0xFFECFDF5);
      tagColor = const Color(0xFF059669);
      impactLabel = '📈 +15% Visibility';
      impactBg = const Color(0xFFECFDF5);
      impactColor = const Color(0xFF059669);
      actionBtnLabel = 'Take Action';
    } else {
      iconBg = const Color(0xFFEFF6FF);
      iconColor = const Color(0xFF2563EB);
      iconData = Icons.campaign_outlined;
      tagLabel = '⭐ IMPORTANT';
      tagBg = const Color(0xFFEFF6FF);
      tagColor = const Color(0xFF2563EB);
      impactLabel = '📈 +20% Reach';
      impactBg = const Color(0xFFEFF6FF);
      impactColor = const Color(0xFF2563EB);
      actionBtnLabel = 'Create Post';
    }

    final duration = rec.effort.isNotEmpty ? rec.effort : '15 mins';

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
          // Top Row: Icon + Badges + Title
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(iconData, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),

              // Title & Badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: tagBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tagLabel,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: tagColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: impactBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            impactLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: impactColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Card Title
                    Text(
                      rec.title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Subtitle Explanation
          Text(
            rec.explanation.isNotEmpty ? rec.explanation : rec.reason,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 16),

          // Footer Action Row (Duration, Dismiss, Primary Action Button)
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Text(
                duration,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
              ),
              const Spacer(),

              // Dismiss Text Button
              InkWell(
                onTap: () => _handleUpdateStatus(rec, 'dismissed'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    'Dismiss',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Primary Action Button (Matching Reference)
              InkWell(
                onTap: () => _handleActionTap(rec),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    actionBtnLabel,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 4. BOTTOM "ASK AI CMO" BANNER (Matching Reference Screen)
  // ==========================================================
  Widget _buildAskCmoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFC4B5FD)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Image.asset('assets/images/optigo-bot.png', fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Ask AI CMO ✨',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF5B21B6),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Ask anything about your marketing.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF7C3AED), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => CmoChatDrawer.show(context, currentScreen: 'recommendations'),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC4B5FD)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ask Now',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6D28D9),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF6D28D9)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 40, color: Color(0xFF10B981)),
            const SizedBox(height: 12),
            const Text(
              'All Caught Up!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            const Text(
              'No pending actions in this category.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _handleGenerateFresh,
              icon: const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
              label: const Text('Generate Fresh Actions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
