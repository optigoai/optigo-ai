import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/services/feature_flag_service.dart';
import 'home/home_screen.dart';
import 'recommendations/recommendations_screen.dart';
import 'content/content_studio_screen.dart';
import 'seo/seo_optimizer_screen.dart';
import 'reviews/reviews_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    FeatureFlagService().syncFlags();
  }

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onNavigateToRecommendations: () => _navigateToTab(1),
        onNavigateToReviews: () => _navigateToTab(4),
        onNavigateToTab: _navigateToTab,
      ),
      RecommendationsScreen(
        onNavigateToReviews: () => _navigateToTab(4),
        onNavigateToSeo: () => _navigateToTab(3),
        onNavigateToCreate: () => _navigateToTab(2),
      ),
      ContentStudioScreen(
        onNavigateToRecommendations: () => _navigateToTab(1),
      ),
      SeoOptimizerScreen(
        onNavigateToRecommendations: () => _navigateToTab(1),
      ),
      const ReviewsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavBarItem(
                  index: 0,
                  activeIcon: Icons.home_rounded,
                  inactiveIcon: Icons.home_outlined,
                  label: 'Home',
                ),
                _buildNavBarItem(
                  index: 1,
                  activeIcon: Icons.trending_up_rounded,
                  inactiveIcon: Icons.trending_up_outlined,
                  label: 'Grow',
                ),
                _buildNavBarItem(
                  index: 2,
                  activeIcon: Icons.campaign_rounded,
                  inactiveIcon: Icons.campaign_outlined,
                  label: 'Studio',
                ),
                _buildNavBarItem(
                  index: 3,
                  activeIcon: Icons.pin_drop_rounded,
                  inactiveIcon: Icons.pin_drop_outlined,
                  label: 'Visibility',
                ),
                _buildNavBarItem(
                  index: 4,
                  activeIcon: Icons.star_rounded,
                  inactiveIcon: Icons.star_outline_rounded,
                  label: 'Reviews',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem({
    required int index,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _navigateToTab(index),
        splashColor: const Color(0xFFEFF6FF),
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: isSelected ? 12 : 0, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
