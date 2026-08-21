// ==================================================
// OptigoAI Mobile — AI CMO Chat Repository (Phase 10)
// ==================================================

import '../api/api_client.dart';
import '../models/cmo_chat_model.dart';

class CmoChatRepository {
  final ApiClient apiClient;

  CmoChatRepository(this.apiClient);

  Future<CmoChatMessage> sendMessage({
    required String businessId,
    required String message,
    String contextScreen = 'home',
  }) async {
    final res = await apiClient.post(
      '/api/v1/cmo/chat',
      body: {
        'business_id': businessId,
        'message': message,
        'context_screen': contextScreen,
      },
    );
    return CmoChatMessage.fromJson(res as Map<String, dynamic>);
  }
}
