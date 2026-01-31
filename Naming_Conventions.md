# Naming Conventions (Code & Data)

**Status**: ACTIVE
**Last Updated**: 2026-01-21
**Enforcement**: Strict

This document defines the correct nomenclature for the Sentinel project. All new code, database schemas, and file structures must adhere to these conventions to ensure maintainability and scalability.

---

## 1. Directory & File Structure

| Context | Convention | Example | Description |
|---------|------------|---------|-------------|
| **Root Modules** | `Proper Case - Description` | `Sentinel - Development` | Top-level project folders. |
| **Backend Modules** | `snake_case` | `jobs_v2` | Python packages/modules. |
| **Frontend Folders** | `snake_case` | `jobs_v2` | Flutter/Dart directories. |
| **Dart Files** | `snake_case.dart` | `mode_selection_screen.dart` | Flutter source files. |
| **HTML Templates** | `snake_case.html` | `admin_portal.html` | Django templates. |

---

## 2. Database (MongoDB)

| Context | Convention | Example | Description |
|---------|------------|---------|-------------|
| **Collections** | `module_entity` (snake_case) | `jobs_users` | Collections are scoped by module prefix for namespace isolation. |
| **Field Names** | `snake_case` | `trust_score` | JSON/BSON fields. |
| **Primary Keys** | `prefix_timestamp` | `usr_173750...` | Public-facing string IDs with type prefix. |

### Canonical Collections (Jobs Module)
- `jobs_users` — User accounts (worker/employer/admin)
- `jobs_posts` — Job listings
- `jobs_applications` — Worker applications to jobs
- `jobs_reports` — User/job reports (fraud/abuse)
- `jobs_moderation_actions` — Append-only audit log

### ID Prefixes (Canonical)
- **User**: `usr_` (e.g., `usr_173750...`)
- **Job**: `job_` (e.g., `job_173750...`)
- **Application**: `app_` (e.g., `app_173750...`)
- **Report**: `rpt_` (e.g., `rpt_173750...`)
- **Moderation Action**: `mod_` (e.g., `mod_173750...`)
- **Event**: `evt_` (e.g., `evt_173750...`)
- **Source**: `src_` (e.g., `src_173750...`)
- **Claim**: `clm_` (e.g., `clm_173750...`)
- **Evidence**: `evd_` (e.g., `evd_173750...`)

---

## 3. API & Networking

| Context | Convention | Example | Description |
|---------|------------|---------|-------------|
| **Base URL** | `/api/module_version/...` | `/api/jobs_v2/...` | Always versioned. |
| **Endpoints** | `snake_case` (or kebab-case) | `/auth/login` | Resource actions. |
| **Query Params** | `snake_case` | `?account_id=...` | HTTP GET parameters. |
| **Authorization** | `X-Custom-Header` | `X-Admin-Secret` | Custom headers. |

---

## 4. Coding Standards

### Python (Backend)
- **Variables/Functions**: `snake_case` (`get_pending_employers`)
- **Classes**: `PascalCase` (`JobsDB`)
- **Constants**: `UPPER_SNAKE_CASE` (`ADMIN_SECRET`)

### Dart (Frontend)
- **Variables/Functions**: `camelCase` (`loadJobsListings`)
- **Classes**: `PascalCase` (`ModeSelectionScreen`)
- **Files**: `snake_case` (`jobs_v2.dart`)

### JavaScript (Web)
- **Variables/Functions**: `camelCase` (`loadJobsListings`)
- **DOM IDs**: `kebab-case` (`#jobs-listings-table`)

---

## 5. Domain Terminology

| Term | Definition |
|------|------------|
| **Employer** | A verified user who posts jobs. |
| **Worker** | A user who applies for jobs. |
| **Listing** | A single job post (referenced as `job` in code). |
| **Application** | A worker's request to take a job. |
| **Trust Score** | 0-100 integer rating reliability. |
| **Risk Score** | 0.0-1.0 float indicating safety risk. |

---

**Note**: This file should be updated with new patterns but existing conventions should remain stable to prevent breaking changes.
