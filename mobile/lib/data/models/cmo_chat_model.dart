// ==================================================
// OptigoAI Mobile — AI CMO Chat Model (Phase 10)
// ==================================================

class CmoSuggestedAction {
  final String label;
  final String route;
  final String icon;

  CmoSuggestedAction({
    required this.label,
    required this.route,
    required this.icon,
  });

  factory CmoSuggestedAction.fromJson(Map<String, dynamic> json) {
    return CmoSuggestedAction(
      label: json['label'] as String? ?? 'Take Action',
      route: json['route'] as String? ?? 'home',
      icon: json['icon'] as String? ?? 'auto_awesome',
    );
  }
}

class CmoChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final List<CmoSuggestedAction> suggestedActions;
  final DateTime createdAt;

  CmoChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.suggestedActions,
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
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isUser => role == 'user';
}
