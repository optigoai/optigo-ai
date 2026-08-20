import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../data/models/intelligence_model.dart';
import '../../data/repositories/business_repository.dart';
import '../auth/auth_provider.dart';
import '../shared/optigo_top_bar.dart';
import 'widgets/gauge_wave_painter.dart';

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
  BusinessIntelligenceModel? _intelligence;
  bool _isLoadingIntel = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _bizRepo = context.read<BusinessRepository>();
      _initialized = true;
      _loadIntelligence();
    }
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
          onRefresh: _loadIntelligence,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              const Text(
                'Marketing Health Score',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF94A3B8)),
              const Spacer(),
              if (_isLoadingIntel)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Score and Semicircle Gauge Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Numeric Score & Quality assessment
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$score',
                            style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -1,
                            ),
                          ),
                          const TextSpan(
                            text: ' /100',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Good',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "You're doing well! Let's make it excellent.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Right: Arc Gauge with Sparkline Wave
              Expanded(
                flex: 5,
                child: SizedBox(
                  height: 95,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(130, 85),
                        painter: GaugeWavePainter(
                          score: score.toDouble(),
                          trackColor: const Color(0xFFE2E8F0),
                          progressColor: const Color(0xFF2563EB),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 12,
                        child: const Text('0', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 12,
                        child: const Text('100', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Bottom Inside Banner: Score Improvement Pill
          InkWell(
            onTap: widget.onNavigateToRecommendations,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your score improved by 12 points',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'Keep following the recommendations!',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF2563EB)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPrioritySection() {
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

        // Hero Priority Card with Left Red Accent
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
                // Left Coral/Red Accent Bar
                Container(
                  width: 4,
                  color: const Color(0xFFEF4444),
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
                            // Icon with Badge
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF2563EB), size: 20),
                                ),
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                    child: const Center(
                                      child: Text(
                                        '3',
                                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Respond to 3 unhappy reviews',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Unanswered negative reviews can hurt your reputation and trust.',
                                    style: TextStyle(
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
                            // Impact Tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.trending_up_rounded, size: 12, color: Color(0xFF2563EB)),
                                  SizedBox(width: 4),
                                  Text(
                                    'High impact • Takes 5 min',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),

                            // Take Action Button
                            ElevatedButton(
                              onPressed: widget.onNavigateToReviews,
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
                icon: Icons.campaign_outlined,
                label: 'Build\nCampaign',
                onTap: () => _showComingSoonDialog('AI Multi-Channel Campaigns', 'Phase 8'),
              ),
              const SizedBox(width: 10),
              _buildQuickActionButton(
                icon: Icons.analytics_outlined,
                label: 'View\nAnalytics',
                onTap: () => _showComingSoonDialog('Advanced ROI Analytics', 'Phase 10'),
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

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _buildOpportunityRow(
                icon: Icons.manage_search_rounded,
                iconColor: const Color(0xFF10B981),
                iconBg: const Color(0xFFECFDF5),
                title: 'Improve Local SEO',
                subtitle: 'Rank higher for 5 important keywords',
                tagText: 'High Impact',
                tagBg: const Color(0xFFECFDF5),
                tagColor: const Color(0xFF10B981),
                onTap: () => _showComingSoonDialog('Local SEO & Keyword Ranking', 'Phase 7'),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              _buildOpportunityRow(
                icon: Icons.description_outlined,
                iconColor: const Color(0xFFA855F7),
                iconBg: const Color(0xFFFAF5FF),
                title: 'Post on Google',
                subtitle: "You haven't posted in 12 days",
                tagText: 'Medium Impact',
                tagBg: const Color(0xFFFEF3C7),
                tagColor: const Color(0xFFD97706),
                onTap: () => _showComingSoonDialog('Automated Google Business Posts', 'Phase 6'),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              _buildOpportunityRow(
                icon: Icons.group_outlined,
                iconColor: const Color(0xFF38BDF8),
                iconBg: const Color(0xFFF0F9FF),
                title: 'Check Competitors',
                subtitle: 'See what your competitors are doing',
                tagText: 'Low Impact',
                tagBg: const Color(0xFFEFF6FF),
                tagColor: const Color(0xFF2563EB),
                onTap: () => _showComingSoonDialog('Competitor Benchmarking Engine', 'Phase 9'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOpportunityRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String tagText,
    required Color tagBg,
    required Color tagColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
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
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: tagBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tagText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: tagColor,
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
