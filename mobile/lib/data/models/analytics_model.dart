class AnalyticsMetricItem {
  final String label;
  final String value;
  final String trend;
  final String description;

  const AnalyticsMetricItem({
    required this.label,
    required this.value,
    required this.trend,
    required this.description,
  });

  factory AnalyticsMetricItem.fromJson(Map<String, dynamic> json) {
    return AnalyticsMetricItem(
      label: json['label']?.toString() ?? '',
      value: json['value']?.toString() ?? '0',
      trend: json['trend']?.toString() ?? '+0%',
      description: json['description']?.toString() ?? '',
    );
  }
}

class LeadAttributionModel {
  final int estimatedLeadsGenerated;
  final String averageTicketValue;
  final String estimatedMonthlyValue;

  const LeadAttributionModel({
    required this.estimatedLeadsGenerated,
    required this.averageTicketValue,
    required this.estimatedMonthlyValue,
  });

  factory LeadAttributionModel.fromJson(Map<String, dynamic> json) {
    return LeadAttributionModel(
      estimatedLeadsGenerated: json['estimated_leads_generated'] ?? 0,
      averageTicketValue: json['average_ticket_value']?.toString() ?? '\$45',
      estimatedMonthlyValue: json['estimated_monthly_value']?.toString() ?? '\$0',
    );
  }
}

class WeeklyViewPoint {
  final String day;
  final int views;
  final double ratio;

  const WeeklyViewPoint({
    required this.day,
    required this.views,
    required this.ratio,
  });

  factory WeeklyViewPoint.fromJson(Map<String, dynamic> json) {
    return WeeklyViewPoint(
      day: json['day']?.toString() ?? '',
      views: (json['views'] as num?)?.toInt() ?? 0,
      ratio: (json['ratio'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RecentActivityItem {
  final String type;
  final String title;
  final String subtitle;
  final String badgeText;
  final String badgeStatus;

  const RecentActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeStatus,
  });

  factory RecentActivityItem.fromJson(Map<String, dynamic> json) {
    return RecentActivityItem(
      type: json['type']?.toString() ?? 'activity',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      badgeText: json['badge_text']?.toString() ?? '',
      badgeStatus: json['badge_status']?.toString() ?? 'primary',
    );
  }
}

class CompetitorBenchmarkItem {
  final String name;
  final double rating;
  final int reviewCount;
  final int visibilityScore;
  final String gapAnalysis;

  const CompetitorBenchmarkItem({
    required this.name,
    required this.rating,
    required this.reviewCount,
    required this.visibilityScore,
    required this.gapAnalysis,
  });

  factory CompetitorBenchmarkItem.fromJson(Map<String, dynamic> json) {
    return CompetitorBenchmarkItem(
      name: json['name']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      visibilityScore: (json['visibility_score'] as num?)?.toInt() ?? 50,
      gapAnalysis: json['gap_analysis']?.toString() ?? '',
    );
  }
}

class BranchAnalyticsDashboardModel {
  final String businessId;
  final String businessName;
  final String category;
  final String location;
  final double avgGoogleRank;
  final int keywordsCount;
  final int top3KeywordsCount;
  final int reviewsCount;
  final double averageRating;
  final int unrepliedReviewsCount;
  final List<RecentActivityItem> recentActivity;
  final List<WeeklyViewPoint> weeklyViews;
  final List<AnalyticsMetricItem> metrics;
  final String estimatedRevenueImpact;
  final String roiMultiplier;
  final Map<String, int> channelBreakdown;
  final LeadAttributionModel? leadAttribution;
  final String? aiSummary;

  const BranchAnalyticsDashboardModel({
    required this.businessId,
    required this.businessName,
    required this.category,
    required this.location,
    required this.avgGoogleRank,
    required this.keywordsCount,
    required this.top3KeywordsCount,
    required this.reviewsCount,
    required this.averageRating,
    required this.unrepliedReviewsCount,
    required this.recentActivity,
    required this.weeklyViews,
    required this.metrics,
    required this.estimatedRevenueImpact,
    required this.roiMultiplier,
    required this.channelBreakdown,
    this.leadAttribution,
    this.aiSummary,
  });

  factory BranchAnalyticsDashboardModel.fromJson(Map<String, dynamic> json) {
    final recentList = (json['recent_activity'] as List?)
            ?.map((item) => RecentActivityItem.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    final weeklyList = (json['weekly_views'] as List?)
            ?.map((item) => WeeklyViewPoint.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    final metricsList = (json['metrics'] as List?)
            ?.map((item) => AnalyticsMetricItem.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    final rawChannels = json['channel_breakdown'] as Map<String, dynamic>?;
    final Map<String, int> parsedChannels = {};
    if (rawChannels != null) {
      rawChannels.forEach((k, v) {
        if (v is num) parsedChannels[k] = v.toInt();
      });
    }

    return BranchAnalyticsDashboardModel(
      businessId: json['business_id']?.toString() ?? '',
      businessName: json['business_name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Local Business',
      location: json['location']?.toString() ?? 'Local Area',
      avgGoogleRank: (json['avg_google_rank'] as num?)?.toDouble() ?? 2.5,
      keywordsCount: (json['keywords_count'] as num?)?.toInt() ?? 0,
      top3KeywordsCount: (json['top3_keywords_count'] as num?)?.toInt() ?? 0,
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 4.8,
      unrepliedReviewsCount: (json['unreplied_reviews_count'] as num?)?.toInt() ?? 0,
      recentActivity: recentList,
      weeklyViews: weeklyList,
      metrics: metricsList,
      estimatedRevenueImpact: json['estimated_revenue_impact']?.toString() ?? '\$0',
      roiMultiplier: json['roi_multiplier']?.toString() ?? '1.0x',
      channelBreakdown: parsedChannels,
      leadAttribution: json['lead_attribution'] != null
          ? LeadAttributionModel.fromJson(json['lead_attribution'] as Map<String, dynamic>)
          : null,
      aiSummary: json['ai_summary']?.toString(),
    );
  }
}

/// Rich Before-vs-After comparison model calculating impact of OptigoAI on branch metrics
class ImpactComparisonModel {
  final DateTime baselineDate;
  final int daysActive;
  final int viewsBefore;
  final int viewsAfter;
  final int callsBefore;
  final int callsAfter;
  final int directionsBefore;
  final int directionsAfter;
  final double ratingBefore;
  final double ratingAfter;
  final int top3KeywordsBefore;
  final int top3KeywordsAfter;
  final int reviewsBefore;
  final int reviewsAfter;
  final int totalActionsCompleted;
  final String responseRateBefore;
  final String responseRateAfter;

  const ImpactComparisonModel({
    required this.baselineDate,
    required this.daysActive,
    required this.viewsBefore,
    required this.viewsAfter,
    required this.callsBefore,
    required this.callsAfter,
    required this.directionsBefore,
    required this.directionsAfter,
    required this.ratingBefore,
    required this.ratingAfter,
    required this.top3KeywordsBefore,
    required this.top3KeywordsAfter,
    required this.reviewsBefore,
    required this.reviewsAfter,
    required this.totalActionsCompleted,
    required this.responseRateBefore,
    required this.responseRateAfter,
  });

  // Calculated getters for delta and percentage gains
  int get viewsDelta => viewsAfter - viewsBefore;
  double get viewsGrowthPct => viewsBefore > 0 ? ((viewsDelta / viewsBefore) * 100) : 100.0;

  int get callsDelta => callsAfter - callsBefore;
  double get callsGrowthPct => callsBefore > 0 ? ((callsDelta / callsBefore) * 100) : 100.0;

  int get directionsDelta => directionsAfter - directionsBefore;
  double get directionsGrowthPct => directionsBefore > 0 ? ((directionsDelta / directionsBefore) * 100) : 100.0;

  int get totalInquiriesBefore => callsBefore + directionsBefore;
  int get totalInquiriesAfter => callsAfter + directionsAfter;
  int get inquiriesDelta => totalInquiriesAfter - totalInquiriesBefore;
  double get inquiriesGrowthPct =>
      totalInquiriesBefore > 0 ? ((inquiriesDelta / totalInquiriesBefore) * 100) : 100.0;

  double get ratingDelta => ratingAfter - ratingBefore;

  int get top3KeywordsDelta => top3KeywordsAfter - top3KeywordsBefore;
}
