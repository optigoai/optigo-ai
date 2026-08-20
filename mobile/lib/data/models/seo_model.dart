class SeoKeywordModel {
  final String id;
  final String businessId;
  final String keyword;
  final String? targetLocation;
  final int? currentRank;
  final int? previousRank;
  final String searchVolume;
  final String difficulty;
  final String intent;
  final bool isTracked;
  final String? createdAt;
  final String? updatedAt;

  SeoKeywordModel({
    required this.id,
    required this.businessId,
    required this.keyword,
    this.targetLocation,
    this.currentRank,
    this.previousRank,
    required this.searchVolume,
    required this.difficulty,
    required this.intent,
    required this.isTracked,
    this.createdAt,
    this.updatedAt,
  });

  factory SeoKeywordModel.fromJson(Map<String, dynamic> json) {
    return SeoKeywordModel(
      id: json['id'] ?? '',
      businessId: json['business_id'] ?? '',
      keyword: json['keyword'] ?? '',
      targetLocation: json['target_location'],
      currentRank: json['current_rank'],
      previousRank: json['previous_rank'],
      searchVolume: json['search_volume'] ?? '500 / mo',
      difficulty: json['difficulty'] ?? 'Medium',
      intent: json['intent'] ?? 'Local Intent',
      isTracked: json['is_tracked'] ?? true,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  int get rankDelta {
    if (currentRank == null || previousRank == null) return 0;
    // Lower rank number means improved rank (e.g. rank 4 -> rank 2 is +2 gain)
    return previousRank! - currentRank!;
  }
}

class SeoAuditModel {
  final String id;
  final String businessId;
  final int overallSeoScore;
  final int mapPackScore;
  final int keywordScore;
  final int citationScore;
  final List<String> missingAttributes;
  final List<String> actionableRecommendations;
  final List<String> competitorInsights;
  final String? createdAt;

  SeoAuditModel({
    required this.id,
    required this.businessId,
    required this.overallSeoScore,
    required this.mapPackScore,
    required this.keywordScore,
    required this.citationScore,
    required this.missingAttributes,
    required this.actionableRecommendations,
    required this.competitorInsights,
    this.createdAt,
  });

  factory SeoAuditModel.fromJson(Map<String, dynamic> json) {
    return SeoAuditModel(
      id: json['id'] ?? '',
      businessId: json['business_id'] ?? '',
      overallSeoScore: json['overall_seo_score'] ?? 75,
      mapPackScore: json['map_pack_score'] ?? 70,
      keywordScore: json['keyword_score'] ?? 75,
      citationScore: json['citation_score'] ?? 80,
      missingAttributes: (json['missing_attributes'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      actionableRecommendations: (json['actionable_recommendations'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      competitorInsights: (json['competitor_insights'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      createdAt: json['created_at'],
    );
  }
}

class GbpOptimizationModel {
  final String optimizedTitle;
  final String optimizedDescription;
  final String primaryCategory;
  final List<String> secondaryCategories;
  final List<String> recommendedAttributes;

  GbpOptimizationModel({
    required this.optimizedTitle,
    required this.optimizedDescription,
    required this.primaryCategory,
    required this.secondaryCategories,
    required this.recommendedAttributes,
  });

  factory GbpOptimizationModel.fromJson(Map<String, dynamic> json) {
    return GbpOptimizationModel(
      optimizedTitle: json['optimized_title'] ?? '',
      optimizedDescription: json['optimized_description'] ?? '',
      primaryCategory: json['primary_category'] ?? '',
      secondaryCategories: (json['secondary_categories'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      recommendedAttributes: (json['recommended_attributes'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
