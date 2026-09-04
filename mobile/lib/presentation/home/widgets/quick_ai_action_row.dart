import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/cmo_chat_drawer.dart';

/// A compact, elegant row of quick AI action pills that replaces
/// the old full-width AI CMO search bar. Each pill triggers a specific
/// AI CMO chat interaction.
class QuickAiActionRow extends StatefulWidget {
  const QuickAiActionRow({super.key});

  @override
  State<QuickAiActionRow> createState() => _QuickAiActionRowState();
}

class _QuickAiActionRowState extends State<QuickAiActionRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Label
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 12,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Quick AI Actions',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),

            // Action Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildActionPill(
                    icon: Icons.rate_review_rounded,
                    label: 'Reply Reviews',
                    prompt: 'Draft a response for my latest customer review',
                    gradientColors: [const Color(0xFF2563EB), const Color(0xFF3B82F6)],
                  ),
                  const SizedBox(width: 8),
                  _buildActionPill(
                    icon: Icons.campaign_rounded,
                    label: 'Create Post',
                    prompt: 'Write a high-converting promotional post for my business',
                    gradientColors: [const Color(0xFF7C3AED), const Color(0xFF8B5CF6)],
                  ),
                  const SizedBox(width: 8),
                  _buildActionPill(
                    icon: Icons.pin_drop_rounded,
                    label: 'Boost SEO',
                    prompt: 'How can I rank #1 on Google Maps in my area?',
                    gradientColors: [const Color(0xFF059669), const Color(0xFF10B981)],
                  ),
                  const SizedBox(width: 8),
                  _buildActionPill(
                    icon: Icons.psychology_rounded,
                    label: 'Ask CMO',
                    prompt: 'What is my top marketing priority today?',
                    gradientColors: [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
                    iconColor: const Color(0xFF92400E),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required String prompt,
    required List<Color> gradientColors,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => CmoChatDrawer.show(
          context,
          currentScreen: 'home',
          initialMessage: prompt,
        ),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 3),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: iconColor ?? Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: iconColor != null ? const Color(0xFF422006) : Colors.white,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
