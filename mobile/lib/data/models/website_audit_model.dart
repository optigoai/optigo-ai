// ==================================================
// OptigoAI Mobile — Website Audit Models
// ==================================================

class WebsiteAuditFinding {
  final String status; // pass, warning, fail
  final String title;
  final String impact;
  final String? fix;

  WebsiteAuditFinding({
    required this.status,
    required this.title,
    required this.impact,
    this.fix,
  });

  factory WebsiteAuditFinding.fromJson(Map<String, dynamic> json) {
    return WebsiteAuditFinding(
      status: json['status'] ?? 'pass',
      title: json['title'] ?? '',
      impact: json['impact'] ?? 'Neutral',
      fix: json['fix'],
    );
  }
}

class WebsiteAuditModel {
  final String id;
  final String businessId;
  final String siteUrl;
  final int overallScore;
  final int technicalScore;
  final int contentScore;
  final int localSignalsScore;
  final List<WebsiteAuditFinding> findings;
  final List<String> actionableRecommendations;
  final DateTime? createdAt;

  WebsiteAuditModel({
    required this.id,
    required this.businessId,
    required this.siteUrl,
    required this.overallScore,
    required this.technicalScore,
    required this.contentScore,
    required this.localSignalsScore,
    required this.findings,
    required this.actionableRecommendations,
    this.createdAt,
  });

  factory WebsiteAuditModel.fromJson(Map<String, dynamic> json) {
    return WebsiteAuditModel(
      id: json['id'] ?? '',
      businessId: json['business_id'] ?? '',
      siteUrl: json['site_url'] ?? '',
      overallScore: json['overall_score'] ?? 75,
      technicalScore: json['technical_score'] ?? 70,
      contentScore: json['content_score'] ?? 80,
      localSignalsScore: json['local_signals_score'] ?? 75,
      findings: (json['findings'] as List<dynamic>?)
              ?.map((f) => WebsiteAuditFinding.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      actionableRecommendations: (json['actionable_recommendations'] as List<dynamic>?)
              ?.map((r) => r.toString())
              .toList() ??
          [],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}
