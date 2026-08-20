import '../api/api_client.dart';
import '../models/content_model.dart';

class ContentRepository {
  final ApiClient apiClient;

  ContentRepository(this.apiClient);

  Future<ContentGenerateResponseModel> generatePosts({
    required String businessId,
    List<String>? channels,
    String? topic,
    String? tone,
    String? goal,
    String? offerDetails,
  }) async {
    final res = await apiClient.post(
      '/api/v1/contents/generate',
      body: {
        'business_id': businessId,
        if (channels != null) 'channels': channels,
        if (topic != null && topic.isNotEmpty) 'topic': topic,
        if (tone != null && tone.isNotEmpty) 'tone': tone,
        if (goal != null && goal.isNotEmpty) 'goal': goal,
        if (offerDetails != null && offerDetails.isNotEmpty) 'offer_details': offerDetails,
      },
    );
    return ContentGenerateResponseModel.fromJson(res as Map<String, dynamic>);
  }

  Future<ContentModel> createPost({
    required String businessId,
    required String contentType,
    String? title,
    required String body,
    String? tone,
    String? hashtags,
    String? callToAction,
    String? imagePrompt,
    String? imageUrl,
    String status = 'draft',
    String? scheduledAt,
  }) async {
    final res = await apiClient.post(
      '/api/v1/contents',
      body: {
        'business_id': businessId,
        'content_type': contentType,
        if (title != null) 'title': title,
        'body': body,
        if (tone != null) 'tone': tone,
        if (hashtags != null) 'hashtags': hashtags,
        if (callToAction != null) 'call_to_action': callToAction,
        if (imagePrompt != null) 'image_prompt': imagePrompt,
        if (imageUrl != null) 'image_url': imageUrl,
        'status': status,
        if (scheduledAt != null) 'scheduled_at': scheduledAt,
      },
    );
    return ContentModel.fromJson(res as Map<String, dynamic>);
  }

  Future<List<ContentModel>> getPosts({
    required String businessId,
    String? contentType,
    String? status,
  }) async {
    String endpoint = '/api/v1/contents?business_id=$businessId';
    if (contentType != null && contentType != 'all') {
      endpoint += '&content_type=$contentType';
    }
    if (status != null && status != 'all') {
      endpoint += '&status=$status';
    }

    final res = await apiClient.get(endpoint);
    if (res is List) {
      return res.map((e) => ContentModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<ContentModel> updatePost({
    required String id,
    required String businessId,
    String? title,
    String? body,
    String? tone,
    String? hashtags,
    String? callToAction,
    String? status,
    String? scheduledAt,
  }) async {
    final res = await apiClient.patch(
      '/api/v1/contents/$id?business_id=$businessId',
      body: {
        if (title != null) 'title': title,
        if (body != null) 'body': body,
        if (tone != null) 'tone': tone,
        if (hashtags != null) 'hashtags': hashtags,
        if (callToAction != null) 'call_to_action': callToAction,
        if (status != null) 'status': status,
        if (scheduledAt != null) 'scheduled_at': scheduledAt,
      },
    );
    return ContentModel.fromJson(res as Map<String, dynamic>);
  }

  Future<ContentModel> publishPost(String id, String businessId) async {
    final res = await apiClient.post(
      '/api/v1/contents/$id/publish?business_id=$businessId',
    );
    return ContentModel.fromJson(res as Map<String, dynamic>);
  }

  Future<void> deletePost(String id, String businessId) async {
    await apiClient.delete(
      '/api/v1/contents/$id?business_id=$businessId',
    );
  }
}
