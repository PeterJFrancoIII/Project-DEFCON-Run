// Jobs v2 - Applied Jobs Tab
// Worker's application history

import 'package:flutter/material.dart';
import '../theme.dart';
import '../api.dart';

import 'application_detail_screen.dart';

class AppliedTab extends StatefulWidget {
  final JobsApi api;
  final String? accountId;

  const AppliedTab({required this.api, this.accountId, super.key});

  @override
  State<AppliedTab> createState() => _AppliedTabState();
}

class _AppliedTabState extends State<AppliedTab> {
  List<dynamic> _applications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _loading = true);
    final resp = await widget.api.getAppliedJobs();

    if (resp.success && resp.data != null) {
      if (mounted) {
        setState(() {
          _applications = resp.data!;
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

    if (_applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_ind,
                size: 64, color: SentinelJobsTheme.textMuted),
            const SizedBox(height: 16),
            const Text('No active missions.',
                style: SentinelJobsTheme.mutedStyle),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // Ideally switch to Browse tab, but parent controls tabs.
                // Just refreshing for now.
                _loadApplications();
              },
              child: const Text('REFRESH',
                  style: TextStyle(color: SentinelJobsTheme.primary)),
            )
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      color: SentinelJobsTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _applications.length,
        itemBuilder: (ctx, i) => _buildApplicationCard(_applications[i]),
      ),
    );
  }

  Widget _buildApplicationCard(dynamic app) {
    final status = app['status'] ?? 'pending';
    // 'job_title' enriched by backend
    final title = app['job_title'] ?? 'Job Application';
    final payType = app['pay_type'] ?? 'unknown';
    // pay_range might be null if job deleted, handle gracefully
    final payRange = app['pay_range'] ?? {};

    final payStr = payType == 'cash'
        ? '\$${payRange['min'] ?? 0} - \$${payRange['max'] ?? 0}'
        : payType == 'hourly'
            ? '\$${payRange['min']}/hr'
            : 'Volunteer';

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'accepted':
        statusColor = SentinelJobsTheme.success;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = SentinelJobsTheme.warning;
        statusIcon = Icons.hourglass_top;
        break;
      case 'declined':
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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JobApplicationDetailScreen(
                api: widget.api,
                applicationId: app['application_id'],
              ),
            ),
          ).then((_) => _loadApplications());
        },
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
                      title.toString().toUpperCase(),
                      style: SentinelJobsTheme.titleStyle,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              const SizedBox(height: 8),
              Text(app['description'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SentinelJobsTheme.mutedStyle),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: SentinelJobsTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(payStr,
                        style: const TextStyle(
                            color: SentinelJobsTheme.success,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  // If accepted, show chat or details button?
                  if (status == 'accepted')
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JobApplicationDetailScreen(
                              api: widget.api,
                              applicationId: app['application_id'],
                              accountId: widget.accountId,
                            ),
                          ),
                        ).then((_) => _loadApplications());
                      },
                      icon: const Icon(Icons.chat, size: 14),
                      label: const Text('VIEW MESSAGES',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 10)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SentinelJobsTheme.success,
                        foregroundColor: SentinelJobsTheme.background,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
