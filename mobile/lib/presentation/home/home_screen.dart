import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Placeholder home screen for Phase 1.
/// Will be replaced with the full AI CMO Home in Phase 5.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OptigoTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(OptigoTheme.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: OptigoTheme.spacingLG),

              // App header
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
                  Text(
                    'OptigoAI',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),

              const SizedBox(height: OptigoTheme.spacingXL),

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
                      '🚀 Foundation Ready',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: OptigoTheme.spacingSM),
                    Text(
                      'Phase 1 Complete — Architecture & Foundation',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: OptigoTheme.spacingLG),

              Text(
                'System Status',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: OptigoTheme.spacingSM),

              _buildStatusItem(context, 'Flutter App', 'Running', true),
              _buildStatusItem(context, 'FastAPI Backend', 'Pending connection', false),
              _buildStatusItem(context, 'PostgreSQL', 'Pending Docker', false),
              _buildStatusItem(context, 'Redis', 'Pending Docker', false),
              _buildStatusItem(context, 'Celery Workers', 'Pending Docker', false),

              const Spacer(),

              Center(
                child: Text(
                  'OptigoAI MVP v0.1.0',
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

  Widget _buildStatusItem(
    BuildContext context,
    String name,
    String status,
    bool isActive,
  ) {
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
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? OptigoTheme.success : OptigoTheme.textTertiary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: OptigoTheme.spacingSM),
          Text(
            name,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const Spacer(),
          Text(
            status,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isActive ? OptigoTheme.success : OptigoTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
