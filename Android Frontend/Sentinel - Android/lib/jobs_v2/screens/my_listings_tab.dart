// Jobs v2 - My Listings Tab (Strict Schema)
// Employer's posted jobs with status and applicant management

import 'package:flutter/material.dart';
import '../theme.dart';
import '../api.dart';
import 'edit_listing_screen.dart';
import 'application_detail_screen.dart';

class MyListingsTab extends StatefulWidget {
  final JobsApi api;
  final String? accountId;

  const MyListingsTab({required this.api, this.accountId, super.key});

  @override
  State<MyListingsTab> createState() => _MyListingsTabState();
}

class _MyListingsTabState extends State<MyListingsTab> {
  List<dynamic> _myListings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMyListings();
  }

  Future<void> _loadMyListings() async {
    setState(() => _loading = true);

    final resp = await widget.api.getMyListings();

    if (resp.success && resp.data != null) {
      if (mounted) {
        setState(() {
          _myListings = resp.data!;
          _loading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: SentinelJobsTheme.primary),
      );
    }

    if (_myListings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 64, color: SentinelJobsTheme.textMuted),
            SizedBox(height: 16),
            Text('No active assignments broadcasted.',
                style: SentinelJobsTheme.mutedStyle),
            // FAB in dashboard handles creation
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyListings,
      color: SentinelJobsTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myListings.length,
        itemBuilder: (ctx, i) => _buildMyListingCard(_myListings[i]),
      ),
    );
  }

  Widget _buildMyListingCard(dynamic listing) {
    final status = listing['status'] ?? 'active';
    final appCount = listing['application_count'] ??
        0; // Backend needs to ensure this count is sent
    final category = listing['category'] ?? 'General';

    // Strict schema doesn't have 'title' in creation, but backend search keys it.
    // If missing, use Category + Date? Or Description snippet.
    final title = listing['title'] ?? category.toString().toUpperCase();

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'active':
        statusColor = SentinelJobsTheme.success;
        statusIcon = Icons.sensors;
        break;
      case 'filled':
        statusColor = SentinelJobsTheme.primary;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = SentinelJobsTheme.error;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = SentinelJobsTheme.textMuted;
        statusIcon = Icons.help;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: SentinelJobsTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showListingActions(listing),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: SentinelJobsTheme.titleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: statusColor),
                      ),
                      child: Row(
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  listing['description'] ?? '',
                  style: SentinelJobsTheme.mutedStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),

                // Footer Stats
                Row(
                  children: [
                    // Applications
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: appCount > 0
                            ? SentinelJobsTheme.primary
                            : SentinelJobsTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$appCount APPLICANTS',
                        style: TextStyle(
                          color: appCount > 0
                              ? SentinelJobsTheme.background
                              : SentinelJobsTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // View applicants button
                    if (status == 'active' && appCount > 0)
                      SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          onPressed: () => _viewApplicants(listing),
                          style: SentinelJobsTheme.secondaryButton.copyWith(
                            padding: WidgetStateProperty.all(
                                const EdgeInsets.symmetric(horizontal: 16)),
                          ),
                          child: const Text('VIEW CANDIDATES'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showListingActions(dynamic listing) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SentinelJobsTheme.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: SentinelJobsTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            if (listing['status'] == 'active') ...[
              // View Candidates
              ListTile(
                leading:
                    const Icon(Icons.people, color: SentinelJobsTheme.primary),
                title: const Text('View Candidates',
                    style: SentinelJobsTheme.bodyStyle),
                onTap: () {
                  Navigator.pop(ctx);
                  _viewApplicants(listing);
                },
              ),

              // Edit Listing
              ListTile(
                leading: const Icon(Icons.edit,
                    color: SentinelJobsTheme.textPrimary),
                title: const Text('Edit Assignment',
                    style: SentinelJobsTheme.bodyStyle),
                onTap: () {
                  Navigator.pop(ctx);
                  _editListing(listing);
                },
              ),

              // Cancel Listing
              ListTile(
                leading:
                    const Icon(Icons.cancel, color: SentinelJobsTheme.error),
                title: const Text('Cancel Assignment',
                    style: TextStyle(color: SentinelJobsTheme.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmCancel(listing);
                },
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _editListing(dynamic listing) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditListingScreen(api: widget.api, listing: listing),
      ),
    );

    if (result == true) {
      _loadMyListings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ASSIGNMENT UPDATED'),
            backgroundColor: SentinelJobsTheme.success,
          ),
        );
      }
    }
  }

  void _confirmCancel(dynamic listing) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SentinelJobsTheme.surface,
        title: const Text('CANCEL ASSIGNMENT?',
            style: SentinelJobsTheme.headerStyle),
        content: const Text(
            'This will remove the job from the board. This action cannot be undone.',
            style: SentinelJobsTheme.bodyStyle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('NO, KEEP IT',
                style: TextStyle(color: SentinelJobsTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cancelListing(listing);
            },
            child: const Text('YES, CANCEL',
                style: TextStyle(color: SentinelJobsTheme.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelListing(dynamic listing) async {
    final jobId = listing['_id'] ?? listing['job_id'];
    final resp = await widget.api.cancelListing(jobId);

    if (!mounted) return;

    if (resp.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ASSIGNMENT CANCELLED'),
          backgroundColor: SentinelJobsTheme.success,
        ),
      );
      _loadMyListings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resp.error ?? 'Failed to cancel listing'),
          backgroundColor: SentinelJobsTheme.error,
        ),
      );
    }
  }

  void _viewApplicants(dynamic listing) async {
    final jobId = listing['_id'] ?? listing['job_id']; // Handle ID field
    final resp = await widget.api.getApplicants(jobId);

    if (!mounted) return;

    if (resp.success && resp.data != null) {
      _showApplicantsSheet(listing, resp.data!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resp.error ?? 'Failed to load applicants'),
          backgroundColor: SentinelJobsTheme.error,
        ),
      );
    }
  }

  void _showApplicantsSheet(dynamic listing, List<dynamic> applicants) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SentinelJobsTheme.surface,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'CANDIDATES FOR: ${listing['category'] ?? "JOB"}',
                style: SentinelJobsTheme.headerStyle,
              ),
            ),
            const Divider(color: SentinelJobsTheme.surfaceLight),
            Expanded(
              child: applicants.isEmpty
                  ? const Center(
                      child: Text("No candidates yet.",
                          style: SentinelJobsTheme.mutedStyle))
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: applicants.length,
                      itemBuilder: (ctx, i) => _buildApplicantCard(
                          listing['_id'] ?? listing['job_id'], applicants[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicantCard(String jobId, dynamic applicant) {
    // Strict schema: real_name, trust_score, verified
    final name =
        '${applicant['real_name_first']} ${applicant['real_name_last']}';
    final trustScore = applicant['trust_score'] ?? 50;
    final rating = applicant['rating_score'] ?? 0.0;

    final status = applicant['status'] ?? 'applied';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: SentinelJobsTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: SentinelJobsTheme.surfaceLight,
                child: Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(color: SentinelJobsTheme.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: SentinelJobsTheme.titleStyle),
                        const SizedBox(width: 8),
                        if (status == 'pending')
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: SentinelJobsTheme.warning
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: SentinelJobsTheme.warning)),
                            child: const Text('INTERVIEWING',
                                style: TextStyle(
                                    color: SentinelJobsTheme.warning,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          )
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.shield,
                            size: 12, color: SentinelJobsTheme.primary),
                        const SizedBox(width: 4),
                        Text('TRUST: $trustScore',
                            style: SentinelJobsTheme.mutedStyle),
                        const SizedBox(width: 12),
                        const Icon(Icons.star,
                            size: 12, color: SentinelJobsTheme.warning),
                        const SizedBox(width: 4),
                        Text('$rating', style: SentinelJobsTheme.mutedStyle),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (status == 'accepted')
            const Center(
                child: Text('WORKER HIRED',
                    style: TextStyle(
                        color: SentinelJobsTheme.success,
                        fontWeight: FontWeight.bold)))
          else
            Row(
              children: [
                // DISMISS
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateAppStatus(
                        applicant['application_id'], 'declined'),
                    style: SentinelJobsTheme.secondaryButton.copyWith(
                        side: WidgetStateProperty.all(
                            const BorderSide(color: SentinelJobsTheme.error)),
                        foregroundColor:
                            WidgetStateProperty.all(SentinelJobsTheme.error)),
                    child: const Text('DISMISS'),
                  ),
                ),
                const SizedBox(width: 12),

                // INTERVIEW (Pending)
                if (status == 'applied')
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateAppStatus(
                          applicant['application_id'], 'pending'),
                      style: SentinelJobsTheme.secondaryButton.copyWith(
                          side: WidgetStateProperty.all(const BorderSide(
                              color: SentinelJobsTheme.warning)),
                          foregroundColor: WidgetStateProperty.all(
                              SentinelJobsTheme.warning)),
                      child: const Text('CONN. OPEN'),
                    ),
                  ),

                if (status == 'applied') const SizedBox(width: 12),

                // HIRE (Accept)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateAppStatus(
                        applicant['application_id'], 'accepted'),
                    style: SentinelJobsTheme.primaryButton,
                    child: const Text('HIRE'),
                  ),
                ),
              ],
            ),

          // Chat Action for Interviewing/Hired
          if (status == 'pending' || status == 'accepted') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JobApplicationDetailScreen(
                        api: widget.api,
                        applicationId: applicant['application_id'],
                        accountId: widget.accountId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat, size: 16),
                label: Text(status == 'pending' ? 'OPEN CHAT' : 'MESSAGE'),
                style: SentinelJobsTheme.secondaryButton,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Future<void> _updateAppStatus(String appId, String status) async {
    final resp = await widget.api.updateApplicationStatus(appId, status);

    if (!mounted) return;
    Navigator.pop(
        context); // Close sheet to refresh or refresh inline? Closing easiest for MVP.

    if (resp.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('STATUS: ${status.toUpperCase()}'),
          backgroundColor: SentinelJobsTheme.success,
        ),
      );
      // Ideally refresh the sheet, but pop is safer to avoid state drift
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resp.error ?? 'Action failed'),
          backgroundColor: SentinelJobsTheme.error,
        ),
      );
    }
  }
}
