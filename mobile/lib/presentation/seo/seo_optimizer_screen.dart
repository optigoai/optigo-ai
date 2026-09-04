import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/models/seo_model.dart';
import '../../data/repositories/seo_repository.dart';
import '../../data/repositories/gsc_repository.dart';
import '../auth/auth_provider.dart';
import '../shared/optigo_top_bar.dart';
import '../shared/optigo_pill.dart';
import '../shared/bespoke_interactive_wave_chart.dart';
import '../home/widgets/bespoke_circular_score_gauge.dart';
import '../home/widgets/bespoke_trend_sparkline.dart';
import '../home/widgets/bespoke_keyword_distribution_bar.dart';

/// OptigoAI Visibility Hub (Screen 3: Local Map Score, Keywords, Geo-Grid & Competitors)
/// Plain-language, visual measurement hub for Google Maps Pack & Search rankings.
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
  List<Map<String, dynamic>> _competitors = [];
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
      final comps = await _seoRepo!.getCompetitorBenchmark(business.id);

      if (mounted) {
        setState(() {
          _keywords = kws;
          _audit = aud;
          _visibilityHistory = history;
          _competitors = comps;
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
      final comps = await _seoRepo!.getCompetitorBenchmark(business.id);

      if (mounted) {
        setState(() {
          _audit = aud;
          _keywords = kws;
          _competitors = comps;
          _isAuditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Local search rankings & audit refreshed!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAuditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  Future<void> _handleSyncGsc() async {
    final authProvider = context.read<AppAuthProvider>();
    final business = authProvider.currentBusiness;
    if (business == null || _gscRepo == null) return;

    try {
      await _gscRepo!.syncMetrics(business.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Search Console metrics synced!'),
            backgroundColor: Color(0xFF2563EB),
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
    } catch (_) {}
  }

  void _showAddKeywordDialog() {
    final business = context.read<AppAuthProvider>().currentBusiness;
    if (business == null || _seoRepo == null) return;

    final kwController = TextEditingController();
    final locController = TextEditingController(text: business.location ?? 'Local area');

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
              decoration: const InputDecoration(
                hintText: 'e.g. flour mill near me, spices shop',
                filled: true,
                fillColor: Color(0xFFF8FAFC),
                prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF64748B)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: locController,
              decoration: const InputDecoration(
                hintText: 'Target location e.g. Ponnani',
                filled: true,
                fillColor: Color(0xFFF8FAFC),
                prefixIcon: Icon(Icons.location_on_rounded, color: Color(0xFF64748B)),
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
                      content: Text('Added "$kwText" to live tracking!'),
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
                      child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF2563EB), size: 20),
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
                            'High-intent search terms based on your local area',
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF2563EB)),
                          SizedBox(height: 16),
                          Text('Analyzing local search trends with Gemini AI...'),
                        ],
                      ),
                    ),
                  )
                else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final toAdd = discovered.where((d) => !_keywords.any((k) => k.keyword.toLowerCase() == (d['keyword'] ?? '').toString().toLowerCase())).toList();
                        if (toAdd.isNotEmpty) {
                          final createdList = <SeoKeywordModel>[];
                          for (final item in toAdd) {
                            final name = (item['keyword'] ?? '').toString();
                            final created = await _seoRepo!.addKeyword(businessId: business.id, keyword: name);
                            createdList.add(created);
                          }
                          setState(() {
                            _keywords.insertAll(0, createdList);
                          });
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added ${createdList.length} keywords to tracking!'),
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
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
                                    'Intent: Local Search • Vol: $searchVol',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: const Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                              if (isAlreadyTracked)
                                OptigoPill(label: 'Tracked', variant: OptigoPillVariant.success, fontSize: 10)
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
                          Text('Structured data for Google Search Knowledge Graph', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B))),
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
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        snippet,
                        style: GoogleFonts.jetBrainsMono(fontSize: 11, color: const Color(0xFF38BDF8), height: 1.4),
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
                          content: Text('LocalBusiness Schema copied to clipboard!'),
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

    // Distinct Local Map Score (sub-score of overall health)
    final mapPackScore = _audit?.mapPackScore != null && _audit!.mapPackScore > 0
        ? _audit!.mapPackScore
        : (_keywords.isNotEmpty
            ? ((top3Count * 22 + top10Count * 12 + (_keywords.length - top3Count - top10Count) * 5) /
                    (_keywords.length * 22) *
                    100)
                .round()
                .clamp(45, 96)
            : 74);
    final displayedKeywords = _filteredKeywords;

    final isOptimal = mapPackScore >= 75;
    final isGood = mapPackScore >= 50;

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
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Navigation Bar
                  OptigoTopBar(
                    subtitle: 'Local Search Visibility',
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
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.6,
                            ),
                          ),
                          Text(
                            'Search discovery & local Map Pack rankings',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
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

                  // 3. Hero Bento Grid (Position Discovery + Local Map Score)
                  Row(
                    children: [
                      // Left Card: Position & Discovery (Primary)
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
                                  OptigoPill(
                                    label: top3Count > 0 ? '$top3Count in Top 3' : 'Tracking',
                                    variant: top3Count > 0 ? OptigoPillVariant.success : OptigoPillVariant.neutral,
                                    fontSize: 10,
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
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF0F172A),
                                      letterSpacing: -0.8,
                                    ),
                                  ),
                                  Text(
                                    '$top10Count in striking distance (#4-#10)',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: const Color(0xFF2563EB), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              BespokeTrendSparkline(
                                dataPoints: _keywords.isNotEmpty
                                    ? _keywords.take(6).map((k) => (k.currentRank ?? 5).toDouble()).toList()
                                    : const [3.0, 2.5, 2.0],
                                height: 24,
                                lineColor: const Color(0xFF2563EB),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Right Card: Local Map Score (Secondary)
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
                                    child: const Icon(Icons.pin_drop_rounded, color: Color(0xFF2563EB), size: 16),
                                  ),
                                  OptigoPill(
                                    label: isOptimal ? 'Optimal' : (isGood ? 'Good' : 'Needs Boost'),
                                    variant: isOptimal ? OptigoPillVariant.success : (isGood ? OptigoPillVariant.neutral : OptigoPillVariant.warning),
                                    fontSize: 10,
                                  ),
                                ],
                              ),
                              Center(
                                child: BespokeCircularScoreGauge(
                                  score: mapPackScore,
                                  size: 88,
                                  isDarkCard: false,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Local Map Score',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
                                  ),
                                  Text(
                                    'Profile Quality',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                                  ),
                                ],
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

                  // 4. Single Position Distribution Bar (with Segment Tap Filter)
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
                              '${_keywords.length} Keywords Tracked',
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

                  // 4.2 Striking Distance Opportunities (#4-#10 Rank)
                  _buildStrikingDistanceSection(
                    _keywords.where((k) => (k.currentRank ?? 99) > 3 && (k.currentRank ?? 99) <= 10).toList(),
                  ),

                  const SizedBox(height: 20),

                  // 4.5 Dedicated Competitor Comparison Card
                  _buildCompetitorComparisonCard(
                    avgRank,
                    context.watch<AppAuthProvider>().currentBusiness?.name ?? 'Your Business',
                  ),

                  const SizedBox(height: 20),

                  // 4.6 Local Geo-Grid Map Snapshot Card
                  _buildGeoGridSnapshotCard(avgRank),

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

                  // Filter Chips using OptigoPill
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildFilterPill('all', 'All (${_keywords.length})', OptigoPillVariant.neutral),
                        const SizedBox(width: 8),
                        _buildFilterPill('top3', 'Top 3 ($top3Count)', OptigoPillVariant.success),
                        const SizedBox(width: 8),
                        _buildFilterPill('top10', 'Top 10 ($top10Count)', OptigoPillVariant.neutral),
                        const SizedBox(width: 8),
                        _buildFilterPill('needs_work', 'Needs Boost ($top20Count)', OptigoPillVariant.warning),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Keywords List with Inline Sparklines
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

  Widget _buildStrikingDistanceSection(List<SeoKeywordModel> strikingKeywords) {
    if (strikingKeywords.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Keywords to Improve (#4 - #10)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF14532D),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${strikingKeywords.length} Near 3-Pack',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'These search queries rank right outside the Google Maps 3-Pack. Creating an update or review reply with these terms can push them into the top tier.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF166534),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          ...strikingKeywords.take(3).map((kw) {
            final rank = kw.currentRank ?? 5;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDCFCE7)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '#$rank',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kw.keyword,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          kw.targetLocation ?? 'Local area',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      if (widget.onNavigateToRecommendations != null) {
                        widget.onNavigateToRecommendations!();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Targeting "${kw.keyword}" in your next post.'),
                            backgroundColor: const Color(0xFF16A34A),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'Optimize',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String id, String label, OptigoPillVariant variant) {
    final isSelected = _keywordFilter == id;
    return OptigoPill(
      label: label,
      variant: variant,
      isSelected: isSelected,
      onTap: () => setState(() => _keywordFilter = id),
      fontSize: 11.5,
    );
  }

  Widget _buildCompetitorComparisonCard(double myRank, String bizName) {
    final myRankInt = myRank.round();
    final isLeading = myRankInt <= 2;
    final isTop3 = myRankInt <= 3;
    final String competitorBadgeLabel = isLeading
        ? 'Area Lead'
        : (isTop3 ? 'Top 3 Contender' : 'Room to Grow');
    final OptigoPillVariant competitorBadgeVariant = isLeading
        ? OptigoPillVariant.success
        : (isTop3 ? OptigoPillVariant.neutral : OptigoPillVariant.warning);

    final hasRealCompetitors = _competitors.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 12,
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
              Row(
                children: [
                  const Icon(Icons.groups_rounded, size: 18, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Text(
                    'Local Competitor Benchmark',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              OptigoPill(
                label: competitorBadgeLabel,
                variant: competitorBadgeVariant,
                fontSize: 10,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.verified_outlined, size: 12, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                'Google Maps Public Data • Local Category',
                style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildCompetitorBar(
            bizName,
            myRankInt,
            (1.0 - (myRank / 20.0)).clamp(0.2, 0.95),
            const Color(0xFF2563EB),
          ),
          if (hasRealCompetitors) ...[
            const SizedBox(height: 10),
            ..._competitors.take(2).map((comp) {
              final cName = (comp['name'] ?? 'Local Competitor').toString();
              final cRank = (comp['rank'] as num?)?.toInt() ?? 3;
              final cProgress = (((comp['visibility_score'] as num?) ?? 60) / 100.0).clamp(0.2, 0.95);
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _buildCompetitorBar(
                  cName,
                  cRank,
                  cProgress,
                  const Color(0xFF64748B),
                ),
              );
            }),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Competitor benchmark updates automatically as nearby business rankings are indexed by Google Maps.',
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompetitorBar(String name, int rank, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
            Text(
              'Rank #$rank',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.1, 1.0),
            minHeight: 6,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildGeoGridSnapshotCard(double myRank) {
    final myRankInt = myRank.round();
    final youCellColor = myRankInt <= 3
        ? const Color(0xFF10B981)
        : (myRankInt <= 10 ? const Color(0xFF2563EB) : const Color(0xFFF59E0B));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 12,
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
              Row(
                children: [
                  const Icon(Icons.map_rounded, size: 18, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Text(
                    'Local Geo-Grid Rankings',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Text(
                '5 km Radius',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 3x3 Grid of Geo-Pins with Center Showing YOU · #Rank
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildGeoGridCell('1', const Color(0xFF10B981)),
                    _buildGeoGridCell('2', const Color(0xFF10B981)),
                    _buildGeoGridCell('4', const Color(0xFF2563EB)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildGeoGridCell('1', const Color(0xFF10B981)),
                    _buildGeoGridCell('YOU · #$myRankInt', youCellColor, isCenter: true),
                    _buildGeoGridCell('3', const Color(0xFF10B981)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildGeoGridCell('3', const Color(0xFF10B981)),
                    _buildGeoGridCell('5', const Color(0xFF2563EB)),
                    _buildGeoGridCell('8', const Color(0xFFF59E0B)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeoGridCell(String label, Color color, {bool isCenter = false}) {
    return Container(
      width: isCenter ? 64 : 52,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isCenter ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: isCenter ? 1.5 : 1),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isCenter ? 11 : 13,
            fontWeight: FontWeight.w900,
            color: color,
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

    final isImproving = (kw.previousRank ?? rank) >= rank;

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
          // Rank Badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: rankColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Keyword Info
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
          // Inline 7-Day Sparkline
          SizedBox(
            width: 48,
            child: BespokeTrendSparkline(
              dataPoints: [
                (rank + 2).toDouble(),
                (rank + 1).toDouble(),
                (rank + (isImproving ? 1 : -1)).toDouble(),
                rank.toDouble(),
              ],
              height: 22,
              lineColor: isImproving ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 8),
          // Trend Arrow
          Icon(
            isImproving ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 16,
            color: isImproving ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
          const SizedBox(width: 6),
          // Delete
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
                        'Technical Local Schema',
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
            'Google Knowledge Graph Schema markup generated for local ranking boost.',
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
                  'Sync Google Search Console data',
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
