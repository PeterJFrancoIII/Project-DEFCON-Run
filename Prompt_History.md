# Prompt History & System Governance

## 📝 Maintenance Protocol
This file acts as the **Final Source of Truth** for the technical evolution of the Sentinel Project. AI models MUST maintain this log with high precision.

### Principles:
- **Traceability**: Every prompt that affects logic, architecture, or code behavior must be logged.
- **Granularity**: High technical detail is required. Cite specific files, functions, and logic changes.
- **Exclusion**: Do NOT log administrative or non-technical prompts (e.g., system reboots, terminal cleanup).
- **Categorization**: Group entries into **Build**, **Framework**, **Updates**, or **Debug**.

### Level of Detail Expected:
- **Build/Updates**: Describe the new feature and the specific code modules affected (e.g., "Updated `LoadingPage` in `main.dart` to support log streaming").
- **Framework**: Note changes to the stack or persistence layer (e.g., "Shifted SitRep storage to MongoDB `news_index`").
- **Debug**: Document the root cause and the specific resolution (e.g., "Fixed `NameError` in `views.py` caused by missing hash utility").

---

# Prompt History

## Session: Enhancing Sentinel Intelligence Features
**Date:** 2026-01-08

### Prompts Issued:

1.  **Initial Objective:**
    *   Implement Clickable SITREP Reports (on-demand citations).
    *   Fix News "DRIFT" (anti-drift module, UTC normalization).
    *   Improve Analyst Prompt & DEFCON Accuracy (defcon 4/5, historical context).
    *   Implement Clickable Forecast Topics.
    *   Integrate Historical Training Context (150 years history).

2.  **Dev Stack Compliance:**
    > "Please be sure to adhere to the Dev stack when building as best as possible. I've created a file with that AI_AGENT_READ_THIS"

3.  **API Key Provision:**
    > [Provided Gemini API Key]

4.  **Local Execution Request:**
    > "run all of it locally please"

6.  **Rule Review Request:**
    > "Please review the recently updated agent rules, and ensure that they are applied correctly."

7.  **Intelligence Logic & UI Refinement:**
    *   **Goal**: Full implementation of Requirements A-F (Observability, SITREP/Forecast Cards, News Drift, DEFCON logic).
    *   **Framework Update**: Added MongoDB-backed status and news persistence to the Backend.
    *   **Build/Update**: Implemented interactive `SitRepEntry` and `ForecastEntry` cards with detailed modals and citation fetching.
    *   **Observability Update**: Integrated a real-time server log viewer (200 lines) and backend status polling on the mobile loading page.

8.  **GUI Sync & Localhost Debugging:**
    > "The code updates don't seem to be changing the Frontend GUI in any of the ways we've desired. Please inspec that."
    *   **Debug Insight**: Discovered the Flutter app was defaulting to the Production VPS, masking local logic and UI changes.
    *   **Fix**: Rewrote `determineServerUrl` in `main.dart` to prioritize the correct Android Emulator loopback (`10.0.2.2`) and detect local heartbeats.
    *   **Debug (Backend)**: Identified and fixed a `NameError: name 'get_msg_hash' is not defined` in `views.py` that was suppressing news generation.

### Technical Implementation Details:

#### A. Server Observability (Req A)
- **Framework**: Created `/intel/status` endpoint in Django.
- **Mobile UI**: Added terminal icon and polling logic to `LoadingPage`.

#### B. SITREP & Data Integrity (Req B/C)
- **Data Model**: Transitioned SITREP from plain text to structured `SitRepEntry` objects.
- **News Anti-Drift**: Implemented MD5 fingerprinting and UTC normalization in MongoDB.
- **DEFCON Logic**: Modified `analyst_system_prompt.txt` to enforce strict proximity (>40km for DEFCON 3) and recency (<72h).

#### C. Map & Evacuation (Req D/B4)
- **Map Update**: Implemented visual indicators for stale threats (>48h) and verified kinetic weapon radii.
- **Evacuation Fallback**: Ensured non-null fallback objects in both Python and Dart parsing.

### Session H: Final Polish (Golden Master)
**Date:** 2026-01-08
**Objective:** Final Clean-up and Code Hygiene.

**Key Changes:**
1. **Lint Fixes (Android)**:
   - Added `const` modifiers to static Text widgets in `_showCitations` (performance).
   - Switched concatenation to string interpolation for distance display (`... km`).
2. **Artifact Finalization**:
   - `task.md` updated with H-series tasks (Linting).
   - Confirmed "Golden Master" state for all modules.

**Status:**
- **System**: STABLE / PRODUCTION READY
- **Known Issues**: None.

### Session I: Report Formatting & Logic Tuning
**Date:** 2026-01-08
**Objective:** Refine Intelligence Reports and Calibrate DEFCON Sensitivity.

**Key Changes:**
1. **Intel Report Formatting (Backend)**:
   - Upgraded Gemini prompt in `views.py` (`intel_citations`) to enforce a strict `Type/Date/Summary` format.
   - Mandated explicit inline citations (e.g., `[Source: BBC]`) for every claim.
2. **DEFCON Calibration (Backend)**:
   - Modified `analyst_system_prompt.txt` to include a "Safe Zone Exclusion" rule.
   - Zip Codes like 32110 (and US/EU in general) are explicitly prevented from triggering DEFCON 3 solely on "Global Tension" without verified local threats.

**Status:**
- **System**: REBOOTED & LIVE.
- **Verification**: Formatting and logic rules applied to active server process.

### Session I.2: Formatting Strictness
**Date:** 2026-01-08
**Objective:** Enforce Rigid Intel Report Formatting.

**Key Changes:**
1. **Views Logic**:
   - Replaced natural language prompt with a strict **Template-Based Prompt**.
   - Explicitly demanded `Type/Date/Summary` structure.
   - Re-emphasized mandatory inline citations.

**Status:**
- **System**: REBOOTED & LIVE.

### Session I.3: Force-Header Injection
**Date:** 2026-01-08
**Objective:** Guarantee Date Display in Reports.

**Key Changes:**
1. **Views Logic**:
   - Switched from "Prompt-Based Formatting" to **"Programmatic Injection"**.
   - The Python backend now prepends `**TYPE:** ... **DATE:** ...` to the Gemini output.
   - This bypasses model variability and guarantees the Date header is always present.

**Status:**
- **System**: REBOOTED & LIVE.
- **Verification**: Headers are now hardcoded requirements.

### Session I.4: Mobile UI Date Fix
**Date:** 2026-01-08
**Objective:** Fix Missing Date in SitRep List Cards.

**Key Changes:**
1. **Main.dart**:
   - Updated `SitRepView` to display `${e.topic} // ${e.date}` in the card header.
   - Used `Expanded` widget to handle overflow gracefully.
   - Rebooted Android App to apply changes.

**Status:**
- **System**: REBOOTED & LIVE.

---

## 🏆 GOLDEN MASTER DESIGNATION
**Date:** 2026-01-08
**Version:** 1.0.0 (Release Candidate)
**Status:** ALL SYSTEMS GO.
- Intelligence Features: Verified (Strict Formatting).
- DEFCON Logic: Tuned (Safe Zone Exclusion).
- UI/UX: Polished (Date Visibility, Citations).
- Backend: Optimized (Deduplication, Headers).

**Action:** Saved & Pushed to Main.

### Session: Enhancing Sentinel Intelligence Features (Continued)
**Date:** 2026-01-15
**Objective:** Enable GUI Requirements for Confidence Labels and Filtering.

**Key Changes:**
1. **Analyst Prompt Schema**:
   - Updated `analyst_system_prompt.txt` to include `confidence_score` and `type` fields in `sitrep_entries` schema.
   - Enabling structured parsing for frontend display (Confidence %, Report Type).

## Session: Enhancing Sentinel Intelligence Features
**Date:** 2026-01-08

### Prompts Issued:
1.  **Initial Objective:** Implement Clickable SITREP Reports, Fix News DRIFT, Improve Analyst Prompt.
2.  **Dev Stack Compliance:** Adhere to `AI_AGENT_READ_THIS`.
3.  **Intelligence Logic:** Implemented MongoDB-backed status/news persistence.

**Technical Implementation Details:**
- **SitRep:** Transitioned to structured `SitRepEntry` objects.
- **News Anti-Drift:** Implemented MD5 fingerprinting/UTC normalization.
- **DEFCON Logic:** Enforced strict proximity (>40km for DEFCON 3) and recency (<72h).

## Session H: Final Polish (Golden Master)
**Date:** 2026-01-08
**Version:** 1.0.0 (Release Candidate)
**Status:** STABLE / PRODUCTION READY.
- **Events:** Confirmed "Golden Master" state.

## Session I: Report Formatting & Logic Tuning
**Date:** 2026-01-08
**Key Changes:**
1. **Intel Report Formatting**: Enforced strict `Type/Date/Summary` format with inline citations.
2. **DEFCON Calibration**: Added "Safe Zone Exclusion" rule (e.g., US/EU never triggers DEFCON 3 alone).

## Session I.2: Formatting Strictness
**Date:** 2026-01-08
**Key Changes:**
- Replaced natural language prompt with **Template-Based Prompt**.
- Explicitly demanded `Type/Date/Summary` structure.

## Session I.3: Force-Header Injection
**Date:** 2026-01-08
**Key Changes:**
- Switched to **Programmatic Injection** of headers (`**TYPE:** ...`) to guarantee Date display.

## Session I.4: Mobile UI Date Fix
**Date:** 2026-01-08
**Key Changes:**
- Updated `Main.dart` to display `${e.topic} // ${e.date}`.

2026-01-15 | AntiGravity | Updated `analyst_system_prompt.txt` to include `confidence_score` and `type` in `sitrep_entries` schema. | Enable GUI requirements for Confidence Labels and Filtering. | User Request
2026-01-20 | Sentinel-Agent | Verified Jobs API Backend using verify_jobs_api.py (success). | Ensure backend readiness for Admin Console integration. | User Request
2026-01-20 | Sentinel-Agent | Built Flutter Web App and launched locally on port 8080. | User requested local verification of Frontend. | User Request
2026-01-20 | Sentinel-Agent | CANCELLED VPS Deployment. Created local launch plan only. | User strictly forbade touching VPS. | User Constraint
2026-01-20 | Sentinel-Agent | Debugging 404 Error on "OS Tab" (Jobs/System). Investigating JobsAuthGate and SystemView for hardcoded paths. | resolving post-launch bugs. | User Request
2026-01-21 | Sentinel-Agent | Launched Local Backend (Port 8000) to support Flutter Web App. | Fix 404 errors in app. | User Request
2026-01-21 | Sentinel-Agent | Replaced `python -m http.server` with `serve_spa.py` (Port 8080) to fix SPA routing 404s. | Fix 404 errors on refresh. | Debug
2026-01-21 | Sentinel-Agent | STOPPED all local servers briefly to restore iOS App VPS connection. | Restore prior state. | User Request
2026-01-21 | Sentinel-Agent | Relaunched Backend on `127.0.0.1:8000` (Strict Localhost) to isolate from iOS App. | Fix Web App while preserving iOS VPS access. | Debug
2026-01-21 | Sentinel-Agent | Relaunched SPA Server on `localhost:8080`. | Restore Web App. | Debug
2026-01-21 | Sentinel-Agent | Verified Backend Health (curl 127.0.0.1:8000/intel/status -> 200 OK). | Debug Confirmation. | Debug
2026-01-21 | Sentinel-Agent | Rebuilding Flutter Web App to ensure `kIsWeb` logic points to local backend. | Fix "Analyst 404" error. | Debug

## Session: Jobs Board Redesign
**Date:** 2026-01-21
**Objective:** Mission-aligned redesign of Jobs module with employer verification gate.

### Key Changes:
1. **db_models.py**:
   - Added employer verification fields: `organization_name`, `organization_type`, `verification_doc_url`, `employer_verified`, `employer_verified_at`.
   - Added worker urgency field: `worker_urgency` (critical/high/available).

2. **views.py (auth_register)**:
   - Employers must provide `organization_name` and `organization_type`.
   - Employers start as `employer_verified=False` (pending admin approval).
   - Response includes "pending_verification" status for employers.

3. **views.py (create_listing)**:
   - Added verification gate: Unverified employers blocked from posting jobs.
   - Added new listing fields: `skills_required`, `duration`.

4. **views.py (admin endpoints)**:
   - New: `admin_get_pending_employers` - Lists employers awaiting verification.
   - New: `admin_verify_employer` - Approve/Reject employer verification.

5. **urls.py**:
   - Added routes: `/admin/employers/pending`, `/admin/employers/verify`.

**Status:**
- **Employer Registration**: Complete with verification gate.
- **Admin Endpoints**: Complete.
- **Next Phase**: Create Listing form (MVL) and View own listings.

2026-01-21 | Sentinel-Agent | Updated `CreateListingScreen` with `duration` dropdown (72h/7d/14d/30d/Ongoing) and `skills_required` filter chips (13 skills). | Complete MVL form per redesign plan. | Execution
2026-01-21 | Sentinel-Agent | Confirmed `JobsDashboard` already has My Listings tab (index 2) with `_fetchMyListings()`. | Verify View Own Listings feature exists. | Verification
2026-01-21 | Sentinel-Agent | Flutter Web build successful. Phase 2 complete. | All employer flow tasks finished. | Verification
2026-01-22 | Sentinel-Agent | Executed regression testing for Jobs V2. Fixed 404 launch errors by starting backend. Created Regression README. | User Request | User Request
2026-01-22 | Sentinel-Agent | Ingested `Naming_Conventions.md` as strict governance for Directory, DB, API, and Coding attributes. | User Directive | User Request
2026-01-27 | Antigravity | ENHANCEMENT: Upgraded Worker Application Lifecycle & Messaging | Implementation of "Pending" state for chat gating, notification settings, and detailed application views. | User Request
