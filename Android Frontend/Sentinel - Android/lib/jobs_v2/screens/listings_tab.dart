// Jobs v2 - Feed Screen (Lazy Load)
// Emergency Labor Board: Category Filters, Geo-Spatial Sort, Large Cards
// Rebuilt for visibility and robust state handling

import 'package:flutter/material.dart';
import '../theme.dart';
import '../api.dart';

class ListingsTab extends StatefulWidget {
  final JobsApi api;
  final String role;

  const ListingsTab({required this.api, required this.role, super.key});

  @override
  State<ListingsTab> createState() => _ListingsTabState();
}

class _ListingsTabState extends State<ListingsTab> {
  List<dynamic> _listings = [];
  bool _loading = true;
  String? _error;
  String? _filterCategory;

  // Default search location (NYC) for MVP if permission not granted
  final double _lat = 40.7128;
  final double _lon = -74.0060;

  final _categories = ['Security', 'Logistics', 'Medical', 'Cleanup', 'Admin'];

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Lazy load with geo-sort
      final resp = await widget.api.searchListings(
          category: _filterCategory, lat: _lat, lon: _lon, radiusKm: 50);

      if (mounted) {
        if (resp.success && resp.data != null) {
          setState(() {
            _listings = resp.data!;
            _loading = false;
          });
        } else {
          setState(() {
            _error = resp.error ?? "Failed to load missions.";
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Connection Error: $e";
          _loading = false;
        });
      }
    }
  }

  Future<void> _applyToJob(String jobId) async {
    final resp = await widget.api.applyToJob(jobId);

    if (!mounted) return;

    if (resp.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('APPLICATION SUBMITTED'),
          backgroundColor: SentinelJobsTheme.success,
        ),
      );
      // Don't reload entire list, just maybe mark as applied locally?
      // For now, reloading is safer to update state
      _loadListings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resp.error ?? 'Apply failed'),
          backgroundColor: SentinelJobsTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Category Filters
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: SentinelJobsTheme.surface,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _FilterChip(
                label: 'ALL SECTORS',
                selected: _filterCategory == null,
                onTap: () {
                  setState(() => _filterCategory = null);
                  _loadListings();
                },
              ),
              ..._categories.map((c) => _FilterChip(
                    label: c.toUpperCase(),
                    selected: _filterCategory == c,
                    onTap: () {
                      setState(() => _filterCategory = c);
                      _loadListings();
                    },
                  )),
            ],
          ),
        ),

        // Status Bar (Location / Connection)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: SentinelJobsTheme.surfaceLight,
          child: Row(
            children: [
              const Icon(Icons.gps_fixed,
                  size: 12, color: SentinelJobsTheme.textSecondary),
              const SizedBox(width: 4),
              const Text("SECTOR: NYC (SIMULATED)",
                  style: TextStyle(
                      color: SentinelJobsTheme.textSecondary, fontSize: 10)),
              const Spacer(),
              if (_loading)
                const Text("UPLINK ACTIVE...",
                    style: TextStyle(
                        color: SentinelJobsTheme.primary, fontSize: 10)),
            ],
          ),
        ),

        // Listings Feed
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: SentinelJobsTheme.primary),
            const SizedBox(height: 16),
            Text("SCANNING FOR MISSIONS...",
                style: SentinelJobsTheme.headerStyle
                    .copyWith(color: SentinelJobsTheme.primary)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.signal_wifi_off,
                size: 48, color: SentinelJobsTheme.error),
            const SizedBox(height: 16),
            Text("UPLINK FAILED",
                style: SentinelJobsTheme.headerStyle
                    .copyWith(color: SentinelJobsTheme.error)),
            const SizedBox(height: 8),
            Text(_error!, style: SentinelJobsTheme.mutedStyle),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _loadListings,
              style: SentinelJobsTheme.secondaryButton,
              child: const Text("RETRY CONNECTION"),
            ),
          ],
        ),
      );
    }

    if (_listings.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadListings,
      color: SentinelJobsTheme.primary,
      backgroundColor: SentinelJobsTheme.surfaceLight,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _listings.length,
        itemBuilder: (ctx, i) => _buildListingCard(_listings[i]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.radar, size: 64, color: SentinelJobsTheme.textMuted),
          const SizedBox(height: 16),
          const Text('NO ACTIVE MISSIONS',
              style: SentinelJobsTheme.headerStyle),
          const SizedBox(height: 8),
          const Text('No assignments found in this sector.',
              style: SentinelJobsTheme.mutedStyle),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _loadListings,
            style: SentinelJobsTheme.secondaryButton,
            child: const Text("REFRESH SCAN"),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(dynamic listing) {
    final title = listing['category'] ?? 'General Task';
    final employerName = listing['employer_name'] ?? 'Unknown';
    final trustScore =
        listing['employer_trust'] ?? listing['trust_score'] ?? 50;
    final isVerified = trustScore >= 80;

    final payType = listing['pay_type'] ?? 'cash';
    final payRange = listing['pay_range'] ?? {};
    final payStr = payType == 'cash'
        ? '\$${payRange['min'] ?? 0} - \$${payRange['max'] ?? 0}'
        : payType == 'hourly'
            ? '\$${payRange['min']}/hr'
            : 'Volunteer';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: SentinelJobsTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showListingDetail(listing),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Category (Title) + Verified Badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title.toString().toUpperCase(),
                        style: SentinelJobsTheme.titleStyle,
                      ),
                    ),
                    if (isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              SentinelJobsTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: SentinelJobsTheme.primary),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified,
                                size: 12, color: SentinelJobsTheme.primary),
                            SizedBox(width: 4),
                            Text('VERIFIED',
                                style: TextStyle(
                                    color: SentinelJobsTheme.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // Employer Name & Rating
                Row(
                  children: [
                    Text(employerName, style: SentinelJobsTheme.mutedStyle),
                    const SizedBox(width: 8),
                    const Icon(Icons.star,
                        size: 12, color: SentinelJobsTheme.warning),
                    const SizedBox(width: 4),
                    Text('${listing['employer_rating'] ?? 0.0}',
                        style: SentinelJobsTheme.mutedStyle),
                  ],
                ),

                const SizedBox(height: 12),

                // Description Snippet
                Text(
                  listing['description'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SentinelJobsTheme.bodyStyle,
                ),

                const SizedBox(height: 16),

                // Footer: Pay & Action
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: SentinelJobsTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        payStr,
                        style: const TextStyle(
                          color: SentinelJobsTheme.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (widget.role == 'worker')
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () =>
                              _applyToJob(listing['_id'] ?? listing['job_id']),
                          style: SentinelJobsTheme.primaryButton,
                          child: const Text('APPLY'),
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

  void _showListingDetail(dynamic listing) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SentinelJobsTheme.surface,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: SentinelJobsTheme.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(listing['category']?.toString().toUpperCase() ?? 'JOB',
                  style: SentinelJobsTheme.titleStyle),
              const SizedBox(height: 8),
              Text(listing['employer_name'] ?? 'Unknown',
                  style: SentinelJobsTheme.mutedStyle),
              const SizedBox(height: 24),
              const Text('MISSION BRIEF:',
                  style: SentinelJobsTheme.headerStyle),
              const SizedBox(height: 8),
              Text(listing['description'] ?? '',
                  style: SentinelJobsTheme.bodyStyle),
              const SizedBox(height: 24),
              const Text('COMPENSATION:', style: SentinelJobsTheme.headerStyle),
              const SizedBox(height: 8),
              Text('Pay Type: ${listing['pay_type'] ?? 'Unknown'}',
                  style: SentinelJobsTheme.bodyStyle),
              const SizedBox(height: 32),
              // Footer Actions
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showReportDialog(listing),
                      icon: const Icon(Icons.flag_outlined, size: 18),
                      label: const Text('REPORT'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SentinelJobsTheme.error,
                        side: const BorderSide(color: SentinelJobsTheme.error),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (widget.role == 'worker')
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _applyToJob(listing['_id'] ?? listing['job_id']);
                        },
                        style: SentinelJobsTheme.primaryButton,
                        child: const Text('APPLY FOR MISSION'),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDialog(dynamic listing) {
    String? selectedReason;
    final reasons = ['fraud', 'spam', 'fake_listing', 'safety', 'other'];
    final reasonLabels = {
      'fraud': 'Fraud / Scam',
      'spam': 'Spam',
      'fake_listing': 'Fake Listing',
      'safety': 'Safety Concern',
      'other': 'Other',
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: SentinelJobsTheme.surface,
          title:
              const Text('Report Listing', style: SentinelJobsTheme.titleStyle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select a reason:',
                  style: SentinelJobsTheme.bodyStyle),
              const SizedBox(height: 16),
              RadioGroup<String>(
                groupValue: selectedReason,
                onChanged: (v) => setDialogState(() => selectedReason = v),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: reasons
                      .map((r) => RadioListTile<String>(
                            title: Text(reasonLabels[r] ?? r,
                                style: SentinelJobsTheme.bodyStyle),
                            value: r,
                            activeColor: SentinelJobsTheme.primary,
                            contentPadding: EdgeInsets.zero,
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () async {
                      Navigator.pop(ctx); // Close dialog
                      // Navigator.pop(context); // Don't close bottom sheet, generic context issue?
                      // Just allow report to fly
                      final result = await widget.api.submitReport(
                        targetId: listing['job_id'] ?? '',
                        targetType: 'job',
                        reason: selectedReason!,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result.success
                                ? 'Report submitted. Thank you.'
                                : 'Failed: ${result.error ?? "Unknown error"}'),
                            backgroundColor:
                                result.success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? SentinelJobsTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? SentinelJobsTheme.primary
                  : SentinelJobsTheme.textMuted,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? SentinelJobsTheme.background
                  : SentinelJobsTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
