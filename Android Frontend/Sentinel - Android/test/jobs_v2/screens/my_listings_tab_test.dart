import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_android/jobs_v2/api.dart';
import 'package:sentinel_android/jobs_v2/screens/my_listings_tab.dart';
import 'package:sentinel_android/jobs_v2/screens/application_detail_screen.dart';

// Mock API
class MockJobsApi extends JobsApi {
  MockJobsApi() : super(baseUrl: 'http://localhost:8000');

  @override
  Future<ApiResponse<List<dynamic>>> getMyListings() async {
    return ApiResponse(
      success: true,
      statusCode: 200,
      data: [
        {
          'job_id': 'job_1',
          'category': 'Security',
          'status': 'active',
          'application_count': 1,
          'employer_id': 'emp_1'
        }
      ],
    );
  }

  @override
  Future<ApiResponse<List<dynamic>>> getApplicants(String jobId) async {
    return ApiResponse(
      success: true,
      statusCode: 200,
      data: [
        {
          'application_id': 'app_1',
          'worker_id': 'worker_1',
          'real_name_first': 'John',
          'real_name_last': 'Doe',
          'status': 'pending', // Interviewing -> Should show COMMS button
          'trust_score': 90
        }
      ],
    );
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getApplication(String appId) async {
    return ApiResponse(
      success: true,
      statusCode: 200,
      data: {
        'application_id': appId,
        'status': 'pending',
        'allow_messaging': false, // Prevent further API calls in test
        'job': {'category': 'Security', 'description': 'Test job'},
        'worker': {'real_name_first': 'John', 'real_name_last': 'Doe'},
        'employer': {'organization_name': 'Test Corp'},
      },
    );
  }
}

void main() {
  testWidgets('MyListingsTab shows COMMS button for pending applicants',
      (WidgetTester tester) async {
    final mockApi = MockJobsApi();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MyListingsTab(api: mockApi)),
    ));
    await tester.pumpAndSettle();

    // 1. Verify Listing
    expect(find.text('SECURITY'), findsOneWidget);
    expect(find.text('1 APPLICANTS'), findsOneWidget);

    // 2. Open Applicants Sheet
    await tester.tap(find.text('VIEW CANDIDATES'));
    await tester.pumpAndSettle();

    // 3. Verify Applicant Card
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('INTERVIEWING'), findsOneWidget);

    // 4. Verify COMMS button
    expect(find.text('OPEN CHAT'), findsOneWidget);
    expect(find.byIcon(Icons.chat), findsOneWidget);

    // 5. Tap COMMS button (Navigation check)
    await tester.tap(find.text('OPEN CHAT'));
    await tester.pumpAndSettle();

    // Should be on Application Detail Screen (Check for app bar title or unique element)
    // Note: Detail screen usually fetches data on load, which might fail with default mock if not handled.
    // The DetailScreen expects api.getApplication to work.
    // However, just checking we are *trying* to push is good for now,
    // or we can verify by Type if we register the route.
    // Since we push MaterialPageRoute, we look for widgets from that screen.
    // Let's assume Detail screen builds at least a Scaffold.
    expect(find.byType(JobApplicationDetailScreen), findsOneWidget);
  });
}
