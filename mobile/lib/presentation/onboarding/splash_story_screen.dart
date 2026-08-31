import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/login_screen.dart';

class SplashStoryScreen extends StatefulWidget {
  const SplashStoryScreen({super.key});

  @override
  State<SplashStoryScreen> createState() => _SplashStoryScreenState();
}

class _SplashStoryScreenState extends State<SplashStoryScreen> with TickerProviderStateMixin {
  int _currentStoryIndex = 0;
  late AnimationController _progressController;
  late AnimationController _bobController;
  late Animation<double> _bobAnimation;

  final List<Map<String, dynamic>> _stories = [
    {
      'badge': 'AI MARKETING MANAGER',
      'headline': 'Your Business, Managed by AI',
      'supporting': 'Finds growth opportunities and helps execute them — in real time.',
      'gradientColors': [
        const Color(0xFF2563EB).withValues(alpha: 0.22),
        const Color(0xFF3B82F6).withValues(alpha: 0.12),
        Colors.transparent,
      ],
      'accentColor': const Color(0xFF2563EB),
      'badgeBg': const Color(0xFFEFF6FF),
      'badgeBorder': const Color(0xFFDBEAFE),
      'badgeText': const Color(0xFF1D4ED8),
      'accessory1': {
        'icon': Icons.auto_awesome_rounded,
        'label': '24/7 AI CMO',
        'color': const Color(0xFF2563EB),
        'bgColor': const Color(0xFFEFF6FF),
      },
      'accessory2': {
        'icon': Icons.trending_up_rounded,
        'label': '+28% Customer Reach',
        'color': const Color(0xFF059669),
        'bgColor': const Color(0xFFECFDF5),
      },
    },
    {
      'badge': 'LOCAL SEO & RANKING',
      'headline': 'Dominate Google Local Search',
      'supporting': 'Real-time keyword tracking, site audits, and Google Business Profile optimization.',
      'gradientColors': [
        const Color(0xFF0D9488).withValues(alpha: 0.24),
        const Color(0xFF10B981).withValues(alpha: 0.12),
        Colors.transparent,
      ],
      'accentColor': const Color(0xFF0D9488),
      'badgeBg': const Color(0xFFF0FDFA),
      'badgeBorder': const Color(0xFFCCFBF1),
      'badgeText': const Color(0xFF0F766E),
      'accessory1': {
        'icon': Icons.pin_drop_rounded,
        'label': '#1 on Google Maps',
        'color': const Color(0xFF0D9488),
        'bgColor': const Color(0xFFF0FDFA),
      },
      'accessory2': {
        'icon': Icons.grid_view_rounded,
        'label': '3x3 Geo-Grid Top 3',
        'color': const Color(0xFF2563EB),
        'bgColor': const Color(0xFFEFF6FF),
      },
    },
    {
      'badge': 'CREATIVE & REPUTATION',
      'headline': 'Automate Growth in 1-Tap',
      'supporting': 'AI-drafted review replies, instant marketing creative, and multi-channel campaigns.',
      'gradientColors': [
        const Color(0xFF7C3AED).withValues(alpha: 0.22),
        const Color(0xFF6366F1).withValues(alpha: 0.12),
        Colors.transparent,
      ],
      'accentColor': const Color(0xFF7C3AED),
      'badgeBg': const Color(0xFFF5F3FF),
      'badgeBorder': const Color(0xFFEDE9FE),
      'badgeText': const Color(0xFF6D28D9),
      'accessory1': {
        'icon': Icons.star_rounded,
        'label': '5.0★ Review Replied',
        'color': const Color(0xFFD97706),
        'bgColor': const Color(0xFFFFFBEB),
      },
      'accessory2': {
        'icon': Icons.palette_rounded,
        'label': 'Studio Creative Live',
        'color': const Color(0xFF7C3AED),
        'bgColor': const Color(0xFFF5F3FF),
      },
    },
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _nextStory();
        }
      });

    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _bobAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _bobController, curve: Curves.easeInOut),
    );

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
    _bobController.stop();
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
    _progressController.dispose();
    _bobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = _stories[_currentStoryIndex];
    final isLastSlide = _currentStoryIndex == _stories.length - 1;

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
          child: Stack(
            children: [
              // 1. Subtle Scattered Background Iconography Pattern
              Positioned.fill(
                child: CustomPaint(
                  painter: _BackgroundPatternPainter(
                    accentColor: story['accentColor'] as Color,
                  ),
                ),
              ),

              // 2. Main Content Layout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Column(
                  children: [
                    // Top Segmented Progress Bars
                    Row(
                      children: List.generate(_stories.length, (index) {
                        return Expanded(
                          child: Container(
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
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
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                                      ),
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

                    // Top Header Bar: Logo Lockup & Skip Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Small Brand Lockup
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1E1B4B), Color(0xFF2563EB)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.auto_awesome,
                                  size: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'OptigoAI',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),

                        // Skip Action (Always jumps straight to Login)
                        InkWell(
                          onTap: _navigateToLogin,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              'Skip',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(flex: 2),

                    // 3. Central Mascot Illustration with Per-Slide Glow & Accessories
                    AnimatedBuilder(
                      animation: _bobAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _bobAnimation.value),
                          child: child,
                        );
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // Soft Radial Glow Blob (Slide-specific hue shift)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: story['gradientColors'] as List<Color>,
                              ),
                            ),
                          ),

                          // Optigo Mascot Avatar
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: Image.asset(
                              'assets/images/optigo-bot.png',
                              fit: BoxFit.contain,
                            ),
                          ),

                          // Per-Slide Floating Accessory 1 (Top-Right)
                          Positioned(
                            top: -6,
                            right: -10,
                            child: _buildFloatingAccessory(
                              icon: story['accessory1']['icon'] as IconData,
                              label: story['accessory1']['label'] as String,
                              color: story['accessory1']['color'] as Color,
                              bgColor: story['accessory1']['bgColor'] as Color,
                            ),
                          ),

                          // Per-Slide Floating Accessory 2 (Bottom-Left)
                          Positioned(
                            bottom: -4,
                            left: -12,
                            child: _buildFloatingAccessory(
                              icon: story['accessory2']['icon'] as IconData,
                              label: story['accessory2']['label'] as String,
                              color: story['accessory2']['color'] as Color,
                              bgColor: story['accessory2']['bgColor'] as Color,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 2),

                    // 4. Category Badge Kicker
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: story['badgeBg'] as Color,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: story['badgeBorder'] as Color),
                      ),
                      child: Text(
                        story['badge'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: story['badgeText'] as Color,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 5. Punchy Headline & Single Supporting Line
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Column(
                        key: ValueKey(_currentStoryIndex),
                        children: [
                          Text(
                            story['headline'] as String,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.8,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              story['supporting'] as String,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                height: 1.45,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 3),

                    // 6. Action Button (Next on Slides 1–2, Get Started on Slide 3)
                    InkWell(
                      onTap: isLastSlide ? _navigateToLogin : _nextStory,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: isLastSlide
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF1E1B4B),
                                    Color(0xFF1E3A8A),
                                    Color(0xFF2563EB),
                                  ],
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF1E3A8A),
                                    Color(0xFF2563EB),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLastSlide ? 'Get Started' : 'Next',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingAccessory({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for subtle scattered iconography background texture
class _BackgroundPatternPainter extends CustomPainter {
  final Color accentColor;

  _BackgroundPatternPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    // Draw subtle decorative ambient circles
    canvas.drawCircle(Offset(size.width * 0.12, size.height * 0.22), 24, paint);
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.35), 32, paint);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.72), 18, paint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.78), 26, paint);
  }

  @override
  bool shouldRepaint(covariant _BackgroundPatternPainter oldDelegate) =>
      oldDelegate.accentColor != accentColor;
}
