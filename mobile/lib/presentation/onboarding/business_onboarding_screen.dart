import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../shared/optigo_button.dart';
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

  // Step 1: Basic Info
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();

  // Step 2: Customer & Services
  final _targetCustomersController = TextEditingController();
  final _servicesController = TextEditingController();

  // Step 3: Goals & Channels
  final _goalsController = TextEditingController();
  final _channelsController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
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
      if (_categoryController.text.trim().isEmpty) {
        _showError('Please specify your business category');
        return;
      }
    } else if (_currentPage == 1) {
      if (_targetCustomersController.text.trim().isEmpty) {
        _showError('Please describe your target customers');
        return;
      }
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: OptigoTheme.error,
      ),
    );
  }

  Future<void> _submitOnboarding() async {
    setState(() => _isSubmitting = true);

    final authProvider = context.read<AppAuthProvider>();
    final result = await authProvider.createBusinessAndOnboard(
      name: _nameController.text.trim(),
      category: _categoryController.text.trim(),
      location: _locationController.text.trim(),
      website: _websiteController.text.trim(),
      targetCustomers: _targetCustomersController.text.trim(),
      services: _servicesController.text.trim(),
      businessGoals: _goalsController.text.trim(),
      marketingChannels: _channelsController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (result == null && mounted) {
      _showError(authProvider.errorMessage ?? 'Failed to save onboarding. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OptigoTheme.background,
      appBar: AppBar(
        title: const Text('Business Setup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, size: 20),
            onPressed: () => context.read<AppAuthProvider>().logout(),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: OptigoTheme.spacingLG,
                vertical: OptigoTheme.spacingMD,
              ),
              child: Row(
                children: [
                  _buildStepIndicator(0, 'Business'),
                  _buildStepDivider(0),
                  _buildStepIndicator(1, 'Audience'),
                  _buildStepDivider(1),
                  _buildStepIndicator(2, 'Goals'),
                ],
              ),
            ),
            const Divider(),

            // Page View
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title) {
    final isDone = _currentPage > stepIndex;
    final isCurrent = _currentPage == stepIndex;

    Color circleColor = OptigoTheme.divider;
    Color textColor = OptigoTheme.textTertiary;

    if (isCurrent) {
      circleColor = OptigoTheme.primary;
      textColor = OptigoTheme.primary;
    } else if (isDone) {
      circleColor = OptigoTheme.success;
      textColor = OptigoTheme.textPrimary;
    }

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isCurrent || isDone ? circleColor : Colors.transparent,
            border: Border.all(color: circleColor, width: 2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '${stepIndex + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isCurrent ? Colors.white : OptigoTheme.textSecondary,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: OptigoTheme.spacingXS),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(int stepIndex) {
    final isDone = _currentPage > stepIndex;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: OptigoTheme.spacingSM),
        color: isDone ? OptigoTheme.success : OptigoTheme.divider,
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(OptigoTheme.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us about your business',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: OptigoTheme.spacingXS),
          Text(
            'Your AI CMO will tailor recommendations specifically for your industry and location.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: OptigoTheme.spacingLG),
          OptigoTextField(
            controller: _nameController,
            label: 'Business Name *',
            hintText: 'e.g. Blossom Dental Clinic',
            prefixIcon: Icons.storefront_outlined,
          ),
          const SizedBox(height: OptigoTheme.spacingMD),
          OptigoTextField(
            controller: _categoryController,
            label: 'Category / Industry *',
            hintText: 'e.g. Dental Care, Italian Restaurant, Auto Repair',
            prefixIcon: Icons.category_outlined,
          ),
          const SizedBox(height: OptigoTheme.spacingMD),
          OptigoTextField(
            controller: _locationController,
            label: 'Location / City',
            hintText: 'e.g. Indiranagar, Bangalore',
            prefixIcon: Icons.location_on_outlined,
          ),
          const SizedBox(height: OptigoTheme.spacingMD),
          OptigoTextField(
            controller: _websiteController,
            label: 'Website / Social URL (Optional)',
            hintText: 'https://blossomdental.in',
            prefixIcon: Icons.language_outlined,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: OptigoTheme.spacingXL),
          OptigoButton(
            text: 'Continue to Audience',
            onPressed: _nextPage,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(OptigoTheme.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Who are your ideal customers?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: OptigoTheme.spacingXS),
          Text(
            'Help OptigoAI understand your target demographic and core offerings.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: OptigoTheme.spacingLG),
          OptigoTextField(
            controller: _targetCustomersController,
            label: 'Target Customers *',
            hintText: 'e.g. Local families, working professionals looking for cosmetic dentistry',
            prefixIcon: Icons.people_outline,
            maxLines: 3,
          ),
          const SizedBox(height: OptigoTheme.spacingMD),
          OptigoTextField(
            controller: _servicesController,
            label: 'Key Services or Products',
            hintText: 'e.g. Teeth Whitening, Root Canal, Dental Implants, Braces',
            prefixIcon: Icons.list_alt_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: OptigoTheme.spacingXL),
          Row(
            children: [
              Expanded(
                child: OptigoButton(
                  text: 'Back',
                  isOutlined: true,
                  onPressed: _previousPage,
                ),
              ),
              const SizedBox(width: OptigoTheme.spacingMD),
              Expanded(
                child: OptigoButton(
                  text: 'Continue',
                  onPressed: _nextPage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(OptigoTheme.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Marketing goals & channels',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: OptigoTheme.spacingXS),
          Text(
            'What is the primary result you want to achieve right now?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: OptigoTheme.spacingLG),
          OptigoTextField(
            controller: _goalsController,
            label: 'Primary Business Goal',
            hintText: 'e.g. Increase monthly cosmetic appointments by 30%, get more 5-star reviews',
            prefixIcon: Icons.flag_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: OptigoTheme.spacingMD),
          OptigoTextField(
            controller: _channelsController,
            label: 'Current Marketing Channels',
            hintText: 'e.g. Google Business Profile, Instagram, Word of mouth',
            prefixIcon: Icons.campaign_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: OptigoTheme.spacingXL),
          Row(
            children: [
              Expanded(
                child: OptigoButton(
                  text: 'Back',
                  isOutlined: true,
                  onPressed: _previousPage,
                ),
              ),
              const SizedBox(width: OptigoTheme.spacingMD),
              Expanded(
                child: OptigoButton(
                  text: 'Complete Setup',
                  isLoading: _isSubmitting,
                  onPressed: _submitOnboarding,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
