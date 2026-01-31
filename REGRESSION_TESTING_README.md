# Regression Testing Suite

## Overview

This document outlines the regression testing protocols for the Sentinel Defense System, covering both the core intelligence system and the Jobs V2 employment module.

---

## Test Architecture

```
test/
└── jobs_v2/
    ├── jobs_api_test.dart           # Unit tests for API client
    ├── integration/
    │   └── jobs_flow_test.dart      # End-to-end workflow tests
    ├── screens/
    │   └── my_listings_tab_test.dart # Screen-specific tests
    └── widgets/
        ├── dashboard_screen_test.dart
        ├── listings_tab_test.dart
        └── login_screen_test.dart
```

---

## Scope

### Jobs V2 Module
| Category | Coverage |
|----------|----------|
| **Authentication** | Login, Register, Token Management, Password Reset |
| **Job Listings** | Create, Search, Filter, My Listings, Edit, Delete |
| **Applications** | Submit, Accept, Reject, Withdraw, Status Transitions |
| **Messaging** | Chat unlock at pending/accepted, Image attachments |
| **Profile** | Role upgrades, Display name, Notification settings |
| **Moderation** | User reporting, Content flagging |
| **Admin** | Employer verification, User management |

### Intelligence System
| Category | Coverage |
|----------|----------|
| **Atlas G3 Pipeline** | Gate 1 ingestion, Gate 2 classification, Gate 2R verification |
| **DEFCON Logic** | Threat classification, Human-in-the-loop gates |
| **Geospatial** | Exclusion zones, Distance calculations |

---

## Running Tests

### Prerequisites
```bash
# Ensure Flutter SDK is installed
flutter doctor

# Ensure dependencies are resolved
cd "Android Frontend/Sentinel - Android"
flutter pub get
```

### Full Regression Suite
```bash
cd "Android Frontend/Sentinel - Android"
flutter test test/jobs_v2/
```

### Individual Test Files
```bash
# API Unit Tests
flutter test test/jobs_v2/jobs_api_test.dart

# Widget Tests
flutter test test/jobs_v2/widgets/

# Integration Tests
flutter test test/jobs_v2/integration/
```

### With Coverage Report
```bash
flutter test --coverage test/jobs_v2/
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## Expected Output

### Successful Run
```text
00:05 +42: All tests passed!
```

### Network Error Handling (Expected)
The `JobsApi` unit tests verify error handling when the backend is unreachable. You may see logs like:

```text
[JobsApi] Login error: ClientException with SocketException: Connection refused...
```

> **This is expected behavior.** The tests assert that the API client gracefully catches these exceptions and returns a structured `ApiResponse` object with `success: false`, rather than crashing the application.

---

## Test Files Reference

| File | Purpose | Key Assertions |
|------|---------|----------------|
| `jobs_api_test.dart` | API client methods and error handling | Network errors return `ApiResponse(success: false)` |
| `dashboard_screen_test.dart` | Navigation and role-based UI | Correct tabs for worker/employer/both roles |
| `listings_tab_test.dart` | Browsing and search flow | Search filters work, listings render correctly |
| `login_screen_test.dart` | Authentication forms | Validation, error states, successful login flow |
| `my_listings_tab_test.dart` | Employer's listing management | Edit, delete, status changes |
| `jobs_flow_test.dart` | End-to-end application lifecycle | applied → pending → accepted → completed |

---

## Backend Test Utilities

### Python Test Scripts
```bash
cd "Server Backend"

# Jobs V2 API Verification
python test_jobs_v2.py

# Endpoint Connectivity
python test_new_endpoints.py
```

### Manual API Testing
```bash
# Health Check
curl http://localhost:8000/intel/status

# Jobs V2 Auth
curl -X POST http://localhost:8000/api/jobs/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "test123"}'
```

---

## Continuous Integration

### Pre-Commit Checklist
- [ ] Run `flutter test test/jobs_v2/`
- [ ] Verify no linting errors (`flutter analyze`)
- [ ] Check backend health (`python test_jobs_v2.py`)
- [ ] Confirm no regression in existing features

### Post-Deployment Verification
- [ ] Test `/intel/status` endpoint
- [ ] Test Jobs V2 login flow
- [ ] Test application submission
- [ ] Verify Admin Console access

---

## Known Test Constraints

1. **Backend Required**: Integration tests require the Django backend running on `localhost:8000`
2. **MongoDB Required**: Database operations need MongoDB accessible
3. **Network Tests**: API tests will log connection errors when backend is offline (this is intentional)

---

## Adding New Tests

When adding new features to Jobs V2:

1. Create test file in appropriate directory (`widgets/`, `screens/`, `integration/`)
2. Follow naming convention: `{feature}_test.dart`
3. Include both success and failure scenarios
4. Mock network calls for unit tests
5. Document expected behavior in this README

---

*Last Updated: 2026-01-31*
