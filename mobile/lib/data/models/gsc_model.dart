// ==================================================
// OptigoAI Mobile — Google Search Console Models
// ==================================================

class GscQueryItem {
  final String query;
  final int clicks;
  final int impressions;
  final double ctr;
  final double position;

  GscQueryItem({
    required this.query,
    required this.clicks,
    required this.impressions,
    required this.ctr,
    required this.position,
  });

  factory GscQueryItem.fromJson(Map<String, dynamic> json) {
    return GscQueryItem(
      query: json['query'] ?? '',
      clicks: json['clicks'] ?? 0,
      impressions: json['impressions'] ?? 0,
      ctr: (json['ctr'] as num?)?.toDouble() ?? 0.0,
      position: (json['position'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class GscMetricsSummaryModel {
  final String businessId;
  final bool isConnected;
  final String? siteUrl;
  final int totalClicks;
  final int totalImpressions;
  final double averageCtr;
  final double averagePosition;
  final String dateRangeLabel;
  final List<GscQueryItem> topQueries;
  final String freshnessLabel;
  final String actionableInsight;

  GscMetricsSummaryModel({
    required this.businessId,
    required this.isConnected,
    this.siteUrl,
    required this.totalClicks,
    required this.totalImpressions,
    required this.averageCtr,
    required this.averagePosition,
    required this.dateRangeLabel,
    required this.topQueries,
    required this.freshnessLabel,
    required this.actionableInsight,
  });

  factory GscMetricsSummaryModel.fromJson(Map<String, dynamic> json) {
    return GscMetricsSummaryModel(
      businessId: json['business_id'] ?? '',
      isConnected: json['is_connected'] ?? false,
      siteUrl: json['site_url'],
      totalClicks: json['total_clicks'] ?? 0,
      totalImpressions: json['total_impressions'] ?? 0,
      averageCtr: (json['average_ctr'] as num?)?.toDouble() ?? 0.0,
      averagePosition: (json['average_position'] as num?)?.toDouble() ?? 0.0,
      dateRangeLabel: json['date_range_label'] ?? 'Last 28 Days',
      topQueries: (json['top_queries'] as List<dynamic>?)
              ?.map((q) => GscQueryItem.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [],
      freshnessLabel: json['freshness_label'] ?? 'Recently synced',
      actionableInsight: json['actionable_insight'] ?? '',
    );
  }
}
