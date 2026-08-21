import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'recommendations/recommendations_screen.dart';
import 'content/content_studio_screen.dart';
import 'seo/seo_optimizer_screen.dart';
import 'reviews/reviews_screen.dart';
import 'shared/cmo_chat_drawer.dart';

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

  void _handleRouteNavigate(String route) {
    if (route == 'home') {
      _navigateToTab(0);
    } else if (route == 'actions') {
      _navigateToTab(1);
    } else if (route == 'create') {
      _navigateToTab(2);
    } else if (route == 'seo') {
      _navigateToTab(3);
    } else if (route == 'reviews') {
      _navigateToTab(4);
    }
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
      // Tab 2: Phase 6, 8, 9 Content, Campaign & Creative Studio
      ContentStudioScreen(
        onNavigateToRecommendations: () => _navigateToTab(1),
      ),
      // Tab 3: Phase 7 SEO & Competitor Optimizer
      SeoOptimizerScreen(
        onNavigateToRecommendations: () => _navigateToTab(1),
      ),
      // Tab 4: Reviews & Google Business
      const ReviewsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CmoChatDrawer.show(
          context,
          currentScreen: ['home', 'actions', 'create', 'seo', 'reviews'][_currentIndex],
          onNavigate: _handleRouteNavigate,
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF60A5FA)),
        label: const Text(
          'Ask AI CMO',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 0.1),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: const Color(0xFFE2E8F0), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.insights_rounded, 'Actions'),
                _buildCreateNavItem(2),
                _buildNavItem(3, Icons.search_rounded, 'SEO'),
                _buildNavItem(4, Icons.rate_review_outlined, 'Reviews'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateNavItem(int index) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => _navigateToTab(index),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.add, color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Create',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => _navigateToTab(index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
