import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import 'notification_modal.dart';

class OptigoTopBar extends StatelessWidget {
  final String? subtitle;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMenuTap;
  final bool showBackButton;

  const OptigoTopBar({
    super.key,
    this.subtitle,
    this.onNotificationTap,
    this.onMenuTap,
    this.showBackButton = false,
  });

  void _showProfileModal(BuildContext context, AppAuthProvider authProvider) {
    final user = authProvider.user;
    final business = authProvider.currentBusiness;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(Icons.person_rounded, color: Color(0xFF2563EB), size: 28),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Business Owner',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            if (business != null) ...[
              Row(
                children: [
                  const Icon(Icons.storefront_rounded, size: 18, color: Color(0xFF64748B)),
                  const SizedBox(width: 10),
                  Text(
                    business.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                const Icon(Icons.verified_user_outlined, size: 18, color: Color(0xFF64748B)),
                const SizedBox(width: 10),
                Text(
                  'Role: ${user?.role.toUpperCase() ?? 'OWNER'}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  authProvider.logout();
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final user = authProvider.user;
    final business = authProvider.currentBusiness;

    final displaySubtitle = subtitle ?? business?.name ?? 'AI Marketing Manager';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Left: Back button or Hamburger Menu
          if (showBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E293B)),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          else
            InkWell(
              onTap: onMenuTap ?? () => _showProfileModal(context, authProvider),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.menu_rounded, size: 26, color: Color(0xFF1E293B)),
              ),
            ),

          const SizedBox(width: 8),

          // Center-Left: Official App Logo Image (No duplicate text) + Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 30,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                ),
                const SizedBox(height: 3),
                Text(
                  displaySubtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Right: Notification Bell with Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              InkWell(
                onTap: onNotificationTap ?? () => NotificationModal.show(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: const Icon(Icons.notifications_none_rounded, size: 24, color: Color(0xFF334155)),
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                  child: const Center(
                    child: Text(
                      '3',
                      style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 8),

          // Right: User Profile Avatar
          InkWell(
            onTap: () => _showProfileModal(context, authProvider),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                color: const Color(0xFFEFF6FF),
              ),
              child: Center(
                child: Text(
                  user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'N',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
