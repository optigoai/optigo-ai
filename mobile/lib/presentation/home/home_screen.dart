import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../data/models/intelligence_model.dart';
import '../../data/repositories/business_repository.dart';
import '../auth/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToReviews;

  const HomeScreen({super.key, this.onNavigateToReviews});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BusinessRepository? _bizRepo;
  BusinessIntelligenceModel? _intelligence;
  bool _isLoadingIntel = true;
  bool _isAnalyzing = false;
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

  Future<void> _handleRunAnalysis() async {
    if (_bizRepo == null) return;
    final authProvider = context.read<AppAuthProvider>();
    final businessId = authProvider.currentBusiness?.id;
    if (businessId == null) return;

    setState(() => _isAnalyzing = true);
    try {
      final data = await _bizRepo!.analyzeBusiness(businessId);
      if (mounted) {
        setState(() {
          _intelligence = BusinessIntelligenceModel.fromJson(data);
          _isAnalyzing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI Marketing Health Audit completed!'),
            backgroundColor: OptigoTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e'), backgroundColor: OptigoTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final user = authProvider.user;
    final business = authProvider.currentBusiness;

    return Scaffold(
      backgroundColor: OptigoTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadIntelligence,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(OptigoTheme.spacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top App Bar
                Row(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: OptigoTheme.spacingSM + 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            business?.name ?? 'OptigoAI Business',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: OptigoTheme.textPrimary,
                              letterSpacing: -0.4,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user != null ? '${user.fullName} • ${user.role.toUpperCase()}' : 'Business Owner',
                            style: const TextStyle(
                              fontSize: 12,
                              color: OptigoTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_outlined, size: 22),
                      color: OptigoTheme.textSecondary,
                      onPressed: () => context.read<AppAuthProvider>().logout(),
                      tooltip: 'Log out',
                    ),
                  ],
                ),

                const SizedBox(height: OptigoTheme.spacingMD),

                // AI Marketing Health Score Card
                _buildHealthScoreCard(),

                const SizedBox(height: OptigoTheme.spacingLG),

                // Critical Problems Detected
                if (_intelligence != null) ...[
                  _buildProblemsSection(),
                  const SizedBox(height: OptigoTheme.spacingLG),
                  _buildOpportunitiesSection(),
                  const SizedBox(height: OptigoTheme.spacingLG),
                  _buildAIBusinessProfileSection(),
                  const SizedBox(height: OptigoTheme.spacingLG),
                ],

                // Quick Reviews Shortcut Banner
                if (widget.onNavigateToReviews != null)
                  InkWell(
                    onTap: widget.onNavigateToReviews,
                    borderRadius: BorderRadius.circular(OptigoTheme.radiusMD),
                    child: Container(
                      padding: const EdgeInsets.all(OptigoTheme.spacingMD),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(OptigoTheme.radiusMD),
                        border: Border.all(color: OptigoTheme.primary.withValues(alpha: 0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: OptigoTheme.primary.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: OptigoTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(OptigoTheme.radiusSM),
                            ),
                            child: const Icon(Icons.rate_review_rounded, color: OptigoTheme.primary, size: 20),
                          ),
                          const SizedBox(width: OptigoTheme.spacingMD),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Manage Customer Reviews',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: OptigoTheme.textPrimary),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'View Google rating, filter sentiment & draft replies',
                                  style: TextStyle(fontSize: 11, color: OptigoTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: OptigoTheme.primary),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: OptigoTheme.spacingXL),
                Center(
                  child: Text(
                    'OptigoAI CMO Intelligence • Phase 4 Live',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: OptigoTheme.spacingMD),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHealthScoreCard() {
    final intel = _intelligence;
    final score = intel?.healthScore ?? 78;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(OptigoTheme.spacingLG),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [OptigoTheme.primary, OptigoTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(OptigoTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: OptigoTheme.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Radial Health Score Gauge
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: OptigoTheme.primary,
                        ),
                      ),
                      const Text(
                        'HEALTH',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: OptigoTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: OptigoTheme.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'AI CMO Health Score',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (_isLoadingIntel) ...[
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(OptigoTheme.radiusSM),
                      ),
                      child: Text(
                        'Reputation: ${intel?.reputationScore ?? 82}%  •  Visibility: ${intel?.visibilityScore ?? 74}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: OptigoTheme.spacingMD),
          Text(
            intel?.healthSummary ??
                'Your business has strong customer satisfaction signals but suffers from visibility drop-off and unanswered customer reviews.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: OptigoTheme.spacingMD),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _handleRunAnalysis,
              icon: _isAnalyzing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: OptigoTheme.primary),
                    )
                  : const Icon(Icons.auto_awesome, size: 16, color: OptigoTheme.primary),
              label: Text(
                _isAnalyzing ? 'Analyzing Business with Gemini AI...' : 'Re-Run AI Marketing Audit',
                style: const TextStyle(
                  color: OptigoTheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(OptigoTheme.radiusMD)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemsSection() {
    final problems = _intelligence?.topProblems ?? [];
    if (problems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 22, color: OptigoTheme.error),
            const SizedBox(width: 8),
            Text(
              'Critical Problems Detected (${problems.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: OptigoTheme.error,
                    letterSpacing: -0.5,
                  ),
            ),
          ],
        ),
        const SizedBox(height: OptigoTheme.spacingMD),
        ...problems.map((p) => Container(
              margin: const EdgeInsets.only(bottom: OptigoTheme.spacingMD),
              padding: const EdgeInsets.all(OptigoTheme.spacingMD),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(OptigoTheme.radiusMD),
                border: Border.all(color: OptigoTheme.error.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: OptigoTheme.error.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: OptigoTheme.error,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: OptigoTheme.spacingMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: OptigoTheme.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: OptigoTheme.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(OptigoTheme.radiusSM),
                                ),
                                child: Text(
                                  p.severity.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: OptigoTheme.error,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            p.explanation,
                            style: const TextStyle(
                              fontSize: 13,
                              color: OptigoTheme.textSecondary,
                              height: 1.4,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          if (p.impact.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: OptigoTheme.surfaceVariant.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(OptigoTheme.radiusSM),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.info_outline_rounded, size: 14, color: OptigoTheme.error),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(fontSize: 12, color: OptigoTheme.textPrimary, height: 1.3),
                                        children: [
                                          const TextSpan(text: 'Impact: ', style: TextStyle(fontWeight: FontWeight.w800)),
                                          TextSpan(text: p.impact, style: const TextStyle(fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildOpportunitiesSection() {
    final opportunities = _intelligence?.topOpportunities ?? [];
    if (opportunities.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.rocket_launch_rounded, size: 22, color: OptigoTheme.success),
            const SizedBox(width: 8),
            Text(
              'High-Impact Opportunities (${opportunities.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: OptigoTheme.success,
                    letterSpacing: -0.5,
                  ),
            ),
          ],
        ),
        const SizedBox(height: OptigoTheme.spacingMD),
        ...opportunities.map((o) => Container(
              margin: const EdgeInsets.only(bottom: OptigoTheme.spacingMD),
              padding: const EdgeInsets.all(OptigoTheme.spacingMD),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(OptigoTheme.radiusMD),
                border: Border.all(color: OptigoTheme.success.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: OptigoTheme.success.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: OptigoTheme.success,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: OptigoTheme.spacingMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  o.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: OptigoTheme.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: OptigoTheme.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(OptigoTheme.radiusSM),
                                ),
                                child: Text(
                                  '${o.priority.toUpperCase()} IMPACT',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: OptigoTheme.success,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            o.suggestedAction,
                            style: const TextStyle(
                              fontSize: 13,
                              color: OptigoTheme.textSecondary,
                              height: 1.4,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          if (o.potentialImpact.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: OptigoTheme.success.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(OptigoTheme.radiusSM),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.auto_awesome_rounded, size: 14, color: OptigoTheme.success),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(fontSize: 12, color: OptigoTheme.textPrimary, height: 1.3),
                                        children: [
                                          const TextSpan(text: 'Potential: ', style: TextStyle(fontWeight: FontWeight.w800, color: OptigoTheme.success)),
                                          TextSpan(text: o.potentialImpact, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildAIBusinessProfileSection() {
    final profile = _intelligence?.aiProfile;
    if (profile == null) return const SizedBox.shrink();

    final summary = profile['business_summary'] as String? ?? '';
    final brandTone = profile['brand_tone'] as String? ?? '';
    final growthAreas = (profile['initial_growth_areas'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(OptigoTheme.spacingMD),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(OptigoTheme.radiusMD),
        border: Border.all(color: OptigoTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_outlined, color: OptigoTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Business Understanding',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
              ),
            ],
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              summary,
              style: const TextStyle(fontSize: 13, color: OptigoTheme.textSecondary, height: 1.4),
            ),
          ],
          if (brandTone.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Brand Tone: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                Text(brandTone, style: const TextStyle(fontSize: 12, color: OptigoTheme.primary, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
          if (growthAreas.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Strategic Growth Levers:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            ...growthAreas.map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: OptigoTheme.primary, fontWeight: FontWeight.w800)),
                      Expanded(
                        child: Text(g, style: const TextStyle(fontSize: 12, color: OptigoTheme.textSecondary, height: 1.3)),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
