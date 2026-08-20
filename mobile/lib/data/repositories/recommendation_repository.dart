import '../api/api_client.dart';
import '../models/recommendation_model.dart';

class RecommendationRepository {
  final ApiClient apiClient;

  RecommendationRepository(this.apiClient);

  Future<CMOGenerateRecommendationsModel> generateRecommendations(String businessId) async {
    final res = await apiClient.post(
      '/api/v1/recommendations/generate?business_id=$businessId',
    );
    return CMOGenerateRecommendationsModel.fromJson(res);
  }

  Future<List<RecommendationModel>> getRecommendations(
    String businessId, {
    String? priority,
    String? status,
    bool includeDismissed = false,
  }) async {
    String endpoint = '/api/v1/recommendations?business_id=$businessId&include_dismissed=$includeDismissed';
    if (priority != null && priority.isNotEmpty) {
      endpoint += '&priority=$priority';
    }
    if (status != null && status.isNotEmpty) {
      endpoint += '&status=$status';
    }

    final res = await apiClient.get(endpoint);
    if (res is List) {
      return res.map((e) => RecommendationModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<RecommendationModel> updateStatus(
    String recommendationId,
    String businessId,
    String newStatus,
  ) async {
    final res = await apiClient.patch(
      '/api/v1/recommendations/$recommendationId/status?business_id=$businessId',
      body: {'status': newStatus},
    );
    return RecommendationModel.fromJson(res as Map<String, dynamic>);
  }
}
