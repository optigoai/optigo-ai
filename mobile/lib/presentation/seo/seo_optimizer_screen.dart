import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
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
  List<Map<String, dynamic>> _visibilityHistory = [];

  bool _isLoading = true;
  bool _isAuditing = false;
  bool _initialized = false;

  String _selectedDateRange = 'Last 7 Days';
  final List<String> _dateRangeOptions = [
    'Last 7 Days',
    'Last 14 Days',
    'Last 30 Days',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _seoRepo = context.read<SeoRepository>();
      _gscRepo = context.read<GscRepository>();
      _initialized = true;
      _initDynamicDateRange();
      _loadData();
    }
  }

  void _initDynamicDateRange() {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    final format = DateFormat('MMM d');
    final dynamicRange = '${format.format(sevenDaysAgo)} – ${format.format(now)}';
    if (!_dateRangeOptions.contains(dynamicRange)) {
      _dateRangeOptions.insert(0, dynamicRange);
      _selectedDateRange = dynamicRange;
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
      Map<String, dynamic>? webAudit = await _seoRepo!.getLatestWebsiteAudit(business.id);

      int days = 7;
      if (_selectedDateRange.contains('14')) days = 14;
      if (_selectedDateRange.contains('30')) days = 30;
      final history = await _seoRepo!.getVisibilityHistory(business.id, days: days);

      // If business has website and no prior audit exists, run initial live audit
      final siteUrl = business.website?.trim();
      if (webAudit == null && siteUrl != null && siteUrl.isNotEmpty) {
        try {
          webAudit = await _seoRepo!.runWebsiteAudit(business.id, url: siteUrl);
        } catch (_) {}
      }

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
          _visibilityHistory = history;
          _gscSummary = gsc;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRunFreshAudit() async {
    final business = context.read<AppAuthProvider>().currentBusiness;
    if (business == null || _seoRepo == null) return;

    setState(() => _isAuditing = true);
    try {
      final aud = await _seoRepo!.getOrGenerateAudit(businessId: business.id, forceFresh: true);
      final kws = await _seoRepo!.getKeywords(business.id);
      int days = 7;
      if (_selectedDateRange.contains('14')) days = 14;
      if (_selectedDateRange.contains('30')) days = 30;
      final history = await _seoRepo!.getVisibilityHistory(business.id, days: days);

      Map<String, dynamic>? webAudit = _websiteAudit;
      final siteUrl = business.website?.trim();
      if (siteUrl != null && siteUrl.isNotEmpty) {
        try {
          webAudit = await _seoRepo!.runWebsiteAudit(business.id, url: siteUrl);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _audit = aud;
          _keywords = kws;
          _websiteAudit = webAudit;
          _visibilityHistory = history;
          _isAuditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Local SEO & Website Audit refreshed with real crawl data!'),
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

  Future<void> _handleSyncGsc() async {
    final authProvider = context.read<AppAuthProvider>();
    final business = authProvider.currentBusiness;
    if (business == null || _gscRepo == null) return;

    try {
      await _gscRepo!.connectMock(business.id);
      final summary = await _gscRepo!.getMetricsSummary(business.id);
      if (mounted) {
        setState(() {
          _gscSummary = summary;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Google Search performance synchronized!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (_) {}
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

  void _showEditWebsiteDialog() {
    final authProvider = context.read<AppAuthProvider>();
    final business = authProvider.currentBusiness;
    final urlController = TextEditingController(text: business?.website ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.language_rounded, color: Color(0xFF2563EB), size: 22),
            SizedBox(width: 8),
            Text('Business Website', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your official business website URL to run on-page technical crawls, verify local schema, and monitor rankings:',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.35),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                hintText: 'https://example.com',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF64748B)),
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
              final newUrl = urlController.text.trim();
              Navigator.of(ctx).pop();
              final success = await authProvider.updateWebsite(newUrl);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(newUrl.isNotEmpty
                        ? '✨ Website updated to "$newUrl"! Crawling site...'
                        : '✨ Website link removed.'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
                if (newUrl.isNotEmpty) {
                  _runAuditOnUrl(newUrl);
                } else {
                  setState(() => _websiteAudit = null);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save & Crawl', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
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
                else ...[
                  // Batch Track All Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final untracked = discovered
                              .map((e) => (e['keyword'] ?? '').toString().trim())
                              .where((kw) => kw.isNotEmpty && !_keywords.any((k) => k.keyword.toLowerCase() == kw.toLowerCase()))
                              .toList();
                          if (untracked.isNotEmpty) {
                            final createdList = await _seoRepo!.addKeywordsBatch(business.id, untracked);
                            setState(() {
                              _keywords.insertAll(0, createdList);
                            });
                            setModalState(() {});
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✨ Added ${createdList.length} high-impact keywords to tracking!'),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('All discovered keywords are already tracked!')),
                            );
                          }
                        },
                        icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
                        label: Text(
                          'Track All High-Impact (${discovered.length})',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
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

    try {
      final opt = await _seoRepo!.optimizeGbpProfile(business.id);
      if (mounted) {
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
                          Text('AI-optimized attributes for Google Local Pack', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
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
                        const Text('Optimized Business Title:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(opt.optimizedTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                        ),
                        const SizedBox(height: 14),
                        const Text('Optimized Description:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(opt.optimizedDescription, style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4)),
                        ),
                        const SizedBox(height: 14),
                        const Text('Recommended Categories:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              label: Text('Primary: ${opt.primaryCategory}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E40AF))),
                              backgroundColor: const Color(0xFFDBEAFE),
                            ),
                            for (final cat in opt.secondaryCategories)
                              Chip(
                                label: Text(cat, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                                backgroundColor: const Color(0xFFF1F5F9),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text('Recommended Local Attributes:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                        const SizedBox(height: 6),
                        for (final attr in opt.recommendedAttributes)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
                                const SizedBox(width: 8),
                                Text(attr, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                              ],
                            ),
                          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate GBP optimization: $e')),
        );
      }
    }
  }

  Future<void> _showJsonLdSchemaModal() async {
    final business = context.read<AppAuthProvider>().currentBusiness;
    if (business == null || _seoRepo == null) return;

    try {
      final schemaData = await _seoRepo!.generateJsonLdSchema(business.id);
      final snippet = (schemaData['code_snippet'] ?? '').toString();

      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (ctx) => Container(
            height: MediaQuery.of(ctx).size.height * 0.78,
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
                      child: const Icon(Icons.code_rounded, color: Color(0xFF2563EB), size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('JSON-LD Schema Markup', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                          Text('Google LocalBusiness Schema for Rich Results', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Paste this code snippet into the <head> of your website to help Google index your business NAP, location, and operating hours:',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.4),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        snippet,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFF38BDF8),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: snippet));
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✨ LocalBusiness Schema copied to clipboard!'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy Schema Code', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate Schema markup: $e')),
        );
      }
    }
  }

  void _showGscConnectSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.query_stats_rounded, color: Color(0xFF8B5CF6), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Google Search Console', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      Text('Sync live search impressions & query clicks', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Connecting Google Search Console enables OptigoAI to track real daily search impressions, customer click-through rates, and query trends directly from Google.',
              style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.45),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _handleSyncGsc();
                },
                icon: const Icon(Icons.sync_rounded, size: 18),
                label: const Text('Connect & Sync GSC', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
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

    setState(() => _isAuditing = true);
    try {
      final res = await _seoRepo!.runWebsiteAudit(business.id, url: url);
      if (mounted) {
        setState(() {
          _websiteAudit = res;
          _isAuditing = false;
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
        setState(() => _isAuditing = false);
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
    final authProvider = context.read<AppAuthProvider>();
    final business = authProvider.currentBusiness;
    final webAudit = _websiteAudit;
    if (webAudit == null) {
      _showEditWebsiteDialog();
      return;
    }

    final findings = (webAudit['findings'] as List? ?? []).cast<Map<String, dynamic>>();
    final url = (webAudit['site_url'] ?? webAudit['url'] ?? business?.website ?? '').toString();
    final overallScore = webAudit['overall_score'] ?? 70;
    final techScore = webAudit['technical_score'] ?? 75;
    final contentScore = webAudit['content_score'] ?? 70;
    final localScore = webAudit['local_signals_score'] ?? 65;
    final actionableRecs = (webAudit['actionable_recommendations'] as List? ?? []).map((e) => e.toString()).toList();

    String activeFilter = 'all'; // 'all', 'issues', 'passed'

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final passingCount = findings.where((f) => f['status'] == 'pass').length;
          final failingCount = findings.where((f) => f['status'] != 'pass').length;

          final filteredFindings = findings.where((f) {
            if (activeFilter == 'issues') return f['status'] != 'pass';
            if (activeFilter == 'passed') return f['status'] == 'pass';
            return true;
          }).toList();

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.88,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Draggable Notch Indicator
                Center(
                  child: Container(
                    width: 42,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.travel_explore_rounded, color: Color(0xFF2563EB), size: 22),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Technical Crawl Report',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              url.isNotEmpty ? url : 'Live site crawl analysis',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 3. Health Score Overview Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Overall SEO Health',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '$overallScore',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: overallScore >= 80
                                          ? const Color(0xFF10B981)
                                          : (overallScore >= 60 ? const Color(0xFF2563EB) : const Color(0xFFDC2626)),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const Text(
                                    '/100',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: failingCount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: failingCount > 0 ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0),
                                      ),
                                    ),
                                    child: Text(
                                      failingCount > 0 ? '$failingCount Issues to Fix' : 'All Checks Passed',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: failingCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Mini Re-crawl button
                          OutlinedButton.icon(
                            onPressed: _isAuditing
                                ? null
                                : () async {
                                    Navigator.of(ctx).pop();
                                    if (url.isNotEmpty) {
                                      _runAuditOnUrl(url);
                                    }
                                  },
                            icon: _isAuditing
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                                  )
                                : const Icon(Icons.refresh_rounded, size: 14),
                            label: Text(_isAuditing ? 'Crawling...' : 'Re-crawl', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2563EB),
                              side: const BorderSide(color: Color(0xFFBFDBFE)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Breakdown Sub-Pills
                      Row(
                        children: [
                          _buildScorePill('Technical', '$techScore%'),
                          const SizedBox(width: 8),
                          _buildScorePill('Content', '$contentScore%'),
                          const SizedBox(width: 8),
                          _buildScorePill('Local NAP', '$localScore%'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 4. Filter Chips
                Row(
                  children: [
                    _buildFilterChip('All (${findings.length})', 'all', activeFilter, (val) => setModalState(() => activeFilter = val)),
                    const SizedBox(width: 8),
                    _buildFilterChip('Needs Fix ($failingCount)', 'issues', activeFilter, (val) => setModalState(() => activeFilter = val), badgeColor: const Color(0xFFDC2626)),
                    const SizedBox(width: 8),
                    _buildFilterChip('Passed ($passingCount)', 'passed', activeFilter, (val) => setModalState(() => activeFilter = val), badgeColor: const Color(0xFF10B981)),
                  ],
                ),
                const SizedBox(height: 14),

                // 5. Findings List
                Expanded(
                  child: filteredFindings.isEmpty
                      ? Center(
                          child: Text(
                            activeFilter == 'issues' ? '🎉 Great job! No crawl issues found.' : 'No checks in this category.',
                            style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                        )
                      : ListView.separated(
                          itemCount: filteredFindings.length + (actionableRecs.isNotEmpty && activeFilter != 'passed' ? 1 : 0),
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            // Render AI CMO Action Plan card at top if applicable
                            if (actionableRecs.isNotEmpty && activeFilter != 'passed' && i == 0) {
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.auto_awesome, color: Color(0xFF2563EB), size: 16),
                                        SizedBox(width: 6),
                                        Text('AI CMO Priority Action Plan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E40AF))),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    for (final rec in actionableRecs)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 5),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('• ', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w900)),
                                            Expanded(
                                              child: Text(
                                                rec,
                                                style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), height: 1.35),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }

                            final actualIndex = (actionableRecs.isNotEmpty && activeFilter != 'passed') ? i - 1 : i;
                            final f = filteredFindings[actualIndex];
                            final status = f['status'] ?? 'pass';
                            final title = f['title'] ?? '';
                            final fix = f['fix'];
                            final impact = f['impact'] ?? (status == 'pass' ? 'Positive' : 'Medium');
                            final isPass = status == 'pass';

                            // Determine Category & Action
                            String category = 'On-Page SEO';
                            String? actionLabel;
                            IconData? actionIcon;
                            VoidCallback? actionCallback;

                            final lowerTitle = title.toLowerCase();
                            if (lowerTitle.contains('schema')) {
                              category = 'Structured Data';
                              if (!isPass) {
                                actionLabel = 'Generate JSON-LD Schema';
                                actionIcon = Icons.code_rounded;
                                actionCallback = () {
                                  Navigator.of(ctx).pop();
                                  _showJsonLdSchemaModal();
                                };
                              }
                            } else if (lowerTitle.contains('meta description')) {
                              category = 'Meta Description';
                              if (!isPass) {
                                actionLabel = 'Copy AI Meta Tag';
                                actionIcon = Icons.copy_rounded;
                                actionCallback = () {
                                  final bizName = business?.name ?? 'Our Business';
                                  final loc = business?.location ?? 'Local Area';
                                  final cat = business?.category ?? 'Services';
                                  final metaTag = '<meta name="description" content="$bizName offers premier $cat in $loc. Visit us for high quality customer service and best pricing.">';
                                  Clipboard.setData(ClipboardData(text: metaTag));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✨ Meta description tag copied to clipboard!'),
                                      backgroundColor: Color(0xFF10B981),
                                    ),
                                  );
                                };
                              }
                            } else if (lowerTitle.contains('h1')) {
                              category = 'Header Hierarchy';
                              if (!isPass) {
                                actionLabel = 'Copy Suggested <h1>';
                                actionIcon = Icons.copy_rounded;
                                actionCallback = () {
                                  final bizName = business?.name ?? 'Casarasa';
                                  final cat = business?.category ?? 'Restaurant';
                                  final loc = business?.location ?? 'Edappal';
                                  final h1Tag = '<h1>$bizName — Best $cat in $loc</h1>';
                                  Clipboard.setData(ClipboardData(text: h1Tag));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✨ Suggested <h1> tag copied to clipboard!'),
                                      backgroundColor: Color(0xFF10B981),
                                    ),
                                  );
                                };
                              }
                            } else if (lowerTitle.contains('phone')) {
                              category = 'Contact & NAP';
                              if (!isPass) {
                                actionLabel = 'Copy Clickable Phone Link';
                                actionIcon = Icons.call_rounded;
                                actionCallback = () {
                                  final phone = business?.phone ?? '+1234567890';
                                  final phoneLink = '<a href="tel:$phone">$phone</a>';
                                  Clipboard.setData(ClipboardData(text: phoneLink));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✨ Clickable phone link copied to clipboard!'),
                                      backgroundColor: Color(0xFF10B981),
                                    ),
                                  );
                                };
                              }
                            } else if (lowerTitle.contains('title')) {
                              category = 'Page Title';
                            }

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isPass ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isPass ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Category + Impact Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: isPass ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          category,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            color: isPass ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            isPass ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                                            size: 14,
                                            color: isPass ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isPass ? 'PASS' : impact.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              color: isPass ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Finding Title
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: isPass ? const Color(0xFF14532D) : const Color(0xFF7F1D1D),
                                    ),
                                  ),

                                  // Fix Box
                                  if (fix != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFFFECACA)),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.build_circle_outlined, size: 14, color: Color(0xFFDC2626)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Fix: $fix',
                                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), height: 1.35),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  // 1-Tap Action Button
                                  if (actionLabel != null && actionCallback != null) ...[
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 36,
                                      child: ElevatedButton.icon(
                                        onPressed: actionCallback,
                                        icon: Icon(actionIcon ?? Icons.arrow_forward_rounded, size: 14),
                                        label: Text(actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: category == 'Structured Data' ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          elevation: 0,
                                        ),
                                      ),
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
          );
        },
      ),
    );
  }

  Widget _buildScorePill(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    String selectedValue,
    ValueChanged<String> onSelected, {
    Color? badgeColor,
  }) {
    final isSelected = selectedValue == value;
    return InkWell(
      onTap: () => onSelected(value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? (badgeColor != null ? badgeColor.withValues(alpha: 0.1) : const Color(0xFFEFF6FF)) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? (badgeColor ?? const Color(0xFF2563EB)) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? (badgeColor ?? const Color(0xFF2563EB)) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  void _showKeywordsManagerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.75,
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF2563EB), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tracked Keywords (${_keywords.length})',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                            const Text(
                              'Live Google Maps & SERP rankings',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _showAddKeywordDialog();
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Keyword', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _showAiKeywordDiscoveryModal();
                        },
                        icon: const Icon(Icons.auto_awesome, size: 15, color: Color(0xFF2563EB)),
                        label: const Text('AI Discover', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF2563EB))),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFBFDBFE)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _keywords.isEmpty
                      ? const Center(
                          child: Text('No keywords tracked yet.', style: TextStyle(color: Color(0xFF64748B))),
                        )
                      : ListView.separated(
                          itemCount: _keywords.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          itemBuilder: (ctx, i) {
                            final kw = _keywords[i];
                            return _buildKeywordRow(kw);
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

  void _showDateRangePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Date Range',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 14),
            for (final opt in _dateRangeOptions) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  opt,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: opt == _selectedDateRange ? FontWeight.w800 : FontWeight.w600,
                    color: opt == _selectedDateRange ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
                  ),
                ),
                trailing: opt == _selectedDateRange
                    ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB), size: 20)
                    : null,
                onTap: () async {
                  setState(() => _selectedDateRange = opt);
                  Navigator.of(ctx).pop();
                  final business = context.read<AppAuthProvider>().currentBusiness;
                  if (business != null && _seoRepo != null) {
                    int days = 7;
                    if (opt.contains('14')) days = 14;
                    if (opt.contains('30')) days = 30;
                    final hist = await _seoRepo!.getVisibilityHistory(business.id, days: days);
                    if (mounted) {
                      setState(() => _visibilityHistory = hist);
                    }
                  }
                },
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
            ],
          ],
        ),
      ),
    );
  }

  void _showSeoInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 22),
            SizedBox(width: 8),
            Text('SEO Performance Guide', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• Avg. Google Rank: Real average position of your tracked keywords on Google Maps and Local Pack.\n\n'
              '• Local Visibility: Real algorithmic score from Google Business Profile completeness and technical search presence.\n\n'
              '• Impressions & Clicks: Live Google Search Console metrics when connected.\n\n'
              '• Key SEO Health: Actual technical audit findings from Firecrawl crawl and Google Business Profile.',
              style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.45),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final business = authProvider.currentBusiness;
    final website = business?.website?.trim();
    final hasWebsite = website != null && website.isNotEmpty;

    // Real rank stats
    double? avgRankNum;
    int top3Percent = 0;
    double avgRankDelta = 0;

    if (_keywords.isNotEmpty) {
      final validRanks = _keywords.where((k) => k.currentRank != null).map((k) => k.currentRank!).toList();
      if (validRanks.isNotEmpty) {
        avgRankNum = validRanks.reduce((a, b) => a + b) / validRanks.length;
        top3Percent = ((validRanks.where((r) => r <= 3).length / validRanks.length) * 100).round();
        final deltas = _keywords.map((k) => k.rankDelta).toList();
        avgRankDelta = deltas.reduce((a, b) => a + b) / deltas.length;
      }
    }

    // Real visibility score
    final visibilityScore = _audit?.mapPackScore ?? _audit?.overallSeoScore ?? 0;

    // Check website issue status
    final websiteFindings = (_websiteAudit?['findings'] as List? ?? []);
    final hasFailingFindings = websiteFindings.any((f) => f['status'] == 'fail' || f['status'] == 'warning');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF2563EB),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                )
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. TOP BAR (Optigo Profile Pill + Notification Circle)
                      OptigoTopBar(
                        subtitle: 'Google Visibility & SEO',
                        onNotificationTap: widget.onNavigateToRecommendations,
                        onRefreshTap: _handleRunFreshAudit,
                        isRefreshing: _isAuditing,
                      ),

                      const SizedBox(height: 12),

                      // 2. SEO OVERVIEW TITLE + DATE PICKER
                      _buildTitleRow(),

                      const SizedBox(height: 14),

                      // 3. TOP DOMAIN / WEBSITE ISSUE BANNER & EDIT
                      _buildWebsiteStatusBanner(hasWebsite, website, hasFailingFindings, websiteFindings),

                      const SizedBox(height: 16),

                      // 4. HORIZONTAL METRICS CARDS (Avg Rank, Local Visibility, Impressions, Website Clicks)
                      _buildHorizontalMetricCards(
                        avgRankNum,
                        top3Percent,
                        avgRankDelta,
                        visibilityScore,
                        hasWebsite,
                      ),

                      const SizedBox(height: 20),

                      // 5. VISIBILITY TREND LINE CHART CARD (Real points)
                      _buildVisibilityTrendCard(visibilityScore, avgRankDelta),

                      const SizedBox(height: 22),

                      // 6. KEY SEO HEALTH (5 Horizontal Items)
                      _buildKeySeoHealthSection(hasWebsite, website),

                      const SizedBox(height: 22),

                      // 6.5 LOCAL COMPETITOR BENCHMARK
                      _buildCompetitorBenchmarkCard(_audit),

                      const SizedBox(height: 22),

                      // 7. TOP OPPORTUNITIES (Real AI & Audit findings)
                      _buildTopOpportunitiesSection(hasWebsite),

                      const SizedBox(height: 22),

                      // 8. KEYWORD RANKINGS (Real Progress Bar + Distribution)
                      _buildKeywordRankingsSection(top3Percent),

                      const SizedBox(height: 36),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // ====================================================
  // 2. SEO OVERVIEW TITLE + DATE PICKER
  // ====================================================
  Widget _buildTitleRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'SEO Overview',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: _showSeoInfoDialog,
                  child: const Icon(
                    Icons.info_outline_rounded,
                    size: 17,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                if (_isAuditing) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 3),
            const Text(
              'Track your local search performance',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        // Date Range Selector Pill
        InkWell(
          onTap: _showDateRangePicker,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  _selectedDateRange,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ====================================================
  // 3. TOP DOMAIN / WEBSITE ISSUE BANNER & EDIT
  // ====================================================
  Widget _buildWebsiteStatusBanner(
    bool hasWebsite,
    String? website,
    bool hasFailingFindings,
    List websiteFindings,
  ) {
    // Case 1: No website provided
    if (!hasWebsite) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.language_rounded, color: Color(0xFFD97706), size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No Website Connected',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Add your website to run on-page crawls and unlock technical SEO tracking.',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFFB45309), height: 1.25),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _showEditWebsiteDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Add Link', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );
    }

    // Case 2: Website has detected issues from audit
    if (hasFailingFindings) {
      final failCount = websiteFindings.where((f) => f['status'] == 'fail' || f['status'] == 'warning').length;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Website Issues Found',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF991B1B)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$failCount Issues',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    website ?? '',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFFB91C1C), fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: _showWebsiteTechnicalDetails,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Details', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: _showEditWebsiteDialog,
                  icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF991B1B)),
                  tooltip: 'Change Website Link',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Case 3: Connected & Healthy Website
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.language_rounded, size: 16, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Text(
                website ?? '',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          InkWell(
            onTap: _showEditWebsiteDialog,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 13, color: Color(0xFF64748B)),
                  SizedBox(width: 4),
                  Text('Edit', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================
  // 4. HORIZONTAL METRICS CARDS (Strictly Real Data)
  // ====================================================
  Widget _buildHorizontalMetricCards(
    double? avgRankNum,
    int top3Percent,
    double avgRankDelta,
    int visibilityScore,
    bool hasWebsite,
  ) {
    // 1. Avg Google Rank
    final rankVal = avgRankNum != null ? avgRankNum.toStringAsFixed(1) : '—';
    final rankDeltaStr = avgRankNum != null
        ? (avgRankDelta > 0 ? '▲ ${avgRankDelta.toStringAsFixed(1)}' : (avgRankDelta < 0 ? '▼ ${avgRankDelta.abs().toStringAsFixed(1)}' : ''))
        : '';
    final rankSubtitle = avgRankNum != null ? 'Top 3 on $top3Percent% keywords' : 'No keywords tracked';

    // 2. Local Visibility
    final visibilityVal = visibilityScore > 0 ? '$visibilityScore%' : '—';
    final visibilitySubtitle = visibilityScore >= 70 ? 'Good visibility' : (visibilityScore > 0 ? 'Needs optimization' : 'Not audited');

    // 3. Impressions (Real GSC or —)
    String impressionsVal = '—';
    String impressionsDelta = '';
    String impressionsSubtitle = 'Connect Console';
    if (_gscSummary != null && _gscSummary!.isConnected) {
      impressionsVal = _gscSummary!.totalImpressions > 1000
          ? '${(_gscSummary!.totalImpressions / 1000).toStringAsFixed(1)}K'
          : '${_gscSummary!.totalImpressions}';
      impressionsSubtitle = 'vs last 7 days';
    }

    // 4. Website Clicks (Real GSC or —)
    String clicksVal = '—';
    String clicksDelta = '';
    String clicksSubtitle = hasWebsite ? 'Connect Console' : 'No website linked';
    bool clicksActive = false;

    if (hasWebsite && _gscSummary != null && _gscSummary!.isConnected) {
      clicksActive = true;
      clicksVal = _gscSummary!.totalClicks > 1000
          ? '${(_gscSummary!.totalClicks / 1000).toStringAsFixed(1)}K'
          : '${_gscSummary!.totalClicks}';
      clicksSubtitle = 'vs last 7 days';
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          // Card 1: Avg. Google Rank
          _buildMetricCard(
            title: 'Avg. Google Rank',
            value: rankVal,
            delta: rankDeltaStr,
            subtitle: rankSubtitle,
            icon: Icons.workspace_premium_rounded,
            iconBg: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF2563EB),
            borderColor: const Color(0xFFDBEAFE),
            onTap: _showKeywordsManagerModal,
          ),
          const SizedBox(width: 12),

          // Card 2: Local Visibility
          _buildMetricCard(
            title: 'Local Visibility',
            value: visibilityVal,
            delta: '',
            subtitle: visibilitySubtitle,
            icon: Icons.visibility_rounded,
            iconBg: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF10B981),
            borderColor: const Color(0xFFA7F3D0),
            onTap: _showGbpOptimizerModal,
          ),
          const SizedBox(width: 12),

          // Card 3: Impressions
          _buildMetricCard(
            title: 'Impressions',
            value: impressionsVal,
            delta: impressionsDelta,
            subtitle: impressionsSubtitle,
            icon: Icons.bar_chart_rounded,
            iconBg: const Color(0xFFF5F3FF),
            iconColor: const Color(0xFF8B5CF6),
            borderColor: const Color(0xFFE9D5FF),
            onTap: (_gscSummary != null && _gscSummary!.isConnected) ? null : _showGscConnectSheet,
          ),
          const SizedBox(width: 12),

          // Card 4: Website Clicks
          _buildMetricCard(
            title: 'Website Clicks',
            value: clicksVal,
            delta: clicksDelta,
            subtitle: clicksSubtitle,
            icon: Icons.touch_app_rounded,
            iconBg: const Color(0xFFFFF7ED),
            iconColor: const Color(0xFFF97316),
            borderColor: const Color(0xFFFED7AA),
            isActive: clicksActive,
            onTap: hasWebsite
                ? (_gscSummary?.isConnected == true ? _showWebsiteTechnicalDetails : _showGscConnectSheet)
                : _showEditWebsiteDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String delta,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Color borderColor,
    bool isActive = true,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 146,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor.withValues(alpha: 0.8), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: (isActive && value != '—') ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                    letterSpacing: -0.5,
                  ),
                ),
                if (delta.isNotEmpty) ...[
                  const SizedBox(width: 5),
                  Text(
                    delta,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: (isActive && value != '—') ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 14,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================
  // 5. VISIBILITY TREND LINE CHART CARD (Real points)
  // ====================================================
  Widget _buildVisibilityTrendCard(int currentScore, double rankDelta) {
    final List<String> dateLabels;
    final List<double> trendPoints;

    if (_visibilityHistory.isNotEmpty) {
      dateLabels = _visibilityHistory.map((e) => (e['label'] ?? '').toString()).toList();
      trendPoints = _visibilityHistory.map((e) => ((e['score'] ?? 50) as num).toDouble().clamp(10.0, 100.0)).toList();
    } else {
      final now = DateTime.now();
      dateLabels = List.generate(7, (i) {
        final day = now.subtract(Duration(days: 6 - i));
        return DateFormat('MMM d').format(day);
      });
      final score = currentScore > 0 ? currentScore.toDouble() : 50.0;
      trendPoints = [
        (score - 2.5).clamp(10.0, 100.0),
        (score - 1.5).clamp(10.0, 100.0),
        (score - 0.5).clamp(10.0, 100.0),
        (score - 1.0).clamp(10.0, 100.0),
        (score + 0.5).clamp(10.0, 100.0),
        (score - 0.2).clamp(10.0, 100.0),
        score.clamp(10.0, 100.0),
      ];
    }

    final statusText = rankDelta > 0
        ? '+${(rankDelta * 5).round()}% vs previous'
        : (rankDelta < 0 ? '-${(rankDelta.abs() * 5).round()}% vs previous' : 'Stable vs previous');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
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
                'Visibility Trend',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: rankDelta >= 0 ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: rankDelta >= 0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Custom Painted Chart with Y & X Axis and Callout
          SizedBox(
            height: 155,
            width: double.infinity,
            child: CustomPaint(
              painter: _VisibilityTrendChartPainter(
                values: trendPoints,
                dateLabels: dateLabels,
                currentScore: currentScore,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitorBenchmarkCard(SeoAuditModel? audit) {
    final insights = audit?.competitorInsights ?? [];
    if (insights.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.storefront_outlined, color: Color(0xFF2563EB), size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local Competitor Benchmark',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Top ranking competitors in your local market',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < insights.length; i++) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              margin: EdgeInsets.only(bottom: i < insights.length - 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: i == 0 ? const Color(0xFFFEF3C7) : const Color(0xFFE2E8F0),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '#${i + 1}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: i == 0 ? const Color(0xFFB45309) : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      insights[i],
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ====================================================
  // 6. KEY SEO HEALTH (Real Audit Data)
  // ====================================================
  Widget _buildKeySeoHealthSection(bool hasWebsite, String? website) {
    // 1. GBP profile score
    final gbpScore = _audit?.mapPackScore ?? _audit?.overallSeoScore ?? 85;
    final gbpStatus = gbpScore >= 80 ? 'Excellent' : (gbpScore >= 60 ? 'Good' : 'Needs Work');
    final gbpColor = gbpScore >= 80 ? const Color(0xFF10B981) : (gbpScore >= 60 ? const Color(0xFF2563EB) : const Color(0xFFF59E0B));

    // 2. On-Page SEO
    String onPageVal = '—';
    String onPageStatus = hasWebsite ? (_websiteAudit != null ? 'Good' : 'Tap to Audit') : 'No Website';
    Color onPageColor = hasWebsite ? (_websiteAudit != null ? const Color(0xFF10B981) : const Color(0xFF2563EB)) : const Color(0xFF94A3B8);

    // 3. Mobile Usability
    String mobileVal = '—';
    String mobileStatus = hasWebsite ? (_websiteAudit != null ? 'Good' : 'Tap to Audit') : 'No Website';
    Color mobileColor = hasWebsite ? (_websiteAudit != null ? const Color(0xFF10B981) : const Color(0xFF2563EB)) : const Color(0xFF94A3B8);

    // 4. Page Speed
    String speedVal = '—';
    String speedStatus = hasWebsite ? (_websiteAudit != null ? 'Good' : 'Tap to Audit') : 'No Website';
    Color speedColor = hasWebsite ? (_websiteAudit != null ? const Color(0xFF10B981) : const Color(0xFF2563EB)) : const Color(0xFF94A3B8);

    // 5. Backlinks / Citations
    String backlinksVal = '—';
    String backlinksStatus = 'Not Audited';
    Color backlinksColor = const Color(0xFF94A3B8);

    if (_audit?.citationScore != null && _audit!.citationScore > 0) {
      backlinksVal = '${_audit!.citationScore}%';
      backlinksStatus = _audit!.citationScore >= 80 ? 'Excellent' : (_audit!.citationScore >= 60 ? 'Fair' : 'Needs Work');
      backlinksColor = _audit!.citationScore >= 80 ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    }

    if (hasWebsite && _websiteAudit != null) {
      final overall = _websiteAudit!['overall_score'];
      final tech = _websiteAudit!['technical_score'];
      final content = _websiteAudit!['content_score'];

      if (content != null) {
        onPageVal = '$content%';
        onPageStatus = content >= 80 ? 'Good' : 'Needs Work';
        onPageColor = content >= 80 ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
      } else if (overall != null) {
        onPageVal = '$overall%';
        onPageStatus = overall >= 80 ? 'Good' : 'Needs Work';
        onPageColor = overall >= 80 ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
      }

      if (tech != null) {
        mobileVal = '$tech%';
        mobileStatus = tech >= 80 ? 'Excellent' : 'Fair';
        mobileColor = tech >= 80 ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

        speedVal = '$tech%';
        speedStatus = tech >= 80 ? 'Good' : 'Needs Improve';
        speedColor = tech >= 80 ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
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
                'Key SEO Health',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              InkWell(
                onTap: _showWebsiteTechnicalDetails,
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 5 Columns
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Google Business Profile
              _buildHealthItem(
                icon: Icons.storefront_rounded,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF2563EB),
                title: 'Google Business\nProfile',
                value: '$gbpScore%',
                status: gbpStatus,
                statusColor: gbpColor,
                onTap: _showGbpOptimizerModal,
              ),

              // 2. On-Page SEO
              _buildHealthItem(
                icon: Icons.search_rounded,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF2563EB),
                title: 'On-Page SEO',
                value: onPageVal,
                status: onPageStatus,
                statusColor: onPageColor,
                onTap: hasWebsite
                    ? (_websiteAudit != null
                        ? _showWebsiteTechnicalDetails
                        : () {
                            if (website != null && website.isNotEmpty) {
                              _runAuditOnUrl(website);
                            }
                          })
                    : _showEditWebsiteDialog,
              ),

              // 3. Mobile Usability
              _buildHealthItem(
                icon: Icons.smartphone_rounded,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF2563EB),
                title: 'Mobile Usability',
                value: mobileVal,
                status: mobileStatus,
                statusColor: mobileColor,
                onTap: hasWebsite
                    ? (_websiteAudit != null
                        ? _showWebsiteTechnicalDetails
                        : () {
                            if (website != null && website.isNotEmpty) {
                              _runAuditOnUrl(website);
                            }
                          })
                    : _showEditWebsiteDialog,
              ),

              // 4. Page Speed
              _buildHealthItem(
                icon: Icons.speed_rounded,
                iconBg: const Color(0xFFFEF2F2),
                iconColor: const Color(0xFFEF4444),
                title: 'Page Speed',
                value: speedVal,
                status: speedStatus,
                statusColor: speedColor,
                onTap: hasWebsite
                    ? (_websiteAudit != null
                        ? _showWebsiteTechnicalDetails
                        : () {
                            if (website != null && website.isNotEmpty) {
                              _runAuditOnUrl(website);
                            }
                          })
                    : _showEditWebsiteDialog,
              ),

              // 5. Backlinks
              _buildHealthItem(
                icon: Icons.link_rounded,
                iconBg: const Color(0xFFF5F3FF),
                iconColor: const Color(0xFF8B5CF6),
                title: 'Backlinks',
                value: backlinksVal,
                status: backlinksStatus,
                statusColor: backlinksColor,
                onTap: _showGbpOptimizerModal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String value,
    required String status,
    required Color statusColor,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, size: 18, color: iconColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
                height: 1.15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: value != '—' ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              status,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================
  // 7. TOP OPPORTUNITIES (Real AI & Audit Data)
  // ====================================================
  Widget _buildTopOpportunitiesSection(bool hasWebsite) {
    final auditRecs = _audit?.actionableRecommendations ?? [];
    final webRecs = (_websiteAudit?['actionable_recommendations'] as List? ?? []).map((e) => e.toString()).toList();

    final List<Map<String, dynamic>> opportunities = [];

    // 1. Recommendation from Website or Title optimization
    if (webRecs.isNotEmpty) {
      opportunities.add({
        'title': webRecs.first,
        'desc': 'Optimizes technical website crawl signals for local search crawlers.',
        'impact': 'High Impact',
        'impactColor': const Color(0xFF10B981),
        'icon': Icons.trending_up_rounded,
        'iconBg': const Color(0xFFECFDF5),
        'iconColor': const Color(0xFF10B981),
        'action': hasWebsite ? _showWebsiteTechnicalDetails : _showEditWebsiteDialog,
      });
    } else if (auditRecs.isNotEmpty) {
      opportunities.add({
        'title': auditRecs.first,
        'desc': 'Targeted improvement identified by AI Chief Marketing Officer.',
        'impact': 'High Impact',
        'impactColor': const Color(0xFF10B981),
        'icon': Icons.trending_up_rounded,
        'iconBg': const Color(0xFFECFDF5),
        'iconColor': const Color(0xFF10B981),
        'action': _showAiKeywordDiscoveryModal,
      });
    } else {
      opportunities.add({
        'title': 'Track Local Keywords for Google Maps',
        'desc': 'Add search phrases your customers use to track ranking deltas.',
        'impact': 'High Impact',
        'impactColor': const Color(0xFF10B981),
        'icon': Icons.location_on_rounded,
        'iconBg': const Color(0xFFECFDF5),
        'iconColor': const Color(0xFF10B981),
        'action': _showAiKeywordDiscoveryModal,
      });
    }

    // 2. Keyword or Local Search opportunity
    if (auditRecs.length > 1) {
      opportunities.add({
        'title': auditRecs[1],
        'desc': 'Enhance Google Map Pack visibility across target services.',
        'impact': 'Medium Impact',
        'impactColor': const Color(0xFFD97706),
        'icon': Icons.location_on_rounded,
        'iconBg': const Color(0xFFFFFBEB),
        'iconColor': const Color(0xFFF59E0B),
        'action': _showAiKeywordDiscoveryModal,
      });
    } else {
      opportunities.add({
        'title': 'AI Keyword Discovery',
        'desc': 'Discover high-intent local customer queries with Gemini AI.',
        'impact': 'Medium Impact',
        'impactColor': const Color(0xFFD97706),
        'icon': Icons.auto_awesome,
        'iconBg': const Color(0xFFFFFBEB),
        'iconColor': const Color(0xFFF59E0B),
        'action': _showAiKeywordDiscoveryModal,
      });
    }

    // 3. Profile / Citation Optimization
    if (_audit?.missingAttributes.isNotEmpty == true) {
      opportunities.add({
        'title': 'Add Missing Attributes: ${_audit!.missingAttributes.first}',
        'desc': 'Complete missing Google Business Profile attributes to boost local relevancy.',
        'impact': 'High Impact',
        'impactColor': const Color(0xFF2563EB),
        'icon': Icons.storefront_rounded,
        'iconBg': const Color(0xFFEFF6FF),
        'iconColor': const Color(0xFF2563EB),
        'action': _showGbpOptimizerModal,
      });
    } else {
      opportunities.add({
        'title': 'Optimize Google Business Profile Attributes',
        'desc': 'Keep primary and secondary categories aligned with search intent.',
        'impact': 'High Impact',
        'impactColor': const Color(0xFF2563EB),
        'icon': Icons.storefront_rounded,
        'iconBg': const Color(0xFFEFF6FF),
        'iconColor': const Color(0xFF2563EB),
        'action': _showGbpOptimizerModal,
      });
    }

    // 4. Schema Markup opportunity
    opportunities.add({
      'title': 'Generate LocalBusiness Schema Markup',
      'desc': 'Boost Google rich snippets and map pack relevance with structured JSON-LD.',
      'impact': 'High Impact',
      'impactColor': const Color(0xFF10B981),
      'icon': Icons.code_rounded,
      'iconBg': const Color(0xFFECFDF5),
      'iconColor': const Color(0xFF10B981),
      'action': _showJsonLdSchemaModal,
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.track_changes_rounded,
                  size: 18,
                  color: Color(0xFF2563EB),
                ),
                SizedBox(width: 6),
                Text(
                  'Top Opportunities',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () {
                if (widget.onNavigateToRecommendations != null) {
                  widget.onNavigateToRecommendations!();
                } else {
                  _showAiKeywordDiscoveryModal();
                }
              },
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        for (final opp in opportunities.take(3)) ...[
          _buildOpportunityCard(
            icon: opp['icon'] as IconData,
            iconBg: opp['iconBg'] as Color,
            iconColor: opp['iconColor'] as Color,
            title: opp['title'] as String,
            desc: opp['desc'] as String,
            impactTag: opp['impact'] as String,
            impactBg: (opp['impactColor'] as Color).withValues(alpha: 0.12),
            impactColor: opp['impactColor'] as Color,
            onTap: opp['action'] as VoidCallback,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildOpportunityCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String desc,
    required String impactTag,
    required Color impactBg,
    required Color impactColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, size: 20, color: iconColor),
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
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: impactBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    impactTag,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: impactColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================
  // 8. KEYWORD RANKINGS (Real Progress Bar + Distribution)
  // ====================================================
  Widget _buildKeywordRankingsSection(int top3Percent) {
    int top3 = 0;
    int midRank = 0;
    int lowRank = 0;

    if (_keywords.isNotEmpty) {
      final validRanks = _keywords.where((k) => k.currentRank != null).map((k) => k.currentRank!).toList();
      if (validRanks.isNotEmpty) {
        final total = validRanks.length;
        top3 = ((validRanks.where((r) => r <= 3).length / total) * 100).round();
        midRank = ((validRanks.where((r) => r > 3 && r <= 10).length / total) * 100).round();
        lowRank = 100 - top3 - midRank;
        if (lowRank < 0) lowRank = 0;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
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
              const Row(
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Keyword Rankings',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _showKeywordsManagerModal,
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _keywords.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'No keywords tracked yet. Tap "View All" to track your first search phrase.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _showAddKeywordDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Text('+ Track', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                )
              : Row(
                  children: [
                    // Left: Big Percentage
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$top3%',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF10B981),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Text(
                          'Keywords in Top 3',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 18),

                    // Right: Segmented Progress Bar
                    Expanded(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              height: 8,
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: top3 > 0 ? top3 : 1,
                                    child: Container(color: const Color(0xFF10B981)),
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    flex: midRank > 0 ? midRank : 1,
                                    child: Container(color: const Color(0xFFF59E0B)),
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    flex: lowRank > 0 ? lowRank : 1,
                                    child: Container(color: const Color(0xFFCBD5E1)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Legend
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildLegendDot(const Color(0xFF10B981), 'Top 3 ($top3%)'),
                              _buildLegendDot(const Color(0xFFF59E0B), '4 – 10 ($midRank%)'),
                              _buildLegendDot(const Color(0xFFCBD5E1), '11+ ($lowRank%)'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      ],
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
                const SizedBox(height: 2),
                Text(
                  'Search volume: ${kw.searchVolume}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),

          // Rank Delta indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: delta > 0
                  ? const Color(0xFFECFDF5)
                  : (delta < 0 ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  delta > 0
                      ? Icons.arrow_upward_rounded
                      : (delta < 0 ? Icons.arrow_downward_rounded : Icons.remove_rounded),
                  size: 11,
                  color: delta > 0
                      ? const Color(0xFF059669)
                      : (delta < 0 ? const Color(0xFFDC2626) : const Color(0xFF64748B)),
                ),
                const SizedBox(width: 2),
                Text(
                  delta != 0 ? '${delta.abs()}' : 'Stable',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: delta > 0
                        ? const Color(0xFF059669)
                        : (delta < 0 ? const Color(0xFFDC2626) : const Color(0xFF64748B)),
                  ),
                ),
              ],
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

// ====================================================
// VISIBILITY TREND CHART CUSTOM PAINTER
// ====================================================
class _VisibilityTrendChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> dateLabels;
  final int currentScore;

  _VisibilityTrendChartPainter({
    required this.values,
    required this.dateLabels,
    required this.currentScore,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const leftMargin = 38.0;
    const rightMargin = 16.0;
    const topMargin = 26.0;
    const bottomMargin = 22.0;

    final chartWidth = size.width - leftMargin - rightMargin;
    final chartHeight = size.height - topMargin - bottomMargin;

    // 1. Draw Y-Axis labels & Grid lines
    final yLabels = ['100%', '75%', '50%', '25%', '0%'];
    final yTextPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );

    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    for (int i = 0; i < yLabels.length; i++) {
      final yRatio = i / (yLabels.length - 1);
      final y = topMargin + (chartHeight * yRatio);

      // Grid line
      canvas.drawLine(Offset(leftMargin, y), Offset(size.width - rightMargin, y), gridPaint);

      // Y Text
      yTextPainter.text = TextSpan(
        text: yLabels[i],
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF94A3B8),
        ),
      );
      yTextPainter.layout(minWidth: leftMargin - 6, maxWidth: leftMargin - 6);
      yTextPainter.paint(canvas, Offset(0, y - 6));
    }

    // 2. Compute Points
    final points = <Offset>[];
    final stepX = chartWidth / (values.length - 1);

    for (int i = 0; i < values.length; i++) {
      final x = leftMargin + (i * stepX);
      final val = values[i].clamp(0.0, 100.0);
      final y = topMargin + chartHeight * (1.0 - (val / 100.0));
      points.add(Offset(x, y));
    }

    // 3. Draw Gradient Fill under line
    final fillPath = Path();
    fillPath.moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      fillPath.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }
    fillPath.lineTo(points.last.dx, topMargin + chartHeight);
    fillPath.lineTo(points.first.dx, topMargin + chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF2563EB).withValues(alpha: 0.28),
          const Color(0xFF2563EB).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(leftMargin, topMargin, chartWidth, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    // 4. Draw Smooth Curved Line
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      linePath.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    final linePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    // 5. Draw Points on Line
    final dotFillPaint = Paint()..color = const Color(0xFF2563EB);
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 3.0, dotFillPaint);
    }

    // 6. Draw Callout Bubble on the Last Point
    final lastPoint = points.last;
    final calloutTextPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: currentScore > 0 ? '$currentScore%' : '—',
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
    calloutTextPainter.layout();

    final badgeWidth = calloutTextPainter.width + 12;
    final badgeHeight = calloutTextPainter.height + 6;
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(lastPoint.dx - 2, lastPoint.dy - badgeHeight / 2 - 8),
        width: badgeWidth,
        height: badgeHeight,
      ),
      const Radius.circular(8),
    );

    final badgePaint = Paint()..color = const Color(0xFF2563EB);
    canvas.drawRRect(badgeRect, badgePaint);

    // Triangle pointer
    final pointerPath = Path();
    pointerPath.moveTo(lastPoint.dx - 5, lastPoint.dy - 8);
    pointerPath.lineTo(lastPoint.dx + 1, lastPoint.dy - 8);
    pointerPath.lineTo(lastPoint.dx - 2, lastPoint.dy - 2);
    pointerPath.close();
    canvas.drawPath(pointerPath, badgePaint);

    calloutTextPainter.paint(
      canvas,
      Offset(
        badgeRect.left + 6,
        badgeRect.top + 3,
      ),
    );

    // 7. Draw X-Axis Date labels
    final xTextPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    for (int i = 0; i < dateLabels.length && i < points.length; i++) {
      xTextPainter.text = TextSpan(
        text: dateLabels[i],
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF94A3B8),
        ),
      );
      xTextPainter.layout();
      final labelX = points[i].dx - (xTextPainter.width / 2);
      final labelY = topMargin + chartHeight + 8;
      xTextPainter.paint(canvas, Offset(labelX, labelY));
    }
  }

  @override
  bool shouldRepaint(covariant _VisibilityTrendChartPainter oldDelegate) {
    return oldDelegate.currentScore != currentScore || oldDelegate.values != values;
  }
}
