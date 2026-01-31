// Jobs v2 - Dashboard Screen (Rebuilt V3)
// Uses IndexedStack for state preservation and explicit navigation

import 'package:flutter/material.dart';
import '../theme.dart';
import '../api.dart';
import 'listings_tab.dart';
import 'my_listings_tab.dart';
import 'profile_tab.dart';
import 'create_listing_screen.dart';
import 'applied_tab.dart';
import 'inbox_tab.dart';

class JobsDashboardScreen extends StatefulWidget {
  final JobsApi api;
  final String accountId;
  final String role;
  final bool verified;
  final VoidCallback onLogout;
  final VoidCallback? onBackToModeSelection;

  const JobsDashboardScreen({
    required this.api,
    required this.accountId,
    required this.role,
    required this.verified,
    required this.onLogout,
    this.onBackToModeSelection,
    super.key,
  });

  @override
  State<JobsDashboardScreen> createState() => _JobsDashboardScreenState();
}

class _JobsDashboardScreenState extends State<JobsDashboardScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isEmployer = widget.role == 'employer';

    return Scaffold(
      backgroundColor: SentinelJobsTheme.background,

      // Header
      appBar: AppBar(
        backgroundColor: SentinelJobsTheme.surface,
        elevation: 2,
        leading: widget.onBackToModeSelection != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: SentinelJobsTheme.primary),
                tooltip: "Change Mode",
                onPressed: widget.onBackToModeSelection,
              )
            : null,
        title: const Text(
          'SENTINEL WORKFORCE',
          style: SentinelJobsTheme.headerStyle,
        ),
        actions: [
          // Pending Verification Badge
          if (isEmployer && !widget.verified)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: SentinelJobsTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: SentinelJobsTheme.warning),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hourglass_empty,
                      size: 14, color: SentinelJobsTheme.warning),
                  SizedBox(width: 4),
                  Text('UNVERIFIED',
                      style: TextStyle(
                          color: SentinelJobsTheme.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),

          // Logout
          IconButton(
            icon: const Icon(Icons.logout, color: SentinelJobsTheme.error),
            tooltip: "Logout",
            onPressed: widget.onLogout,
          ),
        ],
      ),

      // Body - Uses IndexedStack to keep tabs alive
      body: SafeArea(
        child: IndexedStack(
          index: _tabIndex,
          children: [
            ListingsTab(api: widget.api, role: widget.role), // Tab 0: Browse
            isEmployer
                ? MyListingsTab(api: widget.api, accountId: widget.accountId)
                : AppliedTab(
                    api: widget.api,
                    accountId: widget.accountId), // Tab 1: My Jobs / Applied
            InboxTab(
                api: widget.api,
                accountId: widget.accountId), // Tab 2: Inbox (New)
            ProfileTab(api: widget.api), // Tab 3: Profile
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: Container(
        height: 60,
        decoration: const BoxDecoration(
          color: SentinelJobsTheme.surface,
          border:
              Border(top: BorderSide(color: SentinelJobsTheme.surfaceLight)),
        ),
        child: Row(
          children: [
            _NavButton(
              icon: Icons.travel_explore, // Browse
              label: 'BROWSE',
              selected: _tabIndex == 0,
              onTap: () => setState(() => _tabIndex = 0),
            ),
            _NavButton(
              icon: isEmployer
                  ? Icons.business_center
                  : Icons.assignment_turned_in,
              label: isEmployer ? 'MY POSTS' : 'APPLIED',
              selected: _tabIndex == 1,
              onTap: () => setState(() => _tabIndex = 1),
            ),
            _NavButton(
              icon: Icons.chat_bubble_outline,
              label: 'MESSAGES',
              selected: _tabIndex == 2,
              onTap: () => setState(() => _tabIndex = 2),
            ),
            _NavButton(
              icon: Icons.shield, // Profile
              label: 'ID CARD',
              selected: _tabIndex == 3,
              onTap: () => setState(() => _tabIndex = 3),
            ),
          ],
        ),
      ),

      // FAB: Post Job (Employer Only)
      floatingActionButton: isEmployer
          ? FloatingActionButton.extended(
              backgroundColor: widget.verified
                  ? SentinelJobsTheme.primary
                  : SentinelJobsTheme.textMuted,
              foregroundColor: SentinelJobsTheme.background,
              icon: const Icon(Icons.add_location_alt),
              label: const Text("BROADCAST OP"),
              onPressed: _openCreateListing,
            )
          : null,
    );
  }

  void _openCreateListing() async {
    if (!widget.verified) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: SentinelJobsTheme.surface,
          title: const Text('RESTRICTED ACCESS',
              style: SentinelJobsTheme.titleStyle),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, size: 48, color: SentinelJobsTheme.warning),
              SizedBox(height: 16),
              Text(
                'Employer account verification required.',
                style: SentinelJobsTheme.bodyStyle,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Pending Administrator Approval.',
                style: SentinelJobsTheme.mutedStyle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ACKNOWLEDGE',
                  style: TextStyle(color: SentinelJobsTheme.primary)),
            ),
          ],
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateListingScreen(api: widget.api),
      ),
    );

    if (result == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ASSIGNMENT BROADCASTED SUCCESSFULLY'),
          backgroundColor: SentinelJobsTheme.success,
        ),
      );
      // Switch to tab 1 (My Posts) to see it
      setState(() => _tabIndex = 1);
    }
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected
                    ? SentinelJobsTheme.primary
                    : SentinelJobsTheme.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? SentinelJobsTheme.primary
                      : SentinelJobsTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
