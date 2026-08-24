// ==================================================
// OptigoAI Mobile — AI CMO Chat Model (Phase 10)
// ==================================================

class CmoSuggestedAction {
  final String label;
  final String route;
  final String icon;
  final String? prompt;

  CmoSuggestedAction({
    required this.label,
    required this.route,
    required this.icon,
    this.prompt,
  });

  factory CmoSuggestedAction.fromJson(Map<String, dynamic> json) {
    return CmoSuggestedAction(
      label: json['label'] as String? ?? 'Take Action',
      route: json['route'] as String? ?? 'home',
      icon: json['icon'] as String? ?? 'auto_awesome',
      prompt: json['prompt'] as String?,
    );
  }
}

class CmoChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final List<CmoSuggestedAction> suggestedActions;
  final String? actionType; // 'review_reply', 'social_post', 'keyword_audit', etc.
  final Map<String, dynamic>? actionPayload;
  final DateTime createdAt;

  CmoChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.suggestedActions,
    this.actionType,
    this.actionPayload,
    required this.createdAt,
  });

  factory CmoChatMessage.fromJson(Map<String, dynamic> json) {
    var rawActions = json['suggested_actions'] as List<dynamic>? ?? [];
    return CmoChatMessage(
      id: json['id'] as String? ?? '',
      role: json['role'] as String? ?? 'assistant',
      content: json['content'] as String? ?? '',
      suggestedActions: rawActions
          .map((a) => CmoSuggestedAction.fromJson(a as Map<String, dynamic>))
          .toList(),
      actionType: json['action_type'] as String?,
      actionPayload: json['action_payload'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isUser => role == 'user';
}
