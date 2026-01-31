// Jobs v2 - Login Screen
// Unified Registration: Everyone starts as Worker

import 'package:flutter/material.dart';
import '../theme.dart';
import '../api.dart';

class JobsLoginScreen extends StatefulWidget {
  final JobsApi api;
  final Function(String token, String accountId, String role, bool verified)
      onLogin;

  const JobsLoginScreen({
    required this.api,
    required this.onLogin,
    super.key,
  });

  @override
  State<JobsLoginScreen> createState() => _JobsLoginScreenState();
}

class _JobsLoginScreenState extends State<JobsLoginScreen> {
  bool _isRegister = false;
  bool _isLoading = false;
  String? _error;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // Strict Identity
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Email and password required');
      return;
    }

    if (_isRegister) {
      if (_firstNameCtrl.text.isEmpty ||
          _lastNameCtrl.text.isEmpty ||
          _phoneCtrl.text.isEmpty) {
        setState(() => _error = 'Name and phone required for registration');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_isRegister) {
        // Everyone registers as 'worker' by default
        final resp = await widget.api.register(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          phone: _phoneCtrl.text.trim(),
          realNameFirst: _firstNameCtrl.text.trim(),
          realNameLast: _lastNameCtrl.text.trim(),
          role: 'worker', // Always worker on registration
        );

        if (resp.success && resp.data != null) {
          widget.onLogin(
            resp.data!['token'],
            resp.data!['account_id'],
            'worker', // Role is always worker on registration
            true, // Workers are verified by default
          );
        } else {
          setState(() => _error = resp.error ?? 'Registration failed');
        }
      } else {
        final resp = await widget.api.login(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );

        if (resp.success && resp.data != null) {
          widget.onLogin(
            resp.data!['token'],
            resp.data!['account_id'],
            resp.data!['role'] ?? 'worker',
            resp.data!['verified'] ?? true,
          );
        } else {
          setState(() => _error = resp.error ?? 'Login failed');
        }
      }
    } catch (e) {
      setState(() => _error = 'Connection error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SentinelJobsTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Header
              const Icon(Icons.work_outline,
                  size: 60, color: SentinelJobsTheme.primary),
              const SizedBox(height: 16),
              Text(
                _isRegister ? 'JOIN SENTINEL WORKFORCE' : 'WORKFORCE ACCESS',
                style: SentinelJobsTheme.headerStyle,
              ),
              const SizedBox(height: 8),
              Text(
                _isRegister
                    ? 'Create your account to find work'
                    : 'Login to access the Jobs module',
                style: SentinelJobsTheme.mutedStyle,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Email
              TextField(
                controller: _emailCtrl,
                style: SentinelJobsTheme.bodyStyle,
                keyboardType: TextInputType.emailAddress,
                decoration: SentinelJobsTheme.inputDecoration('EMAIL'),
              ),
              const SizedBox(height: 16),

              // Password
              TextField(
                controller: _passCtrl,
                style: SentinelJobsTheme.bodyStyle,
                obscureText: true,
                decoration: SentinelJobsTheme.inputDecoration('PASSWORD'),
              ),
              const SizedBox(height: 16),

              // Registration fields (unified - no role selection)
              if (_isRegister) ...[
                // Identity Fields (Strict)
                TextField(
                  controller: _firstNameCtrl,
                  style: SentinelJobsTheme.bodyStyle,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      SentinelJobsTheme.inputDecoration('FIRST NAME (REAL)'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _lastNameCtrl,
                  style: SentinelJobsTheme.bodyStyle,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      SentinelJobsTheme.inputDecoration('LAST NAME (REAL)'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneCtrl,
                  style: SentinelJobsTheme.bodyStyle,
                  keyboardType: TextInputType.phone,
                  decoration:
                      SentinelJobsTheme.inputDecoration('PHONE (MOBILE)'),
                ),
                const SizedBox(height: 16),

                // Info box about employer upgrade
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SentinelJobsTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: SentinelJobsTheme.primary, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Want to post jobs? You can upgrade to Employer from your Profile after registration.',
                          style: SentinelJobsTheme.mutedStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Error
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SentinelJobsTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: SentinelJobsTheme.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: SentinelJobsTheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                color: SentinelJobsTheme.error)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: SentinelJobsTheme.primaryButton,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: SentinelJobsTheme.background,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(_isRegister ? 'REGISTER' : 'LOGIN'),
                ),
              ),

              const SizedBox(height: 16),

              // Toggle login/register
              TextButton(
                onPressed: () => setState(() {
                  _isRegister = !_isRegister;
                  _error = null;
                }),
                child: Text(
                  _isRegister
                      ? 'Already have an account? Login'
                      : 'Need an account? Register',
                  style:
                      const TextStyle(color: SentinelJobsTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
