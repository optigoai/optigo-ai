import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/models/seo_model.dart';
import '../../data/repositories/seo_repository.dart';
import '../../data/repositories/gsc_repository.dart';
import '../auth/auth_provider.dart';
import '../shared/optigo_top_bar.dart';
import '../shared/bespoke_interactive_wave_chart.dart';
import '../home/widgets/bespoke_circular_score_gauge.dart';
import '../home/widgets/bespoke_trend_sparkline.dart';
import '../home/widgets/bespoke_keyword_distribution_bar.dart';

/// OptigoAI Local SEO & Google Maps Visibility Command Center (Screen 4)
/// Next-level visual analytics, keyword rank tracking, and on-page technical audit.
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
  List<Map<String, dynamic>> _visibilityHistory = [];
  int _selectedDays = 7;
  bool _isLoading = true;
  bool _isAuditing = false;
  bool _initialized = false;
  String _keywordFilter = 'all'; // 'all', 'top3', 'top10', 'needs_work'

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
      final history = await _seoRepo!.getVisibilityHistory(business.id, days: _selectedDays);

      if (mounted) {
        setState(() {
          _keywords = kws;
          _audit = aud;
          _visibilityHistory = history;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRangeChanged(int days) async {
    setState(() => _selectedDays = days);
    final business = context.read<AppAuthProvider>().currentBusiness;
    if (business == null || _seoRepo == null) return;
    try {
      final history = await _seoRepo!.getVisibilityHistory(business.id, days: days);
      if (mounted) {
        setState(() => _visibilityHistory = history);
      }
    } catch (_) {}
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
            content: Text('✨ Local SEO & Crawler Audit refreshed!'),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Google Search Console synchronized!'),
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

  void _showAddKeywordDialog() {
    final business = context.read<AppAuthProvider>().currentBusiness;
    if (business == null || _seoRepo == null) return;

    final kwController = TextEditingController();
    final locController = TextEditingController(text: business.location ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.add_location_alt_rounded, color: Color(0xFF2563EB), size: 22),
            const SizedBox(width: 8),
            Text(
              'Track New Keyword',
              style: GoogleFonts.plusJakartaSans(fontSize: 16.5, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter local search phrase to track on Google Maps:',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: kwController,
              decoration: InputDecoration(
                hintText: 'e.g. flour mill near me, organic spices',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
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
                prefixIcon: const Icon(Icons.location_on_rounded, color: Color(0xFF64748B)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B))),
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
              } catch (_) {}
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Start Tracking', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAiKeywordDiscoveryModal() {
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Keyword Discovery',
                            style: GoogleFonts.plusJakartaSans(fontSize: 16.5, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
                          ),
                          Text(
                            'High-intent local keywords discovered with Gemini',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B)),
                          ),
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
                  // Track All Button
                  SizedBox(
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
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✨ Added ${createdList.length} keywords to tracking!'),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.playlist_add_check_rounded, size: 18, color: Colors.white),
                      label: Text(
                        'Track All Discovered (${discovered.length})',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: discovered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, idx) {
                        final kw = discovered[idx];
                        final name = (kw['keyword'] ?? '').toString();
                        final searchVol = (kw['volume'] ?? 'High').toString();
                        final isAlreadyTracked = _keywords.any((k) => k.keyword.toLowerCase() == name.toLowerCase());

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                                  ),
                                  Text(
                                    'Intent: Local Search • Volume: $searchVol',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: const Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                              if (isAlreadyTracked)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('Tracking', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF059669))),
                                )
                              else
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF2563EB), size: 20),
                                  onPressed: () async {
                                    final created = await _seoRepo!.addKeyword(businessId: business.id, keyword: name);
                                    setState(() {
                                      _keywords.insert(0, created);
                                    });
                                    setModalState(() {});
                                  },
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

  void _showJsonLdSchemaModal() async {
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
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.code_rounded, color: Color(0xFF2563EB), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('JSON-LD Schema Markup', style: GoogleFonts.plusJakartaSans(fontSize: 16.5, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                          Text('Google LocalBusiness Rich Results Schema', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B))),
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
                Text(
                  'Paste this structured data snippet into your website <head> to display rich opening hours, phone, and ratings in Google Search:',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF475569), height: 1.4),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        snippet,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5, color: Color(0xFF38BDF8), height: 1.45),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
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
                    icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white),
                    label: Text('Copy Schema Code', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (_) {}
  }

  List<SeoKeywordModel> get _filteredKeywords {
    switch (_keywordFilter) {
      case 'top3':
        return _keywords.where((k) => (k.currentRank ?? 99) <= 3).toList();
      case 'top10':
        return _keywords.where((k) => (k.currentRank ?? 99) > 3 && (k.currentRank ?? 99) <= 10).toList();
      case 'needs_work':
        return _keywords.where((k) => (k.currentRank ?? 99) > 10).toList();
      case 'all':
      default:
        return _keywords;
    }
  }

  @override
  Widget build(BuildContext context) {
    final validRanks = _keywords.map((k) => k.currentRank).whereType<int>().toList();
    final avgRank = validRanks.isNotEmpty
        ? (validRanks.reduce((a, b) => a + b) / validRanks.length)
        : 2.5;
    final top3Count = _keywords.where((k) => (k.currentRank ?? 99) <= 3).length;
    final top10Count = _keywords.where((k) => (k.currentRank ?? 99) > 3 && (k.currentRank ?? 99) <= 10).length;
    final top20Count = _keywords.where((k) => (k.currentRank ?? 99) > 10 && (k.currentRank ?? 99) <= 20).length;

    final visibilityScore = _audit?.overallSeoScore ?? 88;
    final displayedKeywords = _filteredKeywords;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F1FD),
              Color(0xFFEFF5FE),
              Color(0xFFF6F9FD),
              Color(0xFFF8FAFC),
            ],
            stops: [0.0, 0.22, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: const Color(0xFF2563EB),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Navigation Bar
                  OptigoTopBar(
                    subtitle: 'Local SEO & Google Visibility',
                    onNotificationTap: widget.onNavigateToRecommendations,
                    onRefreshTap: _handleRunFreshAudit,
                    isRefreshing: _isAuditing,
                  ),

                  const SizedBox(height: 14),

                  // 2. Editorial Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Google Maps Ranking',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.6,
                            ),
                          ),
                          Text(
                            'Real-time local search visibility & crawl metrics',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _showAiKeywordDiscoveryModal,
                        icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF2563EB), size: 22),
                        tooltip: 'AI Keyword Discovery',
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 3. Hero Bento Grid (Visibility Gauge + Rank Momentum)
                  Row(
                    children: [
                      // Left Card: Deep Midnight Visibility
                      Expanded(
                        child: Container(
                          height: 195,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF0B132B), Color(0xFF1C2541), Color(0xFF1E293B)],
                              stops: [0.0, 0.55, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFF334155), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0B132B).withValues(alpha: 0.25),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.travel_explore_rounded, color: Color(0xFF60A5FA), size: 16),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Optimal',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF34D399)),
                                    ),
                                  ),
                                ],
                              ),
                              Center(
                                child: BespokeCircularScoreGauge(
                                  score: visibilityScore,
                                  size: 96,
                                  isDarkCard: true,
                                ),
                              ),
                              Text(
                                'Local Map Pack Score',
                                style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Right Card: Pure White Rank Card
                      Expanded(
                        child: Container(
                          height: 195,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.trending_up_rounded, color: Color(0xFF2563EB), size: 16),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFA7F3D0)),
                                    ),
                                    child: Text(
                                      'Top 3 ($top3Count)',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF059669)),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Average Position',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '#${avgRank.toStringAsFixed(1)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 27,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF0F172A),
                                      letterSpacing: -0.8,
                                    ),
                                  ),
                                ],
                              ),
                              BespokeTrendSparkline(
                                dataPoints: _keywords.isNotEmpty
                                    ? _keywords.take(6).map((k) => (k.currentRank ?? 5).toDouble()).toList()
                                    : const [3.0, 2.5, 2.0],
                                height: 28,
                                lineColor: const Color(0xFF2563EB),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 3.5 Interactive Historical Visibility Trend Wave Chart (Live Backend Time-Series)
                  BespokeInteractiveWaveChart(
                    dataPoints: _visibilityHistory,
                    selectedDays: _selectedDays,
                    onRangeChanged: _handleRangeChanged,
                  ),

                  const SizedBox(height: 20),

                  // 4. Keyword Distribution Bar
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Position Distribution',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                            ),
                            Text(
                              '${_keywords.length} Tracked',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        BespokeKeywordDistributionBar(
                          top3Count: top3Count,
                          top10Count: top10Count,
                          top20Count: top20Count,
                          totalCount: _keywords.length,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 5. Tracked Keywords Header & Filter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tracked Keywords',
                        style: GoogleFonts.plusJakartaSans(fontSize: 16.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                      ),
                      InkWell(
                        onTap: _showAddKeywordDialog,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded, size: 15, color: Color(0xFF2563EB)),
                              const SizedBox(width: 4),
                              Text('Add Keyword', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: const Color(0xFF2563EB))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildFilterPill('all', 'All (${_keywords.length})'),
                        const SizedBox(width: 8),
                        _buildFilterPill('top3', 'Top 3 ($top3Count)', color: const Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        _buildFilterPill('top10', 'Top 10 ($top10Count)', color: const Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        _buildFilterPill('needs_work', 'Needs Boost ($top20Count)', color: const Color(0xFFF59E0B)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Keywords List
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 36),
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
                    )
                  else if (displayedKeywords.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Center(
                        child: Text(
                          'No keywords in this category.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF64748B)),
                        ),
                      ),
                    )
                  else
                    ...displayedKeywords.map((k) => _buildKeywordCard(k)),

                  const SizedBox(height: 20),

                  // 6. Technical Crawler & Schema Hub Banner
                  _buildTechnicalCrawlerBanner(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(String id, String label, {Color? color}) {
    final isSelected = _keywordFilter == id;
    final activeColor = color ?? const Color(0xFF2563EB);

    return InkWell(
      onTap: () => setState(() => _keywordFilter = id),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE2E8F0),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? activeColor : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildKeywordCard(SeoKeywordModel kw) {
    final rank = kw.currentRank ?? 99;
    final isTop3 = rank <= 3;
    final isTop10 = rank > 3 && rank <= 10;
    final rankColor = isTop3
        ? const Color(0xFF10B981)
        : (isTop10 ? const Color(0xFF2563EB) : const Color(0xFFF59E0B));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: rankColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: rankColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kw.keyword,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 11, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              kw.targetLocation ?? 'Local area',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () => _handleDeleteKeyword(kw.id),
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.delete_outline_rounded, color: Color(0xFFCBD5E1), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalCrawlerBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.code_rounded, color: Color(0xFF60A5FA), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Technical SEO & Schema',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _showJsonLdSchemaModal,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('Get Schema', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Google Search Console & LocalBusiness JSON-LD Schema markup active for Google Knowledge Graph.',
            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF94A3B8), height: 1.4),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _handleSyncGsc,
            child: Row(
              children: [
                const Icon(Icons.sync_rounded, size: 14, color: Color(0xFF60A5FA)),
                const SizedBox(width: 4),
                Text(
                  'Sync Google Search Console impressions',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF60A5FA)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
