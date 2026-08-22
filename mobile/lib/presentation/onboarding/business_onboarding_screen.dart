import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../shared/optigo_text_field.dart';
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

  // Step 1: Basic Info (Matching Reference Screen 3)
  final _nameController = TextEditingController(text: 'Panekkatt Oil and Flour Mill');
  String _selectedCategory = 'Local Manufacturing & Mill';
  String _selectedLocation = 'Ponnani, Kerala, India';
  final _websiteController = TextEditingController(text: 'https://panekkattmill.com');

  // Step 2: Target Audience & Key Services
  final _targetCustomersController = TextEditingController(text: 'Local households, organic food lovers, and wholesale buyers in Malappuram district');
  final _servicesController = TextEditingController(text: 'Cold pressed coconut oil, sesame oil, freshly milled rice flour, wheat flour, and spice powders');

  // Step 3: Goals & Marketing Channels
  final _goalsController = TextEditingController(text: 'Increase local store foot traffic and rank #1 on Google Maps for oil mill near me');
  final _channelsController = TextEditingController(text: 'Google Business Profile, WhatsApp orders, Instagram');

  final List<String> _categories = [
    'Restaurant / Cafe',
    'Local Manufacturing & Mill',
    'Retail / Supermarket',
    'Health & Wellness',
    'Professional Services',
    'Automotive & Repair',
    'Beauty & Salon',
  ];

  final List<String> _locations = [
    'Ponnani, Kerala, India',
    'Bengaluru, India',
    'Mumbai, India',
    'Delhi NCR, India',
    'Chennai, India',
    'Hyderabad, India',
    'Kochi, Kerala, India',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
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
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  Future<void> _submitOnboarding() async {
    setState(() => _isSubmitting = true);

    final authProvider = context.read<AppAuthProvider>();
    final result = await authProvider.createBusinessAndOnboard(
      name: _nameController.text.trim(),
      category: _selectedCategory,
      location: _selectedLocation,
      website: _websiteController.text.trim(),
      targetCustomers: _targetCustomersController.text.trim(),
      services: _servicesController.text.trim(),
      businessGoals: _goalsController.text.trim(),
      marketingChannels: _channelsController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (result == null && mounted) {
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
            // Top Nav & Step Indicators (Matching Reference Screen 3)
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
                            width: 28,
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

            // Bottom Continue Action Button (Matching Reference Screen 3)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: InkWell(
                onTap: _isSubmitting ? null : _nextPage,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(
                            _currentPage == 2 ? 'Complete Setup' : 'Continue',
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // STEP 1: Tell us about your business (Matching Reference Screen 3)
  // ==========================================================
  Widget _buildStep1BasicInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text(
            'Tell us about\nyour business',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.7,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This helps AI CMO understand your business better.',
            style: TextStyle(
              fontSize: 13.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 28),

          // Business Name
          OptigoTextField(
            controller: _nameController,
            label: 'Business name',
            hintText: 'Coffee House',
            prefixIcon: Icons.storefront_outlined,
          ),

          const SizedBox(height: 16),

          // Business Category Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Business category',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
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
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
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

          // Business Location Dropdown / Input
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Business location',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
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
                    value: _selectedLocation,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    items: _locations.map((loc) {
                      return DropdownMenuItem(value: loc, child: Text(loc));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedLocation = val);
                    },
                  ),
                ),
              ),
            ],
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
          const Text(
            'Audience &\nOfferings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.7,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Who are your ideal customers and what do you sell?',
            style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 28),

          OptigoTextField(
            controller: _targetCustomersController,
            label: 'Target Customers',
            hintText: 'e.g. Local families, office workers, tourists...',
            maxLines: 3,
            prefixIcon: Icons.people_outline,
          ),
          const SizedBox(height: 18),

          OptigoTextField(
            controller: _servicesController,
            label: 'Key Products / Services',
            hintText: 'e.g. Cold pressed oils, fresh bakery, espresso drinks...',
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
          const Text(
            'Growth Goals &\nChannels',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.7,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'What do you want your AI CMO to prioritize?',
            style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 28),

          OptigoTextField(
            controller: _goalsController,
            label: 'Primary Marketing Goal',
            hintText: 'e.g. Rank #1 on Google Maps, get 50 new 5-star reviews...',
            maxLines: 3,
            prefixIcon: Icons.flag_outlined,
          ),
          const SizedBox(height: 18),

          OptigoTextField(
            controller: _channelsController,
            label: 'Active Marketing Channels',
            hintText: 'e.g. Google Business Profile, Instagram, WhatsApp...',
            maxLines: 2,
            prefixIcon: Icons.share_outlined,
          ),
        ],
      ),
    );
  }
}
