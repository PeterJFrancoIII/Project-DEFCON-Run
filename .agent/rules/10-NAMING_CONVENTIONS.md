---
trigger: always_on
---

# .agent/rules/NAMING_CONVENTIONS_ENFORCEMENT.md

Status: ACTIVE  
Last Updated: 2026-01-21  

Purpose
Enforce consistent naming conventions across all code, database schemas, and file structures.

Canonical Reference
Single source of truth: `/Naming_Conventions.md` (project root)

Critical Rules

1. ID Prefixes (MANDATORY)
All public-facing IDs MUST use the following prefixes:
- User: `usr_` (never `u_`)
- Job: `job_`
- Application: `app_`
- Report: `rpt_`
- Moderation Action: `mod_` (never `act_`)
- Event: `evt_`
- Source: `src_`
- Claim: `clm_`
- Evidence: `evd_`

2. Collection Names (MANDATORY)
Collections MUST use module-prefixed names for namespace isolation.
- Allowed: `jobs_users`, `jobs_posts`, `jobs_applications`
- Forbidden: `users`, `posts` (too generic; no isolation)

3. Field Names
- All database fields use `snake_case`
- `status` is acceptable within single-type documents
- Ambiguous names (`data`, `type`, `value`) are forbidden without explicit context

4. Code Standards
Python:
- Variables / functions: `snake_case`
- Classes: `PascalCase`
- Files: `snake_case.py`

Dart:
- Variables / functions: `camelCase`
- Classes: `PascalCase`
- Files: `snake_case.dart`

JavaScript:
- Variables / functions: `camelCase`
- Classes: `PascalCase`
- Files: `snake_case.js`

Enforcement
- New code MUST comply before merge
- Existing code MUST be migrated when modified
- Violations block PRs until resolved