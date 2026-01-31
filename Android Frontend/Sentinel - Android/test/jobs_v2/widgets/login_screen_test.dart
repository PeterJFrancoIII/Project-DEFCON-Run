// Jobs v2 Login Screen Widget Tests
// Tests for JobsLoginScreen widget behavior and UI

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sentinel_android/jobs_v2/api.dart';
import 'package:sentinel_android/jobs_v2/screens/login_screen.dart';
import 'package:sentinel_android/jobs_v2/theme.dart';

// Mock API for testing
class MockJobsApi extends JobsApi {
  MockJobsApi() : super(baseUrl: 'http://localhost:8000');

  bool loginCalled = false;
  bool registerCalled = false;
  bool shouldSucceed = true;
  bool simulateDelay = false; // For testing loading states
  String? lastEmail;
  String? lastPassword;

  @override
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
    Map<String, dynamic>? location,
  }) async {
    loginCalled = true;
    lastEmail = email;
    lastPassword = password;

    // Simulate network delay for loading state tests
    if (simulateDelay) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (shouldSucceed) {
      return ApiResponse(
        success: true,
        statusCode: 200,
        data: {
          'token': 'mock_token',
          'account_id': 'mock_account_id',
          'role': 'worker',
          'verified': true,
        },
      );
    } else {
      return ApiResponse(
        success: false,
        statusCode: 401,
        error: 'Invalid credentials',
      );
    }
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
    registerCalled = true;
    lastEmail = email;

    if (shouldSucceed) {
      return ApiResponse(
        success: true,
        statusCode: 200,
        data: {
          'token': 'mock_token',
          'account_id': 'mock_account_id',
        },
      );
    } else {
      return ApiResponse(
        success: false,
        statusCode: 400,
        error: 'Registration failed',
      );
    }
  }
}

void main() {
  group('JobsLoginScreen', () {
    late MockJobsApi mockApi;
    late bool loginCallbackCalled;
    late String? capturedToken;
    late String? capturedAccountId;
    late String? capturedRole;
    late bool? capturedVerified;

    setUp(() {
      mockApi = MockJobsApi();
      loginCallbackCalled = false;
      capturedToken = null;
      capturedAccountId = null;
      capturedRole = null;
      capturedVerified = null;
    });

    Widget buildTestWidget() {
      return MaterialApp(
        theme: ThemeData.dark(),
        home: JobsLoginScreen(
          api: mockApi,
          onLogin: (token, accountId, role, verified) {
            loginCallbackCalled = true;
            capturedToken = token;
            capturedAccountId = accountId;
            capturedRole = role;
            capturedVerified = verified;
          },
        ),
      );
    }

    testWidgets('renders login form by default', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Verify login UI elements
      expect(find.text('WORKFORCE ACCESS'), findsOneWidget);
      expect(find.text('LOGIN'), findsOneWidget);
      expect(find.text('Need an account? Register'), findsOneWidget);

      // Verify input fields exist
      expect(find.byType(TextField), findsNWidgets(2)); // Email and password
    });

    testWidgets('toggle switches to registration form',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Tap toggle button
      await tester.tap(find.text('Need an account? Register'));
      await tester.pumpAndSettle();

      // Verify registration UI elements
      expect(find.text('JOIN SENTINEL WORKFORCE'), findsOneWidget);
      expect(find.text('REGISTER'), findsOneWidget);
      expect(find.text('Already have an account? Login'), findsOneWidget);

      // Verify additional registration fields
      expect(find.byType(TextField),
          findsNWidgets(5)); // Email, password, first, last, phone
    });

    testWidgets('shows error when fields are empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Tap login without entering credentials
      await tester.tap(find.text('LOGIN'));
      await tester.pumpAndSettle();

      // Should show error
      expect(find.text('Email and password required'), findsOneWidget);
    });

    testWidgets('successful login calls onLogin callback',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Enter credentials
      await tester.enterText(
        find.byType(TextField).first,
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextField).last,
        'password123',
      );

      // Tap login
      await tester.tap(find.text('LOGIN'));
      await tester.pumpAndSettle();

      // Verify API was called
      expect(mockApi.loginCalled, isTrue);
      expect(mockApi.lastEmail, 'test@example.com');

      // Verify callback was invoked
      expect(loginCallbackCalled, isTrue);
      expect(capturedToken, 'mock_token');
      expect(capturedAccountId, 'mock_account_id');
      expect(capturedRole, 'worker');
      expect(capturedVerified, isTrue);
    });

    testWidgets('failed login shows error message',
        (WidgetTester tester) async {
      mockApi.shouldSucceed = false;
      await tester.pumpWidget(buildTestWidget());

      // Enter credentials
      await tester.enterText(
        find.byType(TextField).first,
        'wrong@example.com',
      );
      await tester.enterText(
        find.byType(TextField).last,
        'wrongpass',
      );

      // Tap login
      await tester.tap(find.text('LOGIN'));
      await tester.pumpAndSettle();

      // Verify error is shown
      expect(find.text('Invalid credentials'), findsOneWidget);
      expect(loginCallbackCalled, isFalse);
    });

    testWidgets('registration requires all fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Switch to registration
      await tester.tap(find.text('Need an account? Register'));
      await tester.pumpAndSettle();

      // Enter only email and password
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'new@example.com');
      await tester.enterText(textFields.at(1), 'password123');

      // Scroll to register button (form may be longer than viewport)
      await tester.ensureVisible(find.text('REGISTER'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('REGISTER'));
      await tester.pumpAndSettle();

      // Should show error for missing fields
      expect(find.text('Name and phone required for registration'),
          findsOneWidget);
    });

    testWidgets('successful registration calls onLogin',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Switch to registration
      await tester.tap(find.text('Need an account? Register'));
      await tester.pumpAndSettle();

      // Fill all fields
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'new@example.com');
      await tester.enterText(textFields.at(1), 'password123');
      await tester.enterText(textFields.at(2), 'John');
      await tester.enterText(textFields.at(3), 'Doe');
      await tester.enterText(textFields.at(4), '+1234567890');

      // Scroll to register button (form may be longer than viewport)
      await tester.ensureVisible(find.text('REGISTER'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('REGISTER'));
      await tester.pumpAndSettle();

      // Verify registration was called
      expect(mockApi.registerCalled, isTrue);
      expect(loginCallbackCalled, isTrue);
    });

    testWidgets('shows loading indicator during API call',
        (WidgetTester tester) async {
      // Enable delay to capture loading state
      mockApi.simulateDelay = true;
      await tester.pumpWidget(buildTestWidget());

      // Enter credentials
      await tester.enterText(
        find.byType(TextField).first,
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextField).last,
        'password123',
      );

      // Tap login and don't wait for settle
      await tester.tap(find.text('LOGIN'));
      await tester.pump(); // Single frame to start the async operation
      await tester
          .pump(const Duration(milliseconds: 50)); // Allow state to update

      // Should show loading indicator while waiting
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Now complete the async operation
      await tester.pumpAndSettle();
    });

    testWidgets('uses SentinelJobsTheme styling', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Verify theme is applied
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, SentinelJobsTheme.background);
    });
  });
}
