import '../api/api_client.dart';
import '../models/business_model.dart';
import '../../core/constants.dart';

class BusinessRepository {
  final ApiClient _apiClient;

  BusinessRepository(this._apiClient);

  Future<List<BusinessModel>> getBusinesses() async {
    final response = await _apiClient.get(ApiConstants.businesses);
    if (response is List) {
      return response.map((item) => BusinessModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<BusinessModel> createBusiness({
    required String name,
    String? category,
    String? location,
    String? website,
    String? phone,
    String? description,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.businesses,
      body: {
        'name': name.trim(),
        'category': category?.trim(),
        'location': location?.trim(),
        'website': website?.trim(),
        'phone': phone?.trim(),
        'description': description?.trim(),
      },
    );
    return BusinessModel.fromJson(response);
  }

  Future<BusinessModel> updateBusiness({
    required String businessId,
    String? name,
    String? category,
    String? location,
    String? website,
    String? phone,
    String? description,
  }) async {
    final response = await _apiClient.patch(
      '${ApiConstants.businesses}/$businessId',
      body: {
        if (name != null) 'name': name.trim(),
        if (category != null) 'category': category.trim(),
        if (location != null) 'location': location.trim(),
        if (website != null) 'website': website.trim(),
        if (phone != null) 'phone': phone.trim(),
        if (description != null) 'description': description.trim(),
      },
    );
    return BusinessModel.fromJson(response);
  }

  Future<BusinessModel> submitOnboarding({
    required String businessId,
    required String targetCustomers,
    required String services,
    required String businessGoals,
    required String marketingChannels,
  }) async {
    final response = await _apiClient.post(
      '${ApiConstants.businesses}/$businessId/onboarding',
      body: {
        'target_customers': targetCustomers.trim(),
        'services': services.trim(),
        'business_goals': businessGoals.trim(),
        'marketing_channels': marketingChannels.trim(),
      },
    );
    return BusinessModel.fromJson(response);
  }

  Future<Map<String, dynamic>> syncGbp(String businessId) async {
    final response = await _apiClient.post(
      '${ApiConstants.businesses}/$businessId/sync-gbp',
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> analyzeBusiness(String businessId) async {
    final response = await _apiClient.post(
      '${ApiConstants.businesses}/$businessId/analyze',
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getIntelligence(String businessId) async {
    final response = await _apiClient.get(
      '${ApiConstants.businesses}/$businessId/intelligence',
    );
    return response as Map<String, dynamic>;
  }
}
