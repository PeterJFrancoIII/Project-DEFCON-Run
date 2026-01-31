// Jobs v2 Listings Tab Widget Tests
// Tests for ListingsTab browse/search functionality

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sentinel_android/jobs_v2/api.dart';
import 'package:sentinel_android/jobs_v2/screens/listings_tab.dart';
import 'package:sentinel_android/jobs_v2/theme.dart';

// Mock API for testing
class MockJobsApi extends JobsApi {
  MockJobsApi() : super(baseUrl: 'http://localhost:8000');

  bool searchCalled = false;
  String? lastCategory;
  bool shouldFail = false;
  List<Map<String, dynamic>> mockListings = [];

  @override
  Future<ApiResponse<List<dynamic>>> searchListings({
    String? category,
    double? lat,
    double? lon,
    int? radiusKm,
  }) async {
    searchCalled = true;
    lastCategory = category;

    if (shouldFail) {
      return ApiResponse(
        success: false,
        statusCode: 500,
        error: 'Network error',
      );
    }

    return ApiResponse(
      success: true,
      statusCode: 200,
      data: mockListings,
    );
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> applyToJob(String jobId,
      {String? message}) async {
    return ApiResponse(
        success: true, statusCode: 200, data: {'status': 'applied'});
  }

  @override
  Future<ApiResponse<void>> submitReport({
    required String targetId,
    required String targetType,
    required String reason,
    String? details,
  }) async {
    return ApiResponse(success: true, statusCode: 201);
  }
}

void main() {
  group('ListingsTab', () {
    late MockJobsApi mockApi;

    setUp(() {
      mockApi = MockJobsApi();
      mockApi.mockListings = [
        {
          '_id': 'job_1',
          'job_id': 'job_1',
          'category': 'Security',
          'description': 'Security guard needed for event',
          'pay_type': 'hourly',
          'pay_range': {'min': 20, 'max': 30, 'currency': 'USD'},
          'employer_name': 'Test Corp',
          'employer_trust': 85,
        },
        {
          '_id': 'job_2',
          'job_id': 'job_2',
          'category': 'Medical',
          'description': 'First aid responder',
          'pay_type': 'cash',
          'pay_range': {'min': 100, 'max': 200, 'currency': 'USD'},
          'employer_name': 'Medical Inc',
          'employer_trust': 70,
        },
      ];
    });

    Widget buildTestWidget({String role = 'worker'}) {
      return MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: ListingsTab(api: mockApi, role: role),
        ),
      );
    }

    testWidgets('shows loading indicator initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Should show loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('SCANNING FOR MISSIONS...'), findsOneWidget);
    });

    testWidgets('displays listings after loading', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Should show listings (SECURITY appears twice - in filter chip AND card)
      expect(find.text('SECURITY'), findsNWidgets(2)); // Filter + card
      expect(find.text('MEDICAL'), findsNWidgets(2)); // Filter + card
      expect(find.text('Security guard needed for event'), findsOneWidget);
    });

    testWidgets('shows category filters', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Should show filter chips (some appear twice due to matching listings)
      expect(find.text('ALL SECTORS'), findsOneWidget);
      expect(find.text('SECURITY'), findsNWidgets(2)); // Filter + listing
      expect(find.text('MEDICAL'), findsNWidgets(2)); // Filter + listing
      expect(find.text('LOGISTICS'), findsOneWidget); // Filter only
      expect(find.text('CLEANUP'), findsOneWidget); // Filter only
      expect(find.text('ADMIN'), findsOneWidget); // Filter only
    });

    testWidgets('tapping filter calls API with category',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      mockApi.searchCalled = false;

      // Tap a filter (use first SECURITY which is the filter, not the listing)
      final securityFilters = find.text('SECURITY');
      await tester.tap(securityFilters.first);
      await tester.pumpAndSettle();

      // API should be called with category filter
      expect(mockApi.searchCalled, isTrue);
      expect(mockApi.lastCategory, 'Security');
    });

    testWidgets('shows verified badge for trusted employers',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // First listing has trust >= 80, should show verified
      expect(find.text('VERIFIED'), findsOneWidget);
    });

    testWidgets('shows APPLY button for workers', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(role: 'worker'));
      await tester.pumpAndSettle();

      // Workers should see apply buttons
      expect(find.text('APPLY'), findsNWidgets(2));
    });

    testWidgets('hides APPLY button for employers',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(role: 'employer'));
      await tester.pumpAndSettle();

      // Employers should not see apply buttons
      expect(find.text('APPLY'), findsNothing);
    });

    testWidgets('tapping card opens detail sheet', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap on a listing card
      await tester.tap(find.text('Security guard needed for event'));
      await tester.pumpAndSettle();

      // Bottom sheet should appear with details
      expect(find.text('MISSION BRIEF:'), findsOneWidget);
      expect(find.text('COMPENSATION:'), findsOneWidget);
      expect(find.text('REPORT'), findsOneWidget);
    });

    testWidgets('shows empty state when no listings',
        (WidgetTester tester) async {
      mockApi.mockListings = [];
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.text('NO ACTIVE MISSIONS'), findsOneWidget);
      expect(find.text('No assignments found in this sector.'), findsOneWidget);
      expect(find.text('REFRESH SCAN'), findsOneWidget);
    });

    testWidgets('shows error state on API failure',
        (WidgetTester tester) async {
      mockApi.shouldFail = true;
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Should show error state
      expect(find.text('UPLINK FAILED'), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
      expect(find.text('RETRY CONNECTION'), findsOneWidget);
    });

    testWidgets('pull-to-refresh reloads listings',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      mockApi.searchCalled = false;

      // Perform pull-to-refresh on the vertical ListView (the second one after filter chips)
      final verticalListView = find.byType(ListView).last;
      await tester.fling(
        verticalListView,
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      // API should be called again
      expect(mockApi.searchCalled, isTrue);
    });

    testWidgets('displays pay range correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Hourly pay format
      expect(find.text('\$20/hr'), findsOneWidget);
      // Cash pay format
      expect(find.text('\$100 - \$200'), findsOneWidget);
    });

    testWidgets('report dialog shows reason options',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open listing detail
      await tester.tap(find.text('Security guard needed for event'));
      await tester.pumpAndSettle();

      // Tap report button
      await tester.tap(find.text('REPORT'));
      await tester.pumpAndSettle();

      // Report dialog should show
      expect(find.text('Select a reason:'), findsOneWidget);
      expect(find.text('Fraud / Scam'), findsOneWidget);
      expect(find.text('Spam'), findsOneWidget);
      expect(find.text('Fake Listing'), findsOneWidget);
      expect(find.text('Safety Concern'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
    });

    testWidgets('uses SentinelJobsTheme colors', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Find containers with theme colors
      final refreshIndicator = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );
      expect(refreshIndicator.color, SentinelJobsTheme.primary);
    });
  });
}
