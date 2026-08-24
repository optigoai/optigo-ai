import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../business_profile/business_profile_screen.dart';
import '../settings/settings_screen.dart';

class AppSideDrawer extends StatelessWidget {
  final Function(int)? onNavigateToTab;
  final VoidCallback? onOpenCmoChat;

  const AppSideDrawer({
    super.key,
    this.onNavigateToTab,
    this.onOpenCmoChat,
  });

  static void show(BuildContext context, {Function(int)? onNavigateToTab, VoidCallback? onOpenCmoChat}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AppSideDrawer(
        onNavigateToTab: onNavigateToTab,
        onOpenCmoChat: onOpenCmoChat,
      ),
    );
  }

  void _confirmLogout(BuildContext context, AppAuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        content: const Text('Are you sure you want to log out of OptigoAI?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).popUntil((route) => route.isFirst);
              authProvider.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final user = authProvider.user;
    final currentBiz = authProvider.currentBusiness;
    final businesses = authProvider.businesses;

    final displayName = user?.fullName.isNotEmpty == true ? user!.fullName : 'Ahmed Yazeen';
    final email = user?.email.isNotEmpty == true ? user!.email : 'ahmed@casaraza.com';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // User Profile Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFDBEAFE), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user?.role.toUpperCase() ?? 'OWNER',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Active Business Card & Switcher
          if (currentBiz != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storefront_rounded, size: 18, color: Color(0xFF2563EB)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentBiz.name,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          currentBiz.location ?? 'Active Location',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  if (businesses.length > 1)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF2563EB), size: 20),
                      tooltip: 'Switch Business',
                      onSelected: (bizId) {
                        final selected = businesses.firstWhere((b) => b.id == bizId);
                        authProvider.switchBusiness(selected);
                      },
                      itemBuilder: (ctx) => businesses.map((b) {
                        final isCur = b.id == currentBiz.id;
                        return PopupMenuItem<String>(
                          value: b.id,
                          child: Row(
                            children: [
                              Icon(
                                isCur ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                size: 16,
                                color: isCur ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 8),
                              Text(b.name, style: TextStyle(fontWeight: isCur ? FontWeight.w800 : FontWeight.w500)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Main Navigation Items
          _buildDrawerItem(
            title: 'Main Dashboard',
            subtitle: 'Real-time marketing overview',
            icon: Icons.dashboard_rounded,
            onTap: () {
              Navigator.pop(context);
              onNavigateToTab?.call(0);
            },
          ),
          _buildDrawerItem(
            title: 'Google Business Profile',
            subtitle: 'View live GBP profile & hours',
            badgeText: '86%',
            icon: Icons.storefront_rounded,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BusinessProfileScreen()),
              );
            },
          ),
          _buildDrawerItem(
            title: 'Settings',
            subtitle: 'Account, AI preferences & integrations',
            icon: Icons.settings_rounded,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),

          const SizedBox(height: 14),

          // Log Out Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _confirmLogout(context, authProvider);
              },
              icon: const Icon(Icons.logout_rounded, size: 16, color: Color(0xFFEF4444)),
              label: const Text(
                'Log Out',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFFEF4444)),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required String title,
    required String subtitle,
    required IconData icon,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF2563EB)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            if (badgeText != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                ),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
