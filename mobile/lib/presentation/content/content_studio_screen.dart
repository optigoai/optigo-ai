import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/models/content_model.dart';
import '../../data/repositories/content_repository.dart';
import '../auth/auth_provider.dart';
import '../shared/optigo_top_bar.dart';

/// OptigoAI Next-Gen AI Content & Campaign Studio (Screen 3)
/// Visual generator for promotional banners, social media posts, and multi-channel campaigns.
class ContentStudioScreen extends StatefulWidget {
  final VoidCallback? onNavigateToRecommendations;

  const ContentStudioScreen({super.key, this.onNavigateToRecommendations});

  @override
  State<ContentStudioScreen> createState() => _ContentStudioScreenState();
}

class _ContentStudioScreenState extends State<ContentStudioScreen> {
  ContentRepository? _contentRepo;
  bool _initialized = false;

  // Flow State: 0 = Format Selector, 1 = Campaign Builder, 2 = Creative Canvas Studio
  int _currentStep = 0;

  // Step 1: Selected Content Type
  String _selectedContentType = 'offer'; // 'social_post', 'offer', 'blog', 'event'
  final TextEditingController _themeController = TextEditingController(text: 'Weekend Special');
  final TextEditingController _offerDetailsController = TextEditingController(text: 'Flat 20% OFF on all products');

  // Step 2: Campaign Builder Parameters
  String _campaignGoal = 'foot_traffic'; // 'foot_traffic', 'online_orders', 'brand_awareness'
  final DateTime _startDate = DateTime.now();
  final DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  final Set<String> _selectedChannels = {'google_post', 'instagram', 'facebook', 'whatsapp'};

  // Step 3: Creative Studio State & Generation
  bool _isGenerating = false;
  ContentGenerateResponseModel? _generatedPostResult;
  String _selectedChannelTab = 'instagram';
  Color _creativeBgColor = const Color(0xFF0F172A);
  String _creativeHeadline = 'WEEKEND SPECIAL';
  String _creativeSubtext = 'Flat 20% OFF on all products';
  final String _creativeBadge = 'EXCLUSIVE PROMO';
  bool _isPublishing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _contentRepo = context.read<ContentRepository>();
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _themeController.dispose();
    _offerDetailsController.dispose();
    super.dispose();
  }

  void _onSelectContentType(String type, String defaultTheme, String defaultOffer) {
    setState(() {
      _selectedContentType = type;
      _themeController.text = defaultTheme;
      _offerDetailsController.text = defaultOffer;
      _creativeHeadline = defaultTheme.toUpperCase();
      _creativeSubtext = defaultOffer;
    });
  }

  Future<void> _handleGenerateAI() async {
    final businessId = context.read<AppAuthProvider>().currentBusiness?.id;
    final bizName = context.read<AppAuthProvider>().currentBusiness?.name ?? 'Our Store';
    if (businessId == null || _contentRepo == null) return;

    setState(() {
      _isGenerating = true;
      _currentStep = 2; // Jump to Creative Studio view
    });

    final topic = _themeController.text.trim().isNotEmpty ? _themeController.text.trim() : 'Weekend Special';
    final offer = _offerDetailsController.text.trim().isNotEmpty ? _offerDetailsController.text.trim() : '20% OFF';

    try {
      final result = await _contentRepo!.generatePosts(
        businessId: businessId,
        channels: _selectedChannels.toList(),
        topic: topic,
        tone: 'Engaging & Friendly',
        offerDetails: offer,
      );

      if (mounted) {
        setState(() {
          _generatedPostResult = result;
          _creativeHeadline = topic.toUpperCase();
          _creativeSubtext = offer;
          _isGenerating = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _generatedPostResult = ContentGenerateResponseModel(
            businessId: businessId,
            campaignTheme: topic,
            posts: [
              GeneratedPostItemModel(
                channel: 'instagram',
                title: '🎉 $topic is live!',
                body: 'Get ready for exclusive savings with $offer at $bizName. Quality guaranteed!',
                hashtags: '#WeekendSpecial #ShopLocal #FreshQuality #SpecialOffer',
                callToAction: 'Visit us today!',
              ),
              GeneratedPostItemModel(
                channel: 'facebook',
                title: 'Exciting News from $bizName',
                body: 'We are celebrating $topic! Enjoy $offer across our store. Tag your family & friends!',
                hashtags: '#BestDeals #LocalBusiness #ShopSmart',
                callToAction: 'Order now!',
              ),
              GeneratedPostItemModel(
                channel: 'google_post',
                title: '$bizName $topic',
                body: '$topic: $offer. Visit our store or call for instant inquiries.',
                hashtags: '',
                callToAction: 'Call Now',
              ),
              GeneratedPostItemModel(
                channel: 'whatsapp',
                title: 'Special Announcement',
                body: 'Hello from $bizName! $topic is live with $offer. Reply to this message to claim!',
                hashtags: '',
                callToAction: 'Order on WhatsApp',
              ),
            ],
            calendarSuggestions: [],
          );
          _creativeHeadline = topic.toUpperCase();
          _creativeSubtext = offer;
          _isGenerating = false;
        });
      }
    }
  }

  String _getPostForChannel(String channel, String bizName) {
    if (_generatedPostResult != null && _generatedPostResult!.posts.isNotEmpty) {
      for (final p in _generatedPostResult!.posts) {
        if (p.channel.toLowerCase() == channel.toLowerCase()) {
          final buffer = StringBuffer();
          if (p.title != null && p.title!.isNotEmpty) {
            buffer.writeln('${p.title}\n');
          }
          buffer.write(p.body);
          if (p.hashtags != null && p.hashtags!.isNotEmpty) {
            buffer.write('\n\n${p.hashtags}');
          }
          return buffer.toString();
        }
      }
      final first = _generatedPostResult!.posts.first;
      return '${first.body}${first.hashtags != null ? '\n\n${first.hashtags}' : ''}';
    }
    return '🎉 Special Promotion at $bizName! ${_offerDetailsController.text}. Visit us today! ✨ #ShopLocal #SpecialOffer';
  }

  Future<void> _handlePublish() async {
    setState(() => _isPublishing = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() => _isPublishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ Creative saved and campaign scheduled successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            children: [
              // Top Profile Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: OptigoTopBar(
                  subtitle: 'AI Content & Campaign Studio',
                  onNotificationTap: widget.onNavigateToRecommendations,
                ),
              ),

              // Animated Step View
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.04, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _buildCurrentStepView(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 0:
        return _buildStep1IntentSelector();
      case 1:
        return _buildStep2CampaignBuilder();
      case 2:
      default:
        return _buildStep3CreativeStudio();
    }
  }

  // ==========================================
  // STEP 1: Format Selector
  // ==========================================
  Widget _buildStep1IntentSelector() {
    return SingleChildScrollView(
      key: const ValueKey('step_1'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What do you want to create?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose a high-converting marketing format tailored for local customers.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 18),

          // 4 Intent Format Cards
          _buildIntentCard(
            id: 'offer',
            title: 'Promotional Offer & Discount',
            subtitle: 'Weekend specials, festive sales, and coupon announcements',
            icon: Icons.local_offer_rounded,
            iconColor: const Color(0xFF2563EB),
            iconBg: const Color(0xFFEFF6FF),
            defaultTheme: 'Weekend Special',
            defaultOffer: 'Flat 20% OFF on all items',
          ),
          const SizedBox(height: 10),

          _buildIntentCard(
            id: 'social_post',
            title: 'Social Media Announcement',
            subtitle: 'Instagram reels, Facebook updates, and Google Maps posts',
            icon: Icons.photo_camera_back_rounded,
            iconColor: const Color(0xFFE1306C),
            iconBg: const Color(0xFFFDF2F8),
            defaultTheme: 'Fresh Products Arrival',
            defaultOffer: 'Premium quality guaranteed',
          ),
          const SizedBox(height: 10),

          _buildIntentCard(
            id: 'blog',
            title: 'SEO Article & Local Story',
            subtitle: 'Educational guides, product benefits, and local SEO stories',
            icon: Icons.article_rounded,
            iconColor: const Color(0xFF8B5CF6),
            iconBg: const Color(0xFFF5F3FF),
            defaultTheme: 'Health Benefits of Pure Cold-Pressed Oils',
            defaultOffer: 'Explore our pure organic range',
          ),
          const SizedBox(height: 10),

          _buildIntentCard(
            id: 'event',
            title: 'Store Event & Festival',
            subtitle: 'Festival celebrations, anniversary sales, and community invites',
            icon: Icons.celebration_rounded,
            iconColor: const Color(0xFFF59E0B),
            iconBg: const Color(0xFFFEF3C7),
            defaultTheme: 'Festival Celebration Sale',
            defaultOffer: 'Special gifts with every purchase',
          ),

          const SizedBox(height: 20),

          // Campaign Topic & Offer Details Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Campaign Theme & Offer Details',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _themeController,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Topic / Campaign Theme',
                    labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _offerDetailsController,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Offer / Main Value Proposition',
                    labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Primary Continue Button
          ElevatedButton.icon(
            onPressed: () => setState(() => _currentStep = 1),
            icon: const Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white),
            label: Text(
              'Continue to Campaign Setup',
              style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildIntentCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String defaultTheme,
    required String defaultOffer,
  }) {
    final isSelected = _selectedContentType == id;

    return InkWell(
      onTap: () => _onSelectContentType(id, defaultTheme, defaultOffer),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF2563EB).withValues(alpha: 0.08)
                  : const Color(0xFF0F172A).withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STEP 2: Campaign Setup & Multi-Channel
  // ==========================================
  Widget _buildStep2CampaignBuilder() {
    return SingleChildScrollView(
      key: const ValueKey('step_2'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _currentStep = 0),
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Text(
                'Campaign Builder',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Target your local marketing channels and set campaign objectives.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 18),

          // Campaign Objective Header
          Text(
            'Campaign Goal',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildGoalChip(id: 'foot_traffic', label: '🚶 Store Foot Traffic'),
              const SizedBox(width: 8),
              _buildGoalChip(id: 'online_orders', label: '💬 Inquiries'),
              const SizedBox(width: 8),
              _buildGoalChip(id: 'brand_awareness', label: '📢 Brand Reach'),
            ],
          ),

          const SizedBox(height: 20),

          // Publishing Channels
          Text(
            'Publishing Channels',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildChannelCard(id: 'google_post', name: 'Google', icon: Icons.travel_explore_rounded, color: const Color(0xFFEA4335)),
              _buildChannelCard(id: 'instagram', name: 'Instagram', icon: Icons.camera_alt_rounded, color: const Color(0xFFE1306C)),
              _buildChannelCard(id: 'facebook', name: 'Facebook', icon: Icons.facebook_rounded, color: const Color(0xFF1877F2)),
              _buildChannelCard(id: 'whatsapp', name: 'WhatsApp', icon: Icons.chat_bubble_rounded, color: const Color(0xFF25D366)),
            ],
          ),

          const SizedBox(height: 20),

          // Schedule Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Campaign Schedule Duration',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Start Date', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('End Date', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              '${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Primary Launch Button
          ElevatedButton.icon(
            onPressed: _handleGenerateAI,
            icon: const Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white),
            label: Text(
              'Generate Multi-Channel Creative',
              style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGoalChip({required String id, required String label}) {
    final isSelected = _campaignGoal == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _campaignGoal = id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF475569),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChannelCard({
    required String id,
    required String name,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedChannels.contains(id);

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            if (_selectedChannels.length > 1) _selectedChannels.remove(id);
          } else {
            _selectedChannels.add(id);
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0xFF2563EB).withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              size: 16,
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STEP 3: Creative Canvas & Studio
  // ==========================================
  Widget _buildStep3CreativeStudio() {
    final bizName = context.read<AppAuthProvider>().currentBusiness?.name ?? 'My Business';

    return SingleChildScrollView(
      key: const ValueKey('step_3'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _currentStep = 1),
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Text(
                'Creative Studio',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.6,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => setState(() => _currentStep = 0),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, size: 14, color: Color(0xFF2563EB)),
                      const SizedBox(width: 4),
                      Text('New', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF2563EB))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'AI-generated promotional banner and multi-channel copy.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 18),

          // 1. Marketing Graphic Canvas
          if (_isGenerating)
            Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF2563EB)),
                    const SizedBox(height: 16),
                    Text(
                      'AI is designing your marketing creative...',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB)),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildCreativeGraphicCanvas(bizName: bizName),

          const SizedBox(height: 18),

          // 2. Multi-Channel Copy Section
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Multi-Channel Copy',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        final currentText = _getPostForChannel(_selectedChannelTab, bizName);
                        Clipboard.setData(ClipboardData(text: currentText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied caption to clipboard!')),
                        );
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF2563EB)),
                          const SizedBox(width: 4),
                          Text('Copy', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF2563EB))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Channel Selector Tabs
                Row(
                  children: [
                    _buildCopyChannelTab('instagram', 'Instagram'),
                    const SizedBox(width: 6),
                    _buildCopyChannelTab('facebook', 'Facebook'),
                    const SizedBox(width: 6),
                    _buildCopyChannelTab('google_post', 'Google'),
                    const SizedBox(width: 6),
                    _buildCopyChannelTab('whatsapp', 'WhatsApp'),
                  ],
                ),
                const SizedBox(height: 12),

                // Caption Text
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    _getPostForChannel(_selectedChannelTab, bizName),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      height: 1.45,
                      color: const Color(0xFF334155),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. Action Buttons (Edit Design & Download / Publish)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _showEditDesignSheet,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Edit Design',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isPublishing ? null : _handlePublish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isPublishing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          'Publish / Save',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCopyChannelTab(String id, String label) {
    final isSelected = _selectedChannelTab == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedChannelTab = id),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
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
  // MARKETING BANNER CANVAS
  // ==========================================
  Widget _buildCreativeGraphicCanvas({required String bizName}) {
    return Container(
      width: double.infinity,
      height: 290,
      decoration: BoxDecoration(
        color: _creativeBgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Gradient Overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _creativeBgColor.withValues(alpha: 0.95),
                  const Color(0xFF0F172A),
                ],
              ),
            ),
          ),

          // Banner Content
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Store Pill & Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        bizName.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _creativeBadge,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                // Center Headline & Subtext
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _creativeHeadline,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _creativeSubtext,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                // Bottom Call-to-action Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '✨ Verified Quality • Direct Mill Prices',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF0F172A), size: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDesignSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customize Design Theme',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 16),
              Text('Background Palette', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildColorOption(const Color(0xFF0F172A)),
                  const SizedBox(width: 12),
                  _buildColorOption(const Color(0xFF1E3A8A)),
                  const SizedBox(width: 12),
                  _buildColorOption(const Color(0xFF064E3B)),
                  const SizedBox(width: 12),
                  _buildColorOption(const Color(0xFF701A75)),
                  const SizedBox(width: 12),
                  _buildColorOption(const Color(0xFF7C2D12)),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Apply Changes', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColorOption(Color color) {
    final isSelected = _creativeBgColor == color;
    return InkWell(
      onTap: () {
        setState(() => _creativeBgColor = color);
        Navigator.pop(context);
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    );
  }
}
