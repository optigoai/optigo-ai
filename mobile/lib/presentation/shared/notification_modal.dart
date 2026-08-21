// ==================================================
// OptigoAI Mobile — Notifications Modal (Phase 12)
// ==================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';
import '../auth/auth_provider.dart';

class NotificationModal extends StatefulWidget {
  final Function(String route)? onNavigate;

  const NotificationModal({super.key, this.onNavigate});

  static void show(BuildContext context, {Function(String route)? onNavigate}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificationModal(onNavigate: onNavigate),
    );
  }

  @override
  State<NotificationModal> createState() => _NotificationModalState();
}

class _NotificationModalState extends State<NotificationModal> {
  List<AppNotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final bizId = context.read<AppAuthProvider>().currentBusiness?.id;
    if (bizId == null) return;

    try {
      final repo = context.read<NotificationRepository>();
      final list = await repo.listNotifications(businessId: bizId);
      if (mounted) {
        setState(() {
          _notifications = list.isNotEmpty
              ? list
              : [
                  AppNotificationModel(
                    id: 'seed_1',
                    businessId: bizId,
                    notificationType: 'new_review',
                    title: 'New Google Review Received',
                    message: 'A customer left a 5-star review. Tap to generate an AI reply.',
                    isRead: false,
                    actionUrl: 'reviews',
                    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
                  ),
                  AppNotificationModel(
                    id: 'seed_2',
                    businessId: bizId,
                    notificationType: 'opportunity',
                    title: 'Weekly Post Scheduled',
                    message: 'Keep your Google Maps rank #1 with a fresh promotional post.',
                    isRead: true,
                    actionUrl: 'create',
                    createdAt: DateTime.now().subtract(const Duration(days: 1)),
                  ),
                ];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleMarkAllRead() async {
    final bizId = context.read<AppAuthProvider>().currentBusiness?.id;
    if (bizId == null) return;
    try {
      await context.read<NotificationRepository>().markAllAsRead(bizId);
      await _loadNotifications();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Proactive Alerts',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    TextButton(
                      onPressed: _handleMarkAllRead,
                      child: const Text('Mark all read', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _notifications.isEmpty
                    ? const Center(
                        child: Text('No new alerts.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notif = _notifications[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: notif.isRead ? Colors.white : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: notif.isRead ? const Color(0xFFE2E8F0) : const Color(0xFFBFDBFE),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: notif.isRead ? const Color(0xFFF1F5F9) : const Color(0xFF2563EB),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      notif.notificationType == 'new_review'
                                          ? Icons.star_rounded
                                          : Icons.bolt_rounded,
                                      size: 16,
                                      color: notif.isRead ? const Color(0xFF64748B) : Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notif.title,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: notif.isRead ? FontWeight.w700 : FontWeight.w900,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        notif.message,
                                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.4),
                                      ),
                                    ],
                                  ),
                                ),
                                if (notif.actionUrl != null)
                                  IconButton(
                                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF2563EB)),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      widget.onNavigate?.call(notif.actionUrl!);
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
