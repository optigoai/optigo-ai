import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../shared/optigo_button.dart';
import '../shared/optigo_text_field.dart';
import 'auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _orgController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _orgController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AppAuthProvider>();
    final success = await authProvider.signup(
      email: _emailController.text,
      password: _passwordController.text,
      fullName: _nameController.text,
      organizationName: _orgController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pop(); // Return to auth router which will direct to onboarding
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Signup failed. Please try again.'),
          backgroundColor: OptigoTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final isLoading = authProvider.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: OptigoTheme.background,
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(OptigoTheme.spacingLG),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start growing your business with AI',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: OptigoTheme.spacingXS),
                Text(
                  'Set up your organization in less than a minute.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: OptigoTheme.spacingLG),

                // Full Name
                OptigoTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hintText: 'Sarah Jenkins',
                  prefixIcon: Icons.person_outline,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter your full name';
                    return null;
                  },
                ),
                const SizedBox(height: OptigoTheme.spacingMD),

                // Organization Name
                OptigoTextField(
                  controller: _orgController,
                  label: 'Organization / Company Name',
                  hintText: 'Apex Marketing Group',
                  prefixIcon: Icons.business_outlined,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter your organization name';
                    return null;
                  },
                ),
                const SizedBox(height: OptigoTheme.spacingMD),

                // Email
                OptigoTextField(
                  controller: _emailController,
                  label: 'Work Email Address',
                  hintText: 'sarah@apex.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter your email';
                    if (!val.contains('@')) return 'Please enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: OptigoTheme.spacingMD),

                // Password
                OptigoTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hintText: 'At least 8 characters',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: OptigoTheme.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (val) {
                    if (val == null || val.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: OptigoTheme.spacingXL),

                // Submit Button
                OptigoButton(
                  text: 'Create Account',
                  isLoading: isLoading,
                  onPressed: _handleSignup,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
