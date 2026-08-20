import 'package:flutter/material.dart';
import '../app/theme.dart';
import 'home/home_screen.dart';
import 'recommendations/recommendations_screen.dart';
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
        onNavigateToReviews: () => _navigateToTab(2),
      ),
      RecommendationsScreen(
        onNavigateToReviews: () => _navigateToTab(2),
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
          border: Border(
            top: BorderSide(color: OptigoTheme.divider.withValues(alpha: 0.8), width: 1),
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
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _navigateToTab,
            backgroundColor: Colors.white,
            indicatorColor: OptigoTheme.primary.withValues(alpha: 0.12),
            elevation: 0,
            height: 65,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics_rounded, color: OptigoTheme.primary),
                label: 'Insights',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome_rounded, color: OptigoTheme.primary),
                label: 'AI Actions',
              ),
              NavigationDestination(
                icon: Icon(Icons.rate_review_outlined),
                selectedIcon: Icon(Icons.rate_review_rounded, color: OptigoTheme.primary),
                label: 'Reviews',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
