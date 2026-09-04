import 'package:flutter_test/flutter_test.dart';
import 'package:optigoai_app/data/models/analytics_model.dart';

void main() {
  group('BranchAnalyticsDashboardModel Tests', () {
    test('Correctly parses empty json with defaults', () {
      final model = BranchAnalyticsDashboardModel.fromJson({});
      expect(model.businessId, '');
      expect(model.businessName, '');
      expect(model.avgGoogleRank, 2.5);
      expect(model.keywordsCount, 0);
      expect(model.reviewsCount, 0);
      expect(model.recentActivity, isEmpty);
      expect(model.weeklyViews, isEmpty);
      expect(model.metrics, isEmpty);
    });

    test('Correctly parses complete analytics dashboard json', () {
      final json = {
        'business_id': 'biz_123',
        'business_name': 'Green Spices Store',
        'category': 'Organic Grocery',
        'location': 'Kochi, Kerala',
        'avg_google_rank': 1.8,
        'keywords_count': 15,
        'top3_keywords_count': 9,
        'reviews_count': 142,
        'average_rating': 4.9,
        'unreplied_reviews_count': 2,
        'recent_activity': [
          {
            'type': 'review_reply',
            'title': 'AI Review Reply Sent',
            'subtitle': 'Replied to 5-star customer review',
            'badge_text': 'Completed',
            'badge_status': 'success',
          },
        ],
        'weekly_views': [
          {'day': 'Mon', 'views': 120, 'ratio': 0.6},
          {'day': 'Tue', 'views': 180, 'ratio': 0.9},
        ],
        'metrics': [
          {
            'label': 'Discovery Views',
            'value': '3,240',
            'trend': '+28%',
            'description': 'Customer discovery on Google Search and Maps',
          },
        ],
        'estimated_revenue_impact': '\$4,200',
        'roi_multiplier': '8.2x',
        'channel_breakdown': {
          'google_search': 1800,
          'google_maps': 1440,
        },
        'lead_attribution': {
          'estimated_leads_generated': 78,
          'average_ticket_value': '\$45',
          'estimated_monthly_value': '\$3,510',
        },
        'ai_summary': 'Strong growth in local map visibility.',
      };

      final model = BranchAnalyticsDashboardModel.fromJson(json);

      expect(model.businessId, 'biz_123');
      expect(model.businessName, 'Green Spices Store');
      expect(model.avgGoogleRank, 1.8);
      expect(model.keywordsCount, 15);
      expect(model.top3KeywordsCount, 9);
      expect(model.reviewsCount, 142);
      expect(model.averageRating, 4.9);
      expect(model.unrepliedReviewsCount, 2);
      expect(model.recentActivity.length, 1);
      expect(model.recentActivity.first.title, 'AI Review Reply Sent');
      expect(model.weeklyViews.length, 2);
      expect(model.metrics.first.value, '3,240');
      expect(model.estimatedRevenueImpact, '\$4,200');
      expect(model.channelBreakdown['google_search'], 1800);
      expect(model.leadAttribution?.estimatedLeadsGenerated, 78);
    });
  });

  group('ImpactComparisonModel Tests', () {
    test('Correctly calculates Before vs. After growth and deltas', () {
      final model = ImpactComparisonModel(
        baselineDate: DateTime(2026, 1, 1),
        daysActive: 45,
        viewsBefore: 1800,
        viewsAfter: 2880,
        callsBefore: 90,
        callsAfter: 135,
        directionsBefore: 120,
        directionsAfter: 180,
        ratingBefore: 4.4,
        ratingAfter: 4.8,
        top3KeywordsBefore: 3,
        top3KeywordsAfter: 8,
        reviewsBefore: 45,
        reviewsAfter: 98,
        totalActionsCompleted: 142,
        responseRateBefore: '40%',
        responseRateAfter: '98%',
      );

      expect(model.daysActive, 45);
      expect(model.viewsDelta, 1080);
      expect(model.viewsGrowthPct, 60.0);
      expect(model.callsDelta, 45);
      expect(model.callsGrowthPct, 50.0);
      expect(model.directionsDelta, 60);
      expect(model.directionsGrowthPct, 50.0);
      expect(model.totalInquiriesBefore, 210);
      expect(model.totalInquiriesAfter, 315);
      expect(model.inquiriesDelta, 105);
      expect(model.inquiriesGrowthPct, 50.0);
      expect(model.ratingDelta, closeTo(0.4, 0.001));
      expect(model.top3KeywordsDelta, 5);
      expect(model.totalActionsCompleted, 142);
    });
  });
}
