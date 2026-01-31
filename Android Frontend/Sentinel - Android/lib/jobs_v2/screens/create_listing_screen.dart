// Jobs v2 - Create Listing Screen
// Strict Input Schema: Category, Pay, Location, Duration

import 'package:flutter/material.dart';
import '../theme.dart';
import '../api.dart';

class CreateListingScreen extends StatefulWidget {
  final JobsApi api;

  const CreateListingScreen({required this.api, super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  bool _isLoading = false;
  String? _error;

  final _descCtrl = TextEditingController();

  // Strict Categories
  final _categories = ['Security', 'Logistics', 'Medical', 'Cleanup', 'Admin'];
  String _selectedCategory = 'Security';

  // Pay Logic
  String _payType = 'hourly'; // hourly, cash, volunteer
  final _payMinCtrl = TextEditingController(text: '20');
  final _payMaxCtrl = TextEditingController(text: '30');

  // Duration
  String _duration = '8h';
  final _durations = ['4h', '8h', '12h', '24h', '3d', '7d', '30d'];

  // Location (Mocked for MVP if no plugin, or manual entry)
  // Ideally use Geolocator. For now, strict spec requires precise, we'll send a default or user entered zip/coords if UI allows.
  // Let's simplified: "Current Location" (mock button for web/sim)
  bool _locationSet = false;
  final double _lat = 40.7128;
  final double _lon = -74.0060;

  final DateTime _startTime = DateTime.now().add(const Duration(hours: 1));

  Future<void> _submit() async {
    if (_descCtrl.text.isEmpty) {
      setState(() => _error = 'Description required');
      return;
    }
    if (!_locationSet) {
      // confirm default?
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

      final location = {'lat': _lat, 'lon': _lon, 'accuracy': 10};

      final resp = await widget.api.createListing(
        category: _selectedCategory,
        payType: _payType,
        payRange: payRange,
        startTime: _startTime.toIso8601String(),
        duration: _duration,
        location: location,
        description: _descCtrl.text.trim(),
      );

      if (resp.success) {
        if (!mounted) return;
        Navigator.pop(context, true); // Return success
      } else {
        setState(() => _error = resp.error ?? 'Failed to post job');
      }
    } catch (e) {
      setState(() => _error = 'Connection error');
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
            const Text('POST ASSIGNMENT', style: SentinelJobsTheme.headerStyle),
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
            // Category
            const _SectionHeader('CATEGORY'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: SentinelJobsTheme.cardDecoration,
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                dropdownColor: SentinelJobsTheme.surface,
                underline: const SizedBox(),
                style: SentinelJobsTheme.bodyStyle,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
            ),
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
              children: [
                _PayTypeButton('HOURLY', 'hourly', _payType,
                    () => setState(() => _payType = 'hourly')),
                const SizedBox(width: 8),
                _PayTypeButton('CASH', 'cash', _payType,
                    () => setState(() => _payType = 'cash')),
                const SizedBox(width: 8),
                _PayTypeButton('VOLUNTEER', 'volunteer', _payType,
                    () => setState(() => _payType = 'volunteer')),
              ],
            ),
            if (_payType != 'volunteer') ...[
              const SizedBox(height: 16),
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

            // Duration & Start
            const _SectionHeader('TIMELINE'),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: SentinelJobsTheme.cardDecoration,
                    child: DropdownButton<String>(
                      value: _duration,
                      isExpanded: true,
                      dropdownColor: SentinelJobsTheme.surface,
                      underline: const SizedBox(),
                      style: SentinelJobsTheme.bodyStyle,
                      items: _durations
                          .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (v) => setState(() => _duration = v!),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final time = await showTimePicker(
                          context: context, initialTime: TimeOfDay.now());
                      if (time != null) {
                        // Simplify for MVP
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: SentinelJobsTheme.cardDecoration,
                      child: const Text(
                        'START ASAP', // Placeholder
                        style: SentinelJobsTheme.bodyStyle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Location
            const _SectionHeader('LOCATION'),
            GestureDetector(
              onTap: () {
                setState(() => _locationSet = true);
                // In real app, trigger permission and get coords
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _locationSet
                      ? SentinelJobsTheme.success.withValues(alpha: 0.1)
                      : SentinelJobsTheme.surface,
                  border: Border.all(
                      color: _locationSet
                          ? SentinelJobsTheme.success
                          : SentinelJobsTheme.primary),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _locationSet ? Icons.check_circle : Icons.my_location,
                      color: _locationSet
                          ? SentinelJobsTheme.success
                          : SentinelJobsTheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _locationSet
                          ? 'LOCATION SECURED'
                          : 'USE CURRENT LOCATION',
                      style: TextStyle(
                        color: _locationSet
                            ? SentinelJobsTheme.success
                            : SentinelJobsTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
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
                    : const Text('BROADCAST ASSIGNMENT'),
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

class _PayTypeButton extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final VoidCallback onTap;

  const _PayTypeButton(this.label, this.value, this.groupValue, this.onTap);

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? SentinelJobsTheme.primary
                : SentinelJobsTheme.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
                color: selected
                    ? SentinelJobsTheme.primary
                    : SentinelJobsTheme.textMuted),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected
                  ? SentinelJobsTheme.background
                  : SentinelJobsTheme.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
