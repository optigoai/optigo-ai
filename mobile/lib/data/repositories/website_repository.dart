// ==================================================
// OptigoAI Mobile — Business Website Repository
// ==================================================

import '../api/api_client.dart';
import '../models/website_model.dart';
import '../../core/constants.dart';

class WebsiteRepository {
  final ApiClient _apiClient;

  WebsiteRepository(this._apiClient);

  Future<WebsiteModel> getWebsite(String businessId) async {
    final response = await _apiClient.get(
      '${ApiConstants.businesses}/$businessId/website',
    );
    return WebsiteModel.fromJson(response);
  }

  Future<WebsiteModel> generateWebsite(String businessId) async {
    final response = await _apiClient.post(
      '${ApiConstants.businesses}/$businessId/website/generate',
    );
    return WebsiteModel.fromJson(response);
  }

  Future<WebsiteModel> updateWebsite({
    required String businessId,
    String? slug,
    String? seoTitle,
    String? seoDescription,
    Map<String, dynamic>? contentJson,
    String? customHtml,
    String? customCss,
    String? customJs,
  }) async {
    final response = await _apiClient.put(
      '${ApiConstants.businesses}/$businessId/website',
      body: {
        if (slug != null) 'slug': slug.trim(),
        if (seoTitle != null) 'seo_title': seoTitle.trim(),
        if (seoDescription != null) 'seo_description': seoDescription.trim(),
        if (contentJson != null) 'content_json': contentJson,
        if (customHtml != null) 'custom_html': customHtml,
        if (customCss != null) 'custom_css': customCss,
        if (customJs != null) 'custom_js': customJs,
      },
    );
    return WebsiteModel.fromJson(response);
  }

  Future<WebsiteModel> updateStatus({
    required String businessId,
    required String status,
  }) async {
    final response = await _apiClient.patch(
      '${ApiConstants.businesses}/$businessId/website/status',
      body: {'status': status},
    );
    return WebsiteModel.fromJson(response);
  }

  Future<void> deleteWebsite(String businessId) async {
    await _apiClient.delete(
      '${ApiConstants.businesses}/$businessId/website',
    );
  }
}
