import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../data/models/content_model.dart';
import '../../data/models/campaign_model.dart';
import '../../data/models/creative_model.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/repositories/campaign_repository.dart';
import '../../data/repositories/creative_repository.dart';
import '../auth/auth_provider.dart';
import '../shared/optigo_top_bar.dart';

class ContentStudioScreen extends StatefulWidget {
  final VoidCallback? onNavigateToRecommendations;

  const ContentStudioScreen({super.key, this.onNavigateToRecommendations});

  @override
  State<ContentStudioScreen> createState() => _ContentStudioScreenState();
}

class _ContentStudioScreenState extends State<ContentStudioScreen> {
  ContentRepository? _contentRepo;
  CampaignRepository? _campaignRepo;
  CreativeRepository? _creativeRepo;
  bool _initialized = false;

  // View state: 0 = Social Posts, 1 = Multi-Channel Campaigns, 2 = Smart Creatives, 3 = Saved Assets
  int _activeViewIndex = 0;

  // 1. Social Post Generator state
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _offerController = TextEditingController();
  final Set<String> _selectedChannels = {'google_post', 'instagram', 'facebook', 'linkedin'};
  final String _selectedTone = 'Engaging & Warm';
  bool _isGeneratingPost = false;
  ContentGenerateResponseModel? _generatedPostResult;

  // 2. Campaign Studio (Phase 8) state
  String _campaignGoal = 'foot_traffic'; // foot_traffic, online_orders, seasonal_promo
  final int _campaignDuration = 7;
  final TextEditingController _campaignOfferController = TextEditingController();
  bool _isGeneratingCampaign = false;
  Map<String, dynamic>? _generatedCampaignPlan;
  List<CampaignModel> _activeCampaigns = [];

  // 3. Smart Creatives Studio (Phase 9) state
  final TextEditingController _creativeHeadlineController = TextEditingController(text: 'Special Mill Special');
  final TextEditingController _creativeOfferController = TextEditingController(text: 'Flat 20% Off Pure Coconut Oil');
  final String _creativeStyle = 'Modern Minimal';
  final String _creativeBadge = 'LIMITED OFFER';
  Color _creativeColor = const Color(0xFF2563EB);
  bool _isGeneratingCreative = false;
  List<CreativeModel> _savedCreatives = [];

  // 4. Saved Posts state
  List<ContentModel> _savedPosts = [];
  bool _isLoadingPosts = false;
  final String _savedPostFilter = 'all';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _contentRepo = context.read<ContentRepository>();
      _campaignRepo = context.read<CampaignRepository>();
      _creativeRepo = context.read<CreativeRepository>();
      _initialized = true;
      _loadData();
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    _offerController.dispose();
    _campaignOfferController.dispose();
    _creativeHeadlineController.dispose();
    _creativeOfferController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AppAuthProvider>();
    final businessId = authProvider.currentBusiness?.id;
    if (businessId == null) return;

    _loadSavedPosts();
    _loadCampaigns();
    _loadCreatives();
  }

  Future<void> _loadSavedPosts() async {
    if (_contentRepo == null) return;
    final businessId = context.read<AppAuthProvider>().currentBusiness?.id;
    if (businessId == null) return;

    setState(() => _isLoadingPosts = true);
    try {
      final posts = await _contentRepo!.getPosts(
        businessId: businessId,
        status: _savedPostFilter == 'all' ? null : _savedPostFilter,
      );
      if (mounted) {
        setState(() {
          _savedPosts = posts;
          _isLoadingPosts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPosts = false);
    }
  }

  Future<void> _loadCampaigns() async {
    if (_campaignRepo == null) return;
    final businessId = context.read<AppAuthProvider>().currentBusiness?.id;
    if (businessId == null) return;
    try {
      final camps = await _campaignRepo!.listCampaigns(businessId: businessId);
      if (mounted) setState(() => _activeCampaigns = camps);
    } catch (_) {}
  }

  Future<void> _loadCreatives() async {
    if (_creativeRepo == null) return;
    final businessId = context.read<AppAuthProvider>().currentBusiness?.id;
    if (businessId == null) return;
    try {
      final crs = await _creativeRepo!.listCreatives(businessId: businessId);
      if (mounted) setState(() => _savedCreatives = crs);
    } catch (_) {}
  }

  // Generate Social Posts
  Future<void> _handleGeneratePosts() async {
    if (_contentRepo == null) return;
    final businessId = context.read<AppAuthProvider>().currentBusiness?.id;
    if (businessId == null) return;

    setState(() => _isGeneratingPost = true);
    try {
      final result = await _contentRepo!.generatePosts(
        businessId: businessId,
        channels: _selectedChannels.toList(),
        topic: _topicController.text.trim().isNotEmpty ? _topicController.text.trim() : null,
        tone: _selectedTone,
        offerDetails: _offerController.text.trim().isNotEmpty ? _offerController.text.trim() : null,
      );
      if (mounted) {
        setState(() {
          _generatedPostResult = result;
          _isGeneratingPost = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingPost = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate posts: $e')),
        );
      }
    }
  }

  // Generate Multi-Channel Campaign (Phase 8)
  Future<void> _handleGenerateCampaign() async {
    if (_campaignRepo == null) return;
    final businessId = context.read<AppAuthProvider>().currentBusiness?.id;
    if (businessId == null) return;

    setState(() => _isGeneratingCampaign = true);
    try {
      final plan = await _campaignRepo!.generateCampaign(
        businessId: businessId,
        goal: _campaignGoal,
        durationDays: _campaignDuration,
        customOffer: _campaignOfferController.text.trim().isNotEmpty ? _campaignOfferController.text.trim() : null,
      );
      if (mounted) {
        setState(() {
          _generatedCampaignPlan = plan;
          _isGeneratingCampaign = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingCampaign = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate campaign: $e')),
        );
      }
    }
  }

  // Launch Campaign
  Future<void> _handleLaunchCampaign() async {
    if (_generatedCampaignPlan == null || _campaignRepo == null) return;
    final businessId = context.read<AppAuthProvider>().currentBusiness?.id;
    if (businessId == null) return;

    try {
      final newCamp = await _campaignRepo!.createCampaign(
        businessId: businessId,
        name: _generatedCampaignPlan!['name'] as String,
        objective: _generatedCampaignPlan!['objective'] as String,
        audience: _generatedCampaignPlan!['audience'] as String,
        offer: _generatedCampaignPlan!['offer'] as String?,
        messaging: _generatedCampaignPlan!['messaging'] as String,
        cta: _generatedCampaignPlan!['cta'] as String,
        contentIdeas: _generatedCampaignPlan!['content_ideas'] as Map<String, dynamic>?,
        schedule: _generatedCampaignPlan!['schedule'] as Map<String, dynamic>?,
      );

      await _campaignRepo!.launchCampaign(newCamp.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Campaign launched and scheduled across channels!'),
            backgroundColor: OptigoTheme.success,
          ),
        );
        setState(() => _generatedCampaignPlan = null);
        _loadCampaigns();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to launch campaign: $e'), backgroundColor: OptigoTheme.error),
        );
      }
    }
  }

  // Generate & Save Smart Creative (Phase 9)
  Future<void> _handleGenerateCreative() async {
    if (_creativeRepo == null) return;
    final businessId = context.read<AppAuthProvider>().currentBusiness?.id;
    if (businessId == null) return;

    setState(() => _isGeneratingCreative = true);
    try {
      await _creativeRepo!.generateCreative(
        businessId: businessId,
        headline: _creativeHeadlineController.text.trim(),
        offerText: _creativeOfferController.text.trim(),
        style: _creativeStyle.toLowerCase().replaceAll(' ', '_'),
      );
      if (mounted) {
        setState(() => _isGeneratingCreative = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Smart Creative exported and saved to library!'),
            backgroundColor: OptigoTheme.success,
          ),
        );
        _loadCreatives();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingCreative = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export creative: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: OptigoTopBar(subtitle: 'Marketing & Studio'),
            ),

            // Segment Tabs (Posts, Campaigns, Creatives, Saved)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  _buildStudioTab(0, '✨ Posts'),
                  _buildStudioTab(1, '🚀 Campaigns'),
                  _buildStudioTab(2, '🎨 Creatives'),
                  _buildStudioTab(3, '📁 Library'),
                ],
              ),
            ),

            // Tab Body Content
            Expanded(
              child: IndexedStack(
                index: _activeViewIndex,
                children: [
                  _buildPostsView(),
                  _buildCampaignsView(),
                  _buildCreativesView(),
                  _buildSavedLibraryView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudioTab(int index, String label) {
    final isSelected = _activeViewIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeViewIndex = index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // VIEW 1: AI Social Posts Generator (Phase 6)
  // ==========================================
  Widget _buildPostsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Generation Form Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Multi-Channel Post Generator',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 14),

                // Channels Selector
                Wrap(
                  spacing: 8,
                  children: [
                    _buildChannelChip('google_post', 'Google Maps'),
                    _buildChannelChip('instagram', 'Instagram'),
                    _buildChannelChip('facebook', 'Facebook'),
                  ],
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: _topicController,
                  decoration: InputDecoration(
                    labelText: 'Topic / Highlight (Optional)',
                    hintText: 'e.g. Fresh cold-pressed coconut oil batch',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: _offerController,
                  decoration: InputDecoration(
                    labelText: 'Offer / Discount (Optional)',
                    hintText: 'e.g. 15% Off this weekend',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingPost ? null : _handleGeneratePosts,
                    icon: _isGeneratingPost
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome, size: 18),
                    label: Text(
                      _isGeneratingPost ? 'Generating with Gemini...' : 'Generate Multi-Channel Posts',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Generated Posts Output
          if (_generatedPostResult != null) ...[
            const SizedBox(height: 20),
            const Text(
              'Generated Posts',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            ..._generatedPostResult!.posts.map((p) => _buildPostPreviewCard(p)),
          ],
        ],
      ),
    );
  }

  Widget _buildChannelChip(String channelKey, String label) {
    final isSelected = _selectedChannels.contains(channelKey);
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : const Color(0xFF334155))),
      selected: isSelected,
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: const Color(0xFFF1F5F9),
      checkmarkColor: Colors.white,
      onSelected: (val) {
        setState(() {
          if (val) {
            _selectedChannels.add(channelKey);
          } else if (_selectedChannels.length > 1) {
            _selectedChannels.remove(channelKey);
          }
        });
      },
    );
  }

  Widget _buildPostPreviewCard(GeneratedPostItemModel post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  post.channel.toUpperCase(),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF64748B)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: "${post.body}\n\n${post.hashtags}"));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied post to clipboard!')));
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(post.body, style: const TextStyle(fontSize: 13.5, height: 1.45, color: Color(0xFF1E293B))),
          if (post.hashtags != null && post.hashtags!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(post.hashtags!, style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // VIEW 2: Multi-Channel Campaigns (Phase 8)
  // ==========================================
  Widget _buildCampaignsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Multi-Channel Campaign Synthesizer',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 12),

                // Goal Selector
                const Text('Select Marketing Goal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildGoalChip('foot_traffic', '🚶 Foot Traffic'),
                    _buildGoalChip('online_orders', '📦 Online Orders'),
                    _buildGoalChip('seasonal_promo', '🎉 Seasonal Promo'),
                  ],
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: _campaignOfferController,
                  decoration: InputDecoration(
                    labelText: 'Offer or Discount (Optional)',
                    hintText: 'e.g. Free delivery on orders above \$50',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingCampaign ? null : _handleGenerateCampaign,
                    icon: _isGeneratingCampaign
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.rocket_launch_rounded, size: 18),
                    label: Text(
                      _isGeneratingCampaign ? 'Synthesizing Campaign...' : 'Generate 7-Day Campaign',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_generatedCampaignPlan != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                        child: const Text('AI CAMPAIGN PLAN', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _generatedCampaignPlan!['name'] as String,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _generatedCampaignPlan!['objective'] as String,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Multi-Channel Schedule', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  const SizedBox(height: 8),
                  if (_generatedCampaignPlan!['schedule'] != null)
                    ...(_generatedCampaignPlan!['schedule']['timeline'] as List<dynamic>? ?? []).map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6)),
                              child: Text('Day ${item['day']}', style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "${item['action']} (${item['channel'].toString().toUpperCase()}) — ${item['content_summary']}",
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _handleLaunchCampaign,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Launch & Schedule Campaign 🚀', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
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

  Widget _buildGoalChip(String goalKey, String label) {
    final isSelected = _campaignGoal == goalKey;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : const Color(0xFF334155))),
      selected: isSelected,
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: const Color(0xFFF1F5F9),
      onSelected: (_) => setState(() => _campaignGoal = goalKey),
    );
  }

  // ==========================================
  // VIEW 3: Smart Creatives Studio (Phase 9)
  // ==========================================
  Widget _buildCreativesView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Creative Canvas Preview Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_creativeColor, _creativeColor.withValues(alpha: 0.85)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: _creativeColor.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _creativeBadge,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _creativeHeadlineController.text,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  _creativeOfferController.text,
                  style: const TextStyle(fontSize: 13.5, color: Colors.white70, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('⭐ Authentic Local Quality', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                    Icon(Icons.qr_code_2_rounded, color: Colors.white70, size: 24),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Customizer Inputs
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Customize Flyer & Banner', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                const SizedBox(height: 12),
                TextField(
                  controller: _creativeHeadlineController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Headline',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _creativeOfferController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Offer Text',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                // Color Theme Selector
                Row(
                  children: [
                    _buildColorChoice(const Color(0xFF2563EB)),
                    const SizedBox(width: 10),
                    _buildColorChoice(const Color(0xFF0F172A)),
                    const SizedBox(width: 10),
                    _buildColorChoice(const Color(0xFF059669)),
                    const SizedBox(width: 10),
                    _buildColorChoice(const Color(0xFFDC2626)),
                  ],
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingCreative ? null : _handleGenerateCreative,
                    icon: _isGeneratingCreative
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.file_download_outlined, size: 18),
                    label: const Text('Export & Save High-Res Banner', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildColorChoice(Color c) {
    final isSelected = _creativeColor == c;
    return InkWell(
      onTap: () => setState(() => _creativeColor = c),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: const Color(0xFF0F172A), width: 2.5) : null,
        ),
      ),
    );
  }

  // ==========================================
  // VIEW 4: Saved Library & Campaigns
  // ==========================================
  Widget _buildSavedLibraryView() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        if (_activeCampaigns.isNotEmpty) ...[
          const Text('Active Campaigns', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 10),
          ..._activeCampaigns.map(
            (c) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Row(
                children: [
                  const Icon(Icons.campaign_rounded, color: Color(0xFF2563EB)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        Text(c.status.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (_savedCreatives.isNotEmpty) ...[
          const Text('Saved Smart Creatives', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 10),
          ..._savedCreatives.map(
            (cr) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Row(
                children: [
                  const Icon(Icons.image_outlined, color: Color(0xFF2563EB)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cr.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        if (cr.description != null)
                          Text(cr.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        const Text('Saved Posts & Drafts', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),
        if (_savedPosts.isEmpty && !_isLoadingPosts)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: Text('No saved items yet.', style: TextStyle(color: Color(0xFF64748B))),
            ),
          )
        else
          ..._savedPosts.map(
            (p) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.contentType.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
                  const SizedBox(height: 4),
                  Text(p.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
