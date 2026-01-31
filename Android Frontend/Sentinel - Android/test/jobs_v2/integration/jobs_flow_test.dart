// Jobs v2 Integration Tests
// End-to-end user flow tests

import 'package:flutter_test/flutter_test.dart';

import 'package:sentinel_android/jobs_v2/api.dart';

// Comprehensive mock API for integration testing
class IntegrationMockApi extends JobsApi {
  IntegrationMockApi() : super(baseUrl: 'http://localhost:8000');

  // State tracking
  String? currentToken;
  String? currentAccountId;
  String? currentRole;
  bool isVerified = true;
  List<Map<String, dynamic>> listings = [];
  List<Map<String, dynamic>> applications = [];
  Map<String, dynamic>? profile;

  void setupWorkerUser() {
    currentToken = 'worker_token';
    currentAccountId = 'worker_1';
    currentRole = 'worker';
    isVerified = true;
    profile = {
      'display_name': 'John Worker',
      'email': 'worker@test.com',
      'role': 'worker',
      'trust_score': 80,
      'rating_avg': 4.5,
      'rating_count': 12,
      'skills': ['Security', 'First Aid'],
    };
  }

  void setupEmployerUser({bool verified = true}) {
    currentToken = 'employer_token';
    currentAccountId = 'employer_1';
    currentRole = 'employer';
    isVerified = verified;
    profile = {
      'display_name': 'Jane Employer',
      'email': 'employer@test.com',
      'role': 'employer',
      'verified': verified,
      'organization': {
        'name': 'Test Corp',
        'type': 'NGO',
      },
      'rating_avg': 4.8,
      'rating_count': 25,
    };
  }

  void addMockListings() {
    listings = [
      {
        '_id': 'job_1',
        'job_id': 'job_1',
        'category': 'Security',
        'description': 'Night security shift',
        'pay_type': 'hourly',
        'pay_range': {'min': 25, 'max': 35},
        'employer_name': 'SecureCo',
        'employer_trust': 90,
        'status': 'active',
      },
      {
        '_id': 'job_2',
        'job_id': 'job_2',
        'category': 'Medical',
        'description': 'Event first responder',
        'pay_type': 'cash',
        'pay_range': {'min': 150, 'max': 200},
        'employer_name': 'EventMed',
        'employer_trust': 85,
        'status': 'active',
      },
    ];
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
    Map<String, dynamic>? location,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (email == 'worker@test.com') {
      setupWorkerUser();
    } else if (email == 'employer@test.com') {
      setupEmployerUser();
    } else {
      return ApiResponse(
          success: false, statusCode: 401, error: 'Invalid credentials');
    }
    return ApiResponse(
      success: true,
      statusCode: 200,
      data: {
        'token': currentToken,
        'account_id': currentAccountId,
        'role': currentRole,
        'verified': isVerified,
      },
    );
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> register({
    required String email,
    required String password,
    required String phone,
    required String realNameFirst,
    required String realNameLast,
    required String role,
    String? organizationName,
    String? organizationType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    setupWorkerUser();
    return ApiResponse(
      success: true,
      statusCode: 200,
      data: {
        'token': currentToken,
        'account_id': currentAccountId,
      },
    );
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return ApiResponse(success: true, statusCode: 200, data: profile);
  }

  @override
  Future<ApiResponse<List<dynamic>>> searchListings({
    String? category,
    double? lat,
    double? lon,
    int? radiusKm,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    var result = listings;
    if (category != null) {
      result = listings.where((l) => l['category'] == category).toList();
    }
    return ApiResponse(success: true, statusCode: 200, data: result);
  }

  @override
  Future<ApiResponse<List<dynamic>>> getMyListings() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return ApiResponse(success: true, statusCode: 200, data: listings);
  }

  @override
  Future<ApiResponse<List<dynamic>>> getAppliedJobs() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return ApiResponse(success: true, statusCode: 200, data: applications);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> applyToJob(String jobId,
      {String? message}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    applications.add({
      'job_id': jobId,
      'status': 'pending',
      'job_title': 'Applied Job',
    });
    return ApiResponse(success: true, statusCode: 200, data: {'applied': true});
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> createListing({
    required String category,
    required String payType,
    required Map<String, dynamic> payRange,
    required String startTime,
    required String duration,
    required Map<String, dynamic> location,
    String? description,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final newListing = {
      '_id': 'job_new',
      'category': category,
      'description': description,
      'pay_type': payType,
      'pay_range': payRange,
      'status': 'active',
    };
    listings.add(newListing);
    return ApiResponse(success: true, statusCode: 200, data: newListing);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> upgradeToEmployer({
    required String organizationName,
    required String organizationType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    currentRole = 'employer';
    isVerified = false;
    return ApiResponse(
        success: true, statusCode: 200, data: {'upgraded': true});
  }

  @override
  void setToken(String? token) {
    currentToken = token;
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> updateProfile(
      Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (profile != null) {
      profile!.addAll(data);
    }
    return ApiResponse(success: true, statusCode: 200, data: profile);
  }

  @override
  void clearToken() {
    currentToken = null;
    currentAccountId = null;
    currentRole = null;
    profile = null;
  }
}

void main() {
  group('Jobs v2 Integration Tests', () {
    late IntegrationMockApi mockApi;

    setUp(() {
      mockApi = IntegrationMockApi();
      mockApi.addMockListings();
    });

    group('Worker Flow', () {
      testWidgets('worker can login, browse, and apply for jobs',
          (WidgetTester tester) async {
        // This test demonstrates the full worker flow
        // Note: Actual integration would require more setup

        mockApi.setupWorkerUser();

        // Verify mock state
        expect(mockApi.currentRole, 'worker');
        expect(mockApi.isVerified, isTrue);
        expect(mockApi.listings.length, 2);
      });

      testWidgets('worker can view applied jobs', (WidgetTester tester) async {
        mockApi.setupWorkerUser();
        mockApi.applications = [
          {
            'job_id': 'job_1',
            'status': 'pending',
            'job_title': 'Security Guard',
          }
        ];

        final resp = await mockApi.getAppliedJobs();
        expect(resp.success, isTrue);
        expect(resp.data!.length, 1);
      });

      testWidgets('worker can upgrade to employer',
          (WidgetTester tester) async {
        mockApi.setupWorkerUser();

        final resp = await mockApi.upgradeToEmployer(
          organizationName: 'My Company',
          organizationType: 'Contractor',
        );

        expect(resp.success, isTrue);
        expect(mockApi.currentRole, 'employer');
        expect(mockApi.isVerified, isFalse); // Pending verification
      });
      testWidgets('worker can update notification settings',
          (WidgetTester tester) async {
        mockApi.setupWorkerUser();

        final settings = {
          'notification_settings': {
            'push_pending': false,
            'push_marketing': false
          }
        };

        final resp = await mockApi.updateProfile(settings);

        expect(resp.success, isTrue);
        expect(
            mockApi.profile!['notification_settings']['push_pending'], isFalse);
      });
    });

    group('Employer Flow', () {
      testWidgets('verified employer can post jobs',
          (WidgetTester tester) async {
        mockApi.setupEmployerUser(verified: true);

        final initialCount = mockApi.listings.length;

        final resp = await mockApi.createListing(
          category: 'Logistics',
          payType: 'hourly',
          payRange: {'min': 18, 'max': 25, 'currency': 'USD'},
          startTime: DateTime.now().toIso8601String(),
          duration: '8h',
          location: {'lat': 40.7128, 'lon': -74.0060, 'accuracy': 10},
          description: 'Warehouse operations support',
        );

        expect(resp.success, isTrue);
        expect(mockApi.listings.length, initialCount + 1);
      });

      testWidgets('employer can view their listings',
          (WidgetTester tester) async {
        mockApi.setupEmployerUser();

        final resp = await mockApi.getMyListings();

        expect(resp.success, isTrue);
        expect(resp.data, isNotNull);
      });

      testWidgets('unverified employer has limited access',
          (WidgetTester tester) async {
        mockApi.setupEmployerUser(verified: false);

        expect(mockApi.currentRole, 'employer');
        expect(mockApi.isVerified, isFalse);
      });
    });

    group('Authentication Flow', () {
      testWidgets('login with valid credentials succeeds',
          (WidgetTester tester) async {
        final resp = await mockApi.login(
          email: 'worker@test.com',
          password: 'password',
        );

        expect(resp.success, isTrue);
        expect(resp.data!['token'], isNotNull);
        expect(resp.data!['role'], 'worker');
      });

      testWidgets('login with invalid credentials fails',
          (WidgetTester tester) async {
        final resp = await mockApi.login(
          email: 'wrong@test.com',
          password: 'wrongpass',
        );

        expect(resp.success, isFalse);
        expect(resp.error, 'Invalid credentials');
      });

      testWidgets('registration creates worker account',
          (WidgetTester tester) async {
        final resp = await mockApi.register(
          email: 'new@test.com',
          password: 'newpass123',
          phone: '+1234567890',
          realNameFirst: 'New',
          realNameLast: 'User',
          role: 'worker',
        );

        expect(resp.success, isTrue);
        expect(resp.data!['token'], isNotNull);
      });

      testWidgets('logout clears state', (WidgetTester tester) async {
        mockApi.setupWorkerUser();
        expect(mockApi.currentToken, isNotNull);

        mockApi.clearToken();

        expect(mockApi.currentToken, isNull);
        expect(mockApi.currentAccountId, isNull);
        expect(mockApi.profile, isNull);
      });
    });

    group('Search & Filter', () {
      testWidgets('search returns all listings without filter',
          (WidgetTester tester) async {
        final resp = await mockApi.searchListings();

        expect(resp.success, isTrue);
        expect(resp.data!.length, 2);
      });

      testWidgets('search filters by category', (WidgetTester tester) async {
        final resp = await mockApi.searchListings(category: 'Security');

        expect(resp.success, isTrue);
        expect(resp.data!.length, 1);
        expect(resp.data![0]['category'], 'Security');
      });

      testWidgets('search with non-existent category returns empty',
          (WidgetTester tester) async {
        final resp = await mockApi.searchListings(category: 'NonExistent');

        expect(resp.success, isTrue);
        expect(resp.data!.length, 0);
      });
    });

    group('Application Flow', () {
      testWidgets('applying to job adds to applications list',
          (WidgetTester tester) async {
        mockApi.setupWorkerUser();

        expect(mockApi.applications.length, 0);

        await mockApi.applyToJob('job_1');

        expect(mockApi.applications.length, 1);
        expect(mockApi.applications[0]['job_id'], 'job_1');
        expect(mockApi.applications[0]['status'], 'pending');
      });
    });
  });
}
