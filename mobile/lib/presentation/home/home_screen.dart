import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../auth/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final user = authProvider.user;
    final business = authProvider.currentBusiness;

    return Scaffold(
      backgroundColor: OptigoTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(OptigoTheme.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: OptigoTheme.spacingSM),

              // Header with App Brand and Logout
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [OptigoTheme.primary, OptigoTheme.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(OptigoTheme.radiusSM),
                    ),
                    child: const Center(
                      child: Text(
                        'O',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: OptigoTheme.spacingSM),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business?.name ?? 'OptigoAI',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: OptigoTheme.textPrimary,
                        ),
                      ),
                      Text(
                        user != null ? 'Logged in as ${user.fullName}' : 'AI Marketing Manager',
                        style: const TextStyle(
                          fontSize: 12,
                          color: OptigoTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.logout_outlined, size: 22),
                    color: OptigoTheme.textSecondary,
                    onPressed: () => context.read<AppAuthProvider>().logout(),
                    tooltip: 'Log out',
                  ),
                ],
              ),

              const SizedBox(height: OptigoTheme.spacingLG),

              // Status card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(OptigoTheme.spacingLG),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [OptigoTheme.primary, OptigoTheme.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(OptigoTheme.radiusLG),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚡ Business Connected',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: OptigoTheme.spacingSM),
                    Text(
                      '${business?.name ?? "Your business"} is ready for AI Business Intelligence & CMO Recommendations.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: OptigoTheme.spacingLG),

              Text(
                'Business Profile Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: OptigoTheme.spacingSM),

              _buildInfoItem(context, 'Category', business?.category ?? 'Not specified'),
              _buildInfoItem(context, 'Location', business?.location ?? 'Not specified'),
              _buildInfoItem(context, 'Target Customers', business?.description ?? 'Set in onboarding'),
              _buildInfoItem(context, 'Onboarding Status', 'Complete ✅'),

              const Spacer(),

              Center(
                child: Text(
                  'OptigoAI MVP — Phase 2 Complete',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: OptigoTheme.spacingSM),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: OptigoTheme.spacingSM),
      padding: const EdgeInsets.symmetric(
        horizontal: OptigoTheme.spacingMD,
        vertical: OptigoTheme.spacingSM + 4,
      ),
      decoration: BoxDecoration(
        color: OptigoTheme.surface,
        borderRadius: BorderRadius.circular(OptigoTheme.radiusMD),
        border: Border.all(color: OptigoTheme.divider),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: OptigoTheme.textSecondary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: OptigoTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
