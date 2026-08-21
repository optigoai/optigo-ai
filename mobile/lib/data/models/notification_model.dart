// ==================================================
// OptigoAI Mobile — Notification Model (Phase 12)
// ==================================================

class AppNotificationModel {
  final String id;
  final String businessId;
  final String notificationType;
  final String title;
  final String message;
  final bool isRead;
  final String? actionUrl;
  final DateTime? createdAt;

  AppNotificationModel({
    required this.id,
    required this.businessId,
    required this.notificationType,
    required this.title,
    required this.message,
    required this.isRead,
    this.actionUrl,
    this.createdAt,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      notificationType: json['notification_type'] as String? ?? 'system',
      title: json['title'] as String? ?? 'Alert',
      message: json['message'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      actionUrl: json['action_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
