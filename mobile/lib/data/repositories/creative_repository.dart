// ==================================================
// OptigoAI Mobile — Creative Repository (Phase 9)
// ==================================================

import '../api/api_client.dart';
import '../models/creative_model.dart';

class CreativeRepository {
  final ApiClient apiClient;

  CreativeRepository(this.apiClient);

  Future<CreativeModel> generateCreative({
    required String businessId,
    String? headline,
    String? offerText,
    String style = 'modern_minimal',
    String aspectRatio = '1:1',
    String? campaignId,
  }) async {
    final res = await apiClient.post(
      '/api/v1/creatives/generate',
      body: {
        'business_id': businessId,
        if (headline != null) 'headline': headline,
        if (offerText != null) 'offer_text': offerText,
        'style': style,
        'aspect_ratio': aspectRatio,
        if (campaignId != null) 'campaign_id': campaignId,
      },
    );
    return CreativeModel.fromJson(res as Map<String, dynamic>);
  }

  Future<List<CreativeModel>> listCreatives({
    required String businessId,
    String? campaignId,
  }) async {
    String endpoint = '/api/v1/creatives?business_id=$businessId';
    if (campaignId != null) endpoint += '&campaign_id=$campaignId';
    final res = await apiClient.get(endpoint);
    final list = res as List<dynamic>;
    return list.map((item) => CreativeModel.fromJson(item as Map<String, dynamic>)).toList();
  }
}
