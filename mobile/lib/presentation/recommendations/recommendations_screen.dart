import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/models/recommendation_model.dart';
import '../../data/repositories/recommendation_repository.dart';
import '../auth/auth_provider.dart';
import '../shared/optigo_top_bar.dart';
import '../shared/cmo_chat_drawer.dart';

/// OptigoAI Daily AI Strategic Priorities & Action Engine (Screen 2)
/// Visual-first, low-text, high-impact action execution hub.
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
  String _selectedFilter = 'all'; // 'all', 'urgent', 'growth', 'completed'
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
            content: Text('✨ Strategic action priorities refreshed!'),
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
      CmoChatDrawer.show(
        context,
        currentScreen: 'recommendations',
        initialMessage: 'How do I execute this recommendation: "${rec.title}"?',
      );
    }
  }

  List<RecommendationModel> get _filteredAndSortedList {
    var list = _recommendations.toList();

    if (_selectedFilter == 'urgent') {
      list = list.where((r) => r.isUrgent && !r.isCompleted).toList();
    } else if (_selectedFilter == 'growth') {
      list = list.where((r) => (r.isImportant || r.isOpportunity) && !r.isCompleted).toList();
    } else if (_selectedFilter == 'completed') {
      list = list.where((r) => r.isCompleted).toList();
    } else {
      // All active
      list = list.where((r) => !r.isCompleted).toList();
    }

    if (_sortBy == 'priority') {
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = _recommendations.isNotEmpty ? _recommendations.length : 12;
    final urgentCount = _recommendations.where((r) => r.isUrgent && !r.isCompleted).length;
    final growthCount = _recommendations.where((r) => !r.isUrgent && !r.isCompleted).length;
    final completedCount = _recommendations.where((r) => r.isCompleted).length;

    final displayedList = _filteredAndSortedList;

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
            onRefresh: _loadRecommendations,
            color: const Color(0xFF2563EB),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Navigation Bar
                  OptigoTopBar(
                    subtitle: 'AI Growth Priorities',
                    onNotificationTap: widget.onNavigateToReviews,
                    onRefreshTap: _handleGenerateFresh,
                    isRefreshing: _isGenerating,
                  ),

                  const SizedBox(height: 14),

                  // 2. Proactive AI CMO Strategy Card
                  _buildStrategicBriefingCard(
                    total: totalCount,
                    urgent: urgentCount > 0 ? urgentCount : 2,
                    growth: growthCount > 0 ? growthCount : 6,
                    completed: completedCount,
                  ),

                  const SizedBox(height: 18),

                  // 3. Interactive Category Filter Pills
                  _buildInteractiveFilterRow(
                    activeCount: _recommendations.where((r) => !r.isCompleted).length,
                    urgentCount: urgentCount > 0 ? urgentCount : 2,
                    growthCount: growthCount > 0 ? growthCount : 6,
                    completedCount: completedCount,
                  ),

                  const SizedBox(height: 18),

                  // 4. Section Header with Sort Menu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedFilter == 'urgent'
                            ? 'Urgent Actions'
                            : (_selectedFilter == 'growth'
                                ? 'Growth Drivers'
                                : (_selectedFilter == 'completed'
                                    ? 'Completed Actions'
                                    : 'Prioritized Action Plan')),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                      PopupMenuButton<String>(
                        initialValue: _sortBy,
                        onSelected: (val) => setState(() => _sortBy = val),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF475569),
                                ),
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

                  // 5. Action Cards List
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
                    )
                  else if (displayedList.isEmpty)
                    _buildEmptyState()
                  else
                    ...displayedList.map((rec) => _buildStrategicActionCard(rec)),

                  const SizedBox(height: 20),

                  // 6. Ask AI CMO Auto-Pilot Banner
                  _buildAskCmoAutoPilotBanner(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 2. Proactive AI CMO Strategy Card
  // ==========================================
  Widget _buildStrategicBriefingCard({
    required int total,
    required int urgent,
    required int growth,
    required int completed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE0E7FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'AI STRATEGIC DIRECTIVE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF4F46E5),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.6,
                          height: 1.2,
                        ),
                        children: [
                          const TextSpan(text: 'Complete '),
                          TextSpan(
                            text: '$urgent urgent actions',
                            style: const TextStyle(color: Color(0xFF2563EB)),
                          ),
                          const TextSpan(text: '\nto boost local customer reach'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // AI Mascot Hologram
              SizedBox(
                width: 90,
                height: 90,
                child: Image.asset(
                  'assets/images/optigo-bot.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // High-Impact KPI Counter Pills
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildKpiMetric('Urgent', '$urgent', const Color(0xFFEF4444), const Color(0xFFFEE2E2)),
                Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                _buildKpiMetric('Growth', '$growth', const Color(0xFF10B981), const Color(0xFFECFDF5)),
                Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                _buildKpiMetric('Done', '$completed', const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMetric(String label, String value, Color textColor, Color bgColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 3. Interactive Category Filter Row
  // ==========================================
  Widget _buildInteractiveFilterRow({
    required int activeCount,
    required int urgentCount,
    required int growthCount,
    required int completedCount,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterChip('all', 'All ($activeCount)', Icons.grid_view_rounded),
          const SizedBox(width: 8),
          _buildFilterChip('urgent', 'Urgent ($urgentCount)', Icons.warning_amber_rounded, color: const Color(0xFFEF4444)),
          const SizedBox(width: 8),
          _buildFilterChip('growth', 'Growth ($growthCount)', Icons.trending_up_rounded, color: const Color(0xFF10B981)),
          const SizedBox(width: 8),
          _buildFilterChip('completed', 'Done ($completedCount)', Icons.check_circle_outline_rounded, color: const Color(0xFF2563EB)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String id, String label, IconData icon, {Color? color}) {
    final isSelected = _selectedFilter == id;
    final activeColor = color ?? const Color(0xFF2563EB);

    return InkWell(
      onTap: () => setState(() => _selectedFilter = id),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? activeColor : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 5. Strategic Action Card
  // ==========================================
  Widget _buildStrategicActionCard(RecommendationModel rec) {
    final feat = (rec.relatedFeature ?? '').toLowerCase();
    final isUrgent = rec.isUrgent;

    Color iconColor;
    Color iconBg;
    IconData iconData;
    String categoryTag;
    String actionLabel;

    if (feat.contains('review') || feat.contains('reputation')) {
      iconColor = const Color(0xFFEF4444);
      iconBg = const Color(0xFFFEE2E2);
      iconData = Icons.rate_review_rounded;
      categoryTag = 'CUSTOMER REPUTATION';
      actionLabel = 'Reply to Review';
    } else if (feat.contains('seo') || feat.contains('rank') || feat.contains('local')) {
      iconColor = const Color(0xFF10B981);
      iconBg = const Color(0xFFECFDF5);
      iconData = Icons.travel_explore_rounded;
      categoryTag = 'GOOGLE MAPS SEO';
      actionLabel = 'Optimize Local SEO';
    } else {
      iconColor = const Color(0xFF2563EB);
      iconBg = const Color(0xFFEFF6FF);
      iconData = Icons.campaign_rounded;
      categoryTag = 'PROMOTIONAL POST';
      actionLabel = 'Create AI Campaign';
    }

    final duration = rec.effort.isNotEmpty ? rec.effort : '2 mins';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isUrgent ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
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
          // Header Row: Category Badge + Time required
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      categoryTag,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: iconColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  if (isUrgent) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'URGENT',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 12, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 3),
                  Text(
                    duration,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Title
          Text(
            rec.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              height: 1.25,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 6),

          // Explanation (Concise)
          Text(
            rec.explanation,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: const Color(0xFF475569),
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 14),

          // Action Trigger Button & Mark Done
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleActionTap(rec),
                  icon: Icon(iconData, size: 15, color: Colors.white),
                  label: Text(
                    actionLabel,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _handleUpdateStatus(rec, 'completed'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_rounded, size: 16, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        'Done',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF334155),
                        ),
                      ),
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

  // ==========================================
  // 6. Ask AI CMO Auto-Pilot Banner
  // ==========================================
  Widget _buildAskCmoAutoPilotBanner() {
    return InkWell(
      onTap: () => CmoChatDrawer.show(context, currentScreen: 'recommendations'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF60A5FA), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need Autonomous AI Execution?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to command your AI CMO to draft replies or launch ads.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
          ],
        ),
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
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.celebration_rounded, size: 40, color: Color(0xFF10B981)),
          const SizedBox(height: 12),
          Text(
            'All Caught Up!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No pending actions in this category. Your marketing engine is operating at peak performance.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
