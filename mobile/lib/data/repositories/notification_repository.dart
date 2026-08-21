// ==================================================
// OptigoAI Mobile — Notification Repository (Phase 12)
// ==================================================

import '../api/api_client.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final ApiClient apiClient;

  NotificationRepository(this.apiClient);

  Future<List<AppNotificationModel>> listNotifications({
    required String businessId,
    bool unreadOnly = false,
  }) async {
    final res = await apiClient.get(
      '/api/v1/notifications?business_id=$businessId&unread_only=$unreadOnly',
    );
    final list = res as List<dynamic>;
    return list.map((item) => AppNotificationModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<AppNotificationModel> markAsRead(String notificationId) async {
    final res = await apiClient.patch('/api/v1/notifications/$notificationId/read');
    return AppNotificationModel.fromJson(res as Map<String, dynamic>);
  }

  Future<void> markAllAsRead(String businessId) async {
    await apiClient.post('/api/v1/notifications/mark-all-read?business_id=$businessId');
  }
}
