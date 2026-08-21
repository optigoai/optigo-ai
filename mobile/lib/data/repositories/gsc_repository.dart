// ==================================================
// OptigoAI Mobile — Google Search Console Repository
// ==================================================

import '../api/api_client.dart';
import '../models/gsc_model.dart';

class GscRepository {
  final ApiClient _apiClient;

  GscRepository(this._apiClient);

  Future<GscMetricsSummaryModel> getMetricsSummary(String businessId) async {
    final response = await _apiClient.get(
      '/api/v1/integrations/google/search-console/metrics?business_id=$businessId',
    );
    return GscMetricsSummaryModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> syncMetrics(String businessId) async {
    await _apiClient.post(
      '/api/v1/integrations/google/search-console/sync?business_id=$businessId',
    );
  }

  Future<void> connectMock(String businessId) async {
    await _apiClient.post(
      '/api/v1/integrations/google/search-console/callback',
      body: {
        'code': 'mock_auth_code_mobile',
        'business_id': businessId,
      },
    );
  }
}
