import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

    try {
      final data = await _bizRepo!.getIntelligence(businessId);
      if (mounted) {
        setState(() {
          _intelligence = BusinessIntelligenceModel.fromJson(data);
        });
      }
    } catch (_) {}
  }

  Future<void> _loadRecommendations() async {
    if (_recRepo == null) return;
    final authProvider = context.read<AppAuthProvider>();
    final businessId = authProvider.currentBusiness?.id;
    if (businessId == null) return;

    try {
      final list = await _recRepo!.getRecommendations(businessId);
      if (mounted) {
        setState(() {
          _recommendations = list;
        });
      }
    } catch (_) {}
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


  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final user = authProvider.user;
    final business = authProvider.currentBusiness;

    final firstName = user?.fullName.isNotEmpty == true
        ? user!.fullName.split(' ').first
        : 'Naveen';
    final healthScore = _intelligence?.healthScore ?? 78;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF2563EB),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Universal Top App Bar Header (Brand Logo image without text)
                OptigoTopBar(
                  onNotificationTap: widget.onNavigateToRecommendations,
                ),

                const SizedBox(height: 14),

                // 2. Greeting Header
                Text(
                  '${_getGreeting()}, $firstName! 👋',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Here's what's happening with your business today.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 20),

                // 3. Active Business Storefront Selector Card
                _buildBusinessSelectorCard(business?.name, business?.location),

                const SizedBox(height: 24),

                // 4. Marketing Health Dual-Section Card (Gauge + Graph + 3 Mini Stats)
                _buildMarketingHealthCard(healthScore),

                const SizedBox(height: 24),

                // 5. Weekly Customer Activity Bar Chart (Inspired by reference design)
                _buildWeeklyActivitySection(),

                const SizedBox(height: 28),

                // 6. Top Priority Action Card
                _buildTopPrioritySection(),

                const SizedBox(height: 28),

                // 7. Quick Actions Section
                _buildQuickActionsSection(),

                const SizedBox(height: 28),

                // 8. Growth Opportunities & Recent Activity Section
                _buildGrowthOpportunitiesSection(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 3. Business Selector Card
  // ==========================================
  Widget _buildBusinessSelectorCard(String? name, String? location) {
    final displayName = (name ?? 'Panekkatt Oil & Flour Mill').toUpperCase();
    final displayLocation = location ?? 'Ponnani';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.storefront_rounded, color: Color(0xFF2563EB), size: 24),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 3),
                    Text(
                      displayLocation,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
                    fontWeight: FontWeight.w800,
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

  // ==========================================
  // 4. Marketing Health Card (Gauge + Graph)
  // ==========================================
  Widget _buildMarketingHealthCard(int score) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          const Text(
            'Marketing Health',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Semi-Circle Gauge Arc & Status
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    SizedBox(
                      width: 130,
                      height: 80,
                      child: CustomPaint(
                        painter: _SemiCircleGaugePainter(score: score),
                        child: Align(
                          alignment: const Alignment(0, 0.4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$score',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                  height: 1.0,
                                ),
                              ),
                              const Text(
                                '/100',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Good Standing Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Good Standing',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.thumb_up_rounded, size: 12, color: Color(0xFF2563EB)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Vertical subtle divider
              Container(
                width: 1,
                height: 120,
                color: const Color(0xFFF1F5F9),
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),

              // Right: Trend Sparkline Graph & 3 Mini Stats
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    // Sparkline Chart
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _SparklineChartPainter(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 3 Mini Stats Columns
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildHealthMiniMetric(
                          icon: Icons.visibility_outlined,
                          iconBg: const Color(0xFFEFF6FF),
                          iconColor: const Color(0xFF2563EB),
                          value: '1.2K',
                          label: 'Profile Views',
                          trend: '▲ 18%',
                        ),
                        _buildHealthMiniMetric(
                          icon: Icons.phone_outlined,
                          iconBg: const Color(0xFFECFDF5),
                          iconColor: const Color(0xFF10B981),
                          value: '321',
                          label: 'Calls',
                          trend: '▲ 24%',
                        ),
                        _buildHealthMiniMetric(
                          icon: Icons.alt_route_rounded,
                          iconBg: const Color(0xFFF5F3FF),
                          iconColor: const Color(0xFF8B5CF6),
                          value: '210',
                          label: 'Direction Req.',
                          trend: '▲ 15%',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Phase 11: Real-Time ROI & Customer Lead Attribution Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.currency_exchange_rounded, size: 16, color: Color(0xFF16A34A)),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Est. Monthly Impact', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                        Text('\$23,895 / mo', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.trending_up_rounded, size: 14, color: Color(0xFF2563EB)),
                      SizedBox(width: 4),
                      Text('4.2x ROI', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMiniMetric({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
    required String trend,
  }) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(icon, size: 16, color: iconColor),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          trend,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
        ),
      ],
    );
  }

  // ==========================================
  // 5. Weekly Customer Activity Bar Chart
  // ==========================================
  Widget _buildWeeklyActivitySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Weekly Customer Activity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Profile interactions & customer calls',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up_rounded, size: 14, color: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Text(
                      '+24%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 7-Day Interactive Styled Bar Chart with Active Tooltip (Wednesday peak)
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CustomPaint(
              painter: _WeeklyBarChartPainter(),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 6. Top Priority Action Card
  // ==========================================
  Widget _buildTopPrioritySection() {
    final pendingRecs = _recommendations.where((r) => r.isPending).toList();
    RecommendationModel? topRec;
    if (pendingRecs.isNotEmpty) {
      topRec = pendingRecs.firstWhere(
        (r) => r.isUrgent,
        orElse: () => pendingRecs.first,
      );
    }

    final title = topRec?.title ?? 'Reply to 6 unanswered reviews';
    final desc = topRec?.explanation ??
        'Customers are waiting for your response. This can directly impact your reputation.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Top Priority',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            InkWell(
              onTap: widget.onNavigateToRecommendations,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFEE2E2), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Red Rounded Box with Message Icon and Badge Count
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFFEF4444), size: 24),
                        ),
                      ),
                      Positioned(
                        top: -3,
                        right: -3,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFDC2626),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: const Center(
                            child: Text(
                              '6',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Title, URGENT badge & explanation
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'URGENT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFDC2626),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          desc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Action Buttons Row (Take Action + Mark Done)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (topRec?.relatedFeature == 'reviews' && widget.onNavigateToReviews != null) {
                          widget.onNavigateToReviews!();
                        } else if (topRec?.relatedFeature == 'posts' && widget.onNavigateToTab != null) {
                          widget.onNavigateToTab!(2);
                        } else if (topRec?.relatedFeature == 'seo' && widget.onNavigateToTab != null) {
                          widget.onNavigateToTab!(3);
                        } else if (widget.onNavigateToReviews != null) {
                          widget.onNavigateToReviews!();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Take Action',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: topRec != null
                          ? () => _handleUpdateStatus(topRec!, 'completed')
                          : () {},
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF475569)),
                      label: const Text(
                        'Mark Done',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 6. Quick Actions Section
  // ==========================================
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 14),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildQuickActionItem(
                icon: Icons.auto_awesome,
                iconColor: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
                label: 'Today\'s\nActions',
                onTap: () {
                  if (widget.onNavigateToRecommendations != null) {
                    widget.onNavigateToRecommendations!();
                  }
                },
              ),
              const SizedBox(width: 12),
              _buildQuickActionItem(
                icon: Icons.edit_note_rounded,
                iconColor: const Color(0xFF8B5CF6),
                bgColor: const Color(0xFFF5F3FF),
                label: 'Create\nContent',
                onTap: () {
                  if (widget.onNavigateToTab != null) {
                    widget.onNavigateToTab!(2);
                  }
                },
              ),
              const SizedBox(width: 12),
              _buildQuickActionItem(
                icon: Icons.travel_explore_rounded,
                iconColor: const Color(0xFF10B981),
                bgColor: const Color(0xFFECFDF5),
                label: 'Optimize\nSEO',
                onTap: () {
                  if (widget.onNavigateToTab != null) {
                    widget.onNavigateToTab!(3);
                  }
                },
              ),
              const SizedBox(width: 12),
              _buildQuickActionItem(
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: const Color(0xFF0EA5E9),
                bgColor: const Color(0xFFE0F2FE),
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

  Widget _buildQuickActionItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 90,
        height: 96,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(icon, size: 22, color: iconColor),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 7. Growth Opportunities Section
  // ==========================================
  Widget _buildGrowthOpportunitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Growth Opportunities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            InkWell(
              onTap: widget.onNavigateToRecommendations,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildGrowthCard(
                icon: Icons.bolt_rounded,
                iconColor: const Color(0xFFD97706),
                iconBg: const Color(0xFFFEF3C7),
                title: 'Improve Local SEO',
                impactTag: 'Medium Impact',
                impactColor: const Color(0xFFD97706),
                impactBg: const Color(0xFFFEF3C7),
                highlight: 'Boost visibility',
                subtitle: 'Rank higher on Maps',
                onTap: () {
                  if (widget.onNavigateToTab != null) {
                    widget.onNavigateToTab!(3);
                  }
                },
              ),
              const SizedBox(width: 14),
              _buildGrowthCard(
                icon: Icons.article_outlined,
                iconColor: const Color(0xFF10B981),
                iconBg: const Color(0xFFECFDF5),
                title: 'Post Regular Updates',
                impactTag: 'Low Effort',
                impactColor: const Color(0xFF10B981),
                impactBg: const Color(0xFFECFDF5),
                highlight: 'Stay active',
                subtitle: 'Engage customers',
                onTap: () {
                  if (widget.onNavigateToTab != null) {
                    widget.onNavigateToTab!(2);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Recent Activity Stream (Inspired by reference design screen 3)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Activity & Updates',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              _buildActivityRow(
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFF59E0B),
                iconBg: const Color(0xFFFEF3C7),
                title: 'New 5-Star Google Review',
                subtitle: 'Aarav Sharma • 2h ago',
                badgeText: 'Replied',
                badgeColor: const Color(0xFF10B981),
                badgeBg: const Color(0xFFECFDF5),
              ),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              _buildActivityRow(
                icon: Icons.search_rounded,
                iconColor: const Color(0xFF2563EB),
                iconBg: const Color(0xFFEFF6FF),
                title: '"cold pressed oil near me"',
                subtitle: 'Ranked #2 on Google Maps',
                badgeText: '+3 Ranks',
                badgeColor: const Color(0xFF2563EB),
                badgeBg: const Color(0xFFEFF6FF),
              ),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              _buildActivityRow(
                icon: Icons.edit_note_rounded,
                iconColor: const Color(0xFF8B5CF6),
                iconBg: const Color(0xFFF5F3FF),
                title: 'Multi-Channel Promo Draft',
                subtitle: 'Instagram & Facebook post ready',
                badgeText: 'Draft',
                badgeColor: const Color(0xFF8B5CF6),
                badgeBg: const Color(0xFFF5F3FF),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBg,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(icon, size: 18, color: iconColor),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
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
            color: badgeBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            badgeText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: badgeColor,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildGrowthCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String impactTag,
    required Color impactColor,
    required Color impactBg,
    required String highlight,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: impactBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                impactTag,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: impactColor,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Text(
              highlight,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: impactColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// Custom Painter for Semi-Circle Gauge Arc
// ==========================================
class _SemiCircleGaugePainter extends CustomPainter {
  final int score;

  _SemiCircleGaugePainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 8;

    // Background track arc
    final bgPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      bgPaint,
    );

    // Active progress arc
    final progress = (score / 100).clamp(0.0, 1.0);
    final sweepAngle = pi * progress;

    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      sweepAngle,
      false,
      progressPaint,
    );

    // End indicator dot
    final endAngle = pi + sweepAngle;
    final dotX = center.dx + radius * cos(endAngle);
    final dotY = center.dy + radius * sin(endAngle);

    final dotOuterPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(dotX, dotY), 6.0, dotOuterPaint);

    final dotInnerPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(dotX, dotY), 4.0, dotInnerPaint);
  }

  @override
  bool shouldRepaint(covariant _SemiCircleGaugePainter oldDelegate) {
    return oldDelegate.score != score;
  }
}

// ==========================================
// Custom Painter for Sparkline Trend Chart
// ==========================================
class _SparklineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.12, size.height * 0.55),
      Offset(size.width * 0.25, size.height * 0.65),
      Offset(size.width * 0.38, size.height * 0.45),
      Offset(size.width * 0.50, size.height * 0.60),
      Offset(size.width * 0.62, size.height * 0.50),
      Offset(size.width * 0.75, size.height * 0.70),
      Offset(size.width * 0.88, size.height * 0.35),
      Offset(size.width * 1.0, size.height * 0.15),
    ];

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    // Draw shaded gradient underneath
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF2563EB).withValues(alpha: 0.12),
          const Color(0xFF2563EB).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Draw main stroke line
    final linePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // Endpoint Glowing Dot
    final lastPoint = points.last;
    final outerDot = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(lastPoint, 6.0, outerDot);

    final innerDot = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(lastPoint, 3.5, innerDot);

    final centerDot = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(lastPoint, 1.5, centerDot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==========================================
// Custom Painter for 7-Day Weekly Bar Chart
// Inspired by reference UI with active tooltip
// ==========================================
class _WeeklyBarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const values = [0.45, 0.60, 0.92, 0.68, 0.78, 0.55, 0.38];
    const activeIndex = 2; // Wednesday peak

    final barWidth = (size.width / 7) - 14;
    final maxBarHeight = size.height - 48; // room for tooltip and day label

    for (int i = 0; i < 7; i++) {
      final xCenter = (size.width / 7) * i + (size.width / 14);
      final left = xCenter - (barWidth / 2);
      final top = 32.0;
      final height = maxBarHeight;

      final isSelected = i == activeIndex;

      // 1. Draw Background Track Bar
      final trackPaint = Paint()
        ..color = const Color(0xFFF1F5F9)
        ..style = PaintingStyle.fill;
      final trackRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, height),
        const Radius.circular(8),
      );
      canvas.drawRRect(trackRect, trackPaint);

      // 2. Draw Active Filled Value Bar
      final filledHeight = height * values[i];
      final filledTop = top + (height - filledHeight);

      final fillPaint = Paint()
        ..color = isSelected ? const Color(0xFF2563EB) : const Color(0xFFBFDBFE)
        ..style = PaintingStyle.fill;

      final fillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, filledTop, barWidth, filledHeight),
        const Radius.circular(8),
      );
      canvas.drawRRect(fillRect, fillPaint);

      // 3. Draw Active Floating Tooltip on Highlighted Bar
      if (isSelected) {
        // Tooltip container box
        const tooltipWidth = 72.0;
        const tooltipHeight = 22.0;
        final tooltipLeft = xCenter - (tooltipWidth / 2);
        final tooltipTop = filledTop - tooltipHeight - 6;

        final tooltipBgPaint = Paint()
          ..color = const Color(0xFF0F172A)
          ..style = PaintingStyle.fill;

        final tooltipRRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(tooltipLeft, tooltipTop, tooltipWidth, tooltipHeight),
          const Radius.circular(6),
        );
        canvas.drawRRect(tooltipRRect, tooltipBgPaint);

        // Tooltip downward pointer triangle
        final pointerPath = Path()
          ..moveTo(xCenter - 4, tooltipTop + tooltipHeight)
          ..lineTo(xCenter + 4, tooltipTop + tooltipHeight)
          ..lineTo(xCenter, tooltipTop + tooltipHeight + 4)
          ..close();
        canvas.drawPath(pointerPath, tooltipBgPaint);

        // Tooltip Text
        const textSpan = TextSpan(
          text: '340 views',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            fontFamily: 'Inter',
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(xCenter - (textPainter.width / 2), tooltipTop + 4),
        );
      }

      // 4. Draw Day of Week Label below bar
      final daySpan = TextSpan(
        text: days[i],
        style: TextStyle(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          fontFamily: 'Inter',
        ),
      );
      final dayPainter = TextPainter(
        text: daySpan,
        textDirection: TextDirection.ltr,
      )..layout();
      dayPainter.paint(
        canvas,
        Offset(xCenter - (dayPainter.width / 2), top + height + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

