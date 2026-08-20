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
  final Set<String> _expandedCards = {};
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
            padding: const EdgeInsets.symmetric(horizontal: OptigoTheme.spacingMD, vertical: OptigoTheme.spacingSM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Bar
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: OptigoTheme.spacingSM),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 72,
                        height: 72,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: OptigoTheme.spacingSM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AI CMO Actions',
                              style: TextStyle(
                                fontSize: 19,
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
                ),

                // AI CMO Advisor Card
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
                        color: Colors.black.withValues(alpha: 0.12),
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
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(OptigoTheme.radiusSM),
                            ),
                            child: const Icon(Icons.auto_awesome, color: Color(0xFF38BDF8), size: 16),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'AI CMO Battle Plan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
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
                      const SizedBox(height: 8),
                      Text(
                        _cmoNote.isNotEmpty
                            ? _cmoNote
                            : 'Clear high-priority items first to boost customer trust and drive instant conversions.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: _isGenerating ? null : _handleGenerateFresh,
                          icon: const Icon(Icons.sync_rounded, size: 16),
                          label: Text(
                            _isGenerating ? 'Synthesizing...' : 'Refresh AI Strategy',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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

                // Priority Filter Segment Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All (${_recommendations.length})', null),
                      const SizedBox(width: 6),
                      _buildFilterChip('urgent', '🚨 Urgent ($urgentCount)', OptigoTheme.error),
                      const SizedBox(width: 6),
                      _buildFilterChip('important', '⚡ Important ($importantCount)', const Color(0xFFD97706)),
                      const SizedBox(width: 6),
                      _buildFilterChip('opportunity', '🚀 Opportunities ($opportunityCount)', OptigoTheme.success),
                    ],
                  ),
                ),

                const SizedBox(height: OptigoTheme.spacingMD),

                // Recommendation Action Cards
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
                  ..._recommendations.map((rec) => _buildCleanRecommendationCard(rec)),

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
    final activeColor = color ?? OptigoTheme.primary;

    return InkWell(
      onTap: () {
        setState(() => _selectedPriority = key);
        _loadRecommendations();
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : OptigoTheme.divider,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.2),
                    blurRadius: 4,
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

  Widget _buildCleanRecommendationCard(RecommendationModel rec) {
    Color priorityColor;
    String priorityLabel;
    IconData priorityIcon;

    if (rec.isUrgent) {
      priorityColor = OptigoTheme.error;
      priorityLabel = 'URGENT';
      priorityIcon = Icons.warning_amber_rounded;
    } else if (rec.isOpportunity) {
      priorityColor = OptigoTheme.success;
      priorityLabel = 'OPPORTUNITY';
      priorityIcon = Icons.rocket_launch_rounded;
    } else {
      priorityColor = const Color(0xFFD97706);
      priorityLabel = 'STRATEGIC';
      priorityIcon = Icons.bolt_rounded;
    }

    final isCompleted = rec.isCompleted;
    final isExpanded = _expandedCards.contains(rec.id);

    return Container(
      margin: const EdgeInsets.only(bottom: OptigoTheme.spacingMD),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(OptigoTheme.radiusMD),
        border: Border.all(
          color: isCompleted
              ? OptigoTheme.success.withValues(alpha: 0.3)
              : priorityColor.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header: Badges & Impact
          Padding(
            padding: const EdgeInsets.fromLTRB(OptigoTheme.spacingMD, OptigoTheme.spacingSM + 2, OptigoTheme.spacingMD, 0),
            child: Row(
              children: [
                // Priority Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? OptigoTheme.success.withValues(alpha: 0.1)
                        : priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(OptigoTheme.radiusSM),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isCompleted ? Icons.check_circle : priorityIcon, size: 12, color: isCompleted ? OptigoTheme.success : priorityColor),
                      const SizedBox(width: 4),
                      Text(
                        isCompleted ? 'COMPLETED' : priorityLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isCompleted ? OptigoTheme.success : priorityColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Impact Badge
                if (rec.impact.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: OptigoTheme.surfaceVariant.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(OptigoTheme.radiusSM),
                    ),
                    child: Text(
                      rec.impact,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: OptigoTheme.textPrimary),
                    ),
                  ),
              ],
            ),
          ),

          // Main Action Title
          Padding(
            padding: const EdgeInsets.fromLTRB(OptigoTheme.spacingMD, 8, OptigoTheme.spacingMD, 0),
            child: Text(
              rec.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isCompleted ? OptigoTheme.textSecondary : OptigoTheme.textPrimary,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                letterSpacing: -0.3,
              ),
            ),
          ),

          // Action Box (The single key instruction to take action)
          Padding(
            padding: const EdgeInsets.fromLTRB(OptigoTheme.spacingMD, 8, OptigoTheme.spacingMD, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: priorityColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(OptigoTheme.radiusSM),
                border: Border.all(color: priorityColor.withValues(alpha: 0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.arrow_right_alt_rounded, size: 16, color: priorityColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      rec.suggestedAction,
                      style: TextStyle(
                        fontSize: 12,
                        color: priorityColor,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable Context / "Why this matters" toggle
          if (rec.explanation.isNotEmpty || rec.reason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(OptigoTheme.spacingMD, 4, OptigoTheme.spacingMD, 0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedCards.remove(rec.id);
                    } else {
                      _expandedCards.add(rec.id);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isExpanded ? 'Hide context' : 'Why this matters',
                        style: const TextStyle(fontSize: 11, color: OptigoTheme.primary, fontWeight: FontWeight.w600),
                      ),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 14,
                        color: OptigoTheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(OptigoTheme.spacingMD, 4, OptigoTheme.spacingMD, 0),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: OptigoTheme.surfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(OptigoTheme.radiusSM),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (rec.explanation.isNotEmpty)
                      Text(
                        rec.explanation,
                        style: const TextStyle(fontSize: 11.5, color: OptigoTheme.textSecondary, height: 1.3),
                      ),
                    if (rec.reason.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Strategic reason: ${rec.reason}',
                        style: const TextStyle(fontSize: 11.5, color: OptigoTheme.textPrimary, fontWeight: FontWeight.w600, height: 1.3),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Bottom Action Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(OptigoTheme.spacingMD, 10, OptigoTheme.spacingMD, OptigoTheme.spacingSM + 2),
            child: Row(
              children: [
                if (rec.effort.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 12, color: OptigoTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        rec.effort,
                        style: const TextStyle(fontSize: 11, color: OptigoTheme.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                const Spacer(),

                if (rec.relatedFeature == 'reviews' && widget.onNavigateToReviews != null && !isCompleted)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: OutlinedButton(
                      onPressed: widget.onNavigateToReviews,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: const BorderSide(color: OptigoTheme.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(OptigoTheme.radiusSM)),
                      ),
                      child: const Text('Open Reviews', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ),

                if (!isCompleted) ...[
                  TextButton(
                    onPressed: () => _handleUpdateStatus(rec, 'dismissed'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: OptigoTheme.textSecondary,
                    ),
                    child: const Text('Dismiss', style: TextStyle(fontSize: 11)),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: () => _handleUpdateStatus(rec, 'completed'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: OptigoTheme.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(OptigoTheme.radiusSM)),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: OptigoTheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline, size: 36, color: OptigoTheme.primary),
            ),
            const SizedBox(height: OptigoTheme.spacingSM),
            const Text(
              'No recommendations in this filter',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: OptigoTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap "Refresh AI Strategy" to synthesize new items.',
              style: TextStyle(fontSize: 11, color: OptigoTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
