// ==================================================
// OptigoAI Mobile — AI CMO Assistant Drawer (Phase 10)
// ==================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/models/cmo_chat_model.dart';
import '../../data/repositories/cmo_chat_repository.dart';
import '../auth/auth_provider.dart';

class CmoChatDrawer extends StatefulWidget {
  final String currentScreen;
  final Function(String route)? onNavigate;

  const CmoChatDrawer({
    super.key,
    this.currentScreen = 'home',
    this.onNavigate,
  });

  static void show(BuildContext context, {String currentScreen = 'home', Function(String route)? onNavigate}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CmoChatDrawer(
        currentScreen: currentScreen,
        onNavigate: onNavigate,
      ),
    );
  }

  @override
  State<CmoChatDrawer> createState() => _CmoChatDrawerState();
}

class _CmoChatDrawerState extends State<CmoChatDrawer> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<CmoChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _seedWelcomeMessage();
  }

  void _seedWelcomeMessage() {
    final bizName = context.read<AppAuthProvider>().currentBusiness?.name ?? 'your business';
    _messages.add(
      CmoChatMessage(
        id: 'welcome',
        role: 'assistant',
        content:
            "Hello! I am your AI CMO for $bizName. I track your customer reviews, Google Maps ranking, and marketing health in real-time. How can I help you grow today?",
        suggestedActions: [
          CmoSuggestedAction(
            label: "What's my top priority today?",
            route: 'actions',
            icon: 'bolt',
            prompt: "What is my top marketing priority today?",
          ),
          CmoSuggestedAction(
            label: "Draft response for latest review",
            route: 'reviews',
            icon: 'rate_review',
            prompt: "Draft a response for my latest customer review",
          ),
          CmoSuggestedAction(
            label: "Create a promotional post",
            route: 'create',
            icon: 'campaign',
            prompt: "Create a high-converting promotional post for this week",
          ),
          CmoSuggestedAction(
            label: "How to boost Google ranking?",
            route: 'seo',
            icon: 'travel_explore',
            prompt: "How can I boost my Google Maps ranking to #1?",
          ),
          CmoSuggestedAction(
            label: "Analyze local competitors",
            route: 'seo',
            icon: 'shield',
            prompt: "Analyze my top competitors in this local area",
          ),
        ],
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final businessId = context.read<AppAuthProvider>().currentBusiness?.id;
    if (businessId == null) return;

    final userMsg = CmoChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: text.trim(),
      suggestedActions: [],
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _inputController.clear();
    _scrollToBottom();

    try {
      final cmoRepo = context.read<CmoChatRepository>();
      final reply = await cmoRepo.sendMessage(
        businessId: businessId,
        message: text.trim(),
        contextScreen: widget.currentScreen,
      );

      if (mounted) {
        setState(() {
          _messages.add(reply);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.add(
            CmoChatMessage(
              id: 'err_${DateTime.now().millisecondsSinceEpoch}',
              role: 'assistant',
              content: "I'm analyzing your marketing performance. Reviewing unanswered reviews and active keywords will yield the fastest growth right now.",
              suggestedActions: [
                CmoSuggestedAction(label: "Go to Actions", route: 'actions', icon: 'insights'),
                CmoSuggestedAction(label: "Check SEO", route: 'seo', icon: 'search'),
              ],
              createdAt: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle & Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Image.asset('assets/images/optigo-bot.png', fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'AI CMO Assistant',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Always-On Strategic Advice',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Message Stream
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: const [
                  SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('AI CMO is typing...', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),

          // Bottom Input Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _handleSendMessage,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Ask your AI CMO anything...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFF2563EB)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF2563EB)),
                  onPressed: () => _handleSendMessage(_inputController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(String icon) {
    switch (icon) {
      case 'bolt':
      case 'insights':
        return Icons.bolt_rounded;
      case 'rate_review':
        return Icons.rate_review_rounded;
      case 'campaign':
      case 'edit_note':
        return Icons.campaign_rounded;
      case 'travel_explore':
      case 'search':
        return Icons.travel_explore_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'auto_awesome':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.touch_app_rounded;
    }
  }

  Widget _buildMessageBubble(CmoChatMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(18).copyWith(bottomRight: const Radius.circular(4)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            msg.content,
            style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.4, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20).copyWith(topLeft: const Radius.circular(4)),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI Badge Header
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFDBEAFE)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset('assets/images/optigo-bot.png', fit: BoxFit.contain),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'AI CMO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2563EB),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Beautiful Markdown Formatted Content
                  _buildFormattedContent(msg.content),
                ],
              ),
            ),

            if (msg.actionType != null && msg.actionPayload != null) ...[
              const SizedBox(height: 10),
              _buildFunctionalActionCard(msg),
            ],

            if (msg.suggestedActions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: msg.suggestedActions.map((act) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      onTap: () {
                        if (act.prompt != null && act.prompt!.isNotEmpty) {
                          _handleSendMessage(act.prompt!);
                        } else {
                          Navigator.pop(context);
                          widget.onNavigate?.call(act.route);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getActionIcon(act.icon),
                              size: 16,
                              color: const Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                act.label,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: Color(0xFF2563EB),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFunctionalActionCard(CmoChatMessage msg) {
    final payload = msg.actionPayload ?? {};
    final type = msg.actionType;

    if (type == 'review_reply') {
      final draft = payload['draft_reply'] as String? ?? '';
      final reviewer = payload['reviewer_name'] as String? ?? 'Customer';
      final rating = payload['rating'] as int? ?? 5;

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.rate_review_rounded, size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 6),
                    Text(
                      'Draft for $reviewer ($rating★)',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Ready to Post',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: _buildInlineRichText(draft),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: draft));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reply copied to clipboard!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF2563EB)),
                    label: const Text(
                      'Copy Reply',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onNavigate?.call('reviews');
                    },
                    icon: const Icon(Icons.send_rounded, size: 14, color: Colors.white),
                    label: const Text(
                      'Open Reviews',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (type == 'social_post') {
      final caption = payload['caption'] as String? ?? '';
      final hashtags = (payload['hashtags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.campaign_rounded, size: 16, color: Color(0xFF8B5CF6)),
                SizedBox(width: 6),
                Text(
                  'Generated Social Post',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: _buildInlineRichText(caption),
            ),
            if (hashtags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: hashtags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: caption));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Caption copied to clipboard!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF8B5CF6)),
                    label: const Text(
                      'Copy Caption',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF8B5CF6)),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: const BorderSide(color: Color(0xFFDDD6FE)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onNavigate?.call('create');
                    },
                    icon: const Icon(Icons.edit_note_rounded, size: 15, color: Colors.white),
                    label: const Text(
                      'Creative Studio',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildFormattedContent(String content) {
    final lines = content.split('\n');
    final List<Widget> widgets = [];
    int i = 0;

    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        i++;
        continue;
      }

      // 1. Dividers (***, ---, ___)
      if (trimmed == '***' || trimmed == '---' || trimmed == '___') {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          ),
        );
        i++;
        continue;
      }

      // 2. Headings (#, ##, ###, #### or lines starting with #)
      if (trimmed.startsWith('#')) {
        int level = 1;
        if (trimmed.startsWith('####')) {
          level = 4;
        } else if (trimmed.startsWith('###')) {
          level = 3;
        } else if (trimmed.startsWith('##')) {
          level = 2;
        }

        final headerText = trimmed.replaceFirst(RegExp(r'^#+\s*'), '');
        final double fontSize = level == 1 ? 15.5 : (level == 2 ? 14.5 : (level == 3 ? 14.0 : 13.5));

        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              headerText,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
          ),
        );
        i++;
        continue;
      }

      // 3. Blockquotes (> ...)
      if (trimmed.startsWith('>')) {
        final quoteText = trimmed.replaceFirst(RegExp(r'^>\s*'), '');
        widgets.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: const Border(
                left: BorderSide(color: Color(0xFF2563EB), width: 3.5),
              ),
            ),
            child: _buildInlineRichText(quoteText),
          ),
        );
        i++;
        continue;
      }

      // 4. Bullet lists (- ..., * ..., • ...)
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ') || trimmed.startsWith('• ')) {
        final itemText = trimmed.substring(2).trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 5, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(Icons.circle, size: 5, color: Color(0xFF2563EB)),
                ),
                const SizedBox(width: 8),
                Expanded(child: _buildInlineRichText(itemText)),
              ],
            ),
          ),
        );
        i++;
        continue;
      }

      // 5. Numbered lists (1. ..., 2. ...)
      final numMatch = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(trimmed);
      if (numMatch != null) {
        final numStr = numMatch.group(1)!;
        final itemText = numMatch.group(2)!;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 5, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$numStr. ',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563EB),
                  ),
                ),
                Expanded(child: _buildInlineRichText(itemText)),
              ],
            ),
          ),
        );
        i++;
        continue;
      }

      // 6. Normal text paragraph line
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _buildInlineRichText(trimmed),
        ),
      );
      i++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildInlineRichText(String text) {
    // Strip any residual leading hashtag markers
    final cleanText = text.replaceFirst(RegExp(r'^#+\s*'), '');
    final List<InlineSpan> spans = [];
    final regex = RegExp(r'(\*\*([^*]+)\*\*|`([^`]+)`|\*([^*]+)\*|_([^_]+)_)');
    int lastIndex = 0;

    for (final match in regex.allMatches(cleanText)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: cleanText.substring(lastIndex, match.start),
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF1E293B),
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ));
      }

      final fullMatch = match.group(0)!;
      if (fullMatch.startsWith('**') && fullMatch.endsWith('**')) {
        final boldContent = match.group(2) ?? '';
        spans.add(TextSpan(
          text: boldContent,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            height: 1.45,
          ),
        ));
      } else if (fullMatch.startsWith('`') && fullMatch.endsWith('`')) {
        final codeContent = match.group(3) ?? '';
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Text(
              codeContent,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
        ));
      } else if ((fullMatch.startsWith('*') && fullMatch.endsWith('*')) ||
          (fullMatch.startsWith('_') && fullMatch.endsWith('_'))) {
        final italicContent = match.group(4) ?? match.group(5) ?? '';
        spans.add(TextSpan(
          text: italicContent,
          style: const TextStyle(
            fontSize: 13.5,
            fontStyle: FontStyle.italic,
            color: Color(0xFF334155),
            fontWeight: FontWeight.w500,
            height: 1.45,
          ),
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < cleanText.length) {
      spans.add(TextSpan(
        text: cleanText.substring(lastIndex),
        style: const TextStyle(
          fontSize: 13.5,
          color: Color(0xFF1E293B),
          height: 1.45,
          fontWeight: FontWeight.w500,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
