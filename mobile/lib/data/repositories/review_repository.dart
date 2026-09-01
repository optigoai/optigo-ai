import '../api/api_client.dart';
import '../models/review_model.dart';
import '../../core/constants.dart';

class ReviewRepository {
  final ApiClient _apiClient;

  ReviewRepository(this._apiClient);

  Future<List<ReviewModel>> getReviews({
    required String businessId,
    String? sentiment,
    bool unansweredOnly = false,
  }) async {
    String path = '${ApiConstants.reviews}?business_id=$businessId';
    if (sentiment != null && sentiment.isNotEmpty) {
      path += '&sentiment=$sentiment';
    }
    if (unansweredOnly) {
      path += '&unanswered_only=true';
    }

    final response = await _apiClient.get(path);
    if (response is List) {
      return response.map((item) => ReviewModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<ReviewModel> replyToReview({
    required String reviewId,
    required String businessId,
    required String replyText,
  }) async {
    final response = await _apiClient.post(
      '${ApiConstants.reviews}/$reviewId/reply?business_id=$businessId',
      body: {'reply_text': replyText},
    );
    return ReviewModel.fromJson(response);
  }

  Future<String> generateAiReviewReply({
    required String reviewId,
    required String businessId,
    String tone = 'warm & professional',
  }) async {
    final response = await _apiClient.post(
      '${ApiConstants.reviews}/$reviewId/generate-reply?business_id=$businessId&tone=${Uri.encodeComponent(tone)}',
    );
    if (response is Map && response['reply_text'] != null) {
      return response['reply_text'] as String;
    }
    return '';
  }

  Future<Map<String, dynamic>> getReviewIntelligence({
    required String businessId,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.reviews}/intelligence?business_id=$businessId',
      );
      if (response is Map<String, dynamic>) {
        return response;
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> getReviewManagementAnalytics({
    required String businessId,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.reviews}/management-analytics?business_id=$businessId',
      );
      if (response is Map<String, dynamic>) {
        return response;
      }
    } catch (_) {}
    return {};
  }
}

