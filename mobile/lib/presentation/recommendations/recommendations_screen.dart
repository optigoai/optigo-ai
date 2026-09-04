import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/models/recommendation_model.dart';
import '../../data/repositories/recommendation_repository.dart';
import '../auth/auth_provider.dart';
import '../shared/optigo_top_bar.dart';
import '../shared/cmo_chat_drawer.dart';
import '../shared/optigo_pill.dart';

/// OptigoAI Grow Hub (Screen 2: Priorities + Recommendations + Automation)
/// Unified Action Center: Execute high-impact growth tasks and manage automated marketing workflows.
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
  String _selectedFilter = 'urgent'; // 'urgent', 'growth', 'automation', 'completed'
  String _sortBy = 'priority'; // 'priority', 'impact', 'effort'
  bool _initialized = false;

  // Automation Rule States
  bool _masterAutomationEnabled = true;
  final Map<String, bool> _automationRules = {
    'review_reply': true,
    'rank_drop_defense': true,
    'urgent_review_alert': true,
    'weekend_promo': false,
  };

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
            content: Text('Strategic growth priorities refreshed!'),
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
      }
    } catch (_) {}
  }

  void _handleActionTap(RecommendationModel rec) {
    final feat = (rec.relatedFeature ?? '').toLowerCase();
    if (feat.contains('review') || feat.contains('reputation')) {
      if (widget.onNavigateToReviews != null) {
        widget.onNavigateToReviews!();
      }
    } else if (feat.contains('seo') || feat.contains('rank') || feat.contains('local')) {
      if (widget.onNavigateToSeo != null) {
        widget.onNavigateToSeo!();
      }
    } else if (feat.contains('post') || feat.contains('campaign') || feat.contains('content')) {
      if (widget.onNavigateToCreate != null) {
        widget.onNavigateToCreate!();
      }
    } else {
      CmoChatDrawer.show(
        context,
        currentScreen: 'actions',
        initialMessage: 'Help me execute: "${rec.title}" with maximum local impact.',
      );
    }
  }

  List<RecommendationModel> get _filteredAndSortedList {
    var list = _recommendations.toList();

    if (_selectedFilter == 'urgent') {
      list = list.where((r) => r.isUrgent && !r.isCompleted).toList();
    } else if (_selectedFilter == 'growth') {
      list = list.where((r) => !r.isUrgent && !r.isCompleted).toList();
    } else if (_selectedFilter == 'completed') {
      list = list.where((r) => r.isCompleted).toList();
    } else {
      list = list.where((r) => !r.isCompleted).toList();
    }

    if (_sortBy == 'priority') {
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Navigation Bar
                  OptigoTopBar(
                    subtitle: 'Your Next Best Actions',
                    onNotificationTap: widget.onNavigateToReviews,
                    onRefreshTap: _handleGenerateFresh,
                    isRefreshing: _isGenerating,
                  ),

                  const SizedBox(height: 14),

                  // 2. Executive Hero Strategy Directive
                  _buildStrategicBriefingCard(
                    urgent: urgentCount,
                    growth: growthCount,
                    completed: completedCount,
                  ),

                  const SizedBox(height: 18),

                  // 3. Segmented Navigation Bar (Urgent / Growth / Automation / Done)
                  _buildSegmentedTabBar(
                    urgentCount: urgentCount,
                    growthCount: growthCount,
                    completedCount: completedCount,
                  ),

                  const SizedBox(height: 18),

                  // 4. Content Area: Either Automation Rules or Action Cards
                  if (_selectedFilter == 'automation')
                    _buildAutomationRulesSection()
                  else ...[
                    // Section Header with Sort Menu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedFilter == 'urgent'
                              ? 'Urgent Actions ($urgentCount)'
                              : (_selectedFilter == 'growth'
                                  ? 'Growth Drivers ($growthCount)'
                                  : 'Completed Actions ($completedCount)'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.3,
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

                    // Action Cards List
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
                      )
                    else if (displayedList.isEmpty)
                      _buildEmptyState()
                    else
                      ...displayedList.map((rec) => _buildStrategicActionCard(rec)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 2. Executive Hero Strategy Directive
  // ==========================================
  Widget _buildStrategicBriefingCard({
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
            color: const Color(0xFF6366F1).withValues(alpha: 0.05),
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
                    OptigoPill(
                      label: 'AI STRATEGIC DIRECTIVE',
                      variant: OptigoPillVariant.neutral,
                      fontSize: 10,
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                        children: [
                          const TextSpan(text: 'Complete '),
                          TextSpan(
                            text: '$urgent urgent ${urgent == 1 ? 'action' : 'actions'}',
                            style: const TextStyle(color: Color(0xFF2563EB)),
                          ),
                          const TextSpan(text: '\nto maximize customer reach today'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 78,
                height: 78,
                child: Image.asset(
                  'assets/images/optigo-bot.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // High-Impact KPI Counter Row
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
                _buildKpiMetric('Growth', '$growth', const Color(0xFFF59E0B), const Color(0xFFFEF3C7)),
                Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                _buildKpiMetric('Done', '$completed', const Color(0xFF10B981), const Color(0xFFECFDF5)),
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
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
  // 3. Segmented Navigation Tab Bar
  // ==========================================
  Widget _buildSegmentedTabBar({
    required int urgentCount,
    required int growthCount,
    required int completedCount,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSegmentTab('urgent', 'Urgent', '$urgentCount', Icons.warning_amber_rounded, const Color(0xFFEF4444)),
            const SizedBox(width: 4),
            _buildSegmentTab('growth', 'Growth', '$growthCount', Icons.trending_up_rounded, const Color(0xFF10B981)),
            const SizedBox(width: 4),
            _buildSegmentTab('automation', 'Automation', '4', Icons.smart_toy_rounded, const Color(0xFF2563EB)),
            const SizedBox(width: 4),
            _buildSegmentTab('completed', 'Done', '$completedCount', Icons.check_circle_outline_rounded, const Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentTab(String id, String title, String count, IconData icon, Color semanticColor) {
    final isSelected = _selectedFilter == id;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = id),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : semanticColor,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : semanticColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : semanticColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 4. Automation Rules Section
  // ==========================================
  Widget _buildAutomationRulesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Master Kill Switch Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _masterAutomationEnabled ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _masterAutomationEnabled ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _masterAutomationEnabled ? Icons.shield_rounded : Icons.pause_circle_rounded,
                color: _masterAutomationEnabled ? const Color(0xFF059669) : const Color(0xFFDC2626),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _masterAutomationEnabled ? 'Marketing Autopilot Active' : 'All Automations Paused',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: _masterAutomationEnabled ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _masterAutomationEnabled
                          ? 'AI monitors your Google Maps, reviews, and posts 24/7.'
                          : 'No automated drafts or notifications will run.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: _masterAutomationEnabled ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _masterAutomationEnabled,
                onChanged: (val) => setState(() => _masterAutomationEnabled = val),
                activeThumbColor: const Color(0xFF10B981),
                activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.4),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'Visual If/Then Rules',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),

        const SizedBox(height: 12),

        _buildAutomationRuleCard(
          ruleKey: 'review_reply',
          title: '5★ Review Appreciation Auto-Draft',
          ifCondition: 'New 5-star Google review received',
          thenAction: 'Draft personalized reply tailored to customer praise',
          approvalRequirement: 'You approve with 1 tap before sending',
          icon: Icons.rate_review_rounded,
          iconColor: const Color(0xFF10B981),
        ),

        const SizedBox(height: 12),

        _buildAutomationRuleCard(
          ruleKey: 'rank_drop_defense',
          title: 'Google Map Pack Rank Defense',
          ifCondition: 'Keyword drops out of Top 3 in your area',
          thenAction: 'Generate targeted Google update with local keywords',
          approvalRequirement: 'Suggested post ready in your daily brief',
          icon: Icons.pin_drop_rounded,
          iconColor: const Color(0xFF2563EB),
        ),

        const SizedBox(height: 12),

        _buildAutomationRuleCard(
          ruleKey: 'urgent_review_alert',
          title: 'Critical Review Escalation',
          ifCondition: '1★ or 2★ review unreplied for > 24 hours',
          thenAction: 'Send high-priority push alert with recovery response',
          approvalRequirement: 'Requires owner confirmation',
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFEF4444),
        ),

        const SizedBox(height: 12),

        _buildAutomationRuleCard(
          ruleKey: 'weekend_promo',
          title: 'Weekend Traffic Booster',
          ifCondition: 'Every Friday at 4:00 PM',
          thenAction: 'Auto-create weekend promotional story campaign',
          approvalRequirement: 'Optional 1-tap schedule',
          icon: Icons.campaign_rounded,
          iconColor: const Color(0xFF6366F1),
        ),
      ],
    );
  }

  Widget _buildAutomationRuleCard({
    required String ruleKey,
    required String title,
    required String ifCondition,
    required String thenAction,
    required String approvalRequirement,
    required IconData icon,
    required Color iconColor,
  }) {
    final isEnabled = (_automationRules[ruleKey] ?? false) && _masterAutomationEnabled;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              Switch.adaptive(
                value: isEnabled,
                onChanged: _masterAutomationEnabled
                    ? (val) => setState(() => _automationRules[ruleKey] = val)
                    : null,
                activeThumbColor: const Color(0xFF2563EB),
                activeTrackColor: const Color(0xFF2563EB).withValues(alpha: 0.4),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Visual If/Then Chip Flow
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IF: ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        ifCondition,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THEN: ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        thenAction,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.touch_app_rounded, size: 12, color: Color(0xFF059669)),
                    const SizedBox(width: 4),
                    Text(
                      approvalRequirement,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. Strategic Action Card
  // ==========================================
  Widget _buildStrategicActionCard(RecommendationModel rec) {
    final feat = (rec.relatedFeature ?? '').toLowerCase();
    final isUrgent = rec.isUrgent;

    String categoryTag;
    OptigoPillVariant pillVariant;
    IconData actionIcon;
    String actionLabel;

    if (feat.contains('review') || feat.contains('reputation')) {
      categoryTag = 'REVIEWS';
      pillVariant = isUrgent ? OptigoPillVariant.error : OptigoPillVariant.warning;
      actionIcon = Icons.rate_review_rounded;
      actionLabel = 'Reply to Review';
    } else if (feat.contains('seo') || feat.contains('rank') || feat.contains('local')) {
      categoryTag = 'LOCAL VISIBILITY';
      pillVariant = isUrgent ? OptigoPillVariant.error : OptigoPillVariant.neutral;
      actionIcon = Icons.pin_drop_rounded;
      actionLabel = 'Optimize Visibility';
    } else {
      categoryTag = 'PROMOTIONS';
      pillVariant = isUrgent ? OptigoPillVariant.error : OptigoPillVariant.success;
      actionIcon = Icons.campaign_rounded;
      actionLabel = 'Create Campaign';
    }

    final duration = rec.effort.isNotEmpty ? rec.effort : '2 mins';
    final desc = rec.explanation.isNotEmpty ? rec.explanation : rec.reason;

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
              OptigoPill(
                label: categoryTag,
                variant: pillVariant,
                fontSize: 10,
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

          // Explanation
          Text(
            desc,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: const Color(0xFF475569),
              height: 1.35,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 10),

          // Plain-Language Business Impact
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.insights_rounded, size: 13, color: Color(0xFF2563EB)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    rec.impact,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Action Controls (Primary Action + Mark Done + Overflow)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleActionTap(rec),
                  icon: Icon(actionIcon, size: 15, color: Colors.white),
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
                onTap: () => _handleUpdateStatus(rec, rec.isCompleted ? 'pending' : 'completed'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: rec.isCompleted ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: rec.isCompleted ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        rec.isCompleted ? Icons.check_circle_rounded : Icons.check_rounded,
                        size: 16,
                        color: const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rec.isCompleted ? 'Done' : 'Mark Done',
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
              if (!rec.isCompleted) ...[
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'dismiss') {
                      _handleUpdateStatus(rec, 'dismissed');
                    }
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF94A3B8)),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'dismiss',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_off_outlined, size: 16, color: Color(0xFF64748B)),
                          SizedBox(width: 8),
                          Text('Not now (dismiss)'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: const Center(
              child: Icon(Icons.verified_rounded, color: Color(0xFF2563EB), size: 32),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'All Caught Up!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No pending actions in this category. Your store is running smoothly.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF64748B),
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _handleGenerateFresh,
              icon: _isGenerating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white),
              label: Text(
                _isGenerating ? 'Analyzing Market...' : 'Generate New Growth Plan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
