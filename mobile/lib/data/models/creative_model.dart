// ==================================================
// OptigoAI Mobile — Creative Model (Phase 9)
// ==================================================

class CreativeModel {
  final String id;
  final String businessId;
  final String title;
  final String? description;
  final String? style;
  final String? fileUrl;
  final String status;
  final Map<String, dynamic>? generationMetadata;
  final String? campaignId;
  final DateTime? createdAt;

  CreativeModel({
    required this.id,
    required this.businessId,
    required this.title,
    this.description,
    this.style,
    this.fileUrl,
    required this.status,
    this.generationMetadata,
    this.campaignId,
    this.createdAt,
  });

  factory CreativeModel.fromJson(Map<String, dynamic> json) {
    return CreativeModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      title: json['title'] as String? ?? 'Promo Banner',
      description: json['description'] as String?,
      style: json['style'] as String?,
      fileUrl: json['file_url'] as String?,
      status: json['status'] as String? ?? 'completed',
      generationMetadata: json['generation_metadata'] as Map<String, dynamic>?,
      campaignId: json['campaign_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
