import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app/app.dart';
import '../../app/theme.dart';
import '../shared/optigo_text_field.dart';
import '../shared/optigo_button.dart';
import '../auth/auth_provider.dart';

class BusinessOnboardingScreen extends StatefulWidget {
  const BusinessOnboardingScreen({super.key});

  @override
  State<BusinessOnboardingScreen> createState() => _BusinessOnboardingScreenState();
}

class _BusinessOnboardingScreenState extends State<BusinessOnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isSubmitting = false;

  // Step 1: Basic Info
  final _nameController = TextEditingController();
  final _locationController = TextEditingController(text: 'Bengaluru, India');
  String _selectedCategory = 'Restaurant / Cafe';
  final _websiteController = TextEditingController();

  // Step 2: Target Audience & Key Services
  final _targetCustomersController = TextEditingController();
  final _servicesController = TextEditingController();

  // Step 3: Goals & Marketing Channels
  final _goalsController = TextEditingController();
  final _channelsController = TextEditingController();

  final List<String> _categories = [
    'Restaurant / Cafe',
    'Local Manufacturing & Mill',
    'Retail / Supermarket',
    'Health & Wellness',
    'Professional Services',
    'Automotive & Repair',
    'Beauty & Salon',
    'Real Estate & Construction',
    'Education & Coaching',
    'Other Local Business',
  ];

  final List<String> _locationSuggestions = [
    'Bengaluru, India',
    'Ponnani, Kerala',
    'Mumbai, India',
    'Delhi NCR, India',
    'Kochi, Kerala',
    'Chennai, India',
    'Hyderabad, India',
    'Dubai, UAE',
    'Singapore',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _targetCustomersController.dispose();
    _servicesController.dispose();
    _goalsController.dispose();
    _channelsController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0) {
      if (_nameController.text.trim().isEmpty) {
        _showError('Please enter your business name');
        return;
      }
      if (_locationController.text.trim().isEmpty) {
        _showError('Please enter your business location');
        return;
      }
    }

    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: OptigoTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _submitOnboarding() async {
    setState(() => _isSubmitting = true);

    final authProvider = context.read<AppAuthProvider>();
    final result = await authProvider.createBusinessAndOnboard(
      name: _nameController.text.trim(),
      category: _selectedCategory,
      location: _locationController.text.trim(),
      website: _websiteController.text.trim(),
      targetCustomers: _targetCustomersController.text.trim(),
      services: _servicesController.text.trim(),
      businessGoals: _goalsController.text.trim(),
      marketingChannels: _channelsController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (result != null && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthRouter()),
        (route) => false,
      );
    } else if (result == null && mounted) {
      _showError(authProvider.errorMessage ?? 'Failed to complete onboarding. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Nav & Step Indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0)
                        IconButton(
                          onPressed: _previousPage,
                          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        )
                      else
                        const SizedBox(width: 24),

                      // Step Segmented Progress Indicator
                      Row(
                        children: List.generate(3, (index) {
                          final isActive = index <= _currentPage;
                          return Container(
                            width: 32,
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),

                      IconButton(
                        onPressed: () => context.read<AppAuthProvider>().logout(),
                        icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFF94A3B8)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Log Out',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildStep1BasicInfo(),
                  _buildStep2Audience(),
                  _buildStep3Goals(),
                ],
              ),
            ),

            // Bottom Continue Action Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: OptigoButton(
                text: _currentPage == 2 ? 'Complete Setup & Launch' : 'Continue',
                useGradient: true,
                isLoading: _isSubmitting,
                onPressed: _nextPage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // STEP 1: Tell us about your business
  // ==========================================================
  Widget _buildStep1BasicInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Tell us about\nyour business',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.7,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'OptigoAI tailors local SEO, reviews, and campaigns for your store.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 24),

          // Business Name
          OptigoTextField(
            controller: _nameController,
            label: 'Business Name',
            hintText: 'e.g. Panekkatt Oil & Flour Mill',
            prefixIcon: Icons.storefront_outlined,
          ),

          const SizedBox(height: 16),

          // Business Category Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Business Category',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedCategory,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                    items: _categories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Business Location Open Input
          OptigoTextField(
            controller: _locationController,
            label: 'Business Location (City / Area)',
            hintText: 'e.g. Ponnani, Kerala, India',
            prefixIcon: Icons.location_on_outlined,
          ),

          const SizedBox(height: 8),

          // Location quick chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _locationSuggestions.map((loc) {
              final isSel = _locationController.text == loc;
              return InkWell(
                onTap: () => setState(() => _locationController.text = loc),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSel ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    loc,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                      color: isSel ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Website (Optional)
          OptigoTextField(
            controller: _websiteController,
            label: 'Website URL (Optional)',
            hintText: 'https://yourbusiness.com',
            prefixIcon: Icons.language_outlined,
            keyboardType: TextInputType.url,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==========================================================
  // STEP 2: Target Audience & Services
  // ==========================================================
  Widget _buildStep2Audience() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Audience &\nOfferings',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.7,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Who are your ideal customers and what do you sell?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),

          OptigoTextField(
            controller: _targetCustomersController,
            label: 'Target Customers',
            hintText: 'e.g. Local families, health-conscious shoppers, neighborhood clients...',
            maxLines: 3,
            prefixIcon: Icons.people_outline,
          ),
          const SizedBox(height: 18),

          OptigoTextField(
            controller: _servicesController,
            label: 'Key Products / Services',
            hintText: 'e.g. Cold pressed oils, fresh flour milling, organic spices...',
            maxLines: 3,
            prefixIcon: Icons.inventory_2_outlined,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // STEP 3: Goals & Growth Focus
  // ==========================================================
  Widget _buildStep3Goals() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Growth Goals &\nChannels',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.7,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'What should your AI Marketing Co-Pilot prioritize first?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),

          OptigoTextField(
            controller: _goalsController,
            label: 'Primary Marketing Goal',
            hintText: 'e.g. Rank #1 on Google Maps, get 50 new 5-star reviews, boost walk-ins...',
            maxLines: 3,
            prefixIcon: Icons.flag_outlined,
          ),
          const SizedBox(height: 18),

          OptigoTextField(
            controller: _channelsController,
            label: 'Active Marketing Channels',
            hintText: 'e.g. Google Business Profile, Instagram, WhatsApp Business...',
            maxLines: 2,
            prefixIcon: Icons.share_outlined,
          ),
        ],
      ),
    );
  }
}
