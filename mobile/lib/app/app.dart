import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import '../presentation/auth/auth_provider.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/onboarding/business_onboarding_screen.dart';
import '../presentation/main_shell.dart';

class OptigoAIApp extends StatelessWidget {
  const OptigoAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OptigoAI',
      debugShowCheckedModeBanner: false,
      theme: OptigoTheme.lightTheme,
      home: const AuthRouter(),
    );
  }
}

class AuthRouter extends StatelessWidget {
  const AuthRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();

    if (authProvider.status == AuthStatus.initial ||
        (authProvider.status == AuthStatus.loading && authProvider.user == null)) {
      return Scaffold(
        backgroundColor: OptigoTheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: OptigoTheme.spacingLG),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(OptigoTheme.primary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    if (authProvider.currentBusiness == null ||
        !authProvider.currentBusiness!.onboardingCompleted) {
      return const BusinessOnboardingScreen();
    }

    return const MainShell();
  }
}
