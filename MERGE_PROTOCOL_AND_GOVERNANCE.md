# MERGE PROTOCOL & GOVERNANCE: SENTINEL PROJECT

**Status**: ACTIVE  
**Effective Date**: 2026-01-31  
**Repository**: [GitHub - Project-DEFCON-Run](https://github.com/PeterJFrancoIII/Project-DEFCON-Run)

---

## 1. Core Governance Directive

### Priority Rule: "Peter's Rules Take Precedence"

When conflicts arise between branches or documentation:

| Priority | Source | Authority |
|----------|--------|-----------|
| 1 (Highest) | `Sentinel - Development` (Main Branch) | Single Source of Truth |
| 2 | `MASTER_DESCRIPTION.md` | System architecture |
| 3 | `03-ai-usage-constraints.md` | Security constraints |
| 4 | `01-system-identity.md` | System identity |
| 5 (Lowest) | Fork-specific docs | Module-scoped only |

### 1.1. Unified Rulebook

| Rule | Source | Description |
|------|--------|-------------|
| Safety > Speed | Peter | Human-in-the-loop for DEFCON 1-2 |
| Tech Stack | Shared | Python/Django/MongoDB/Flutter only |
| No Auto-Certify | Peter | AI cannot approve high-severity alerts |
| Stack Deviations | Conor | "Avoided unless strictly necessary" |

---

## 2. Lessons Learned (Post-Mortem: 2026-01-30 Merge)

### 2.1. The "Silent Loss" of Admin Tools

| Aspect | Details |
|--------|---------|
| **Incident** | Admin Console (`portal_views.py`, templates) existed in Main but missing from Target Fork |
| **Failure** | Assumed Target Fork was complete superset of Main |
| **Result** | Admin Console initially deleted/lost |
| **Lesson** | **Never assume a Fork contains the Base system. Treat Main as inventory of record.** |

### 2.2. The "Hybrid View" Conflict

| Aspect | Details |
|--------|---------|
| **Incident** | Both branches modified `core/views.py` |
| **Main** | Contained `admin_verify_threat` (Critical for Safety) |
| **Fork** | Contained `run_atlas_pipeline` (Critical for Intelligence) |
| **Lesson** | **File-level merging is dangerous. Use line-level patching.** |

### 2.3. The Workspace Constraint

| Aspect | Details |
|--------|---------|
| **Incident** | Cloning outside Agent's allowed workspace prevented verification |
| **Lesson** | **All merge targets must be within authorized file tree.** |

---

## 3. Standard Operating Procedure (SOP)

### Phase 1: Inventory & Protection

```
□ Lock Main: Treat `Sentinel - Development` as Read-Only until final swap
□ Identify Golden Assets: List critical files (jobs_v2, admin_verify_threat, etc.)
□ Dependency Audit: Check for new files the incoming code needs
□ Create Backup: Copy current Main to timestamped archive
```

### Phase 2: Constructive Merge Strategy

Do **NOT** rely on `git merge` for radical divergences. Use this script pattern:

```bash
#!/bin/bash
# safe_merge.sh

# 1. Create clean target
mkdir -p "Sentinel - Merged"

# 2. Copy Main first (preserves Admin/Legacy tools)
cp -r "Sentinel - Development"/* "Sentinel - Merged/"

# 3. Inject features (overwrites specific modules only)
cp -r "Feature-Fork/new_module"/* "Sentinel - Merged/new_module/"

# 4. Patch hybrids (append, don't overwrite)
# For conflicting files like views.py:
cat "Feature-Fork/core/new_functions.py" >> "Sentinel - Merged/core/views.py"
```

### Phase 3: Verification Gates

Before notifying user, run these checks:

```bash
# Verify Golden Functions exist
grep -r "admin_verify_threat" "Sentinel - Merged/Server Backend/" || echo "MISSING: admin_verify_threat"
grep -r "run_atlas_pipeline" "Sentinel - Merged/Server Backend/" || echo "MISSING: run_atlas_pipeline"

# Verify critical files
ls "Sentinel - Merged/Server Backend/portal_views.py" || echo "MISSING: portal_views.py"
ls "Sentinel - Merged/Server Backend/core/gates/" || echo "MISSING: gates directory"

# Verify Jobs V2 module
ls "Sentinel - Merged/Server Backend/jobs_v2/views/" || echo "MISSING: jobs_v2 views"
```

### Phase 4: Post-Merge Validation

```bash
# Start backend and verify
cd "Sentinel - Merged/Server Backend"
sh run_public.sh &

# Test critical endpoints
curl http://localhost:8000/intel/status
curl http://localhost:8000/admin_portal/
curl http://localhost:8000/api/jobs/auth/status
```

---

## 4. Git Workflow

### Branch Structure
```
main (protected)
├── feature/atlas-g3
├── feature/jobs-v2-messaging
├── fix/gate1-duplicate-key
└── release/v1.0.34
```

### Commit Message Format
```
[MODULE] Action: Description

Examples:
[Jobs V2] Add: Employer verification workflow
[Atlas G3] Fix: DuplicateKeyError in Gate 1
[Admin] Update: 2FA token validation
[Docs] Update: MASTER_DESCRIPTION.md
```

### Pull Request Checklist
```
□ All tests pass (`flutter test`, `python test_jobs_v2.py`)
□ No linting errors
□ Documentation updated if API changes
□ Golden Assets verified (grep checks)
□ MASTER_DESCRIPTION.md version bumped
```

---

## 5. Emergency Rollback Procedure

If a merge causes critical failure:

```bash
# 1. Stop all services
pkill -f "python manage.py"
pkill -f "flutter"

# 2. Restore from backup
rm -rf "Sentinel - Development"
cp -r "Sentinel - Development.backup.YYYYMMDD" "Sentinel - Development"

# 3. Restart services
cd "Sentinel - Development/Server Backend"
sh run_public.sh

# 4. Document incident in Prompt_History.md
```

---

## 6. Module Inventory (Golden Assets)

These files/directories must **NEVER** be deleted during a merge:

### Critical Backend
| Path | Purpose |
|------|---------|
| `Server Backend/portal_views.py` | Admin Console views |
| `Server Backend/core/views.py` | Main API + `admin_verify_threat` |
| `Server Backend/core/gates/` | Atlas G3 pipeline |
| `Server Backend/jobs_v2/` | Employment module |
| `Server Backend/core/compliance.py` | Exclusion zone enforcement |

### Critical Frontend
| Path | Purpose |
|------|---------|
| `Android Frontend/Sentinel - Android/lib/main.dart` | App entry |
| `Android Frontend/Sentinel - Android/lib/jobs_v2/` | Jobs UI |

### Critical Documentation
| Path | Purpose |
|------|---------|
| `MASTER_DESCRIPTION.md` | System authority |
| `Naming_Conventions.md` | Code standards |

---

## 7. Related Documentation

- [MASTER_DESCRIPTION.md](MASTER_DESCRIPTION.md) - System architecture
- [Prompt_History.md](Prompt_History.md) - Change log
- [Naming_Conventions.md](Naming_Conventions.md) - Code standards
- [REGRESSION_TESTING_README.md](REGRESSION_TESTING_README.md) - Test protocols

---

*This document is part of Project Memory and must be consulted before any merge operation.*

*Last Updated: 2026-01-31*
