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
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFloatingNavItem(0, Icons.home_rounded, 'Home'),
              _buildFloatingNavItem(1, Icons.insights_rounded, 'Actions'),
              _buildFloatingNavItem(2, Icons.add_circle_outline_rounded, 'Create'),
              _buildFloatingNavItem(3, Icons.search_rounded, 'SEO'),
              _buildFloatingNavItem(4, Icons.rate_review_outlined, 'Reviews'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    if (isSelected) {
      // Dark active pill capsule
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Inactive circular button
    return InkWell(
      onTap: () => _navigateToTab(index),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            icon,
            color: const Color(0xFF64748B),
            size: 20,
          ),
        ),
      ),
    );
  }
}
