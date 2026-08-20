import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/recommendation_model.dart';
import '../../data/repositories/recommendation_repository.dart';
import '../auth/auth_provider.dart';
import '../shared/optigo_top_bar.dart';

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
  String _selectedFilter = 'all'; // 'all', 'urgent', 'important', 'opportunity'
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
          _cmoNote = result.cmoNote;
          _recommendations = result.recommendations;
          _isGenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI CMO Battle Plan updated with fresh action cards!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate: $e'), backgroundColor: const Color(0xFFEF4444)),
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

  @override
  Widget build(BuildContext context) {
    final pendingList = _recommendations.where((r) => !r.isCompleted).toList();
    final completedList = _recommendations.where((r) => r.isCompleted).toList();

    final urgentCount = _recommendations.where((r) => r.isUrgent && !r.isCompleted).length;
    final importantCount = _recommendations.where((r) => r.isImportant && !r.isCompleted).length;
    final opportunityCount = _recommendations.where((r) => r.isOpportunity && !r.isCompleted).length;

    // Filter pending items according to selected filter
    final displayedPending = pendingList.where((r) {
      if (_selectedFilter == 'urgent') return r.isUrgent;
      if (_selectedFilter == 'important') return r.isImportant;
      if (_selectedFilter == 'opportunity') return r.isOpportunity;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRecommendations,
          color: const Color(0xFF2563EB),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Universal Top App Bar
                const OptigoTopBar(
                  subtitle: 'AI CMO Actions',
                ),

                const SizedBox(height: 8),

                // 2. AI CMO Battle Plan Hero Card
                _buildBattlePlanCard(
                  totalCount: _recommendations.length,
                  attentionCount: pendingList.length,
                  completedCount: completedList.length,
                ),

                const SizedBox(height: 16),

                // 3. Filter Chips
                _buildFilterChips(
                  total: _recommendations.length,
                  urgent: urgentCount,
                  important: importantCount,
                  opportunity: opportunityCount,
                ),

                const SizedBox(height: 20),

                // 4. "Needs Your Attention" Section
                Row(
                  children: [
                    const Text(
                      'Needs Your Attention',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${displayedPending.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: const [
                        Text(
                          'Sort by: ',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Priority',
                          style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w700),
                        ),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF2563EB)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Pending Actions List
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                    ),
                  )
                else if (displayedPending.isEmpty)
                  _buildEmptyState()
                else
                  ...displayedPending.map((rec) => _buildActiveActionCard(rec)),

                const SizedBox(height: 20),

                // 5. "Completed Actions" Section
                if (completedList.isNotEmpty) ...[
                  Row(
                    children: [
                      const Text(
                        'Completed Actions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${completedList.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'View All',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...completedList.map((rec) => _buildCompletedActionCard(rec)),
                  const SizedBox(height: 16),
                ],

                // 6. "Keep the momentum going!" Motivational Card
                _buildMomentumCard(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildBattlePlanCard({
    required int totalCount,
    required int attentionCount,
    required int completedCount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI CMO Battle Plan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _cmoNote.isNotEmpty
                          ? _cmoNote
                          : "We've prioritized the actions that will get you the best results right now.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _isGenerating ? null : _handleGenerateFresh,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isGenerating)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      else ...[
                        const Text(
                          'View Plan',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 3-Metric Stats Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _buildStatItem('$totalCount', 'Total Actions', Colors.white),
                Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.2)),
                _buildStatItem('$attentionCount', 'Needs Attention', const Color(0xFFFCA5A5)),
                Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.2)),
                _buildStatItem('$completedCount', 'Completed', const Color(0xFF86EFAC)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label, Color countColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: countColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips({
    required int total,
    required int urgent,
    required int important,
    required int opportunity,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChipItem('all', 'All ($total)', Icons.grid_view_rounded, const Color(0xFF2563EB)),
          const SizedBox(width: 8),
          _buildFilterChipItem('urgent', '🚨 Urgent ($urgent)', null, const Color(0xFFEF4444)),
          const SizedBox(width: 8),
          _buildFilterChipItem('important', '⚡ Important ($important)', null, const Color(0xFFD97706)),
          const SizedBox(width: 8),
          _buildFilterChipItem('opportunity', '🎯 Opportunities ($opportunity)', null, const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _buildFilterChipItem(String key, String label, IconData? icon, Color activeColor) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF64748B)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF334155),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveActionCard(RecommendationModel rec) {
    Color themeColor;
    String priorityTag;
    IconData leadingIcon;
    Color iconBg;

    if (rec.isUrgent) {
      themeColor = const Color(0xFFEF4444);
      priorityTag = '🚨 URGENT';
      leadingIcon = Icons.chat_bubble_outline_rounded;
      iconBg = const Color(0xFFFEF2F2);
    } else if (rec.isOpportunity) {
      themeColor = const Color(0xFF10B981);
      priorityTag = '🎯 OPPORTUNITY';
      leadingIcon = Icons.rocket_launch_outlined;
      iconBg = const Color(0xFFECFDF5);
    } else {
      themeColor = const Color(0xFFD97706);
      priorityTag = '⚡ IMPORTANT';
      leadingIcon = Icons.bolt_rounded;
      iconBg = const Color(0xFFFFFBEB);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: rec.isUrgent ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
          width: 1,
        ),
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
          // Top Row: Leading Icon + Title + Impact Box
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Box
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(leadingIcon, color: themeColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      priorityTag,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: themeColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rec.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rec.explanation,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Right Impact Badge Box
              if (rec.impact.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'High Impact',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: themeColor),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.trending_up_rounded, size: 12, color: themeColor),
                          const SizedBox(width: 2),
                          Text(
                            rec.impact.replaceAll(RegExp(r'High|\(|\)|ROI|Rate'), '').trim(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: themeColor,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Conversion Rate',
                        style: TextStyle(fontSize: 8, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Suggested Action Highlight Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.arrow_forward_rounded, size: 14, color: themeColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    rec.suggestedAction,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: themeColor,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Bottom Action Row
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Text(
                rec.effort.isNotEmpty ? rec.effort.replaceAll(RegExp(r'Low|Medium|High|\(|\)'), '').trim() : '5 min',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              const Spacer(),

              if (rec.relatedFeature == 'reviews' && widget.onNavigateToReviews != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    onPressed: widget.onNavigateToReviews,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: const BorderSide(color: Color(0xFF2563EB)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Open Reviews', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
                  ),
                ),

              TextButton(
                onPressed: () => _handleUpdateStatus(rec, 'dismissed'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: const Color(0xFF64748B),
                ),
                child: const Text('Dismiss', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 6),

              ElevatedButton(
                onPressed: () => _handleUpdateStatus(rec, 'completed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Take Action', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedActionCard(RecommendationModel rec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'COMPLETED',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF10B981),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rec.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Completed recently',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: const [
                Text(
                  'High Impact',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                ),
                SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up_rounded, size: 10, color: Color(0xFF10B981)),
                    SizedBox(width: 2),
                    Text(
                      '+15%',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
                Text(
                  'Conversion Rate',
                  style: TextStyle(fontSize: 7, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMomentumCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: Color(0xFF2563EB), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Keep the momentum going!',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                ),
                SizedBox(height: 2),
                Text(
                  'Here are your top opportunities to grow your business.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => setState(() => _selectedFilter = 'opportunity'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'See Opportunities',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios_rounded, size: 9, color: Color(0xFF2563EB)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline, size: 36, color: Color(0xFF2563EB)),
            ),
            const SizedBox(height: 10),
            const Text(
              'All caught up in this category!',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap "View Plan" in the header to generate new AI actions.',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
