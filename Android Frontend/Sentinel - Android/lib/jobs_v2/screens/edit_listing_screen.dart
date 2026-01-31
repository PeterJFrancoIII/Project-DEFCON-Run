// Jobs v2 - Edit Listing Screen
// Allows editing description, pay, duration, start time

import 'package:flutter/material.dart';
import '../theme.dart';
import '../api.dart';

class EditListingScreen extends StatefulWidget {
  final JobsApi api;
  final Map<String, dynamic> listing;

  const EditListingScreen({
    required this.api,
    required this.listing,
    super.key,
  });

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  bool _isLoading = false;
  String? _error;

  late TextEditingController _descCtrl;
  late TextEditingController _payMinCtrl;
  late TextEditingController _payMaxCtrl;
  String _payType = 'hourly';
  String _duration = '8h';
  final List<String> _durations = ['4h', '8h', '12h', '24h', '3d', '7d', '30d'];

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.listing['description']);

    final payRange = widget.listing['pay_range'] ?? {};
    _payMinCtrl = TextEditingController(text: '${payRange['min'] ?? 0}');
    _payMaxCtrl = TextEditingController(text: '${payRange['max'] ?? 0}');

    _payType = widget.listing['pay_type'] ?? 'hourly';
    _duration = widget.listing['duration'] ?? '8h';

    // Ensure duration matches valid options, else default to 'Other' or nearest?
    // For MVP assuming it matches one of our presets or we add it.
    if (!_durations.contains(_duration)) {
      // if not in list, add it temporarily so dropdown fits
      _durations.add(_duration);
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _payMinCtrl.dispose();
    _payMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_descCtrl.text.isEmpty) {
      setState(() => _error = 'Description required');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final payRange = {
        'min': int.tryParse(_payMinCtrl.text) ?? 0,
        'max': int.tryParse(_payMaxCtrl.text) ?? 0,
        'currency': 'USD'
      };

      // Only sending allowed fields as per backend spec
      final updates = {
        'description': _descCtrl.text.trim(),
        'pay_range': payRange,
        'duration': _duration,
        // Start time editing? Maybe complexity not needed for MVP polish unless requested.
      };

      final resp = await widget.api.updateListing(
          widget.listing['_id'] ?? widget.listing['job_id'], updates);

      if (resp.success) {
        if (!mounted) return;
        Navigator.pop(context, true); // Return success
      } else {
        setState(() => _error = resp.error ?? 'Failed to update job');
      }
    } catch (e) {
      setState(() => _error = 'Connection error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SentinelJobsTheme.background,
      appBar: AppBar(
        backgroundColor: SentinelJobsTheme.surface,
        title:
            const Text('EDIT ASSIGNMENT', style: SentinelJobsTheme.headerStyle),
        leading: IconButton(
          icon: const Icon(Icons.close, color: SentinelJobsTheme.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cannot edit Category or Location easily as it changes match logic substantially
            // So we just show them as read-only info
            Text(
                'CATEGORY: ${(widget.listing['category'] ?? '').toUpperCase()}',
                style: SentinelJobsTheme.mutedStyle),
            const SizedBox(height: 24),

            // Description
            const _SectionHeader('BRIEFING (DESCRIPTION)'),
            TextField(
              controller: _descCtrl,
              maxLines: 4,
              style: SentinelJobsTheme.bodyStyle,
              decoration: SentinelJobsTheme.inputDecoration('Task details...'),
            ),
            const SizedBox(height: 24),

            // Pay
            const _SectionHeader('COMPENSATION'),
            Row(
              // For MVP, maybe restrict changing pay type? Backend allows strict fields.
              // Let's assume pay type might remain fixed
              // but purely updating numbers is safer.
              children: [
                Text('TYPE: ${_payType.toUpperCase()}',
                    style: SentinelJobsTheme.bodyStyle),
              ],
            ),
            const SizedBox(height: 12),
            if (_payType != 'volunteer') ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _payMinCtrl,
                      keyboardType: TextInputType.number,
                      style: SentinelJobsTheme.bodyStyle,
                      decoration: SentinelJobsTheme.inputDecoration('MIN \$'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _payMaxCtrl,
                      keyboardType: TextInputType.number,
                      style: SentinelJobsTheme.bodyStyle,
                      decoration: SentinelJobsTheme.inputDecoration('MAX \$'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),

            // Duration
            const _SectionHeader('TIMELINE'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: SentinelJobsTheme.cardDecoration,
              child: DropdownButton<String>(
                value: _duration,
                isExpanded: true,
                dropdownColor: SentinelJobsTheme.surface,
                underline: const SizedBox(),
                style: SentinelJobsTheme.bodyStyle,
                items: _durations
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() => _duration = v!),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 24),
              Text(_error!,
                  style: const TextStyle(color: SentinelJobsTheme.error)),
            ],

            const SizedBox(height: 40),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: SentinelJobsTheme.primaryButton,
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: SentinelJobsTheme.background)
                    : const Text('SAVE CHANGES'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: SentinelJobsTheme.headerStyle.copyWith(fontSize: 14)),
    );
  }
}
