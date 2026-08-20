import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../data/models/intelligence_model.dart';
import '../../data/models/recommendation_model.dart';
import '../../data/repositories/business_repository.dart';
import '../../data/repositories/recommendation_repository.dart';
import '../auth/auth_provider.dart';
import '../shared/optigo_top_bar.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToRecommendations;
  final VoidCallback? onNavigateToReviews;
  final Function(int)? onNavigateToTab;

  const HomeScreen({
    super.key,
    this.onNavigateToRecommendations,
    this.onNavigateToReviews,
    this.onNavigateToTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BusinessRepository? _bizRepo;
  RecommendationRepository? _recRepo;
  BusinessIntelligenceModel? _intelligence;
  List<RecommendationModel> _recommendations = [];
  bool _isLoadingIntel = true;
  bool _isLoadingRecs = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _bizRepo = context.read<BusinessRepository>();
      _recRepo = context.read<RecommendationRepository>();
      _initialized = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadIntelligence(),
      _loadRecommendations(),
    ]);
  }

  Future<void> _loadIntelligence() async {
    if (_bizRepo == null) return;
    final authProvider = context.read<AppAuthProvider>();
    final businessId = authProvider.currentBusiness?.id;
    if (businessId == null) return;

    setState(() => _isLoadingIntel = true);
    try {
      final data = await _bizRepo!.getIntelligence(businessId);
      if (mounted) {
        setState(() {
          _intelligence = BusinessIntelligenceModel.fromJson(data);
          _isLoadingIntel = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingIntel = false);
    }
  }

  Future<void> _loadRecommendations() async {
    if (_recRepo == null) return;
    final authProvider = context.read<AppAuthProvider>();
    final businessId = authProvider.currentBusiness?.id;
    if (businessId == null) return;

    setState(() => _isLoadingRecs = true);
    try {
      final list = await _recRepo!.getRecommendations(businessId);
      if (mounted) {
        setState(() {
          _recommendations = list;
          _isLoadingRecs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingRecs = false);
    }
  }

  Future<void> _handleUpdateStatus(RecommendationModel rec, String newStatus) async {
    final authProvider = context.read<AppAuthProvider>();
    final bizId = authProvider.currentBusiness?.id;
    if (bizId == null || _recRepo == null) return;

    try {
      await _recRepo!.updateStatus(rec.id, bizId, newStatus);
      _loadRecommendations();
    } catch (_) {}
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showComingSoonDialog(String featureName, String phaseNumber) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(OptigoTheme.radiusLG)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: OptigoTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(OptigoTheme.radiusMD),
              ),
              child: const Icon(Icons.auto_awesome, color: OptigoTheme.primary, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                featureName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This AI capability is scheduled for $phaseNumber of development.',
              style: const TextStyle(fontSize: 13, color: OptigoTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: OptigoTheme.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(OptigoTheme.radiusSM),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 16, color: OptigoTheme.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ready to be unlocked upon phase launch instruction.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: OptigoTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final user = authProvider.user;
    final business = authProvider.currentBusiness;

    final firstName = user?.fullName.split(' ').first ?? 'Naveen';
    final healthScore = _intelligence?.healthScore ?? 78;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF2563EB),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Universal Top App Bar Header
                OptigoTopBar(
                  onNotificationTap: widget.onNavigateToRecommendations,
                ),

                const SizedBox(height: 8),

                // 2. Greeting Header
                Text(
                  '${_getGreeting()}, $firstName! 👋',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  "Here's what's happening with your business today.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Active Business Selector Card
                _buildBusinessSelectorCard(business?.name, business?.location),

                const SizedBox(height: 16),

                // 4. Marketing Health Score Hero Card
                _buildMarketingHealthScoreCard(healthScore),

                const SizedBox(height: 22),

                // 5. Top Priority for You Section
                _buildTopPrioritySection(),

                const SizedBox(height: 22),

                // 6. Quick Actions Section
                _buildQuickActionsSection(),

                const SizedBox(height: 22),

                // 7. Other Opportunities Section
                _buildOtherOpportunitiesSection(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildBusinessSelectorCard(String? businessName, String? location) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Business Logo Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 44,
              height: 44,
              color: const Color(0xFFF1F5F9),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.storefront_rounded, color: Color(0xFF2563EB)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        businessName ?? "Naveen's Cafe",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  location ?? 'Kochi, Kerala',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Growing Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_up_rounded, size: 14, color: Color(0xFF10B981)),
                SizedBox(width: 4),
                Text(
                  'Growing',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketingHealthScoreCard(int score) {
    Color scoreColor = const Color(0xFF2563EB);
    String statusLabel = 'Good Standing';
    if (score >= 85) {
      scoreColor = const Color(0xFF10B981);
      statusLabel = 'Excellent Health';
    } else if (score < 60) {
      scoreColor = const Color(0xFFEF4444);
      statusLabel = 'Needs Attention';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
      child: Row(
        children: [
          // Circular Clean Progress Ring
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 54,
                height: 54,
                child: CircularProgressIndicator(
                  value: (score / 100).clamp(0.0, 1.0),
                  strokeWidth: 5.5,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '$score',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Title & Health Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: scoreColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (_isLoadingIntel)
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF2563EB)),
                      )
                    else
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: scoreColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Marketing Health Score',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // Direct Insights Action Pill
          InkWell(
            onTap: widget.onNavigateToRecommendations,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Insights',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                  ),
                  SizedBox(width: 3),
                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF2563EB)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPrioritySection() {
    final pending = _recommendations.where((r) => r.isPending).toList();

    // Prioritize urgent first, then important, then opportunity
    RecommendationModel? topRec;
    if (pending.isNotEmpty) {
      topRec = pending.firstWhere(
        (r) => r.isUrgent,
        orElse: () => pending.firstWhere(
          (r) => r.isImportant,
          orElse: () => pending.first,
        ),
      );
    }

    Color themeColor;
    String priorityTag;
    IconData leadingIcon;
    Color iconBg;

    if (topRec?.isUrgent == true) {
      themeColor = const Color(0xFFEF4444);
      priorityTag = 'URGENT';
      leadingIcon = Icons.emergency_rounded;
      iconBg = const Color(0xFFFEF2F2);
    } else if (topRec?.isOpportunity == true) {
      themeColor = const Color(0xFF10B981);
      priorityTag = 'OPPORTUNITY';
      leadingIcon = Icons.rocket_launch_rounded;
      iconBg = const Color(0xFFECFDF5);
    } else {
      themeColor = const Color(0xFFD97706);
      priorityTag = 'IMPORTANT';
      leadingIcon = Icons.bolt_rounded;
      iconBg = const Color(0xFFFFFBEB);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Top Priority for You',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            InkWell(
              onTap: widget.onNavigateToRecommendations,
              child: const Row(
                children: [
                  Text(
                    'View all',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF2563EB)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_isLoadingRecs)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
              ),
            ),
          )
        else if (topRec == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Caught Up! 🎉',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Your AI CMO marketing health is in great shape.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: topRec.isUrgent ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    color: themeColor,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: iconBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(leadingIcon, color: themeColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: iconBg,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: themeColor.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            priorityTag,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              color: themeColor,
                                            ),
                                          ),
                                        ),
                                        if (topRec.effort.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            '• ${topRec.effort}',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      topRec.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      topRec.explanation,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (topRec.impact.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.trending_up_rounded, size: 12, color: Color(0xFF2563EB)),
                                      const SizedBox(width: 4),
                                      Text(
                                        topRec.impact,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                                      ),
                                    ],
                                  ),
                                ),
                              const Spacer(),

                              TextButton(
                                onPressed: () => _handleUpdateStatus(topRec!, 'completed'),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor: const Color(0xFF64748B),
                                ),
                                child: const Text('Mark Done', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 6),

                              ElevatedButton(
                                onPressed: () {
                                  if (topRec!.relatedFeature == 'reviews' && widget.onNavigateToReviews != null) {
                                    widget.onNavigateToReviews!();
                                  } else if (topRec.relatedFeature == 'posts' && widget.onNavigateToTab != null) {
                                    widget.onNavigateToTab!(2);
                                  } else if (topRec.relatedFeature == 'seo' && widget.onNavigateToTab != null) {
                                    widget.onNavigateToTab!(3);
                                  } else if (widget.onNavigateToRecommendations != null) {
                                    widget.onNavigateToRecommendations!();
                                  }
                                },
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
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildQuickActionButton(
                icon: Icons.auto_awesome,
                label: 'Ask AI CMO',
                onTap: () {
                  if (widget.onNavigateToRecommendations != null) {
                    widget.onNavigateToRecommendations!();
                  }
                },
              ),
              const SizedBox(width: 10),
              _buildQuickActionButton(
                icon: Icons.edit_note_rounded,
                label: 'Create\nContent',
                onTap: () {
                  if (widget.onNavigateToTab != null) {
                    widget.onNavigateToTab!(2);
                  }
                },
              ),
              const SizedBox(width: 10),
              _buildQuickActionButton(
                icon: Icons.travel_explore_rounded,
                label: 'Optimize\nSEO',
                onTap: () {
                  if (widget.onNavigateToTab != null) {
                    widget.onNavigateToTab!(3);
                  }
                },
              ),
              const SizedBox(width: 10),
              _buildQuickActionButton(
                icon: Icons.campaign_outlined,
                label: 'Build\nCampaign',
                onTap: () => _showComingSoonDialog('AI Multi-Channel Campaigns', 'Phase 8'),
              ),
              const SizedBox(width: 10),
              _buildQuickActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Manage\nReviews',
                onTap: () {
                  if (widget.onNavigateToReviews != null) {
                    widget.onNavigateToReviews!();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 76,
        height: 84,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: const Color(0xFF2563EB)),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherOpportunitiesSection() {
    final pending = _recommendations.where((r) => r.isPending).toList();
    // Exclude the top priority card already displayed above
    final otherRecs = pending.length > 1 ? pending.sublist(1, pending.length > 4 ? 4 : pending.length) : <RecommendationModel>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Other Opportunities',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            InkWell(
              onTap: widget.onNavigateToRecommendations,
              child: const Row(
                children: [
                  Text(
                    'View all',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF2563EB)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (otherRecs.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.insights_rounded, color: Color(0xFF2563EB), size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'No additional pending actions. Tap "Ask AI CMO" to discover new growth opportunities.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                for (int i = 0; i < otherRecs.length; i++) ...[
                  _buildDynamicOpportunityRow(otherRecs[i]),
                  if (i < otherRecs.length - 1)
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDynamicOpportunityRow(RecommendationModel rec) {
    Color iconColor;
    Color iconBg;
    IconData icon;

    if (rec.isUrgent) {
      iconColor = const Color(0xFFEF4444);
      iconBg = const Color(0xFFFEF2F2);
      icon = Icons.emergency_rounded;
    } else if (rec.isOpportunity) {
      iconColor = const Color(0xFF10B981);
      iconBg = const Color(0xFFECFDF5);
      icon = Icons.rocket_launch_rounded;
    } else {
      iconColor = const Color(0xFFD97706);
      iconBg = const Color(0xFFFFFBEB);
      icon = Icons.bolt_rounded;
    }

    return InkWell(
      onTap: () {
        if (rec.relatedFeature == 'reviews' && widget.onNavigateToReviews != null) {
          widget.onNavigateToReviews!();
        } else if (rec.relatedFeature == 'posts' && widget.onNavigateToTab != null) {
          widget.onNavigateToTab!(2);
        } else if (rec.relatedFeature == 'seo' && widget.onNavigateToTab != null) {
          widget.onNavigateToTab!(3);
        } else if (widget.onNavigateToRecommendations != null) {
          widget.onNavigateToRecommendations!();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rec.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    rec.explanation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (rec.impact.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  rec.impact.length > 18 ? rec.impact.substring(0, 18) : rec.impact,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
