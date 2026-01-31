// Jobs v2 Dashboard Screen Widget Tests
// Tests for main navigation and role-based UI

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sentinel_android/jobs_v2/api.dart';
import 'package:sentinel_android/jobs_v2/screens/dashboard_screen.dart';
import 'package:sentinel_android/jobs_v2/theme.dart';

// Mock API for testing
class MockJobsApi extends JobsApi {
  MockJobsApi() : super(baseUrl: 'http://localhost:8000');

  @override
  Future<ApiResponse<List<dynamic>>> searchListings({
    String? category,
    double? lat,
    double? lon,
    int? radiusKm,
  }) async {
    return ApiResponse(success: true, statusCode: 200, data: []);
  }

  @override
  Future<ApiResponse<List<dynamic>>> getMyListings() async {
    return ApiResponse(success: true, statusCode: 200, data: []);
  }

  @override
  Future<ApiResponse<List<dynamic>>> getAppliedJobs() async {
    return ApiResponse(success: true, statusCode: 200, data: []);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getProfile() async {
    return ApiResponse(
      success: true,
      statusCode: 200,
      data: {
        'display_name': 'Test User',
        'email': 'test@example.com',
        'role': 'worker',
        'trust_score': 75,
        'rating_avg': 4.5,
        'rating_count': 10,
      },
    );
  }

  @override
  Future<ApiResponse<List<dynamic>>> getInbox() async {
    return ApiResponse(success: true, statusCode: 200, data: []);
  }
}

void main() {
  group('JobsDashboardScreen', () {
    late MockJobsApi mockApi;
    late bool logoutCalled;
    late bool backToModeCalled;

    setUp(() {
      mockApi = MockJobsApi();
      logoutCalled = false;
      backToModeCalled = false;
    });

    Widget buildTestWidget({
      String role = 'worker',
      bool verified = true,
    }) {
      return MaterialApp(
        theme: ThemeData.dark(),
        home: JobsDashboardScreen(
          api: mockApi,
          accountId: 'test_account',
          role: role,
          verified: verified,
          onLogout: () => logoutCalled = true,
          onBackToModeSelection: () => backToModeCalled = true,
        ),
      );
    }

    testWidgets('shows correct header', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('SENTINEL WORKFORCE'), findsOneWidget);
    });

    testWidgets('shows back button when mode selection enabled',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('back button calls onBackToModeSelection',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(backToModeCalled, isTrue);
    });

    testWidgets('logout button calls onLogout', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      expect(logoutCalled, isTrue);
    });

    testWidgets('worker sees BROWSE, APPLIED, ID CARD tabs',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(role: 'worker'));
      await tester.pumpAndSettle();

      expect(find.text('BROWSE'), findsOneWidget);
      expect(find.text('APPLIED'), findsOneWidget);
      expect(find.text('MESSAGES'), findsOneWidget);
      expect(find.text('ID CARD'), findsOneWidget);
    });

    testWidgets('employer sees BROWSE, MY POSTS, ID CARD tabs',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(role: 'employer'));
      await tester.pumpAndSettle();

      expect(find.text('BROWSE'), findsOneWidget);
      expect(find.text('MY POSTS'), findsOneWidget);
      expect(find.text('MESSAGES'), findsOneWidget);
      expect(find.text('ID CARD'), findsOneWidget);
    });

    testWidgets('employer sees FAB for posting jobs',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(role: 'employer'));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('BROADCAST OP'), findsOneWidget);
    });

    testWidgets('worker does not see FAB', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(role: 'worker'));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('unverified employer sees UNVERIFIED badge',
        (WidgetTester tester) async {
      await tester
          .pumpWidget(buildTestWidget(role: 'employer', verified: false));
      await tester.pumpAndSettle();

      expect(find.text('UNVERIFIED'), findsOneWidget);
    });

    testWidgets('verified employer does not see UNVERIFIED badge',
        (WidgetTester tester) async {
      await tester
          .pumpWidget(buildTestWidget(role: 'employer', verified: true));
      await tester.pumpAndSettle();

      expect(find.text('UNVERIFIED'), findsNothing);
    });

    testWidgets('unverified employer FAB shows restricted dialog',
        (WidgetTester tester) async {
      await tester
          .pumpWidget(buildTestWidget(role: 'employer', verified: false));
      await tester.pumpAndSettle();

      // Tap FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Should show restricted access dialog
      expect(find.text('RESTRICTED ACCESS'), findsOneWidget);
      expect(
          find.text('Employer account verification required.'), findsOneWidget);
      expect(find.text('Pending Administrator Approval.'), findsOneWidget);
    });

    testWidgets('tapping tab changes view', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(role: 'worker'));
      await tester.pumpAndSettle();

      // Initially on BROWSE tab (index 0)
      // Tap APPLIED tab
      await tester.tap(find.text('APPLIED'));
      await tester.pumpAndSettle();

      // Tap ID CARD tab
      await tester.tap(find.text('ID CARD'));
      await tester.pumpAndSettle();

      // Should be on profile tab now (verified by profile content loading)
    });

    testWidgets('uses IndexedStack for state preservation',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify IndexedStack is used
      expect(find.byType(IndexedStack), findsOneWidget);
    });

    testWidgets('uses theme background color', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, SentinelJobsTheme.background);
    });

    testWidgets('bottom nav uses correct icons for worker',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(role: 'worker'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.travel_explore), findsOneWidget);
      expect(find.byIcon(Icons.assignment_turned_in), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byIcon(Icons.shield), findsOneWidget);
    });

    testWidgets('bottom nav uses correct icons for employer',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(role: 'employer'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.travel_explore), findsOneWidget);
      expect(find.byIcon(Icons.business_center), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byIcon(Icons.shield), findsOneWidget);
    });
  });
}
