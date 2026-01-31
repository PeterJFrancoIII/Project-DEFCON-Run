# Regression Testing Suite

## Overview
This document outlines the regression testing protocols for the Sentinel Defense System, specifically focusing on the `jobs_v2` module.

## Scope
The regression suite covers:
- **Authentication**: Login, Register, Token Management.
- **Job Listings**: Creation, Search, Filtering, My Listings.
- **Applications**: Application submission, Applicant retrieval, Worker assignment.
- **Profile**: Role upgrades, Profile management.
- **Moderation**: Reporting mechanisms.

## Running Tests
To execute the full regression suite, run the following command from the `Android Frontend/Sentinel - Android` directory:

```bash
flutter test test/jobs_v2/
```

### Expected Output
You should see:
```text
All tests passed!
```

### Note on Network Errors
The `JobsApi` unit tests (`jobs_api_test.dart`) are designed to verify error handling when the backend is unreachable. You may see logs similar to:
`[JobsApi] Login error: ClientException with SocketException: Connection refused...`

**This is expected behavior.** The tests assert that the API client gracefully catches these exceptions and returns a structured `ApiResponse` object with `success: false`, rather than crashing the application.

## Key Test Files
| File | Purpose |
|------|---------|
| `test/jobs_v2/jobs_api_test.dart` | Unit tests for API client methods and error handling. |
| `test/jobs_v2/widgets/dashboard_screen_test.dart` | Widget tests for navigation and role-based UI. |
| `test/jobs_v2/widgets/listings_tab_test.dart` | Widget tests for the browsing and searching flow. |
| `test/jobs_v2/widgets/login_screen_test.dart` | Widget tests for authentication forms. |
