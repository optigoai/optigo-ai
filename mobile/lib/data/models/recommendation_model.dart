class RecommendationModel {
  final String id;
  final String businessId;
  final String title;
  final String explanation;
  final String reason;
  final String priority; // 'urgent', 'important', 'opportunity'
  final String impact;
  final String effort;
  final String suggestedAction;
  final String? relatedFeature; // 'reviews', 'posts', 'campaigns', 'seo'
  final String status; // 'pending', 'in_progress', 'completed', 'dismissed'
  final int sortOrder;
  final String? createdAt;

  RecommendationModel({
    required this.id,
    required this.businessId,
    required this.title,
    required this.explanation,
    required this.reason,
    required this.priority,
    required this.impact,
    required this.effort,
    required this.suggestedAction,
    this.relatedFeature,
    required this.status,
    required this.sortOrder,
    this.createdAt,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    return RecommendationModel(
      id: json['id'] ?? '',
      businessId: json['business_id'] ?? '',
      title: json['title'] ?? '',
      explanation: json['explanation'] ?? '',
      reason: json['reason'] ?? '',
      priority: (json['priority'] ?? 'important').toString().toLowerCase(),
      impact: json['impact'] ?? '',
      effort: json['effort'] ?? '',
      suggestedAction: json['suggested_action'] ?? '',
      relatedFeature: json['related_feature'],
      status: (json['status'] ?? 'pending').toString().toLowerCase(),
      sortOrder: json['sort_order'] ?? 0,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'title': title,
      'explanation': explanation,
      'reason': reason,
      'priority': priority,
      'impact': impact,
      'effort': effort,
      'suggested_action': suggestedAction,
      'related_feature': relatedFeature,
      'status': status,
      'sort_order': sortOrder,
      'created_at': createdAt,
    };
  }

  bool get isUrgent => priority == 'urgent';
  bool get isImportant => priority == 'important';
  bool get isOpportunity => priority == 'opportunity';
  bool get isCompleted => status == 'completed';
  bool get isDismissed => status == 'dismissed';
}

class CMOGenerateRecommendationsModel {
  final String businessId;
  final String cmoNote;
  final List<RecommendationModel> recommendations;

  CMOGenerateRecommendationsModel({
    required this.businessId,
    required this.cmoNote,
    required this.recommendations,
  });

  factory CMOGenerateRecommendationsModel.fromJson(Map<String, dynamic> json) {
    return CMOGenerateRecommendationsModel(
      businessId: json['business_id'] ?? '',
      cmoNote: json['cmo_note'] ?? '',
      recommendations: (json['recommendations'] as List? ?? [])
          .map((r) => RecommendationModel.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}
