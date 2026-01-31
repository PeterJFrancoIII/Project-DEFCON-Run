# Prompt History & System Governance

## 📝 Maintenance Protocol

This file acts as the **Final Source of Truth** for the technical evolution of the Sentinel Project. AI models MUST maintain this log with high precision.

### Principles
- **Traceability**: Every prompt that affects logic, architecture, or code behavior must be logged.
- **Granularity**: High technical detail is required. Cite specific files, functions, and logic changes.
- **Exclusion**: Do NOT log administrative or non-technical prompts (e.g., system reboots, terminal cleanup).
- **Categorization**: Group entries into **Build**, **Framework**, **Updates**, or **Debug**.

### Level of Detail Expected
- **Build/Updates**: Describe the new feature and the specific code modules affected.
- **Framework**: Note changes to the stack or persistence layer.
- **Debug**: Document the root cause and the specific resolution.

---

# Version History

## v1.0.34 - Repository Migration (2026-01-31)

### Changes
| Agent | Action | Details | Trigger |
|-------|--------|---------|---------|
| Antigravity | Initialized git repository in `Sentinel - Development` | Created `.gitignore`, excluded credentials, node_modules, mongodb_data | User Request |
| Antigravity | Force pushed to GitHub `main` branch | https://github.com/PeterJFrancoIII/Project-DEFCON-Run | User Request |
| Antigravity | Updated all project documentation | README.md, MASTER_DESCRIPTION.md, Prompt_History.md, REGRESSION_TESTING_README.md, MERGE_PROTOCOL_AND_GOVERNANCE.md | User Request |

---

## v1.0.33 - Atlas G3 + Jobs V2 Merge (2026-01-30)

### Changes
| Agent | Action | Details | Trigger |
|-------|--------|---------|---------|
| Antigravity | Merged Conor's fork with Peter's fork | Created unified `Sentinel - Merged` directory | User Request |
| Antigravity | Resolved Gate 1 `DuplicateKeyError` | Fixed MongoDB upsert logic in `gate_1_ingest.py` | Debug |
| Antigravity | Verified Atlas G3 pipeline flow | Gate 1 → Gate 2 Base → Gate 2 Reinforced | Verification |
| Antigravity | Recovered Admin Console | Restored `portal_views.py` and admin templates | Debug |

---

## v1.0.32 - Worker Application Lifecycle Enhancement (2026-01-27)

### Changes
| Agent | Action | Details | Trigger |
|-------|--------|---------|---------|
| Antigravity | Implemented "Pending" state for applications | Chat gating, notification settings | User Request |
| Antigravity | Added application detail views | `application_detail_screen.dart` with messaging | User Request |
| Antigravity | Enhanced notification settings | Per-status notification toggles | User Request |

---

## v1.0.31 - Regression Testing & Naming Conventions (2026-01-22)

### Changes
| Agent | Action | Details | Trigger |
|-------|--------|---------|---------|
| Sentinel-Agent | Created regression testing suite | `test/jobs_v2/` with API and widget tests | User Request |
| Sentinel-Agent | Ingested `Naming_Conventions.md` | Strict governance for all code attributes | User Directive |

---

## v1.0.30 - Jobs Board Redesign (2026-01-21)

### Changes
| Agent | Action | Details | Trigger |
|-------|--------|---------|---------|
| Sentinel-Agent | Added employer verification fields | `db_models.py`: org_name, org_type, verification_doc_url | User Request |
| Sentinel-Agent | Implemented verification gate | Unverified employers blocked from posting | User Request |
| Sentinel-Agent | Created admin endpoints | `admin_get_pending_employers`, `admin_verify_employer` | User Request |
| Sentinel-Agent | Updated `CreateListingScreen` | Duration dropdown, skills_required chips | Execution |
| Sentinel-Agent | Launched Backend + SPA servers | Port 8000 (Django), Port 8080 (Flutter Web) | Debug |

---

## v1.0.0 - Golden Master Release (2026-01-08)

### Session H: Final Polish
**Objective:** Final Clean-up and Code Hygiene.

**Key Changes:**
1. **Lint Fixes (Android)**: Added `const` modifiers, string interpolation
2. **Artifact Finalization**: Confirmed "Golden Master" state

### Session I: Report Formatting & Logic Tuning
**Objective:** Refine Intelligence Reports and Calibrate DEFCON Sensitivity.

**Key Changes:**
1. **Intel Report Formatting**: Enforced strict `Type/Date/Summary` format with inline citations
2. **DEFCON Calibration**: Added "Safe Zone Exclusion" rule (US/EU never triggers DEFCON 3 alone)
3. **Programmatic Header Injection**: Backend prepends `**TYPE:** ... **DATE:** ...` to AI output
4. **Mobile UI Date Fix**: Updated `Main.dart` to display `${e.topic} // ${e.date}`

---

## Initial Release Sessions (2026-01-08)

### Session: Enhancing Sentinel Intelligence Features

**Prompts Issued:**
1. Implement Clickable SITREP Reports (on-demand citations)
2. Fix News "DRIFT" (anti-drift module, UTC normalization)
3. Improve Analyst Prompt & DEFCON Accuracy
4. Implement Clickable Forecast Topics
5. Integrate Historical Training Context

**Technical Implementation:**

#### A. Server Observability
- Created `/intel/status` endpoint in Django
- Added terminal icon and polling logic to `LoadingPage`

#### B. SITREP & Data Integrity
- Transitioned SITREP from plain text to structured `SitRepEntry` objects
- Implemented MD5 fingerprinting and UTC normalization in MongoDB
- Modified `analyst_system_prompt.txt` for strict proximity (>40km for DEFCON 3)

#### C. Map & Evacuation
- Implemented visual indicators for stale threats (>48h)
- Ensured non-null fallback objects in Python and Dart

#### D. GUI Sync & Localhost Debugging
- Fixed Flutter app defaulting to Production VPS
- Rewrote `determineServerUrl` in `main.dart` for correct emulator loopback (`10.0.2.2`)
- Fixed `NameError: name 'get_msg_hash' is not defined` in `views.py`

---

# AI Model Configuration History

| Date | Model Assignment | Purpose |
|------|------------------|---------|
| 2026-01-30 | Gemini 3 Pro | Main Analyst & Jobs Analyst |
| 2026-01-30 | Gemini 2.5 Flash Lite | Translation & Gate 1 |
| 2026-01-30 | Gemini 2.5 Flash | Gate 2 Base |
| 2026-01-30 | Gemini 3 Flash | Gate 2 Reinforced |
| 2026-01-08 | gemini-3-pro-preview | Initial reasoning engine |

---

# Critical Debug Log

| Date | Issue | Resolution | File(s) |
|------|-------|------------|---------|
| 2026-01-30 | DuplicateKeyError in Gate 1 | Fixed MongoDB upsert with `update_one` | `gate_1_ingest.py` |
| 2026-01-21 | 404 on SPA refresh | Created `serve_spa.py` for proper routing | `serve_spa.py` |
| 2026-01-21 | iOS App losing VPS connection | Bound backend to `127.0.0.1:8000` (strict localhost) | `run_public.sh` |
| 2026-01-08 | `NameError: get_msg_hash` | Added missing hash utility function | `views.py` |
| 2026-01-08 | Flutter using wrong server URL | Rewrote `determineServerUrl` logic | `main.dart` |

---

*Last Updated: 2026-01-31*
