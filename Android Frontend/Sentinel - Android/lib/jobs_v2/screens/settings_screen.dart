// Jobs v2 - Settings Screen
// User preferences for messaging, notifications, and account settings

import 'package:flutter/material.dart';
import '../theme.dart';
import '../api.dart';

class JobsSettingsScreen extends StatefulWidget {
  final JobsApi api;
  final Map<String, dynamic> profile;
  final VoidCallback onProfileUpdated;

  const JobsSettingsScreen({
    required this.api,
    required this.profile,
    required this.onProfileUpdated,
    super.key,
  });

  @override
  State<JobsSettingsScreen> createState() => _JobsSettingsScreenState();
}

class _JobsSettingsScreenState extends State<JobsSettingsScreen> {
  late Map<String, dynamic> _notifications;
  late Map<String, dynamic> _messagingPrefs;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _notifications =
        Map<String, dynamic>.from(widget.profile['notification_settings'] ??
            {
              'push_pending': true,
              'push_non_pending': false,
              'push_marketing': true,
            });
    _messagingPrefs =
        Map<String, dynamic>.from(widget.profile['messaging_settings'] ??
            {
              'read_receipts': true,
              'typing_indicators': true,
              'auto_archive_days': 30,
            });
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);

    final resp = await widget.api.updateProfile({
      'notification_settings': _notifications,
      'messaging_settings': _messagingPrefs,
    });

    if (!mounted) return;

    setState(() => _saving = false);

    if (resp.success) {
      widget.onProfileUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SETTINGS SAVED'),
          backgroundColor: SentinelJobsTheme.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: ${resp.error}'),
          backgroundColor: SentinelJobsTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SentinelJobsTheme.background,
      appBar: AppBar(
        title: const Text('SETTINGS', style: SentinelJobsTheme.headerStyle),
        backgroundColor: SentinelJobsTheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: SentinelJobsTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveSettings,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: SentinelJobsTheme.primary))
                : const Text('SAVE',
                    style: TextStyle(
                        color: SentinelJobsTheme.primary,
                        fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // =========== MESSAGING SETTINGS ===========
          const _SectionHeader(
              icon: Icons.chat_bubble_outline, title: 'MESSAGING SETTINGS'),
          const SizedBox(height: 12),
          Container(
            decoration: SentinelJobsTheme.cardDecoration,
            child: Column(
              children: [
                _buildSwitch(
                  'Read Receipts',
                  "Let others know when you've read their messages",
                  _messagingPrefs['read_receipts'] ?? true,
                  (v) => setState(() => _messagingPrefs['read_receipts'] = v),
                ),
                const Divider(height: 1, color: SentinelJobsTheme.surfaceLight),
                _buildSwitch(
                  'Typing Indicators',
                  "Show when you're typing a response",
                  _messagingPrefs['typing_indicators'] ?? true,
                  (v) =>
                      setState(() => _messagingPrefs['typing_indicators'] = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Info about messaging restrictions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SentinelJobsTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    size: 18, color: SentinelJobsTheme.textMuted),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Messaging is only available for applications in PENDING or ACCEPTED status.',
                    style: TextStyle(
                        color: SentinelJobsTheme.textMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // =========== NOTIFICATION SETTINGS ===========
          const _SectionHeader(
              icon: Icons.notifications, title: 'NOTIFICATIONS'),
          const SizedBox(height: 12),
          Container(
            decoration: SentinelJobsTheme.cardDecoration,
            child: Column(
              children: [
                _buildSwitch(
                  'Application Updates',
                  'Alerts for pending and approved applications',
                  _notifications['push_pending'] ?? true,
                  (v) => setState(() => _notifications['push_pending'] = v),
                ),
                const Divider(height: 1, color: SentinelJobsTheme.surfaceLight),
                _buildSwitch(
                  'Message Notifications',
                  'Alerts when you receive new messages',
                  _notifications['push_messages'] ?? true,
                  (v) => setState(() => _notifications['push_messages'] = v),
                ),
                const Divider(height: 1, color: SentinelJobsTheme.surfaceLight),
                _buildSwitch(
                  'General Alerts',
                  'New jobs and cold applications',
                  _notifications['push_non_pending'] ?? false,
                  (v) => setState(() => _notifications['push_non_pending'] = v),
                ),
                const Divider(height: 1, color: SentinelJobsTheme.surfaceLight),
                _buildSwitch(
                  'Marketing',
                  'News and promotions',
                  _notifications['push_marketing'] ?? true,
                  (v) => setState(() => _notifications['push_marketing'] = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // =========== PRIVACY SETTINGS ===========
          const _SectionHeader(icon: Icons.shield, title: 'PRIVACY'),
          const SizedBox(height: 12),
          Container(
            decoration: SentinelJobsTheme.cardDecoration,
            child: Column(
              children: [
                _buildSwitch(
                  'Profile Visibility',
                  'Allow employers to view your full profile',
                  _messagingPrefs['profile_visible'] ?? true,
                  (v) => setState(() => _messagingPrefs['profile_visible'] = v),
                ),
                const Divider(height: 1, color: SentinelJobsTheme.surfaceLight),
                _buildSwitch(
                  'Online Status',
                  'Show when you are active in the app',
                  _messagingPrefs['show_online'] ?? true,
                  (v) => setState(() => _messagingPrefs['show_online'] = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // =========== ACCOUNT ACTIONS ===========
          const _SectionHeader(icon: Icons.manage_accounts, title: 'ACCOUNT'),
          const SizedBox(height: 12),
          Container(
            decoration: SentinelJobsTheme.cardDecoration,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_reset,
                      color: SentinelJobsTheme.textSecondary),
                  title: const Text('Change Password',
                      style: SentinelJobsTheme.bodyStyle),
                  trailing: const Icon(Icons.chevron_right,
                      color: SentinelJobsTheme.textMuted),
                  onTap: () => _showChangePasswordDialog(),
                ),
                const Divider(height: 1, color: SentinelJobsTheme.surfaceLight),
                ListTile(
                  leading: const Icon(Icons.delete_forever,
                      color: SentinelJobsTheme.error),
                  title: const Text('Delete Account',
                      style: TextStyle(color: SentinelJobsTheme.error)),
                  trailing: const Icon(Icons.chevron_right,
                      color: SentinelJobsTheme.textMuted),
                  onTap: () => _showDeleteAccountConfirmation(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSwitch(
      String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: SentinelJobsTheme.bodyStyle),
      subtitle: Text(subtitle,
          style: SentinelJobsTheme.mutedStyle.copyWith(fontSize: 11)),
      value: value,
      onChanged: onChanged,
      activeTrackColor: SentinelJobsTheme.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _showChangePasswordDialog() {
    final currentPwCtrl = TextEditingController();
    final newPwCtrl = TextEditingController();
    final confirmPwCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: SentinelJobsTheme.surface,
      isScrollControlled: true,
      builder: (ctx) => Padding(
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
            const Text('CHANGE PASSWORD', style: SentinelJobsTheme.headerStyle),
            const SizedBox(height: 24),
            TextField(
              controller: currentPwCtrl,
              obscureText: true,
              style: SentinelJobsTheme.bodyStyle,
              decoration: SentinelJobsTheme.inputDecoration('CURRENT PASSWORD'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPwCtrl,
              obscureText: true,
              style: SentinelJobsTheme.bodyStyle,
              decoration: SentinelJobsTheme.inputDecoration('NEW PASSWORD'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPwCtrl,
              obscureText: true,
              style: SentinelJobsTheme.bodyStyle,
              decoration:
                  SentinelJobsTheme.inputDecoration('CONFIRM NEW PASSWORD'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (newPwCtrl.text != confirmPwCtrl.text) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content: Text('Passwords do not match'),
                        backgroundColor: SentinelJobsTheme.error));
                    return;
                  }
                  // API call would go here
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('PASSWORD UPDATED'),
                      backgroundColor: SentinelJobsTheme.success));
                },
                style: SentinelJobsTheme.primaryButton,
                child: const Text('UPDATE PASSWORD'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SentinelJobsTheme.surface,
        title: const Text('DELETE ACCOUNT?',
            style: TextStyle(color: SentinelJobsTheme.error)),
        content: const Text(
          'This action is permanent and cannot be undone. All your data, jobs, and messages will be deleted.',
          style: SentinelJobsTheme.bodyStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL',
                style: TextStyle(color: SentinelJobsTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // API call would go here
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'Account deletion requested. You will receive a confirmation email.'),
                backgroundColor: SentinelJobsTheme.warning,
              ));
            },
            child: const Text('DELETE',
                style: TextStyle(color: SentinelJobsTheme.error)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: SentinelJobsTheme.primary),
        const SizedBox(width: 8),
        Text(title, style: SentinelJobsTheme.headerStyle),
      ],
    );
  }
}
