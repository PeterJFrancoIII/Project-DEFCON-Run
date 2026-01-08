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
