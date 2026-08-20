class BusinessProblemModel {
  final String title;
  final String severity; // critical, high, medium, low
  final String explanation;
  final String impact;

  BusinessProblemModel({
    required this.title,
    required this.severity,
    required this.explanation,
    required this.impact,
  });

  factory BusinessProblemModel.fromJson(Map<String, dynamic> json) {
    return BusinessProblemModel(
      title: json['title'] as String? ?? 'Identified Issue',
      severity: json['severity'] as String? ?? 'medium',
      explanation: json['explanation'] as String? ?? '',
      impact: json['impact'] as String? ?? '',
    );
  }
}

class BusinessOpportunityModel {
  final String title;
  final String priority; // high, medium, low
  final String potentialImpact;
  final String suggestedAction;

  BusinessOpportunityModel({
    required this.title,
    required this.priority,
    required this.potentialImpact,
    required this.suggestedAction,
  });

  factory BusinessOpportunityModel.fromJson(Map<String, dynamic> json) {
    return BusinessOpportunityModel(
      title: json['title'] as String? ?? 'Growth Opportunity',
      priority: json['priority'] as String? ?? 'medium',
      potentialImpact: json['potential_impact'] as String? ?? '',
      suggestedAction: json['suggested_action'] as String? ?? '',
    );
  }
}

class BusinessIntelligenceModel {
  final String businessId;
  final int healthScore;
  final int reputationScore;
  final int visibilityScore;
  final String healthSummary;
  final String customerSentimentSummary;
  final String strategicAdvice;
  final List<BusinessProblemModel> topProblems;
  final List<BusinessOpportunityModel> topOpportunities;
  final Map<String, dynamic>? aiProfile;

  BusinessIntelligenceModel({
    required this.businessId,
    required this.healthScore,
    required this.reputationScore,
    required this.visibilityScore,
    required this.healthSummary,
    required this.customerSentimentSummary,
    required this.strategicAdvice,
    required this.topProblems,
    required this.topOpportunities,
    this.aiProfile,
  });

  factory BusinessIntelligenceModel.fromJson(Map<String, dynamic> json) {
    final analysis = json['health_analysis'] as Map<String, dynamic>? ?? {};
    final problemsRaw = analysis['top_problems'] as List? ?? [];
    final opportunitiesRaw = analysis['top_opportunities'] as List? ?? [];

    return BusinessIntelligenceModel(
      businessId: json['business_id'] as String? ?? '',
      healthScore: json['health_score'] as int? ?? (analysis['health_score'] as int? ?? 75),
      reputationScore: analysis['reputation_score'] as int? ?? 80,
      visibilityScore: analysis['visibility_score'] as int? ?? 70,
      healthSummary: analysis['health_summary'] as String? ?? 'Marketing analysis complete.',
      customerSentimentSummary: analysis['customer_sentiment_summary'] as String? ?? '',
      strategicAdvice: analysis['strategic_advice'] as String? ?? '',
      topProblems: problemsRaw.map((p) => BusinessProblemModel.fromJson(p as Map<String, dynamic>)).toList(),
      topOpportunities: opportunitiesRaw.map((o) => BusinessOpportunityModel.fromJson(o as Map<String, dynamic>)).toList(),
      aiProfile: json['ai_profile'] as Map<String, dynamic>?,
    );
  }
}
