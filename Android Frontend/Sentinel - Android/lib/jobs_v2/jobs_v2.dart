// Jobs v2 - Main Entry Point
// Auth gate, mode selection, and navigation

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';
import 'api.dart';
import 'screens/login_screen.dart';
import 'screens/mode_selection_screen.dart';
import 'screens/dashboard_screen.dart';

/// Jobs v2 Entry Point - Handles auth state and mode selection
class JobsV2Gate extends StatefulWidget {
  final String serverUrl;

  const JobsV2Gate({required this.serverUrl, super.key});

  @override
  State<JobsV2Gate> createState() => _JobsV2GateState();
}

class _JobsV2GateState extends State<JobsV2Gate> {
  late final JobsApi _api;
  String? _token;
  String? _accountId;
  String? _role;
  bool _verified = true;
  bool _loading = true;

  // Session mode: null = show selection, 'worker' = job search, 'employer' = list jobs
  String? _sessionMode;

  @override
  void initState() {
    super.initState();
    _api = JobsApi(baseUrl: widget.serverUrl);
    _loadSession();
  }

  /// Load saved session from SharedPreferences
  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jobs_v2_token');
    final accountId = prefs.getString('jobs_v2_account_id');
    final role = prefs.getString('jobs_v2_role');
    final verified = prefs.getBool('jobs_v2_verified') ?? true;

    if (token != null && accountId != null) {
      _api.setToken(token);

      // Refresh profile to get latest role/verification status
      final profileResp = await _api.getProfile();
      if (profileResp.success && profileResp.data != null) {
        final profile = profileResp.data!;
        setState(() {
          _token = token;
          _accountId = accountId;
          _role = profile['role'] ?? role ?? 'worker';
          _verified = (profile['trust_score'] ?? 0) >= 80;
          _loading = false;
          _sessionMode = null; // Show mode selection
        });

        // Update saved role/verified if changed
        await prefs.setString('jobs_v2_role', _role!);
        await prefs.setBool('jobs_v2_verified', _verified);
      } else {
        setState(() {
          _token = token;
          _accountId = accountId;
          _role = role;
          _verified = verified;
          _loading = false;
          _sessionMode = null;
        });
      }
    } else {
      setState(() => _loading = false);
    }
  }

  /// Save session to SharedPreferences
  Future<void> _saveSession(
      String token, String accountId, String role, bool verified) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jobs_v2_token', token);
    await prefs.setString('jobs_v2_account_id', accountId);
    await prefs.setString('jobs_v2_role', role);
    await prefs.setBool('jobs_v2_verified', verified);

    _api.setToken(token);
    setState(() {
      _token = token;
      _accountId = accountId;
      _role = role;
      _verified = verified;
      _sessionMode = null; // Show mode selection after login
    });
  }

  /// Clear session
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jobs_v2_token');
    await prefs.remove('jobs_v2_account_id');
    await prefs.remove('jobs_v2_role');
    await prefs.remove('jobs_v2_verified');

    _api.clearToken();
    setState(() {
      _token = null;
      _accountId = null;
      _role = null;
      _verified = true;
      _sessionMode = null;
    });
  }

  /// Handle mode selection
  void _onModeSelected(String mode) {
    setState(() {
      _sessionMode = mode;
    });
  }

  /// Go back to mode selection
  void _goBackToModeSelection() {
    setState(() {
      _sessionMode = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: SentinelJobsTheme.background,
        body: Center(
          child: CircularProgressIndicator(
            color: SentinelJobsTheme.primary,
          ),
        ),
      );
    }

    // Not logged in -> Login Screen
    if (_token == null) {
      return JobsLoginScreen(
        api: _api,
        onLogin: _saveSession,
      );
    }

    // Logged in but no mode selected -> Mode Selection Screen
    if (_sessionMode == null) {
      return ModeSelectionScreen(
        api: _api,
        accountId: _accountId!,
        role: _role ?? 'worker',
        verified: _verified,
        onLogout: _logout,
        onModeSelected: _onModeSelected,
      );
    }

    // Mode selected -> Dashboard with role context
    return JobsDashboardScreen(
      api: _api,
      accountId: _accountId!,
      role: _sessionMode!, // Use selected mode as role context
      verified: _verified,
      onLogout: _logout,
      onBackToModeSelection: _goBackToModeSelection,
    );
  }
}
