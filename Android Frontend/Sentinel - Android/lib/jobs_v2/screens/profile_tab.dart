// Jobs v2 - Profile Tab
// User profile management

import 'package:flutter/material.dart';
import '../theme.dart';
import '../api.dart';
import 'settings_screen.dart';

class ProfileTab extends StatefulWidget {
  final JobsApi api;

  const ProfileTab({required this.api, super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);

    final resp = await widget.api.getProfile();

    if (resp.success && resp.data != null) {
      if (mounted) {
        setState(() {
          _profile = resp.data;
          _loading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showEmployerUpgradeDialog() {
    final orgNameCtrl = TextEditingController();
    String selectedOrgType = 'NGO';
    final orgTypes = ['NGO', 'Government', 'Contractor', 'Local Authority'];
    bool isLoading = false;
    String? error;

    showModalBottomSheet(
      context: context,
      backgroundColor: SentinelJobsTheme.surface,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('BECOME AN EMPLOYER',
                  style: SentinelJobsTheme.headerStyle),
              const SizedBox(height: 8),
              const Text(
                'Provide your organization details to start posting jobs.',
                style: SentinelJobsTheme.mutedStyle,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: orgNameCtrl,
                style: SentinelJobsTheme.bodyStyle,
                decoration:
                    SentinelJobsTheme.inputDecoration('ORGANIZATION NAME'),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: SentinelJobsTheme.cardDecoration,
                child: DropdownButton<String>(
                  value: selectedOrgType,
                  isExpanded: true,
                  dropdownColor: SentinelJobsTheme.surface,
                  underline: const SizedBox(),
                  style: SentinelJobsTheme.bodyStyle,
                  items: orgTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setModalState(() => selectedOrgType = v!),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 16),
                Text(error!,
                    style: const TextStyle(color: SentinelJobsTheme.error)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (orgNameCtrl.text.trim().isEmpty) {
                            setModalState(
                                () => error = 'Organization name required');
                            return;
                          }

                          setModalState(() {
                            isLoading = true;
                            error = null;
                          });

                          final resp = await widget.api.upgradeToEmployer(
                            organizationName: orgNameCtrl.text.trim(),
                            organizationType: selectedOrgType,
                          );

                          if (!ctx.mounted) return;

                          if (resp.success) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'UPGRADED TO EMPLOYER - PENDING VERIFICATION'),
                                backgroundColor: SentinelJobsTheme.success,
                              ),
                            );
                            _loadProfile(); // Refresh
                          } else {
                            setModalState(() {
                              isLoading = false;
                              error = resp.error ?? 'Upgrade failed';
                            });
                          }
                        },
                  style: SentinelJobsTheme.primaryButton,
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: SentinelJobsTheme.background)
                      : const Text('UPGRADE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSkillsDialog() {
    // Available skills list
    final allSkills = [
      'First Aid',
      'CPR',
      'Security',
      'Driving',
      'Logistics',
      'Construction',
      'Cooking',
      'Translation',
      'IT Support',
      'Administration',
      'Search & Rescue',
      'Nursing',
      'Childcare'
    ];

    // Current skills
    final currentSkills = List<String>.from(_profile!['skills'] ?? []);
    bool isLoading = false;
    String? error;

    showModalBottomSheet(
      context: context,
      backgroundColor: SentinelJobsTheme.surface,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('EDIT SKILLS', style: SentinelJobsTheme.headerStyle),
              const SizedBox(height: 8),
              const Text(
                'Select skills that match your qualifications.',
                style: SentinelJobsTheme.mutedStyle,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allSkills.map((skill) {
                      final isSelected = currentSkills.contains(skill);
                      return FilterChip(
                        label: Text(skill),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          setModalState(() {
                            if (selected) {
                              currentSkills.add(skill);
                            } else {
                              currentSkills.remove(skill);
                            }
                          });
                        },
                        backgroundColor: SentinelJobsTheme.surfaceLight,
                        selectedColor:
                            SentinelJobsTheme.primary.withValues(alpha: 0.2),
                        checkmarkColor: SentinelJobsTheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? SentinelJobsTheme.primary
                              : SentinelJobsTheme.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide(
                            color: isSelected
                                ? SentinelJobsTheme.primary
                                : SentinelJobsTheme.textMuted
                                    .withValues(alpha: 0.3)),
                      );
                    }).toList(),
                  ),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 16),
                Text(error!,
                    style: const TextStyle(color: SentinelJobsTheme.error)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setModalState(() => isLoading = true);

                          // Call API
                          final resp = await widget.api
                              .updateProfile({'skills': currentSkills});

                          if (!ctx.mounted) return;

                          if (resp.success) {
                            Navigator.pop(ctx);
                            _loadProfile(); // Refresh
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('SKILLS UPDATED'),
                                  backgroundColor: SentinelJobsTheme.success,
                                ),
                              );
                            }
                          } else {
                            setModalState(() {
                              isLoading = false;
                              error = resp.error ?? 'Failed to update skills';
                            });
                          }
                        },
                  style: SentinelJobsTheme.primaryButton,
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: SentinelJobsTheme.background)
                      : const Text('SAVE SKILLS'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: SentinelJobsTheme.primary),
      );
    }

    if (_profile == null) {
      return const Center(
        child:
            Text('Failed to load profile', style: SentinelJobsTheme.mutedStyle),
      );
    }

    final role = _profile!['role'] ?? 'worker';
    final isWorker = role == 'worker';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Avatar (simple initials)
          CircleAvatar(
            radius: 40,
            backgroundColor: SentinelJobsTheme.surface,
            child: Text(
              (_profile!['display_name'] ?? 'U')[0].toUpperCase(),
              style: const TextStyle(
                color: SentinelJobsTheme.primary,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _profile!['display_name'] ?? 'Unknown',
            style: SentinelJobsTheme.titleStyle,
          ),
          const SizedBox(height: 4),
          Text(
            _profile!['email'] ?? '',
            style: SentinelJobsTheme.mutedStyle,
          ),

          const SizedBox(height: 8),

          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: SentinelJobsTheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              role.toUpperCase(),
              style: const TextStyle(
                color: SentinelJobsTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Stats
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.star,
                  label: 'RATING',
                  value: '${_profile!['rating_avg'] ?? 0.0}',
                  color: SentinelJobsTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.reviews,
                  label: 'REVIEWS',
                  value: '${_profile!['rating_count'] ?? 0}',
                  color: SentinelJobsTheme.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Worker: Trust Score
          if (isWorker) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: SentinelJobsTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TRUST SCORE:',
                      style: SentinelJobsTheme.headerStyle),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.shield,
                          color: SentinelJobsTheme.primary, size: 40),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_profile!['trust_score'] ?? 50} / 100',
                            style: const TextStyle(
                              color: SentinelJobsTheme.primary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'VERIFIED IDENTITY',
                            style: SentinelJobsTheme.mutedStyle,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Become an Employer CTA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SentinelJobsTheme.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: SentinelJobsTheme.primary.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.business, color: SentinelJobsTheme.primary),
                      SizedBox(width: 12),
                      Text('WANT TO POST JOBS?',
                          style: SentinelJobsTheme.headerStyle),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Upgrade to Employer to post job listings and hire workers.',
                    style: SentinelJobsTheme.mutedStyle,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showEmployerUpgradeDialog(),
                      style: SentinelJobsTheme.primaryButton,
                      child: const Text('BECOME AN EMPLOYER'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Worker: Skills
          if (isWorker) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: SentinelJobsTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('MY SKILLS:',
                          style: SentinelJobsTheme.headerStyle),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _showEditSkillsDialog(),
                        child: const Text(
                          'EDIT',
                          style: TextStyle(color: SentinelJobsTheme.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if ((_profile!['skills'] as List?)?.isEmpty ?? true)
                    const Text(
                      'No skills added yet',
                      style: SentinelJobsTheme.mutedStyle,
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (_profile!['skills'] as List)
                          .map((s) => Chip(
                                label: Text(s),
                                backgroundColor: SentinelJobsTheme.surfaceLight,
                                labelStyle: SentinelJobsTheme.bodyStyle,
                              ))
                          .toList(),
                    ),
                ],
              ),
            ),
          ],

          // Employer: Organization info
          if (!isWorker) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: SentinelJobsTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ORGANIZATION:',
                      style: SentinelJobsTheme.headerStyle),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.business,
                    label: 'Name',
                    value: _profile!['organization']?['name'] ?? 'Unknown',
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.category,
                    label: 'Type',
                    value: _profile!['organization']?['type'] ?? 'Unknown',
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.verified,
                    label: 'Status',
                    value:
                        _profile!['verified'] == true ? 'VERIFIED' : 'PENDING',
                    valueColor: _profile!['verified'] == true
                        ? SentinelJobsTheme.success
                        : SentinelJobsTheme.warning,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Account info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: SentinelJobsTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ACCOUNT:', style: SentinelJobsTheme.headerStyle),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.calendar_today,
                  label: 'Joined',
                  value: _profile!['created_at']?.substring(0, 10) ?? 'Unknown',
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.shield,
                  label: 'Status',
                  value: (_profile!['status'] ?? 'active').toUpperCase(),
                  valueColor: SentinelJobsTheme.success,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Settings Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => JobsSettingsScreen(
                      api: widget.api,
                      profile: _profile!,
                      onProfileUpdated: _loadProfile,
                    ),
                  ),
                );
                _loadProfile(); // Refresh after settings change
              },
              icon:
                  const Icon(Icons.settings, color: SentinelJobsTheme.primary),
              label: const Text('SETTINGS',
                  style: TextStyle(
                      color: SentinelJobsTheme.primary,
                      fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: SentinelJobsTheme.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SentinelJobsTheme.cardDecoration,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: SentinelJobsTheme.mutedStyle),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: SentinelJobsTheme.textMuted),
        const SizedBox(width: 8),
        Text('$label: ', style: SentinelJobsTheme.mutedStyle),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? SentinelJobsTheme.textPrimary,
              fontWeight:
                  valueColor != null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
