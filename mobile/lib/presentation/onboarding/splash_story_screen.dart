import 'dart:async';
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

class SplashStoryScreen extends StatefulWidget {
  const SplashStoryScreen({super.key});

  @override
  State<SplashStoryScreen> createState() => _SplashStoryScreenState();
}

class _SplashStoryScreenState extends State<SplashStoryScreen> with SingleTickerProviderStateMixin {
  int _currentStoryIndex = 0;
  Timer? _timer;
  late AnimationController _progressController;

  final List<Map<String, String>> _stories = [
    {
      'title': 'AI CMO',
      'subtitle': 'Your AI Marketing Manager',
      'description': 'Understand your business, find growth opportunities, and help execute it in real-time.',
      'badge': '24/7 STRATEGIC CMO',
    },
    {
      'title': 'Local SEO & Visibility',
      'subtitle': 'Dominate Google Local Search',
      'description': 'Real-time keyword tracking, Firecrawl site audits, and automated Google Business Profile optimization.',
      'badge': 'GOOGLE RANKING #1',
    },
    {
      'title': 'Creative & Reputation',
      'subtitle': 'Automate Growth in 1-Tap',
      'description': 'Gemini-powered review replies, instant marketing promotional banners, and multi-channel campaign generation.',
      'badge': 'AI CAMPAIGN STUDIO',
    },
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _nextStory();
        }
      });

    _startStory();
  }

  void _startStory() {
    _progressController.forward(from: 0.0);
  }

  void _nextStory() {
    if (_currentStoryIndex < _stories.length - 1) {
      setState(() {
        _currentStoryIndex++;
      });
      _startStory();
    } else {
      _navigateToLogin();
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
      });
      _startStory();
    } else {
      _startStory();
    }
  }

  void _navigateToLogin() {
    _progressController.stop();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = _stories[_currentStoryIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          onTapDown: (details) {
            final screenWidth = MediaQuery.of(context).size.width;
            if (details.globalPosition.dx < screenWidth * 0.35) {
              _previousStory();
            } else {
              _nextStory();
            }
          },
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // 1. Instagram-Story Progress Bars
                Row(
                  children: List.generate(_stories.length, (index) {
                    return Expanded(
                      child: Container(
                        height: 3.5,
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, _) {
                            double value = 0.0;
                            if (index < _currentStoryIndex) {
                              value = 1.0;
                            } else if (index == _currentStoryIndex) {
                              value = _progressController.value;
                            }
                            return FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: value,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 16),

                // Top Skip Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Text(
                        story['badge']!,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2563EB),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _navigateToLogin,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 2),

                // 2. Large 3D Optigo Bot Mascot (Matching Reference Screen 1)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 210,
                      height: 210,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF818CF8).withValues(alpha: 0.25),
                            const Color(0xFFC7D2FE).withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 175,
                      height: 175,
                      child: Image.asset(
                        'assets/images/optigo-bot.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 2),

                // 3. Title & Subtitle (Matching Reference Screen 1)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    key: ValueKey(_currentStoryIndex),
                    children: [
                      Text(
                        story['title']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        story['subtitle']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          story['description']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 3),

                // 4. Primary Get Started Button
                InkWell(
                  onTap: _navigateToLogin,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
