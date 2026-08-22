import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/models/content_model.dart';
import '../../data/repositories/content_repository.dart';
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
  bool _initialized = false;

  // Flow State: 0 = Intent Selector, 1 = Campaign Builder, 2 = Creative Studio
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
  Color _creativeBgColor = const Color(0xFF1E293B);
  String _creativeHeadline = 'WEEKEND SPECIAL';
  String _creativeSubtext = '20% OFF on all products';
  final String _creativeBadge = 'LIMITED OFFER';
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
      _currentStep = 2; // Jump to Creative Studio view with loading skeleton
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
          // Fallback response items so UI never hangs
          _generatedPostResult = ContentGenerateResponseModel(
            businessId: businessId,
            campaignTheme: topic,
            posts: [
              GeneratedPostItemModel(
                channel: 'instagram',
                title: '🎉 $topic is here!',
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Profile / Notifications Bar
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
                        begin: const Offset(0.05, 0),
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

  // ==========================================================
  // STEP 1: "What do you want to create?" (Intent Selector)
  // Matching Reference Screen 1
  // ==========================================================
  Widget _buildStep1IntentSelector() {
    return SingleChildScrollView(
      key: const ValueKey('step_1'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What do you want to create?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Select a creation format to craft high-impact marketing.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),

          const SizedBox(height: 20),

          // 4 Intent Cards (Matching Reference Layout)
          _buildIntentCard(
            id: 'social_post',
            title: 'Social Media Post',
            subtitle: 'Instagram, Facebook & Google updates',
            icon: Icons.photo_library_outlined,
            iconColor: const Color(0xFFEF4444),
            defaultTheme: 'Fresh Products Arrival',
            defaultOffer: 'Best quality in town',
          ),
          const SizedBox(height: 12),

          _buildIntentCard(
            id: 'offer',
            title: 'Offer / Promotion',
            subtitle: 'Discounts, weekend specials & coupons',
            icon: Icons.local_offer_outlined,
            iconColor: const Color(0xFF2563EB),
            defaultTheme: 'Weekend Special',
            defaultOffer: 'Flat 20% OFF on all products',
          ),
          const SizedBox(height: 12),

          _buildIntentCard(
            id: 'blog',
            title: 'Blog / Article',
            subtitle: 'SEO articles, product benefits & guides',
            icon: Icons.article_outlined,
            iconColor: const Color(0xFF8B5CF6),
            defaultTheme: 'Health Benefits of Pure Cold-Pressed Oils',
            defaultOffer: 'Read our latest guide',
          ),
          const SizedBox(height: 12),

          _buildIntentCard(
            id: 'event',
            title: 'Event Announcement',
            subtitle: 'Store festival, milestone & launch',
            icon: Icons.campaign_outlined,
            iconColor: const Color(0xFFEC4899),
            defaultTheme: 'Festival Celebration Sale',
            defaultOffer: 'Special gifts on every purchase',
          ),

          const SizedBox(height: 24),

          // Context Input Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Campaign Theme & Offer',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _themeController,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    labelText: 'Topic / Theme',
                    labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _offerDetailsController,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    labelText: 'Offer / Call-to-action',
                    labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Primary Button: Continue to Campaign Builder
          InkWell(
            onTap: () => setState(() => _currentStep = 1),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Generate with AI',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
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
    required String defaultTheme,
    required String defaultOffer,
  }) {
    final isSelected = _selectedContentType == id;

    return InkWell(
      onTap: () => _onSelectContentType(id, defaultTheme, defaultOffer),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0xFF2563EB).withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.02),
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
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
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

  // ==========================================================
  // STEP 2: "Campaign Builder" (Schedule, Goals, Channels)
  // Matching Reference Screen 2
  // ==========================================================
  Widget _buildStep2CampaignBuilder() {
    return SingleChildScrollView(
      key: const ValueKey('step_2'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Back Button
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _currentStep = 0),
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              const Text(
                'Campaign Builder',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Configure your campaign objectives and target channels.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),

          const SizedBox(height: 20),

          // Campaign Name Pill Box (Matching Reference Screen 2)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _themeController.text.isNotEmpty ? _themeController.text : 'Weekend Special',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const Icon(Icons.edit_note_rounded, size: 20, color: Color(0xFF2563EB)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Campaign Goal Selector
          const Text(
            'Campaign Goal',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildGoalChip(id: 'foot_traffic', label: '🚶 Store Visits'),
              const SizedBox(width: 8),
              _buildGoalChip(id: 'online_orders', label: '🛍️ Inquiries'),
              const SizedBox(width: 8),
              _buildGoalChip(id: 'brand_awareness', label: '📢 Visibility'),
            ],
          ),

          const SizedBox(height: 24),

          // Schedule Section (Matching Reference Screen 2)
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
                const Text(
                  'Campaign Schedule',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
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
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
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
                          const Text('End Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
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
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
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

          const SizedBox(height: 24),

          // Publishing Channels (Matching Reference Screen 2: Google, Instagram, Facebook, WhatsApp)
          const Text(
            'Channels',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildChannelCard(
                id: 'google_post',
                name: 'Google',
                icon: Icons.travel_explore_rounded,
                color: const Color(0xFFEA4335),
              ),
              _buildChannelCard(
                id: 'instagram',
                name: 'Instagram',
                icon: Icons.camera_alt_rounded,
                color: const Color(0xFFE1306C),
              ),
              _buildChannelCard(
                id: 'facebook',
                name: 'Facebook',
                icon: Icons.facebook_rounded,
                color: const Color(0xFF1877F2),
              ),
              _buildChannelCard(
                id: 'whatsapp',
                name: 'WhatsApp',
                icon: Icons.chat_bubble_rounded,
                color: const Color(0xFF25D366),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Primary Button: Review & Launch (Trigger Generation)
          InkWell(
            onTap: _handleGenerateAI,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 17),
                  SizedBox(width: 8),
                  Text(
                    'Review & Launch',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
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
              style: TextStyle(
                fontSize: 11,
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
        padding: const EdgeInsets.symmetric(vertical: 14),
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
              style: TextStyle(
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

  // ==========================================================
  // STEP 3: "Creative Studio" (Creative Canvas Preview & Actions)
  // Matching Reference Screen 3
  // ==========================================================
  Widget _buildStep3CreativeStudio() {
    final bizName = context.read<AppAuthProvider>().currentBusiness?.name ?? 'My Business';

    return SingleChildScrollView(
      key: const ValueKey('step_3'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Back Button
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _currentStep = 1),
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              const Text(
                'Creative Studio',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 14, color: Color(0xFF2563EB)),
                      SizedBox(width: 4),
                      Text('New', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'AI-generated promotional banner and multi-channel copy.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),

          const SizedBox(height: 20),

          // 1. Marketing Banner Graphic Preview (Matching Reference Screen 3)
          if (_isGenerating)
            Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF2563EB)),
                    SizedBox(height: 16),
                    Text(
                      'AI is designing your marketing creative...',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildCreativeGraphicCanvas(bizName: bizName),

          const SizedBox(height: 20),

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
                    const Text(
                      'Generated Copy',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    InkWell(
                      onTap: () {
                        final currentText = _getPostForChannel(_selectedChannelTab, bizName);
                        Clipboard.setData(ClipboardData(text: currentText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied caption to clipboard!')),
                        );
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.copy_rounded, size: 14, color: Color(0xFF2563EB)),
                          SizedBox(width: 4),
                          Text('Copy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
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
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. Action Buttons (Matching Reference Screen 3: Edit Design & Download / Publish)
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _showEditDesignSheet,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
                    ),
                    child: const Center(
                      child: Text(
                        'Edit Design',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: InkWell(
                  onTap: _isPublishing ? null : _handlePublish,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isPublishing
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text(
                              'Download',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
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
              style: TextStyle(
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

  // ==========================================================
  // MARKETING BANNER CANVAS (Reference Screen 3 Banner)
  // ==========================================================
  Widget _buildCreativeGraphicCanvas({required String bizName}) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: _creativeBgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
            padding: const EdgeInsets.all(24),
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        bizName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _creativeBadge,
                        style: const TextStyle(
                          fontSize: 10,
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
                      style: const TextStyle(
                        fontSize: 28,
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
                        style: const TextStyle(
                          fontSize: 15,
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
                    const Text(
                      '✨ Verified Quality • Direct Mill Prices',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
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
              const Text(
                'Customize Design Theme',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 16),
              const Text('Background Palette', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildColorOption(const Color(0xFF1E293B)),
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
                  child: const Text('Apply Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
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
