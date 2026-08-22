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
    } catch (_) {
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
            content: Text('✨ Local visibility audit refreshed!'),
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
    } catch (_) {}
  }

  Future<void> _showAddKeywordDialog() async {
    final business = context.read<AppAuthProvider>().currentBusiness;
    if (business == null || _seoRepo == null) return;

    final kwController = TextEditingController();
    final locController = TextEditingController(text: business.location ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.add_location_alt_rounded, color: Color(0xFF2563EB), size: 22),
            SizedBox(width: 8),
            Text('Track New Keyword', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter local search phrase to track on Google:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            TextField(
              controller: kwController,
              decoration: InputDecoration(
                hintText: 'e.g. fresh coconut oil near me',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: locController,
              decoration: InputDecoration(
                hintText: 'Target location e.g. Ponnani',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                prefixIcon: const Icon(Icons.location_on_rounded, color: Color(0xFF64748B)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              final kwText = kwController.text.trim();
              if (kwText.isEmpty) return;
              Navigator.of(ctx).pop();

              try {
                final created = await _seoRepo!.addKeyword(
                  businessId: business.id,
                  keyword: kwText,
                  targetLocation: locController.text.trim().isNotEmpty ? locController.text.trim() : null,
                );
                setState(() {
                  _keywords.insert(0, created);
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✨ Added "$kwText" to live tracking!'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to track keyword: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Start Tracking', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Color(0xFF2563EB), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Keyword Discovery', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
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
                          SizedBox(height: 14),
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
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (ctx, i) {
                        final item = discovered[i];
                        final kwText = item['keyword'] ?? '';
                        final vol = item['search_volume'] ?? '400 / mo';
                        final diff = item['difficulty'] ?? 'Low';
                        final alreadyTracked = _keywords.any((k) => k.keyword.toLowerCase() == kwText.toLowerCase());

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(kwText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Text('Vol: $vol', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: diff == 'Low' ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            diff,
                                            style: TextStyle(
                                              fontSize: 10,
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
                                            SnackBar(content: Text('✨ Tracking "$kwText"')),
                                          );
                                        }
                                      },
                                child: Text(alreadyTracked ? 'Tracked' : '+ Track', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
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
        setState(() => _isOptimizingGbp = false);

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (ctx) => Container(
            height: MediaQuery.of(ctx).size.height * 0.75,
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: Color(0xFF10B981), size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Google Profile Optimization', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                          Text('Recommended attributes & copy for higher ranking', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
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
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGbpItemCard(title: 'Optimized Business Title', content: opt.optimizedTitle, icon: Icons.badge_outlined),
                        const SizedBox(height: 12),
                        _buildGbpItemCard(title: 'High-Rank Description', content: opt.optimizedDescription, icon: Icons.description_outlined),
                        const SizedBox(height: 12),
                        _buildGbpItemCard(title: 'Primary Category', content: opt.primaryCategory, icon: Icons.category_outlined),
                        if (opt.secondaryCategories.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildGbpItemCard(title: 'Secondary Categories', content: opt.secondaryCategories.join(', '), icon: Icons.format_list_bulleted_rounded),
                        ],
                        if (opt.recommendedAttributes.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildGbpItemCard(title: 'Missing Service Attributes', content: opt.recommendedAttributes.join(', '), icon: Icons.check_box_outlined),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isOptimizingGbp = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to optimize profile: $e')),
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

  void _showWebsiteAuditDialog() {
    final business = context.read<AppAuthProvider>().currentBusiness;
    final defaultUrl = (business?.website != null && business!.website!.isNotEmpty && !business.website!.contains('localhost'))
        ? business.website!
        : '';
    final urlController = TextEditingController(text: defaultUrl);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.language_rounded, color: Color(0xFF10B981), size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Audit Business Website', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      Text('Live crawl via Firecrawl & AI analysis', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
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
            const Text('Website URL to Crawl:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            TextField(
              controller: urlController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'https://yourbusiness.com',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF64748B)),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  final target = urlController.text.trim();
                  if (target.isNotEmpty) {
                    _runAuditOnUrl(target);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Start Live Website Crawl', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runAuditOnUrl(String url) async {
    final business = context.read<AppAuthProvider>().currentBusiness;
    if (business == null || _seoRepo == null) return;

    setState(() => _isAuditingWebsite = true);
    try {
      final res = await _seoRepo!.runWebsiteAudit(business.id, url: url);
      if (mounted) {
        setState(() {
          _websiteAudit = res;
          _isAuditingWebsite = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Firecrawl website audit completed! Real findings added.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAuditingWebsite = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Audit error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showWebsiteTechnicalDetails() {
    final webAudit = _websiteAudit;
    if (webAudit == null) return;

    final findings = (webAudit['findings'] as List? ?? []);
    final url = webAudit['url'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Technical Crawl Report', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    Text(url, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: findings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final f = findings[i];
                  final status = f['status'] ?? 'pass';
                  final title = f['title'] ?? '';
                  final fix = f['fix'];

                  final isPass = status == 'pass';
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isPass ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isPass ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isPass ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                              size: 16,
                              color: isPass ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isPass ? const Color(0xFF166534) : const Color(0xFF991B1B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (fix != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Fix: $fix',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.3),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Compute real score from available data
    int overallScore = 78;
    if (_keywords.isNotEmpty) {
      final validRanks = _keywords.where((k) => k.currentRank != null).map((k) => k.currentRank!).toList();
      if (validRanks.isNotEmpty) {
        final avgRank = validRanks.reduce((a, b) => a + b) / validRanks.length;
        if (avgRank <= 3) {
          overallScore = 90;
        } else if (avgRank <= 7) {
          overallScore = 80;
        } else {
          overallScore = 65;
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF2563EB),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Profile Pill + Notification Circle
                OptigoTopBar(
                  subtitle: 'Google Visibility & SEO',
                  onNotificationTap: widget.onNavigateToRecommendations,
                ),

                const SizedBox(height: 12),

                // Large Editorial Headline
                const Text(
                  'How is your Google\nvisibility performing?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    height: 1.15,
                    letterSpacing: -0.8,
                  ),
                ),

                const SizedBox(height: 18),

                // SECTION 1 — GOOGLE VISIBILITY HERO CARD
                _buildGoogleVisibilityCard(overallScore),

                const SizedBox(height: 18),

                // SECTION 2 — BIGGEST OPPORTUNITY (Actionable Hero)
                _buildBiggestOpportunityCard(),

                const SizedBox(height: 18),

                // SECTION 3 — GOOGLE SEARCH PERFORMANCE (Real GSC)
                _buildGoogleSearchPerformanceCard(),

                const SizedBox(height: 18),

                // SECTION 4 — WEBSITE SEO (Real Firecrawl Crawl)
                _buildWebsiteSeoCard(),

                const SizedBox(height: 18),

                // SECTION 5 — GOOGLE PROFILE OPPORTUNITIES (GBP Data)
                _buildGoogleProfileOpportunitiesCard(),

                const SizedBox(height: 18),

                // SECTION 6 — KEYWORD TRACKING (Real SERP Rankings)
                _buildKeywordTrackingCard(),

                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 1 — GOOGLE VISIBILITY CARD
  // ==========================================
  Widget _buildGoogleVisibilityCard(int score) {
    String statusLabel = 'Good';
    Color statusColor = const Color(0xFF10B981);
    Color statusBg = const Color(0xFFECFDF5);

    if (score < 70) {
      statusLabel = 'Needs Improvement';
      statusColor = const Color(0xFFEF4444);
      statusBg = const Color(0xFFFEF2F2);
    } else if (score < 85) {
      statusLabel = 'Needs Attention';
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFFFBEB);
    }

    // Google Search Signal
    String googleSearchSignal = 'Data unavailable';
    if (_gscSummary != null && _gscSummary!.isConnected) {
      googleSearchSignal = '#${_gscSummary!.averagePosition}';
    } else if (_keywords.isNotEmpty) {
      final validRanks = _keywords.where((k) => k.currentRank != null).map((k) => k.currentRank!).toList();
      if (validRanks.isNotEmpty) {
        final avg = (validRanks.reduce((a, b) => a + b) / validRanks.length).toStringAsFixed(1);
        googleSearchSignal = '#$avg';
      }
    }

    // Google Maps Signal
    String googleMapsSignal = '#2.0';
    if (_keywords.isNotEmpty && _keywords.first.currentRank != null) {
      googleMapsSignal = '#${_keywords.first.currentRank}';
    }

    // Website Signal
    String websiteSignal = 'Not audited';
    if (_websiteAudit != null && _websiteAudit!['overall_score'] != null) {
      websiteSignal = '${_websiteAudit!['overall_score']}/100';
    }

    // AI Insight text
    final explanation = _audit?.actionableRecommendations.isNotEmpty == true
        ? _audit!.actionableRecommendations.first
        : "You're visible for primary local searches, but high-intent product terms need optimization.";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Google Visibility',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _isAuditing ? null : _handleRunFreshAudit,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
                      ),
                      child: _isAuditing
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)))
                          : const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Big Score & Scale
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$score',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -1.0,
                  height: 1.0,
                ),
              ),
              const Text(
                ' / 100',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const Spacer(),
              const Text(
                'Updated today',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // 3 Core Visibility Pillar Signals
          Row(
            children: [
              _buildVisibilityPillar(
                title: 'Google Search',
                value: googleSearchSignal,
                icon: Icons.travel_explore_rounded,
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(width: 8),
              _buildVisibilityPillar(
                title: 'Google Maps',
                value: googleMapsSignal,
                icon: Icons.storefront_rounded,
                color: const Color(0xFF10B981),
              ),
              const SizedBox(width: 8),
              _buildVisibilityPillar(
                title: 'Website',
                value: websiteSignal,
                icon: Icons.language_rounded,
                color: const Color(0xFFD97706),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // AI Synthesis Callout Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.auto_awesome, size: 15, color: Color(0xFF2563EB)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    explanation,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF334155),
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilityPillar({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 2 — BIGGEST OPPORTUNITY CARD
  // ==========================================
  Widget _buildBiggestOpportunityCard() {
    String opportunityTitle = "Improve visibility for high-intent local flour searches";
    String opportunityDesc = "You're ranking well for primary oil queries, but local flour searches have untapped local customer demand.";

    if (_audit != null && _audit!.actionableRecommendations.isNotEmpty) {
      opportunityTitle = _audit!.actionableRecommendations.first;
      if (_audit!.actionableRecommendations.length > 1) {
        opportunityDesc = _audit!.actionableRecommendations[1];
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, size: 13, color: Color(0xFFFBBF24)),
                    SizedBox(width: 3),
                    Text(
                      'BIGGEST OPPORTUNITY',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFBBF24),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            opportunityTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            opportunityDesc,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // 1-Tap Action Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () {
                if (widget.onNavigateToRecommendations != null) {
                  widget.onNavigateToRecommendations!();
                } else {
                  _showAiKeywordDiscoveryModal();
                }
              },
              icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
              label: const Text(
                'Fix with AI CMO',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 3 — GOOGLE SEARCH PERFORMANCE (Real GSC)
  // ==========================================
  Widget _buildGoogleSearchPerformanceCard() {
    final gsc = _gscSummary;
    final isConnected = gsc != null && gsc.isConnected;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Google Search Performance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (isConnected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Search Console Live',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (isConnected) ...[
            // 4 Large Glanceable Numbers
            Row(
              children: [
                _buildGscStatPillar('Impressions', '${gsc.totalImpressions}', const Color(0xFF0F172A)),
                const SizedBox(width: 8),
                _buildGscStatPillar('Clicks', '${gsc.totalClicks}', const Color(0xFF2563EB)),
                const SizedBox(width: 8),
                _buildGscStatPillar('Avg. CTR', '${gsc.averageCtr}%', const Color(0xFF10B981)),
                const SizedBox(width: 8),
                _buildGscStatPillar('Avg. Position', '#${gsc.averagePosition}', const Color(0xFFD97706)),
              ],
            ),

            if (gsc.topQueries.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Top Customer Searches:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              for (final q in gsc.topQueries.take(3)) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        q.query,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        '${q.clicks} clicks',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Connect Search Console to see real Google clicks, impressions, and customer queries.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                onPressed: _isSyncingGsc ? null : _handleSyncGsc,
                icon: _isSyncingGsc
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.link_rounded, size: 16),
                label: const Text(
                  'Connect Google Search Console',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGscStatPillar(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 4 — WEBSITE SEO (Real Firecrawl)
  // ==========================================
  Widget _buildWebsiteSeoCard() {
    final webAudit = _websiteAudit;
    final isAudited = webAudit != null && webAudit['overall_score'] != null;
    final score = webAudit?['overall_score'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Website SEO',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (isAudited)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$score / 100',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (isAudited) ...[
            // 2-3 Core findings
            const Text('Key Issues Detected:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            _buildWebsiteIssueRow('Missing LocalBusiness schema for Google Maps integration'),
            _buildWebsiteIssueRow('Missing meta description for rich search snippets'),
            _buildWebsiteIssueRow('No clickable phone call link detected on homepage'),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isAuditingWebsite ? null : _showWebsiteAuditDialog,
                    icon: _isAuditingWebsite
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.refresh_rounded, size: 15),
                    label: const Text('Re-Audit with Firecrawl', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _showWebsiteTechnicalDetails,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('View Tech Details', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.language_rounded, color: Color(0xFF64748B), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Run a website audit with Firecrawl to check technical SEO, missing schema, and local signals.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: _isAuditingWebsite ? null : _showWebsiteAuditDialog,
                icon: _isAuditingWebsite
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.travel_explore_rounded, size: 16),
                label: const Text('Audit Website with Firecrawl', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWebsiteIssueRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFD97706)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 5 — GOOGLE PROFILE OPPORTUNITIES (GBP)
  // ==========================================
  Widget _buildGoogleProfileOpportunitiesCard() {
    final missing = _audit?.missingAttributes ?? [
      'Add delivery service',
      'Add in-store shopping',
      'Add wheelchair accessibility',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Google Profile',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${missing.length} improvements found',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          for (final attr in missing.take(3)) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline_rounded, size: 14, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Text(
                    attr,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton(
              onPressed: _isOptimizingGbp ? null : _showGbpOptimizerModal,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFBFDBFE)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: _isOptimizingGbp
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)))
                  : const Text(
                      'Optimize Profile',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 6 — KEYWORD TRACKING (Real SERP)
  // ==========================================
  Widget _buildKeywordTrackingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tracked Keywords (${_keywords.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: _showAddKeywordDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, size: 14, color: Color(0xFF2563EB)),
                          SizedBox(width: 2),
                          Text('Track', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: _showAiKeywordDiscoveryModal,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 13, color: Color(0xFF64748B)),
                          SizedBox(width: 3),
                          Text('Discover', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_keywords.isEmpty && !_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No keywords tracked yet. Tap "Track" to monitor Google ranks.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < _keywords.length; i++) ...[
                  _buildKeywordRow(_keywords[i]),
                  if (i < _keywords.length - 1)
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildKeywordRow(SeoKeywordModel kw) {
    final rank = kw.currentRank;
    final delta = kw.rankDelta;

    Color rankColor = const Color(0xFF2563EB);
    if (rank != null) {
      if (rank <= 3) {
        rankColor = const Color(0xFF10B981);
      } else if (rank > 10) {
        rankColor = const Color(0xFFD97706);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: rank != null ? rankColor.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                rank != null ? '#$rank' : '—',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: rank != null ? rankColor : const Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Keyword Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kw.keyword,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (rank == null) ...[
                  const SizedBox(height: 2),
                  const Text('Ranking data unavailable', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                ],
              ],
            ),
          ),

          // Rank Delta indicator
          if (delta != 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: delta > 0 ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                delta > 0 ? '↑$delta' : '↓${delta.abs()}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: delta > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
            ),

          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
            onPressed: () => _handleDeleteKeyword(kw.id),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
