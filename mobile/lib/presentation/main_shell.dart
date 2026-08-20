import 'package:flutter/material.dart';
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
      ),
      // Tab 2: Phase 6 Content & Social Post Studio
      ContentStudioScreen(
        onNavigateToRecommendations: () => _navigateToTab(1),
      ),
      // Tab 3: Phase 7 SEO & Visibility Optimizer
      SeoOptimizerScreen(
        onNavigateToRecommendations: () => _navigateToTab(1),
      ),
      // More Tab (Reviews & Settings)
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
          border: Border(
            top: BorderSide(color: const Color(0xFFE2E8F0), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 62,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.lightbulb_outline_rounded, 'Insights'),
                _buildNavItem(2, Icons.add_box_outlined, 'Create'),
                _buildNavItem(3, Icons.travel_explore_rounded, 'SEO'),
                _buildNavItem(4, Icons.more_horiz_rounded, 'More'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => _navigateToTab(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected && index == 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
              )
            else
              Icon(
                icon,
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                size: 22,
              ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
