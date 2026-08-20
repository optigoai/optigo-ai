import '../api/api_client.dart';
import '../models/seo_model.dart';
import '../../core/constants.dart';

class SeoRepository {
  final ApiClient _apiClient;

  SeoRepository(this._apiClient);

  Future<List<SeoKeywordModel>> getKeywords(String businessId) async {
    final response = await _apiClient.get('${ApiConstants.seo}/keywords?business_id=$businessId');
    if (response is List) {
      return response.map((item) => SeoKeywordModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<SeoKeywordModel> addKeyword({
    required String businessId,
    required String keyword,
    String? targetLocation,
    String? searchVolume,
    String? difficulty,
    String? intent,
  }) async {
    final response = await _apiClient.post(
      '${ApiConstants.seo}/keywords?business_id=$businessId',
      body: {
        'keyword': keyword,
        if (targetLocation != null) 'target_location': targetLocation,
        if (searchVolume != null) 'search_volume': searchVolume,
        if (difficulty != null) 'difficulty': difficulty,
        if (intent != null) 'intent': intent,
      },
    );
    return SeoKeywordModel.fromJson(response);
  }

  Future<void> deleteKeyword({
    required String businessId,
    required String keywordId,
  }) async {
    await _apiClient.delete('${ApiConstants.seo}/keywords/$keywordId?business_id=$businessId');
  }

  Future<SeoAuditModel> getOrGenerateAudit({
    required String businessId,
    bool forceFresh = false,
  }) async {
    final response = await _apiClient.post(
      '${ApiConstants.seo}/audit?business_id=$businessId&force_fresh=$forceFresh',
    );
    return SeoAuditModel.fromJson(response);
  }

  Future<List<Map<String, dynamic>>> discoverKeywords({
    required String businessId,
    List<String>? targetServices,
  }) async {
    final response = await _apiClient.post(
      '${ApiConstants.seo}/discover-keywords?business_id=$businessId',
      body: {
        'target_services': targetServices ?? [],
      },
    );
    if (response is List) {
      return List<Map<String, dynamic>>.from(response);
    }
    return [];
  }

  Future<GbpOptimizationModel> optimizeGbpProfile(String businessId) async {
    final response = await _apiClient.post(
      '${ApiConstants.seo}/optimize-profile?business_id=$businessId',
    );
    return GbpOptimizationModel.fromJson(response);
  }
}
