import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// VS Colors for Jobs Module
class VS {
  static const Color neogreen = Color(0xFF00FF41);
  static const Color neocyan = Color(0xFF00F0FF);
  // Add other needed colors
}

class JobsService {
  // Use localhost for simulator if needed, or the configured VPS URL
  // Ideally this comes from the central config in main.dart
  static String get baseUrl {
    if (kIsWeb || Platform.isIOS || Platform.isMacOS) {
      return "http://127.0.0.1:8000/api/jobs";
    }
    return "http://10.0.2.2:8000/api/jobs"; // Android Fallback
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jobs_auth_token');
  }

  static Future<String?> getAccountId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jobs_account_id');
  }

  static Future<void> saveAuth(String token, String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jobs_auth_token', token);
    await prefs.setString('jobs_account_id', accountId);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jobs_auth_token');
    await prefs.remove('jobs_account_id');
  }

  static Future<void> deleteAccount(String? baseUrlOverride) async {
    final token = await getToken();
    if (token == null) throw Exception("Unauthorized");

    // Remove double slash if present
    String base = baseUrlOverride ?? baseUrl;
    String url = "$base/auth/delete";
    final response = await http
        .post(Uri.parse(url), headers: {"Authorization": "Bearer $token"});

    if (response.statusCode == 200) {
      await logout(); // Clear local data
    } else {
      throw Exception(response.body);
    }
  }

  // AUTH
  static Future<Map<String, dynamic>> login(String email, String password,
      {String? baseUrlOverride}) async {
    String base = baseUrlOverride ?? baseUrl;
    String url = "$base/auth/login";

    try {
      final response = await http.post(
        Uri.parse(url),
        body: jsonEncode({"email": email, "password": password}),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception(response.body);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> register(
      String email, String password, String role, String profilePic) async {
    String url = "$baseUrl/auth/register";
    try {
      final response = await http.post(
        Uri.parse(url),
        body: jsonEncode({
          "email": email,
          "password": password,
          "role": role,
          "profile_pic": profilePic
        }),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception(response.body);
    } catch (e) {
      rethrow;
    }
  }

  // LISTINGS
  static Future<List<dynamic>> searchListings(String? baseUrlOverride) async {
    String url = "${baseUrlOverride ?? baseUrl}/listings/search?limit=50";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    }
    throw Exception("Failed to load jobs");
  }

  static Future<void> createListing(String? baseUrlOverride, String title,
      String description, String pay, String zip) async {
    final token = await getToken();
    if (token == null) throw Exception("Unauthorized");

    String url = "${baseUrlOverride ?? baseUrl}/listings/create";
    final response = await http.post(Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "title": title,
          "description": description,
          "pay": pay,
          "location": {"zip": zip}
        }));
    if (response.statusCode != 200) throw Exception(response.body);
  }

  // REPORT
  static Future<void> report(String? baseUrlOverride, String targetType,
      String targetId, String reason) async {
    final token = await getToken();
    if (token == null) throw Exception("Unauthorized");

    String url = "${baseUrlOverride ?? baseUrl}/report";
    final response = await http.post(Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "target_type": targetType,
          "target_id": targetId,
          "reason": reason
        }));
    if (response.statusCode != 200) throw Exception(response.body);
  }

  static Future<void> submitRating(
      String? baseUrlOverride, String jobId, int score, String text) async {
    final token = await getToken();
    if (token == null) throw Exception("Unauthorized");
    String url = "${baseUrlOverride ?? baseUrl}/ratings/submit";
    final response = await http.post(Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({"job_id": jobId, "score": score, "text": text}));
    if (response.statusCode != 200) throw Exception(response.body);
  }
}

// --- UI WIDGETS ---

class JobsAuthGate extends StatefulWidget {
  final String serverUrl;
  const JobsAuthGate({super.key, required this.serverUrl});

  @override
  State<JobsAuthGate> createState() => _JobsAuthGateState();
}

class _JobsAuthGateState extends State<JobsAuthGate> {
  bool _isAuthenticated = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await JobsService.getToken();
    setState(() {
      _isAuthenticated = token != null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: VS.neogreen));
    }

    // Fix: If serverUrl is "http://10.0.2.2:8000", we want "http://10.0.2.2:8000/api/jobs"
    String apiBase = "${widget.serverUrl}/api/jobs";

    if (!_isAuthenticated) {
      return JobsAuthView(
        apiBase: apiBase,
        onLoginSuccess: () {
          setState(() {
            _isAuthenticated = true;
          });
        },
      );
    }

    return JobsDashboard(
        apiBase: apiBase,
        onLogout: () async {
          await JobsService.logout();
          setState(() => _isAuthenticated = false);
        });
  }
}

class JobsAuthView extends StatefulWidget {
  final String apiBase;
  final VoidCallback onLoginSuccess;
  const JobsAuthView(
      {super.key, required this.apiBase, required this.onLoginSuccess});

  @override
  State<JobsAuthView> createState() => _JobsAuthViewState();
}

class _JobsAuthViewState extends State<JobsAuthView> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _picCtrl = TextEditingController(); // Profile Pic
  bool _isRegistering = false;
  String? _error;

  // Use a hack to set the base URL in service temporarily or pass it down
  // For simplicity, we just modify the static getter logic if possible,
  // but here we will instantiate a helper or just modify the raw http calls in service to take url arg.
  // Updated Service above to take optional override.

  Future<void> _submit() async {
    // Simple override for static service
    JobsService.baseUrl; // Using strict class unfortunately.
    // Re-implementing raw call here for strict correctness with passed apiBase
    String endpoint = _isRegistering ? "/auth/register" : "/auth/login";
    String url = "${widget.apiBase}$endpoint";

    try {
      final body = {
        "email": _emailCtrl.text,
        "password": _passCtrl.text,
        if (_isRegistering) "role": "worker",
        if (_isRegistering) "profile_pic": _picCtrl.text
      };

      final response = await http.post(Uri.parse(url),
          body: jsonEncode(body),
          headers: {"Content-Type": "application/json"});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await JobsService.saveAuth(data['token'], data['account_id']);
        widget.onLoginSuccess();
      } else {
        setState(() => _error = "Error: ${response.body}");
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.work_outline, size: 60, color: VS.neogreen),
            const SizedBox(height: 20),
            Text(_isRegistering ? "Join Sentinel Force" : "Sentinel Jobs Login",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontFamily: 'ShareTechMono')),
            const SizedBox(height: 30),
            TextField(
              controller: _emailCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Email",
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Password",
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey)),
              ),
            ),
            const SizedBox(height: 20),
            if (_isRegistering) ...[
              TextField(
                controller: _picCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Profile Pic URL (Optional)",
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(backgroundColor: VS.neogreen),
              child: Text(_isRegistering ? "REGISTER" : "LOGIN",
                  style: const TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () => setState(() => _isRegistering = !_isRegistering),
              child: Text(
                  _isRegistering
                      ? "Already have an account? Login"
                      : "Need an account? Register",
                  style: const TextStyle(color: VS.neocyan)),
            )
          ],
        ),
      ),
    );
  }
}

class JobsDashboard extends StatefulWidget {
  final String apiBase;
  final VoidCallback onLogout;
  const JobsDashboard(
      {super.key, required this.apiBase, required this.onLogout});

  @override
  State<JobsDashboard> createState() => _JobsDashboardState();
}

class _JobsDashboardState extends State<JobsDashboard> {
  // Load jobs on init
  Future<List<dynamic>>? _jobsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _jobsFuture = JobsService.searchListings(widget.apiBase);
    });
  }

  void _showCreateDialog() {
    showDialog(
        context: context,
        builder: (_) =>
            CreateJobDialog(apiBase: widget.apiBase, onSuccess: _refresh));
  }

  void _confirmDeleteAccount() {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF222222),
              title: const Text("DELETE ACCOUNT?",
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
              content: const Text(
                  "This action is permanent. All your data will be wiped.",
                  style: TextStyle(color: Colors.white)),
              actions: [
                TextButton(
                    child: const Text("CANCEL"),
                    onPressed: () => Navigator.pop(context)),
                TextButton(
                    child: const Text("CONFIRM DELETE",
                        style: TextStyle(color: Colors.red)),
                    onPressed: () async {
                      try {
                        Navigator.pop(context); // Close dialog first
                        await JobsService.deleteAccount(widget.apiBase);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Account Deleted")));
                        widget.onLogout();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Delete Failed")));
                      }
                    })
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: VS.neogreen,
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black45,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Available Missions",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontFamily: 'ShareTechMono')),
                IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.grey),
                    onPressed: _confirmDeleteAccount),
                IconButton(
                    icon: const Icon(Icons.logout, color: Colors.red),
                    onPressed: widget.onLogout)
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _jobsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: VS.neogreen));
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text("Error: ${snapshot.error}",
                          style: const TextStyle(color: Colors.red)));
                }

                final jobs = snapshot.data ?? [];
                if (jobs.isEmpty) {
                  return const Center(
                      child: Text("No active missions found.",
                          style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(job['title'] ?? 'Untitled',
                            style: const TextStyle(
                                color: VS.neocyan,
                                fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              CircleAvatar(
                                  backgroundImage:
                                      (job['employer_pic'] != null &&
                                              job['employer_pic']
                                                  .toString()
                                                  .isNotEmpty)
                                          ? NetworkImage(job['employer_pic'])
                                          : null,
                                  backgroundColor: Colors.grey[800],
                                  radius: 10,
                                  child: (job['employer_pic'] == null ||
                                          job['employer_pic']
                                              .toString()
                                              .isEmpty)
                                      ? const Icon(Icons.person, size: 12)
                                      : null),
                              const SizedBox(width: 6),
                              Text(
                                  "⭐ ${job['employer_rating']?.toStringAsFixed(1) ?? '0.0'} (${job['employer_rating_count']})",
                                  style: const TextStyle(
                                      color: Colors.yellow, fontSize: 10)),
                              const SizedBox(width: 8),
                              Text("Done: ${job['employer_jobs_count'] ?? 0}",
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 10)),
                            ]),
                            const SizedBox(height: 4),
                            Text(job['description'] ?? '',
                                style: const TextStyle(color: Colors.white70),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(job['pay'] ?? 'Unpaid',
                                style: const TextStyle(
                                    color: VS.neogreen, fontSize: 12)),
                          ],
                        ),
                        trailing:
                            Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                              icon: const Icon(Icons.star_half,
                                  color: Colors.yellow),
                              onPressed: () => _showRatingDialog(job['_id'])),
                          IconButton(
                            icon: const Icon(Icons.flag_outlined,
                                color: Colors.grey),
                            onPressed: () => _showReportDialog(job['_id']),
                          )
                        ]),
                        onTap: () {
                          // Show details
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(String jobId) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF222222),
              title: const Text("Report Listing",
                  style: TextStyle(color: Colors.white)),
              content: const Text(
                  "Flag this listing as dangerous, spam, or fake?",
                  style: TextStyle(color: Colors.white70)),
              actions: [
                TextButton(
                    child: const Text("CANCEL"),
                    onPressed: () => Navigator.pop(context)),
                TextButton(
                    child: const Text("REPORT",
                        style: TextStyle(color: Colors.red)),
                    onPressed: () async {
                      try {
                        await JobsService.report(
                            widget.apiBase, "listing", jobId, "spam");
                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Report Submitted")));
                        // In pro version, remove from local list immediately
                      } catch (e) {
                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Error reporting")));
                      }
                    })
              ],
            ));
  }

  void _showRatingDialog(String jobId) {
    showDialog(
        context: context,
        builder: (_) => RateJobDialog(apiBase: widget.apiBase, jobId: jobId));
  }
}

class CreateJobDialog extends StatefulWidget {
  final String apiBase;
  final VoidCallback onSuccess;
  const CreateJobDialog(
      {super.key, required this.apiBase, required this.onSuccess});

  @override
  State<CreateJobDialog> createState() => _CreateJobDialogState();
}

class _CreateJobDialogState extends State<CreateJobDialog> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _pay = TextEditingController();
  final _zip = TextEditingController();

  Future<void> _post() async {
    try {
      await JobsService.createListing(
          widget.apiBase, _title.text, _desc.text, _pay.text, _zip.text);
      if (!mounted) return;
      widget.onSuccess();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF222222),
      title: const Text("Create Mission",
          style: TextStyle(color: VS.neogreen, fontFamily: 'ShareTechMono')),
      content: SingleChildScrollView(
        child: Column(
          children: [
            _field(_title, "Title"),
            _field(_desc, "Description", lines: 3),
            _field(_pay, "Pay (e.g. 500 THB)"),
            _field(_zip, "Zip Code"),
          ],
        ),
      ),
      actions: [
        TextButton(
            child: const Text("CANCEL"),
            onPressed: () => Navigator.pop(context)),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: VS.neogreen),
          onPressed: _post,
          child: const Text("POST", style: TextStyle(color: Colors.black)),
        )
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String label, {int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: ctrl,
        maxLines: lines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey)),
        ),
      ),
    );
  }
}

class RateJobDialog extends StatefulWidget {
  final String apiBase;
  final String jobId;
  const RateJobDialog({super.key, required this.apiBase, required this.jobId});

  @override
  State<RateJobDialog> createState() => _RateJobDialogState();
}

class _RateJobDialogState extends State<RateJobDialog> {
  double _score = 100;
  final _comment = TextEditingController();

  Future<void> _submit() async {
    try {
      await JobsService.submitRating(
          widget.apiBase, widget.jobId, _score.toInt(), _comment.text);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Rating Submitted!")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title:
            const Text("Rate Employer", style: TextStyle(color: VS.neogreen)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text("Score: ${_score.toInt()}",
              style: const TextStyle(color: Colors.yellow, fontSize: 20)),
          Slider(
              value: _score,
              min: 0,
              max: 100,
              divisions: 100,
              activeColor: VS.neogreen,
              onChanged: (v) => setState(() => _score = v)),
          TextField(
              controller: _comment,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  labelText: "Comment (Optional)",
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey))))
        ]),
        actions: [
          TextButton(
              child: const Text("CANCEL"),
              onPressed: () => Navigator.pop(context)),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: VS.neogreen),
              onPressed: _submit,
              child:
                  const Text("SUBMIT", style: TextStyle(color: Colors.black)))
        ]);
  }
}
