// ==================================================
// OptigoAI Mobile — AI CMO Assistant Drawer (Phase 10)
// ==================================================

import 'package:flutter/material.dart';
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
          CmoSuggestedAction(label: "What's my top priority today?", route: 'actions', icon: 'insights'),
          CmoSuggestedAction(label: "How to boost Google ranking?", route: 'seo', icon: 'search'),
          CmoSuggestedAction(label: "Create a promotional post", route: 'create', icon: 'edit_note'),
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
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.auto_awesome, color: Colors.white, size: 18),
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
        margin: const EdgeInsets.only(bottom: 16, right: 28),
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
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.auto_awesome, size: 12, color: Color(0xFF2563EB)),
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

            if (msg.suggestedActions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: msg.suggestedActions.map((act) {
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      widget.onNavigate?.call(act.route);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.touch_app_rounded, size: 14, color: Color(0xFF2563EB)),
                          const SizedBox(width: 5),
                          Text(
                            act.label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
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

  Widget _buildFormattedContent(String content) {
    final paragraphs = content.split('\n\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < paragraphs.length; i++) ...[
          _buildParagraph(paragraphs[i]),
          if (i < paragraphs.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildParagraph(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();

    // Check for bullet list lines
    final lines = trimmed.split('\n');
    if (lines.length > 1 && lines.any((l) => l.trim().startsWith('- ') || l.trim().startsWith('* ') || l.trim().startsWith('• '))) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((line) {
          final l = line.trim();
          if (l.startsWith('- ') || l.startsWith('* ') || l.startsWith('• ')) {
            final itemText = l.substring(2);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 4),
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
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _buildInlineRichText(l),
          );
        }).toList(),
      );
    }

    // Header check: ###
    if (trimmed.startsWith('### ')) {
      return Text(
        trimmed.substring(4),
        style: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w900,
          color: Color(0xFF0F172A),
        ),
      );
    }

    return _buildInlineRichText(trimmed);
  }

  Widget _buildInlineRichText(String text) {
    final List<InlineSpan> spans = [];
    final regex = RegExp(r'(\*\*([^*]+)\*\*|\*([^*]+)\*|`([^`]+)`)');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF1E293B),
            height: 1.5,
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
            height: 1.5,
          ),
        ));
      } else if (fullMatch.startsWith('*') && fullMatch.endsWith('*')) {
        final italicContent = match.group(3) ?? '';
        spans.add(TextSpan(
          text: italicContent,
          style: const TextStyle(
            fontSize: 13.5,
            fontStyle: FontStyle.italic,
            color: Color(0xFF2563EB),
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ));
      } else if (fullMatch.startsWith('`') && fullMatch.endsWith('`')) {
        final codeContent = match.group(4) ?? '';
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
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
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: const TextStyle(
          fontSize: 13.5,
          color: Color(0xFF1E293B),
          height: 1.5,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
