import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/notification_repository.dart';
import '../auth/auth_provider.dart';
import '../business_profile/business_profile_screen.dart';
import 'app_side_drawer.dart';
import 'cmo_chat_drawer.dart';
import 'notification_modal.dart';

/// An executive, uncluttered, and spacious top navigation bar for OptigoAI.
/// Redesigned to be:
/// - Spacious & Substantial: 44px button sizing with comfortable padding and zero congestion
/// - Clean Store Identity: Uses a modern Monogram Avatar + Smart Brand Name (e.g. [PO] Panekkatt ▾)
///   instead of writing out the redundant 30-letter full legal business name
/// - Single-line layout: Eliminates multi-line column stacking to completely prevent bottom overflow
/// - 44x44 Iconic AI CMO Mascot button: Replaces wide 85px text button with a radiant bot action button
/// - Smooth 60fps Live Sync physics: Continuous rotation physics when syncing
/// - Dynamic unread notification counter badge
class OptigoTopBar extends StatefulWidget {
  final String? subtitle;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMenuTap;
  final Function(int)? onNavigateToTab;
  final VoidCallback? onRefreshTap;
  final bool isRefreshing;
  final bool showBackButton;
  final VoidCallback? onBackTap;

  const OptigoTopBar({
    super.key,
    this.subtitle,
    this.onNotificationTap,
    this.onMenuTap,
    this.onNavigateToTab,
    this.onRefreshTap,
    this.isRefreshing = false,
    this.showBackButton = false,
    this.onBackTap,
  });

  @override
  State<OptigoTopBar> createState() => _OptigoTopBarState();
}

class _OptigoTopBarState extends State<OptigoTopBar> with SingleTickerProviderStateMixin {
  late final AnimationController _syncController;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _syncController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    if (widget.isRefreshing) {
      _syncController.repeat();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUnreadNotifications();
    });
  }

  @override
  void didUpdateWidget(covariant OptigoTopBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRefreshing && !_syncController.isAnimating) {
      _syncController.repeat();
    } else if (!widget.isRefreshing && _syncController.isAnimating) {
      _syncController.stop();
      _syncController.reset();
    }
  }

  @override
  void dispose() {
    _syncController.dispose();
    super.dispose();
  }

  Future<void> _fetchUnreadNotifications() async {
    if (!mounted) return;
    try {
      final bizId = context.read<AppAuthProvider>().currentBusiness?.id;
      if (bizId == null) return;
      final repo = context.read<NotificationRepository>();
      final list = await repo.listNotifications(businessId: bizId, unreadOnly: true);
      if (mounted) {
        setState(() {
          _unreadCount = list.length;
        });
      }
    } catch (_) {
      // Graceful fallback if offline
    }
  }

  void _openSideDrawer(BuildContext context) {
    AppSideDrawer.show(context, onNavigateToTab: widget.onNavigateToTab);
  }

  /// Extracts clean initials from business name (e.g. "Panekkatt Oil" -> "PO")
  String _getBusinessInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'OP';
    final words = clean.split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words[0].substring(0, words[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  /// Extracts concise brand name instead of writing full legal name
  /// E.g. "panekkatt oil and flour mill" -> "Panekkatt"
  /// "Dr. Smile Dental Clinic" -> "Dr. Smile"
  String _getShortBrandName(String fullName) {
    final clean = fullName.trim();
    if (clean.isEmpty) return 'Store';
    final words = clean.split(RegExp(r'\s+'));
    if (words.isEmpty) return 'Store';

    String firstWord = words[0];
    if (firstWord.length > 1) {
      firstWord = firstWord[0].toUpperCase() + firstWord.substring(1).toLowerCase();
    } else {
      firstWord = firstWord.toUpperCase();
    }

    // If first word is short prefix (e.g. "Dr.", "The", "My") and second word exists, join them
    if (words.length > 1 && (firstWord.length <= 3 || firstWord.toLowerCase() == 'the')) {
      String secondWord = words[1];
      if (secondWord.length > 1) {
        secondWord = secondWord[0].toUpperCase() + secondWord.substring(1).toLowerCase();
      }
      return '$firstWord $secondWord';
    }

    return firstWord;
  }

  String _resolveCurrentScreen() {
    final sub = widget.subtitle?.toLowerCase() ?? '';
    if (sub.contains('review') || sub.contains('reputation')) return 'reviews';
    if (sub.contains('visibility') || sub.contains('seo')) return 'seo';
    if (sub.contains('action') || sub.contains('recommendation') || sub.contains('grow')) return 'actions';
    if (sub.contains('studio') || sub.contains('content') || sub.contains('campaign')) return 'create';
    return 'home';
  }

  void _showBusinessSwitcherSheet(BuildContext context, AppAuthProvider authProvider) {
    final currentBiz = authProvider.currentBusiness;
    final businesses = authProvider.businesses;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 42,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Title and Close Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Store & Business Hub',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Select active storefront or view location health',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Active Business Hero Card
                if (currentBiz != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEFF6FF), Color(0xFFF0FDF4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _getBusinessInitials(currentBiz.name),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      currentBiz.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'ACTIVE',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF059669),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentBiz.location ?? currentBiz.category ?? 'Google Business Connected',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: const Color(0xFF475569),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (currentBiz.healthScore != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${currentBiz.healthScore}%',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                                Text(
                                  'Health',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 8.5,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Other Businesses List (if more than 1)
                if (businesses.length > 1) ...[
                  Text(
                    'OTHER REGISTERED LOCATIONS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF64748B),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: businesses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (c, idx) {
                        final biz = businesses[idx];
                        final isCurrent = biz.id == currentBiz?.id;
                        return InkWell(
                          onTap: () {
                            authProvider.switchBusiness(biz);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Switched active store to ${biz.name}',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: const Color(0xFF0F172A),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isCurrent ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isCurrent ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isCurrent ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                                  size: 18,
                                  color: isCurrent ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        biz.name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                          color: const Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (biz.location != null)
                                        Text(
                                          biz.location!,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10.5,
                                            color: const Color(0xFF64748B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Quick Action Bar inside sheet
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BusinessProfileScreen()),
                          );
                        },
                        icon: const Icon(Icons.storefront_outlined, size: 16),
                        label: Text(
                          'Store Profile',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(color: Color(0xFFDBEAFE)),
                          backgroundColor: const Color(0xFFEFF6FF),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openSideDrawer(context);
                        },
                        icon: const Icon(Icons.menu_open_rounded, size: 16),
                        label: Text(
                          'All Features',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final currentBiz = authProvider.currentBusiness;
    final bizName = currentBiz?.name ?? 'Optigo Business';
    final initials = _getBusinessInitials(bizName);
    final shortBrand = _getShortBrandName(bizName);

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Group: Navigation Trigger (Menu / Back) + Compact Store Avatar Chip
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildLeadingNavButton(context),
              const SizedBox(width: 8),
              _buildStoreAvatarChip(
                context: context,
                authProvider: authProvider,
                initials: initials,
                shortBrand: shortBrand,
              ),
            ],
          ),

          // Right Group: [Live Sync (if provided)], [44x44 AI Mascot], [44x44 Notifications]
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.onRefreshTap != null) ...[
                _buildSyncButton(context),
                const SizedBox(width: 8),
              ],
              _buildAskAiMascotButton(context),
              const SizedBox(width: 8),
              _buildNotificationButton(context),
            ],
          ),
        ],
      ),
    );
  }

  /// 1. 44x44 Tactile Leading Navigation Button (Menu or Back)
  Widget _buildLeadingNavButton(BuildContext context) {
    final isBack = widget.showBackButton;
    return Tooltip(
      message: isBack ? 'Go Back' : 'Open Menu',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isBack
              ? (widget.onBackTap ?? () => Navigator.maybePop(context))
              : (widget.onMenuTap ?? () => _openSideDrawer(context)),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                isBack ? Icons.arrow_back_ios_new_rounded : Icons.menu_rounded,
                size: isBack ? 18 : 22,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 2. 44px Height Compact Storefront Avatar Chip
  /// Uses Monogram Avatar (e.g. [PO]) + Short Brand Name (e.g. "Panekkatt") + Chevron
  /// completely eliminating redundant full 30-letter legal name text and vertical overflow.
  Widget _buildStoreAvatarChip({
    required BuildContext context,
    required AppAuthProvider authProvider,
    required String initials,
    required String shortBrand,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showBusinessSwitcherSheet(context, authProvider),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Store Monogram Badge with Active Emerald Live Indicator
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),

              // Concise Brand Name (e.g. "Panekkatt")
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(
                  shortBrand,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 3),

              // Subtle Dropdown Indicator
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 3. 44x44 Live Sync Button with continuous 60fps rotation animation
  Widget _buildSyncButton(BuildContext context) {
    return Tooltip(
      message: widget.isRefreshing ? 'Syncing with Google Business...' : 'Sync Data',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isRefreshing ? null : widget.onRefreshTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.isRefreshing ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: RotationTransition(
                turns: _syncController,
                child: Icon(
                  Icons.sync_rounded,
                  size: 21,
                  color: widget.isRefreshing ? const Color(0xFF2563EB) : const Color(0xFF475569),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 4. 44x44 Iconic Radiant "Ask AI" CMO Mascot Button
  /// Replaces the wide 85px pill with an iconic 44x44 squircle button to save space and remove congestion.
  Widget _buildAskAiMascotButton(BuildContext context) {
    return Tooltip(
      message: 'Ask AI CMO Copilot',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => CmoChatDrawer.show(
            context,
            currentScreen: _resolveCurrentScreen(),
          ),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/images/optigo-bot.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.smart_toy_rounded,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF60A5FA),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 5. 44x44 Notification Bell with dynamic unread counter badge
  Widget _buildNotificationButton(BuildContext context) {
    return Tooltip(
      message: 'Notifications',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (widget.onNotificationTap != null) {
              widget.onNotificationTap!();
            } else {
              NotificationModal.show(context);
              _fetchUnreadNotifications();
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  size: 21,
                  color: Color(0xFF334155),
                ),
                if (_unreadCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          _unreadCount > 9 ? '9+' : '$_unreadCount',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
