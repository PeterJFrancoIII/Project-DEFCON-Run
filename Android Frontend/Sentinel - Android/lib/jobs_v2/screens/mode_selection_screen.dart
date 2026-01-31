// Jobs v2 - Mode Selection Screen
// Prompts user to choose: List a Job (Employer) or Job Search (Worker)

import 'package:flutter/material.dart';
import '../theme.dart';
import '../api.dart';

class ModeSelectionScreen extends StatelessWidget {
  final JobsApi api;
  final String accountId;
  final String role;
  final bool verified;
  final VoidCallback onLogout;
  final Function(String mode) onModeSelected;

  const ModeSelectionScreen({
    required this.api,
    required this.accountId,
    required this.role,
    required this.verified,
    required this.onLogout,
    required this.onModeSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SentinelJobsTheme.background,
      appBar: AppBar(
        backgroundColor: SentinelJobsTheme.surface,
        title: const Text('SENTINEL WORKFORCE',
            style: SentinelJobsTheme.headerStyle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout,
                color: SentinelJobsTheme.textSecondary),
            onPressed: onLogout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.work_outline,
              size: 80,
              color: SentinelJobsTheme.primary,
            ),
            const SizedBox(height: 24),
            const Text(
              'WHAT WOULD YOU LIKE TO DO?',
              style: SentinelJobsTheme.headerStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Select your mission for this session',
              style: SentinelJobsTheme.mutedStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Worker Mode - FIND WORK
            _ModeCard(
              icon: Icons.work_history,
              title: 'FIND WORK',
              description: 'Browse and apply for available jobs',
              onTap: () => onModeSelected('worker'),
            ),

            const SizedBox(height: 16),

            // Employer Mode - POST A JOB
            _ModeCard(
              icon: Icons.add_business,
              title: 'POST A JOB',
              description: 'Create listings and hire workers',
              onTap: () {
                // Check if user can post jobs
                if (role == 'employer') {
                  if (verified) {
                    onModeSelected('employer');
                  } else {
                    // Employer but not verified
                    _showPendingVerificationDialog(context);
                  }
                } else {
                  // Worker - needs to upgrade
                  _showUpgradePrompt(context);
                }
              },
              isSecondary: role != 'employer',
            ),
          ],
        ),
      ),
    );
  }

  void _showPendingVerificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SentinelJobsTheme.surface,
        title: const Text('VERIFICATION PENDING',
            style: SentinelJobsTheme.titleStyle),
        content: const Text(
          'Your employer account is pending admin verification. You will be able to post jobs once approved.',
          style: SentinelJobsTheme.bodyStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK',
                style: TextStyle(color: SentinelJobsTheme.primary)),
          ),
        ],
      ),
    );
  }

  void _showUpgradePrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SentinelJobsTheme.surface,
        title: const Text('BECOME AN EMPLOYER',
            style: SentinelJobsTheme.titleStyle),
        content: const Text(
          'To post job listings, you need to upgrade to an Employer account. Go to your Profile to upgrade.',
          style: SentinelJobsTheme.bodyStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL',
                style: TextStyle(color: SentinelJobsTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Go to worker mode (they can upgrade from profile)
              onModeSelected('worker');
            },
            child: const Text('GO TO PROFILE',
                style: TextStyle(color: SentinelJobsTheme.primary)),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool isSecondary;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSecondary
              ? SentinelJobsTheme.surface
              : SentinelJobsTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSecondary
                ? SentinelJobsTheme.surfaceLight
                : SentinelJobsTheme.primary,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSecondary
                    ? SentinelJobsTheme.surfaceLight
                    : SentinelJobsTheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: isSecondary
                    ? SentinelJobsTheme.textSecondary
                    : SentinelJobsTheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSecondary
                          ? SentinelJobsTheme.textSecondary
                          : SentinelJobsTheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: SentinelJobsTheme.mutedStyle,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isSecondary
                  ? SentinelJobsTheme.textMuted
                  : SentinelJobsTheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
