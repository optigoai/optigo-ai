import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
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

  // View state: 0 = AI Generator, 1 = Saved & Scheduled Posts
  int _activeViewIndex = 0;

  // Generator inputs
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _offerController = TextEditingController();
  final Set<String> _selectedChannels = {'google_post', 'instagram', 'facebook', 'linkedin'};
  String _selectedTone = 'Engaging & Warm';
  final List<String> _toneOptions = [
    'Engaging & Warm',
    'Mouthwatering',
    'Festive Special',
    'Urgent / Limited Time',
    'Professional & B2B'
  ];

  bool _isGenerating = false;
  ContentGenerateResponseModel? _generatedResult;

  // Saved Posts state
  List<ContentModel> _savedPosts = [];
  bool _isLoadingPosts = false;
  String _savedPostFilter = 'all';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _contentRepo = context.read<ContentRepository>();
      _initialized = true;
      _loadSavedPosts();
    }
  }

  Future<void> _loadSavedPosts() async {
    if (_contentRepo == null) return;
    final authProvider = context.read<AppAuthProvider>();
    final businessId = authProvider.currentBusiness?.id;
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

  Future<void> _handleGenerate() async {
    if (_contentRepo == null) return;
    final authProvider = context.read<AppAuthProvider>();
    final businessId = authProvider.currentBusiness?.id;
    if (businessId == null) return;

    if (_selectedChannels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one social channel')),
      );
      return;
    }

    setState(() => _isGenerating = true);
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
          _generatedResult = result;
          _isGenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Multi-channel posts synthesized successfully! ✨'),
            backgroundColor: OptigoTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generation failed: $e'), backgroundColor: OptigoTheme.error),
        );
      }
    }
  }

  Future<void> _handleSavePost(GeneratedPostItemModel item, {bool isScheduled = false}) async {
    if (_contentRepo == null) return;
    final authProvider = context.read<AppAuthProvider>();
    final businessId = authProvider.currentBusiness?.id;
    if (businessId == null) return;

    try {
      await _contentRepo!.createPost(
        businessId: businessId,
        contentType: item.channel,
        title: item.title,
        body: item.body,
        tone: _selectedTone,
        hashtags: item.hashtags,
        callToAction: item.callToAction,
        imagePrompt: item.imagePrompt,
        status: isScheduled ? 'scheduled' : 'draft',
        scheduledAt: isScheduled ? DateTime.now().add(const Duration(days: 1)).toIso8601String() : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isScheduled ? 'Post scheduled successfully!' : 'Post saved to drafts!'),
            backgroundColor: OptigoTheme.success,
          ),
        );
        _loadSavedPosts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: OptigoTheme.error),
        );
      }
    }
  }

  Future<void> _handlePublishSaved(ContentModel post) async {
    if (_contentRepo == null) return;
    final authProvider = context.read<AppAuthProvider>();
    final businessId = authProvider.currentBusiness?.id;
    if (businessId == null) return;

    try {
      await _contentRepo!.publishPost(post.id, businessId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post published successfully! 🎉'), backgroundColor: OptigoTheme.success),
        );
        _loadSavedPosts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: OptigoTheme.error),
        );
      }
    }
  }

  Future<void> _handleDeleteSaved(ContentModel post) async {
    if (_contentRepo == null) return;
    final authProvider = context.read<AppAuthProvider>();
    final businessId = authProvider.currentBusiness?.id;
    if (businessId == null) return;

    try {
      await _contentRepo!.deletePost(post.id, businessId);
      if (mounted) {
        setState(() => _savedPosts.removeWhere((p) => p.id == post.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: OptigoTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _activeViewIndex == 0 ? () async {} : _loadSavedPosts,
          color: const Color(0xFF2563EB),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Universal Top Bar
                OptigoTopBar(
                  subtitle: 'Content & Post Studio',
                  onNotificationTap: widget.onNavigateToRecommendations,
                ),

                const SizedBox(height: 12),

                // 2. Segment View Switcher (AI Generator vs Scheduled Posts)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSegmentButton(
                          title: '✨ AI Generator',
                          isSelected: _activeViewIndex == 0,
                          onTap: () => setState(() => _activeViewIndex = 0),
                        ),
                      ),
                      Expanded(
                        child: _buildSegmentButton(
                          title: '📅 Saved Posts (${_savedPosts.length})',
                          isSelected: _activeViewIndex == 1,
                          onTap: () {
                            setState(() => _activeViewIndex = 1);
                            _loadSavedPosts();
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Main Content
                if (_activeViewIndex == 0)
                  _buildGeneratorTab()
                else
                  _buildSavedPostsTab(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGeneratorTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Generator Configuration Box
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
                'Target Social Channels',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChannelToggle('google_post', 'Google Business', Icons.storefront_rounded),
                  _buildChannelToggle('instagram', 'Instagram', Icons.camera_alt_outlined),
                  _buildChannelToggle('facebook', 'Facebook', Icons.facebook_rounded),
                  _buildChannelToggle('linkedin', 'LinkedIn', Icons.business_center_outlined),
                ],
              ),

              const SizedBox(height: 14),

              const Text(
                'Topic or Promotion (Optional)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _topicController,
                decoration: InputDecoration(
                  hintText: 'e.g. Weekend special menu, 20% discount on catering',
                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Tone of Voice',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _toneOptions.map((tone) {
                    final isSelected = _selectedTone == tone;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(tone, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500)),
                        selected: isSelected,
                        selectedColor: const Color(0xFF2563EB),
                        labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF334155)),
                        onSelected: (_) => setState(() => _selectedTone = tone),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _handleGenerate,
                  icon: _isGenerating
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: Text(
                    _isGenerating ? 'Synthesizing with Gemini AI...' : 'Generate Multi-Channel Posts',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Generated Results Feed
        if (_generatedResult != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.palette_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Campaign Theme',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF93C5FD)),
                      ),
                      Text(
                        _generatedResult!.campaignTheme,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ..._generatedResult!.posts.map((p) => _buildGeneratedPostCard(p)),
        ],
      ],
    );
  }

  Widget _buildChannelToggle(String key, String label, IconData icon) {
    final isSelected = _selectedChannels.contains(key);
    return FilterChip(
      avatar: Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF2563EB)),
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600)),
      selected: isSelected,
      selectedColor: const Color(0xFF2563EB),
      labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF334155)),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedChannels.add(key);
          } else {
            _selectedChannels.remove(key);
          }
        });
      },
    );
  }

  Widget _buildGeneratedPostCard(GeneratedPostItemModel item) {
    Color channelColor;
    String channelLabel;
    IconData channelIcon;

    switch (item.channel) {
      case 'google_post':
        channelColor = const Color(0xFF2563EB);
        channelLabel = 'Google Business Post';
        channelIcon = Icons.storefront_rounded;
        break;
      case 'instagram':
        channelColor = const Color(0xFFE1306C);
        channelLabel = 'Instagram Caption';
        channelIcon = Icons.camera_alt_outlined;
        break;
      case 'facebook':
        channelColor = const Color(0xFF1877F2);
        channelLabel = 'Facebook Post';
        channelIcon = Icons.facebook_rounded;
        break;
      case 'linkedin':
        channelColor = const Color(0xFF0A66C2);
        channelLabel = 'LinkedIn Update';
        channelIcon = Icons.business_center_outlined;
        break;
      default:
        channelColor = const Color(0xFF2563EB);
        channelLabel = item.channel.toUpperCase();
        channelIcon = Icons.share_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Header Bar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: channelColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(channelIcon, color: channelColor, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                channelLabel,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: channelColor),
              ),
              const Spacer(),
              if (item.bestTimeToPost != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '⏰ ${item.bestTimeToPost}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                ),
            ],
          ),

          if (item.title != null && item.title!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              item.title!,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
          ],

          const SizedBox(height: 8),

          // Caption Body
          Text(
            item.body,
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
          ),

          if (item.hashtags != null && item.hashtags!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.hashtags!,
              style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
            ),
          ],

          if (item.callToAction != null && item.callToAction!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_rounded, size: 14, color: Color(0xFF2563EB)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'CTA: ${item.callToAction}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Action Buttons: Copy, Save Draft, Schedule
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  final textToCopy = '${item.title != null ? "${item.title}\n\n" : ""}${item.body}\n\n${item.hashtags ?? ""}';
                  Clipboard.setData(ClipboardData(text: textToCopy.trim()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Caption copied to clipboard! 📋')),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: const Text('Copy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _handleSavePost(item, isScheduled: false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Save Draft', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                onPressed: () => _handleSavePost(item, isScheduled: true),
                icon: const Icon(Icons.schedule_send_rounded, size: 14),
                label: const Text('Schedule', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: channelColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavedPostsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildSavedFilterChip('all', 'All Posts'),
              const SizedBox(width: 6),
              _buildSavedFilterChip('draft', 'Drafts'),
              const SizedBox(width: 6),
              _buildSavedFilterChip('scheduled', 'Scheduled'),
              const SizedBox(width: 6),
              _buildSavedFilterChip('published', 'Published'),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (_isLoadingPosts)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (_savedPosts.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: const [
                  Icon(Icons.feed_outlined, size: 40, color: Color(0xFF94A3B8)),
                  SizedBox(height: 8),
                  Text('No saved posts in this category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                  Text('Generate posts using the AI Generator tab.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ),
          )
        else
          ..._savedPosts.map((post) => _buildSavedPostCard(post)),
      ],
    );
  }

  Widget _buildSavedFilterChip(String key, String label) {
    final isSelected = _savedPostFilter == key;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500)),
      selected: isSelected,
      selectedColor: const Color(0xFF2563EB),
      labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF334155)),
      onSelected: (_) {
        setState(() => _savedPostFilter = key);
        _loadSavedPosts();
      },
    );
  }

  Widget _buildSavedPostCard(ContentModel post) {
    Color statusColor;
    if (post.isPublished) {
      statusColor = const Color(0xFF10B981);
    } else if (post.isScheduled) {
      statusColor = const Color(0xFF2563EB);
    } else {
      statusColor = const Color(0xFF64748B);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  post.status.toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: statusColor),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                post.contentType.replaceAll('_', ' ').toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
                onPressed: () => _handleDeleteSaved(post),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          if (post.title != null && post.title!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              post.title!,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            post.body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.3),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (post.scheduledAt != null)
                Text(
                  'Scheduled: ${post.scheduledAt!.split('T').first}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              const Spacer(),
              if (!post.isPublished)
                ElevatedButton(
                  onPressed: () => _handlePublishSaved(post),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Publish Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
