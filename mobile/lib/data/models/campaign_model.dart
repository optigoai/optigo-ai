// ==================================================
// OptigoAI Mobile — Campaign Model (Phase 8)
// ==================================================

class CampaignModel {
  final String id;
  final String businessId;
  final String name;
  final String objective;
  final String audience;
  final String? offer;
  final String messaging;
  final String cta;
  final Map<String, dynamic>? contentIdeas;
  final Map<String, dynamic>? schedule;
  final String status;
  final DateTime? createdAt;

  CampaignModel({
    required this.id,
    required this.businessId,
    required this.name,
    required this.objective,
    required this.audience,
    this.offer,
    required this.messaging,
    required this.cta,
    this.contentIdeas,
    this.schedule,
    required this.status,
    this.createdAt,
  });

  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    return CampaignModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      name: json['name'] as String? ?? 'Marketing Campaign',
      objective: json['objective'] as String? ?? '',
      audience: json['audience'] as String? ?? '',
      offer: json['offer'] as String?,
      messaging: json['messaging'] as String? ?? '',
      cta: json['cta'] as String? ?? 'Visit Us',
      contentIdeas: json['content_ideas'] as Map<String, dynamic>?,
      schedule: json['schedule'] as Map<String, dynamic>?,
      status: json['status'] as String? ?? 'draft',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  bool get isActive => status == 'active';
  bool get isDraft => status == 'draft';
}
