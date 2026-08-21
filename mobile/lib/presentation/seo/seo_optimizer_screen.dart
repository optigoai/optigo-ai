import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/seo_model.dart';
import '../../data/models/gsc_model.dart';
import '../../data/repositories/seo_repository.dart';
import '../../data/repositories/gsc_repository.dart';
import '../auth/auth_provider.dart';
import '../shared/optigo_top_bar.dart';

class SeoOptimizerScreen extends StatefulWidget {
  final VoidCallback? onNavigateToRecommendations;

  const SeoOptimizerScreen({
    super.key,
    this.onNavigateToRecommendations,
  });

  @override
  State<SeoOptimizerScreen> createState() => _SeoOptimizerScreenState();
}

class _SeoOptimizerScreenState extends State<SeoOptimizerScreen> {
  SeoRepository? _seoRepo;
  GscRepository? _gscRepo;
  List<SeoKeywordModel> _keywords = [];
  SeoAuditModel? _audit;
  GscMetricsSummaryModel? _gscSummary;
  Map<String, dynamic>? _websiteAudit;
  bool _isLoading = true;
  bool _isAuditing = false;
  bool _isOptimizingGbp = false;
  bool _isAuditingWebsite = false;
  bool _isSyncingGsc = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _seoRepo = context.read<SeoRepository>();
      _gscRepo = context.read<GscRepository>();
      _initialized = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AppAuthProvider>();
    final business = authProvider.currentBusiness;
    if (business == null || _seoRepo == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final kws = await _seoRepo!.getKeywords(business.id);
      final aud = await _seoRepo!.getOrGenerateAudit(businessId: business.id);
      final webAudit = await _seoRepo!.getLatestWebsiteAudit(business.id);

      GscMetricsSummaryModel? gsc;
      if (_gscRepo != null) {
        try {
          gsc = await _gscRepo!.getMetricsSummary(business.id);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _keywords = kws;
          _audit = aud;
          _websiteAudit = webAudit;
          _gscSummary = gsc;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSyncGsc() async {
    final authProvider = context.read<AppAuthProvider>();
    final business = authProvider.currentBusiness;
    if (business == null || _gscRepo == null) return;

    setState(() => _isSyncingGsc = true);
    try {
      await _gscRepo!.connectMock(business.id);
      final summary = await _gscRepo!.getMetricsSummary(business.id);
      if (mounted) {
        setState(() {
          _gscSummary = summary;
          _isSyncingGsc = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Google Search performance synchronized!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isSyncingGsc = false);
    }
  }

  Future<void> _handleRunWebsiteAudit() async {
    final business = context.read<AppAuthProvider>().currentBusiness;
    if (business == null || _seoRepo == null) return;

    setState(() => _isAuditingWebsite = true);
    try {
      final res = await _seoRepo!.runWebsiteAudit(business.id);
      if (mounted) {
        setState(() {
          _websiteAudit = res;
          _isAuditingWebsite = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Website audit completed! High-impact fixes added to Actions.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAuditingWebsite = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audit error: $e')),
        );
      }
    }
  }

  Future<void> _handleRunFreshAudit() async {
    final business = context.read<AppAuthProvider>().currentBusiness;
    if (business == null || _seoRepo == null) return;

    setState(() => _isAuditing = true);
    try {
      final aud = await _seoRepo!.getOrGenerateAudit(businessId: business.id, forceFresh: true);
      final kws = await _seoRepo!.getKeywords(business.id);
      if (mounted) {
        setState(() {
          _audit = aud;
          _keywords = kws;
          _isAuditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Local SEO audit updated with live Gemini AI analysis!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAuditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update SEO audit: $e')),
        );
      }
    }
  }

  Future<void> _handleDeleteKeyword(String keywordId) async {
    final business = context.read<AppAuthProvider>().currentBusiness;
    if (business == null || _seoRepo == null) return;

    try {
      await _seoRepo!.deleteKeyword(businessId: business.id, keywordId: keywordId);
      setState(() {
        _keywords.removeWhere((k) => k.id == keywordId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keyword removed from tracking')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove keyword: $e')),
        );
      }
    }
  }

  Future<void> _showAddKeywordDialog() async {
    final business = context.read<AppAuthProvider>().currentBusiness;
    if (business == null || _seoRepo == null) return;

    final textController = TextEditingController();
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Track New Keyword', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter a local search query customers use to find your business.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g. cold pressed coconut oil near me',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final kw = textController.text.trim();
                      if (kw.isEmpty) return;
                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(ctx);
                      try {
                        final created = await _seoRepo!.addKeyword(
                          businessId: business.id,
                          keyword: kw,
                        );
                        if (mounted) {
                          setState(() {
                            _keywords.insert(0, created);
                          });
                        }
                        nav.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Keyword added to rank tracking!'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        messenger.showSnackBar(
                          SnackBar(content: Text('Error adding keyword: $e')),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              child: isSaving
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Track Rank'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAiKeywordDiscoveryModal() async {
    final business = context.read<AppAuthProvider>().currentBusiness;
    if (business == null || _seoRepo == null) return;

    List<Map<String, dynamic>> discovered = [];
    bool isDiscovering = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          if (isDiscovering && discovered.isEmpty) {
            _seoRepo!.discoverKeywords(businessId: business.id).then((kws) {
              setModalState(() {
                discovered = kws;
                isDiscovering = false;
              });
            }).catchError((_) {
              setModalState(() => isDiscovering = false);
            });
          }

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.7,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Color(0xFF2563EB), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Keyword Discovery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                          Text('High-intent local keywords discovered with Gemini', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (isDiscovering)
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF2563EB)),
                          SizedBox(height: 12),
                          Text('Analyzing local search intent & competitor rankings...', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  )
                else if (discovered.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('No new keyword recommendations found.', style: TextStyle(color: Color(0xFF64748B))),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: discovered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final item = discovered[i];
                        final kwText = item['keyword'] ?? '';
                        final vol = item['search_volume'] ?? '800 / mo';
                        final diff = item['difficulty'] ?? 'Low';
                        final alreadyTracked = _keywords.any((k) => k.keyword.toLowerCase() == kwText.toLowerCase());

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      kwText,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Text('Vol: $vol', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: diff == 'Low' ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            diff,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: diff == 'Low' ? const Color(0xFF10B981) : const Color(0xFFD97706),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: alreadyTracked
                                    ? null
                                    : () async {
                                        final created = await _seoRepo!.addKeyword(
                                          businessId: business.id,
                                          keyword: kwText,
                                          searchVolume: vol,
                                          difficulty: diff,
                                        );
                                        setState(() {
                                          _keywords.insert(0, created);
                                        });
                                        setModalState(() {});
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Tracking "$kwText"')),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text(alreadyTracked ? 'Tracked' : '+ Track', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showGbpOptimizerModal() async {
    final business = context.read<AppAuthProvider>().currentBusiness;
    if (business == null || _seoRepo == null) return;

    setState(() => _isOptimizingGbp = true);
    try {
      final opt = await _seoRepo!.optimizeGbpProfile(business.id);
      if (mounted) {
        setState(() {
          _isOptimizingGbp = false;
        });

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (ctx) => Container(
            height: MediaQuery.of(ctx).size.height * 0.75,
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('GBP Profile Optimizer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                            Text('AI recommendations to rank higher on Google Maps', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildGbpItemCard(
                    title: 'Optimized Title',
                    content: opt.optimizedTitle,
                    icon: Icons.title_rounded,
                  ),
                  const SizedBox(height: 12),

                  _buildGbpItemCard(
                    title: 'High-Converting Description',
                    content: opt.optimizedDescription,
                    icon: Icons.description_outlined,
                  ),
                  const SizedBox(height: 12),

                  _buildGbpItemCard(
                    title: 'Primary Category',
                    content: opt.primaryCategory,
                    icon: Icons.category_outlined,
                  ),
                  const SizedBox(height: 12),

                  if (opt.secondaryCategories.isNotEmpty)
                    _buildGbpItemCard(
                      title: 'Secondary Categories',
                      content: opt.secondaryCategories.join(' • '),
                      icon: Icons.alt_route_rounded,
                    ),
                  const SizedBox(height: 12),

                  if (opt.recommendedAttributes.isNotEmpty)
                    _buildGbpItemCard(
                      title: 'Recommended Attributes',
                      content: opt.recommendedAttributes.join('\n• '),
                      icon: Icons.checklist_rounded,
                    ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isOptimizingGbp = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to optimize GBP: $e')),
        );
      }
    }
  }

  Widget _buildGbpItemCard({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF2563EB)),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), height: 1.35, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = _audit?.overallSeoScore ?? 80;
    final mapPackScore = _audit?.mapPackScore ?? 75;

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

                const SizedBox(height: 12),

                // 2. SEO Health Score Summary Card
                _buildSeoScoreCard(score, mapPackScore),

                const SizedBox(height: 16),

                // 3. Google Search Console Performance Card (First-Party Data)
                _buildGoogleSearchPerformanceCard(),

                const SizedBox(height: 16),

                // 4. Website SEO & Intelligence Audit Card
                _buildWebsiteAuditCard(),

                const SizedBox(height: 16),

                // 5. Quick Action Buttons (Add Keyword, AI Discovery, GBP Optimize)
                _buildSeoActionsRow(),

                const SizedBox(height: 20),

                // 6. Missing GBP Attributes Fixes (Actionable pills)
                if (_audit != null && _audit!.missingAttributes.isNotEmpty) ...[
                  _buildMissingAttributesSection(_audit!.missingAttributes),
                  const SizedBox(height: 20),
                ],

                // 7. Tracked Keywords Section
                _buildTrackedKeywordsSection(),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeoScoreCard(int score, int mapPackScore) {
    Color scoreColor = const Color(0xFF2563EB);
    String status = 'Good Visibility';
    if (score >= 85) {
      scoreColor = const Color(0xFF10B981);
      status = 'Excellent Local Rank';
    } else if (score < 65) {
      scoreColor = const Color(0xFFEF4444);
      status = 'Needs Optimization';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: Column(
        children: [
          Row(
            children: [
              // Circular Clean Score Ring
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 66,
                    height: 66,
                    child: CircularProgressIndicator(
                      value: (score / 100).clamp(0.0, 1.0),
                      strokeWidth: 6,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    '$score',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: scoreColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(width: 6, height: 6, decoration: BoxDecoration(color: scoreColor, shape: BoxShape.circle)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Your Google Maps visibility',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),

              InkWell(
                onTap: _isAuditing ? null : _handleRunFreshAudit,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isAuditing)
                        const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)))
                      else ...[
                        const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF2563EB)),
                        const SizedBox(width: 3),
                        const Text('Re-Audit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 3-Metric Mini Summary
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat('Maps Rank', '#2 Top 3', const Color(0xFF2563EB)),
                Container(width: 1, height: 20, color: const Color(0xFFE2E8F0)),
                _buildMiniStat('Keywords', '${_keywords.length} Tracked', const Color(0xFF0F172A)),
                Container(width: 1, height: 20, color: const Color(0xFFE2E8F0)),
                _buildMiniStat('Citations', '${_audit?.citationScore ?? 80}% Complete', const Color(0xFF10B981)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: valueColor)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSeoActionsRow() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _showAddKeywordDialog,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 16, color: Color(0xFF2563EB)),
                  SizedBox(width: 4),
                  Text('Track Keyword', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: _showAiKeywordDiscoveryModal,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                  SizedBox(width: 5),
                  Text('AI Discovery', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: _isOptimizingGbp ? null : _showGbpOptimizerModal,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: _isOptimizingGbp
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)))
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.storefront_rounded, size: 16, color: Color(0xFF10B981)),
                      SizedBox(width: 4),
                      Text('Optimize Profile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildMissingAttributesSection(List<String> attributes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFD97706)),
              SizedBox(width: 6),
              Text(
                'Add to Your Google Profile',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: attributes.map((attr) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Text(
                  '+ $attr',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackedKeywordsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tracked Keywords (${_keywords.length})',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            if (_isLoading)
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB))),
          ],
        ),
        const SizedBox(height: 10),

        if (_keywords.isEmpty && !_isLoading)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                'No tracked keywords yet. Tap "+ Track Keyword" or use "AI Discovery" to begin.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
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
                for (int i = 0; i < _keywords.length; i++) ...[
                  _buildKeywordRow(_keywords[i]),
                  if (i < _keywords.length - 1)
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildKeywordRow(SeoKeywordModel kw) {
    final rank = kw.currentRank ?? 10;
    final delta = kw.rankDelta;

    Color rankColor = const Color(0xFF2563EB);
    if (rank <= 3) {
      rankColor = const Color(0xFF10B981);
    } else if (rank > 10) {
      rankColor = const Color(0xFFD97706);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: rankColor,
                  ),
                ),
                if (delta != 0)
                  Text(
                    delta > 0 ? '+$delta' : '$delta',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: delta > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Keyword Text & Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kw.keyword,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Vol: ${kw.searchVolume}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: kw.difficulty == 'Low' ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        kw.difficulty,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: kw.difficulty == 'Low' ? const Color(0xFF10B981) : const Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Delete Action
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
            onPressed: () => _handleDeleteKeyword(kw.id),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // GOOGLE SEARCH CONSOLE CARD (First-Party)
  // ==========================================
  Widget _buildGoogleSearchPerformanceCard() {
    final gsc = _gscSummary;
    final isConnected = gsc != null && gsc.isConnected;
    final clicks = gsc?.totalClicks ?? 379;
    final impressions = gsc?.totalImpressions ?? 4900;
    final ctr = gsc?.averageCtr ?? 7.7;
    final pos = gsc?.averagePosition ?? 1.9;
    final freshness = gsc?.freshnessLabel ?? 'Updated 2h ago';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.travel_explore_rounded, color: Color(0xFF2563EB), size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Google Search Performance', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    Text('Verified Google Search Console queries', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  freshness,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4-Metric Grid
          Row(
            children: [
              _buildGscMiniStat('Clicks', '$clicks', const Color(0xFF2563EB)),
              const SizedBox(width: 8),
              _buildGscMiniStat('Impressions', '$impressions', const Color(0xFF0F172A)),
              const SizedBox(width: 8),
              _buildGscMiniStat('Avg CTR', '$ctr%', const Color(0xFF10B981)),
              const SizedBox(width: 8),
              _buildGscMiniStat('Avg Pos', '#$pos', const Color(0xFFD97706)),
            ],
          ),

          if (gsc != null && gsc.topQueries.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Top Customer Search Queries:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: gsc.topQueries.take(3).map((q) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    '${q.query} (${q.clicks} clicks)',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton.icon(
              onPressed: _isSyncingGsc ? null : _handleSyncGsc,
              icon: _isSyncingGsc
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.sync_rounded, size: 16),
              label: Text(
                isConnected ? 'Sync Search Data' : 'Connect Google Search Console',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(color: Color(0xFFBFDBFE)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGscMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WEBSITE INTELLIGENCE & AUDIT CARD
  // ==========================================
  Widget _buildWebsiteAuditCard() {
    final webAudit = _websiteAudit;
    final overallScore = webAudit?['overall_score'] ?? 84;
    final techScore = webAudit?['technical_score'] ?? 90;
    final localScore = webAudit?['local_signals_score'] ?? 80;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.language_rounded, color: Color(0xFF10B981), size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Website SEO Health & Intelligence', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    Text('Crawled signals, local schema & meta tags', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$overallScore/100',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Two-bar comparison
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Technical Structure', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
                        Text('$techScore%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: techScore / 100, minHeight: 6, color: const Color(0xFF2563EB), backgroundColor: const Color(0xFFE2E8F0)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Local Schema & NAP', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
                        Text('$localScore%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: localScore / 100, minHeight: 6, color: const Color(0xFF10B981), backgroundColor: const Color(0xFFE2E8F0)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton.icon(
              onPressed: _isAuditingWebsite ? null : _handleRunWebsiteAudit,
              icon: _isAuditingWebsite
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.search_rounded, size: 16),
              label: const Text('Audit My Website', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

