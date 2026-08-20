import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../data/models/recommendation_model.dart';
import '../../data/repositories/recommendation_repository.dart';
import '../auth/auth_provider.dart';

class RecommendationsScreen extends StatefulWidget {
  final VoidCallback? onNavigateToReviews;

  const RecommendationsScreen({super.key, this.onNavigateToReviews});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  RecommendationRepository? _recRepo;
  List<RecommendationModel> _recommendations = [];
  String _cmoNote = '';
  bool _isLoading = true;
  bool _isGenerating = false;
  String _selectedPriority = 'all'; // 'all', 'urgent', 'important', 'opportunity'
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
        priority: _selectedPriority == 'all' ? null : _selectedPriority,
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
          _cmoNote = result.cmoNote;
          _recommendations = result.recommendations;
          _isGenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI CMO Strategy updated with fresh action cards!'),
            backgroundColor: OptigoTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate: $e'), backgroundColor: OptigoTheme.error),
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
            content: Text(newStatus == 'completed' ? 'Action marked as completed!' : 'Recommendation dismissed'),
            backgroundColor: newStatus == 'completed' ? OptigoTheme.success : OptigoTheme.textSecondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: OptigoTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final business = authProvider.currentBusiness;

    final urgentCount = _recommendations.where((r) => r.isUrgent && !r.isCompleted).length;
    final importantCount = _recommendations.where((r) => r.isImportant && !r.isCompleted).length;
    final opportunityCount = _recommendations.where((r) => r.isOpportunity && !r.isCompleted).length;

    return Scaffold(
      backgroundColor: OptigoTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRecommendations,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(OptigoTheme.spacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header
                Row(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 88,
                      height: 88,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: OptigoTheme.spacingSM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI CMO Recommendations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: OptigoTheme.textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            business?.name ?? 'OptigoAI Business',
                            style: const TextStyle(
                              fontSize: 12,
                              color: OptigoTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: OptigoTheme.spacingMD),

                // AI CMO Strategy Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(OptigoTheme.spacingMD),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(OptigoTheme.radiusLG),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
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
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: OptigoTheme.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(OptigoTheme.radiusSM),
                            ),
                            child: const Icon(Icons.auto_awesome, color: Color(0xFF38BDF8), size: 18),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'AI Chief Marketing Officer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          if (_isGenerating)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _cmoNote.isNotEmpty
                            ? _cmoNote
                            : 'Here is your prioritized marketing battle plan for this week. Focus on clearing urgent items first to safeguard customer acquisition.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: ElevatedButton.icon(
                          onPressed: _isGenerating ? null : _handleGenerateFresh,
                          icon: const Icon(Icons.sync_rounded, size: 16),
                          label: Text(
                            _isGenerating ? 'Synthesizing...' : 'Synthesize Fresh Strategy',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: OptigoTheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(OptigoTheme.radiusMD)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: OptigoTheme.spacingMD),

                // Priority Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All (${_recommendations.length})', null),
                      const SizedBox(width: 8),
                      _buildFilterChip('urgent', '🚨 Urgent ($urgentCount)', OptigoTheme.error),
                      const SizedBox(width: 8),
                      _buildFilterChip('important', '⚡ Important ($importantCount)', const Color(0xFFD97706)),
                      const SizedBox(width: 8),
                      _buildFilterChip('opportunity', '🚀 Opportunities ($opportunityCount)', OptigoTheme.success),
                    ],
                  ),
                ),

                const SizedBox(height: OptigoTheme.spacingMD),

                // Recommendation List
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (_recommendations.isEmpty)
                  _buildEmptyState()
                else
                  ..._recommendations.map((rec) => _buildRecommendationCard(rec)),

                const SizedBox(height: OptigoTheme.spacingLG),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, Color? color) {
    final isSelected = _selectedPriority == key;
    return InkWell(
      onTap: () {
        setState(() => _selectedPriority = key);
        _loadRecommendations();
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? (color ?? OptigoTheme.primary) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? (color ?? OptigoTheme.primary) : OptigoTheme.divider,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (color ?? OptigoTheme.primary).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : OptigoTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(RecommendationModel rec) {
    Color priorityColor;
    String priorityLabel;
    IconData priorityIcon;

    if (rec.isUrgent) {
      priorityColor = OptigoTheme.error;
      priorityLabel = 'URGENT ACTION';
      priorityIcon = Icons.warning_amber_rounded;
    } else if (rec.isOpportunity) {
      priorityColor = OptigoTheme.success;
      priorityLabel = 'GROWTH OPPORTUNITY';
      priorityIcon = Icons.rocket_launch_rounded;
    } else {
      priorityColor = const Color(0xFFD97706);
      priorityLabel = 'STRATEGIC PRIORITY';
      priorityIcon = Icons.bolt_rounded;
    }

    final isCompleted = rec.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: OptigoTheme.spacingMD),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(OptigoTheme.radiusLG),
        border: Border.all(
          color: isCompleted ? OptigoTheme.success.withValues(alpha: 0.3) : priorityColor.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: priorityColor.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar with Priority & Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: OptigoTheme.spacingMD, vertical: 10),
            decoration: BoxDecoration(
              color: isCompleted
                  ? OptigoTheme.success.withValues(alpha: 0.08)
                  : priorityColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(OptigoTheme.radiusLG)),
            ),
            child: Row(
              children: [
                Icon(isCompleted ? Icons.check_circle : priorityIcon, size: 16, color: isCompleted ? OptigoTheme.success : priorityColor),
                const SizedBox(width: 6),
                Text(
                  isCompleted ? 'COMPLETED' : priorityLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isCompleted ? OptigoTheme.success : priorityColor,
                    letterSpacing: 0.6,
                  ),
                ),
                const Spacer(),
                if (rec.impact.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(OptigoTheme.radiusSM),
                      border: Border.all(color: OptigoTheme.divider),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.trending_up_rounded, size: 12, color: OptigoTheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          rec.impact,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: OptigoTheme.primary),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(OptigoTheme.spacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  rec.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isCompleted ? OptigoTheme.textSecondary : OptigoTheme.textPrimary,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),

                // Explanation
                Text(
                  rec.explanation,
                  style: const TextStyle(fontSize: 13, color: OptigoTheme.textSecondary, height: 1.4),
                ),

                const SizedBox(height: 10),

                // Reason / Why It Matters
                if (rec.reason.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: OptigoTheme.surfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(OptigoTheme.radiusSM),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.psychology_outlined, size: 16, color: OptigoTheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 12, color: OptigoTheme.textPrimary, height: 1.3),
                              children: [
                                const TextSpan(text: 'Why this matters: ', style: TextStyle(fontWeight: FontWeight.w800)),
                                TextSpan(text: rec.reason),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 10),

                // Suggested Action Box
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(OptigoTheme.radiusSM),
                    border: Border.all(color: priorityColor.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.directions_run_rounded, size: 16, color: priorityColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rec.suggestedAction,
                          style: TextStyle(fontSize: 12, color: priorityColor, fontWeight: FontWeight.w600, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Effort & Action Buttons
                Row(
                  children: [
                    if (rec.effort.isNotEmpty) ...[
                      const Icon(Icons.timer_outlined, size: 14, color: OptigoTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        rec.effort,
                        style: const TextStyle(fontSize: 11, color: OptigoTheme.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                    const Spacer(),

                    // Jump to related feature if applicable (e.g. reviews)
                    if (rec.relatedFeature == 'reviews' && widget.onNavigateToReviews != null && !isCompleted)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: OutlinedButton(
                          onPressed: widget.onNavigateToReviews,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: const BorderSide(color: OptigoTheme.primary),
                          ),
                          child: const Text('Open Reviews', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ),

                    if (!isCompleted) ...[
                      TextButton(
                        onPressed: () => _handleUpdateStatus(rec, 'dismissed'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: OptigoTheme.textSecondary,
                        ),
                        child: const Text('Dismiss', style: TextStyle(fontSize: 11)),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () => _handleUpdateStatus(rec, 'completed'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: OptigoTheme.success,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Mark Done', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ] else
                      const Text(
                        '✓ Completed',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: OptigoTheme.success),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: OptigoTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline, size: 40, color: OptigoTheme.primary),
            ),
            const SizedBox(height: OptigoTheme.spacingMD),
            const Text(
              'No active recommendations in this category',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: OptigoTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap "Synthesize Fresh Strategy" to generate new AI actions.',
              style: TextStyle(fontSize: 12, color: OptigoTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
