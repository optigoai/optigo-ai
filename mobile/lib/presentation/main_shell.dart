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
        icon: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            'assets/images/optigo-bot.png',
            width: 22,
            height: 22,
            fit: BoxFit.contain,
          ),
        ),
        label: const Text(
          'Ask AI CMO',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 0.1),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
                  activeIcon: Icons.pie_chart_rounded,
                  inactiveIcon: Icons.pie_chart_outline_rounded,
                  label: 'Actions',
                ),
                _buildNavBarItem(
                  index: 2,
                  activeIcon: Icons.add_circle_rounded,
                  inactiveIcon: Icons.add_circle_outline_rounded,
                  label: 'Create',
                ),
                _buildNavBarItem(
                  index: 3,
                  activeIcon: Icons.travel_explore_rounded,
                  inactiveIcon: Icons.search_rounded,
                  label: 'SEO',
                ),
                _buildNavBarItem(
                  index: 4,
                  activeIcon: Icons.chat_bubble_rounded,
                  inactiveIcon: Icons.chat_bubble_outline_rounded,
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
              // Micro-animation scale for the active icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: isSelected ? 1.15 : 1.0),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Icon(
                      isSelected ? activeIcon : inactiveIcon,
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF94A3B8),
                      size: 24,
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              // Smooth label text animation
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF64748B),
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
