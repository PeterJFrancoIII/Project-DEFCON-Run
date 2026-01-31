# MERGE PROTOCOL & GOVERNANCE: SENTINEL PROJECT

**Status**: ACTIVE
**Effective Date**: 2026-01-30
**Event**: Post-Mortem of "Atlas G3 + Jobs V2 + Admin" Merge.

---

## 1. Core Governance Directive
**Priority Rule**: "Peter's Rules Take Precedence."

When conflicts arise between branches or documentation:
1.  **Primary Authority**: `Sentinel - Development` (Main Branch).
    *   Source of Truth: `MASTER_DESCRIPTION.md`.
    *   Security Constraints: `03-ai-usage-constraints.md`.
    *   System Identity: `01-system-identity.md`.
2.  **Secondary Context**: Fork-specific documentation (e.g., Conor's `AI_AGENT_READ_THIS.rtf`) applies *only* to the specific module being merged and *only* if it does not violate Primary Authority.

### 1.1. Unified Rulebook (Merged Context)
*   **System Identity**: Sentinel is a civilian-protection intelligence system. Safety > Speed. (From Peter).
*   **Tech Stack**: Python/Django/MongoDB/Flutter. (Shared).
*   **Agent Constraint**: AI must not auto-certify DEFCON 1-2. (From Peter).
*   **Module Constraint**: Deviations from the stack "should be avoided unless strictly necessary". (From Conor).

---

## 2. Issues Encountered (The "Why" of this Protocol)
During the Jan 30, 2026 Merge, the following critical failure modes were identified. Agents must check for these patterns in all future operations.

### 2.1. The "Silent Loss" of Admin Tools
*   **Incident**: The Admin Console (`portal_views.py` and `templates/admin`) existed in `Main` but was missing from the Target Fork (`Conor`).
*   **Failure**: A standard merge/copy operation assumed the Target Fork was a complete superset of `Main`. It was not.
*   **Result**: The Admin Console was initially deleted/lost in the merge.
*   **Lesson**: **Never assume a Fork contains the "Base" system.** Always treat `Main` as the inventory of record.

### 2.2. The "Hybrid View" Conflict
*   **Incident**: Both branches modified `core/views.py`.
    *   Main: Contained `admin_verify_threat` (Critical for Safety).
    *   Conor: Contained `run_atlas_pipeline` (Critical for Intelligence).
*   **Failure**: A file-level overwrite would have destroyed one of these critical functions.
*   **Lesson**: **File-level merging is dangerous for core controllers.** Use line-level patching or "Base + Patch" appending strategies.

### 2.3. The Workspace Constraint
*   **Incident**: Cloning to a fresh directory (`Sentinel - Merged`) outside the Agent's allowed workspace prevented automated verification.
*   **Lesson**: All merge targets must be within the Agent's authorized file tree, or the User must manually verify the final launch.

---

## 3. The New Merge Protocol (Standard Operating Procedure)

For all future merges involving `Sentinel`, the following checklist is **MANDATORY**.

### Phase 1: Inventory & Protection
- [ ] **Lock Main**: Treat the `Sentinel - Development` directory as Read-Only until the final swap.
- [ ] **Identify "Golden Assets"**: List files that MUST NOT be lost (e.g., `jobs_v2`, `admin_verify_threat`).
- [ ] **Dependency Audit**: Does the incoming code rely on new files (e.g., `atlas_schema.py`)? Add them to the copy list.

### Phase 2: safe_merge.sh Strategy
Do not rely on `git merge` for radical divergences. Use a "Constructive Merge" script:
1.  **Create Clean Target**: `mkdir Sentinel - Merged`.
2.  **Copy Main First**: `cp -r Main/* Target/`. (Ensures all Admin/Legacy tools are present).
3.  **Inject Features**: `cp -r Feature/* Target/`. (Overwrites *only* specific modules).
4.  **Patch Hybrids**:
    *   If a file exists in both, DO NOT OVERWRITE.
    *   Append the *new* functions to the *old* file (or vice versa, whichever is cleaner).
    *   *Example*: `cat admin_patch.py >> new_views.py`.

### Phase 3: Verification Gates
Before notifying the user:
- [ ] **grep "Golden Function"**: Ensure critical safety logic (e.g., `admin_verify_threat`) exists.
- [ ] **grep "New Feature"**: Ensure new logic (e.g., `run_atlas_pipeline`) exists.
- [ ] **ls "Missing Assets"**: Check for files that might have been "left behind" (e.g., `portal_views.py`).

---

## 4. Updates to MASTER_DESCRIPTION
*   **Added**: `Jobs V2` Module (Employer Verification, Worker Applications).
*   **Added**: `Atlas G3` Pipeline (Multi-Agent News Verification).
*   **Added**: `Admin Console` (Recovery confirmed).

*This document is now attached to the Project Memory.*
