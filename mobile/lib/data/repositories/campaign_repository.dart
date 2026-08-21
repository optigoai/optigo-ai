// ==================================================
// OptigoAI Mobile — Campaign Repository (Phase 8)
// ==================================================

import '../api/api_client.dart';
import '../models/campaign_model.dart';

class CampaignRepository {
  final ApiClient apiClient;

  CampaignRepository(this.apiClient);

  Future<Map<String, dynamic>> generateCampaign({
    required String businessId,
    String goal = 'increase_sales',
    List<String>? channels,
    int durationDays = 7,
    String? customOffer,
    String? targetAudience,
  }) async {
    final res = await apiClient.post(
      '/api/v1/campaigns/generate',
      body: {
        'business_id': businessId,
        'goal': goal,
        if (channels != null) 'channels': channels,
        'duration_days': durationDays,
        if (customOffer != null) 'custom_offer': customOffer,
        if (targetAudience != null) 'target_audience': targetAudience,
      },
    );
    return res as Map<String, dynamic>;
  }

  Future<CampaignModel> createCampaign({
    required String businessId,
    required String name,
    required String objective,
    required String audience,
    String? offer,
    required String messaging,
    required String cta,
    Map<String, dynamic>? contentIdeas,
    Map<String, dynamic>? schedule,
  }) async {
    final res = await apiClient.post(
      '/api/v1/campaigns',
      body: {
        'business_id': businessId,
        'name': name,
        'objective': objective,
        'audience': audience,
        if (offer != null) 'offer': offer,
        'messaging': messaging,
        'cta': cta,
        if (contentIdeas != null) 'content_ideas': contentIdeas,
        if (schedule != null) 'schedule': schedule,
        'status': 'draft',
      },
    );
    return CampaignModel.fromJson(res as Map<String, dynamic>);
  }

  Future<List<CampaignModel>> listCampaigns({
    required String businessId,
    String? status,
  }) async {
    String endpoint = '/api/v1/campaigns?business_id=$businessId';
    if (status != null) endpoint += '&status=$status';
    final res = await apiClient.get(endpoint);
    final list = res as List<dynamic>;
    return list.map((item) => CampaignModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<CampaignModel> launchCampaign(String campaignId) async {
    final res = await apiClient.post('/api/v1/campaigns/$campaignId/launch');
    return CampaignModel.fromJson(res as Map<String, dynamic>);
  }
}
