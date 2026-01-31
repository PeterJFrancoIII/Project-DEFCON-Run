# Ultra Master Program Descriptor for LLM Ingestion

## 1. System Identity & Core Directive

- **System Name:** SENTINEL Defense System
- **Version:** 1.0.34 (Production)
- **Repository:** [GitHub - Project-DEFCON-Run](https://github.com/PeterJFrancoIII/Project-DEFCON-Run)
- **Primary Directive:** To mitigate civilian risk in high-kinetic conflict zones by providing real-time, AI-verified intelligence, predictive forecasting, and evacuation logistics.
- **Operational Philosophy:** "Safety over Speed." The system employs a **Human-In-The-Loop (HITL)** architecture where high-severity alerts (DEFCON 1-2) are artificially gated until human verification is received.

---

## 2. Architectural Topology

The system operates on a decentralized **Client-Server-Controller** topology.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         SENTINEL ARCHITECTURE                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│    ┌─────────────────┐         ┌─────────────────┐                      │
│    │  Tactical       │         │  Command        │                      │
│    │  Interface      │◄───────►│  Controller     │                      │
│    │  (Flutter)      │         │  (Django Admin) │                      │
│    └────────┬────────┘         └────────┬────────┘                      │
│             │                           │                                │
│             │         ┌─────────────────┴────────────────┐              │
│             │         │      Intelligence Node            │              │
│             └────────►│      (Django Backend)             │◄────────┐   │
│                       │                                   │         │   │
│                       │  ┌─────────────────────────────┐ │         │   │
│                       │  │ Atlas G3 Pipeline           │ │         │   │
│                       │  │ Gate1 → Gate2Base → Gate2R  │ │         │   │
│                       │  └─────────────────────────────┘ │         │   │
│                       │                                   │         │   │
│                       │  ┌─────────────────────────────┐ │         │   │
│                       │  │ Jobs V2 Module              │ │         │   │
│                       │  │ Auth → Listings → Apps      │ │         │   │
│                       │  └─────────────────────────────┘ │         │   │
│                       └─────────────────┬────────────────┘         │   │
│                                         │                           │   │
│                       ┌─────────────────┴────────────────┐         │   │
│                       │           MongoDB                 │         │   │
│                       │  sentinel_intel | jobs_users     │         │   │
│                       │  jobs_posts | jobs_applications  │         │   │
│                       └──────────────────────────────────┘         │   │
│                                                                     │   │
│    ┌─────────────────┐                                             │   │
│    │    Website      │─────────────────────────────────────────────┘   │
│    │    (React)      │                                                  │
│    └─────────────────┘                                                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.1. The Intelligence Node (`/Server Backend`)
- **Role:** The "Brain". Handles data ingestion, deductive reasoning, and state persistence.
- **Tech Stack:** Python 3.9+, Django 4.1.13, MongoDB (Application Data), SQLite (Session Data).
- **AI Engine:** 
  - Gemini 3 Pro (Main Analyst & Jobs Analyst)
  - Gemini 2.5 Flash Lite (Translation & Gate 1)
  - Gemini 2.5 Flash (Gate 2 Base)
  - Gemini 3 Flash (Gate 2 Reinforced)
- **Key Libraries:** `genai`, `shapely` (Geospatial), `feedparser` (OSINT), `pymongo`.

### 2.2. The Tactical Interface (`/Android Frontend`)
- **Role:** The "Face". Visualizes threat vectors and provides navigation.
- **Tech Stack:** Flutter (Dart), Provider (State Management), `flutter_map` (OpenStreetMap).
- **Key Logic:** Ephemeral ID rotation (PDPA), Offline-First Architecture, Polling intervals (15s).

### 2.3. The Command Controller (`/Admin Console`)
- **Role:** The "Gavel". Allows human override of AI decisions.
- **Tech Stack:** Django Templates, HTMX, Bootstrap 5.
- **Key Logic:** 2FA (TOTP) Authentication, Prompt Injection, Exclusion Zone Management.

### 2.4. The Website (`/Website`)
- **Role:** Public-facing marketing and information portal.
- **Tech Stack:** React, Vite, TypeScript.
- **Key Features:** System status display, investor access, donation portal.

---

## 3. Core Modules

### 3.1. Atlas G3 Pipeline (`/Server Backend/core/gates`)

The multi-gate news verification system:

| Gate | File | AI Model | Purpose |
|------|------|----------|---------|
| Gate 1 | `gate_1_ingest.py` | Gemini 2.5 Flash Lite | Initial ingestion, translation, deduplication |
| Gate 2 Base | `gate_2_base.py` | Gemini 2.5 Flash | Threat classification, DEFCON assessment |
| Gate 2 Reinforced | `gate_2_reinforced.py` | Gemini 3 Flash | High-confidence verification for DEFCON 1-2 |

**Pipeline Flow:**
```
RSS/News Feed → Gate 1 (Ingest) → Gate 2 Base (Classify) → Gate 2 Reinforced (Verify) → MongoDB
```

### 3.2. Jobs V2 Module (`/Server Backend/jobs_v2`)

Employment platform connecting workers with crisis-response organizations.

**API Structure:**
| View File | Endpoints |
|-----------|-----------|
| `views/auth.py` | Login, Register, Token management |
| `views/listings.py` | Create, Search, Filter job postings |
| `views/applications.py` | Apply, Accept, Reject, Chat messaging |
| `views/admin.py` | Employer verification, user management |
| `views/moderation.py` | Reporting and content moderation |
| `views/uploads.py` | File/image upload handling |

**Application Lifecycle:**
```
applied → pending (Chat Unlock) → accepted (Contractual) → completed
```

**Key Constraints:**
- Chat is STRICTLY disabled until status is `pending` or `accepted`
- Employers must be admin-verified before posting jobs
- Notification settings customizable for "Pending" vs "Non-Pending" alerts

### 3.3. MongoDB Collections

| Collection | Purpose |
|------------|---------|
| `sentinel_intel` | Threat intelligence data |
| `intel_history` | Historical intelligence records |
| `news_index` | OSINT news with MD5 deduplication |
| `system_status` | Server health and observability |
| `jobs_users` | Jobs V2 user accounts |
| `jobs_posts` | Job listings |
| `jobs_applications` | Worker applications |

---

## 4. Data Schema Registry

### 4.1. Master Intelligence Object (`IntelDetails`)

```json
{
  "zip_code": "10110",
  "country": "TH",
  "defcon_status": 3,
  "is_certified": false,
  "summary": [
    "ASSESSMENT: Artillery detected in Preah Vihear sector.",
    "** ALERT: UNCONFIRMED RATING **"
  ],
  "tactical_overlays": [
    {
      "name": "Preah Vihear",
      "lat": 14.3914, "lon": 104.6804,
      "radius": 40000.0,
      "type": "Artillery",
      "last_kinetic": "2025-12-15"
    }
  ],
  "evacuation_point": {
    "name": "Bunker Alpha",
    "lat": 14.1, "lon": 103.5,
    "distance_km": 12.4,
    "reason": "Hardened Structure"
  },
  "predictive": {
    "forecast_summary": ["Expect escalation within 24h."],
    "forecast_trend": "Rising",
    "risk_probability": 85,
    "defcon": 2
  },
  "sitrep_entries": [
    { "id": "a1b2", "topic": "Shelling", "summary": "...", "date": "..." }
  ],
  "forecast_entries": [
     { "topic": "Troop Movement", "prediction": "...", "rationale": "..." }
  ],
  "last_updated": "2026-01-13T12:00:00Z"
}
```

### 4.2. Jobs User Object

```json
{
  "_id": "ObjectId",
  "user_id": "usr_1234567890",
  "email": "user@example.com",
  "password_hash": "bcrypt_hash",
  "role": "worker|employer|both",
  "display_name": "John Doe",
  "organization_name": "Relief Org",
  "organization_type": "NGO|Government|Private",
  "employer_verified": true,
  "employer_verified_at": "2026-01-15T10:00:00Z",
  "notification_settings": {
    "pending_alerts": true,
    "non_pending_alerts": false
  },
  "created_at": "2026-01-01T00:00:00Z"
}
```

---

## 5. AI Prohibitions (CRITICAL)

These rules are **IMMUTABLE** and must never be bypassed by any AI agent:

1. **No raw news feeds** - All news must pass through Atlas G3 gates
2. **No Drift Guard/Compliance Gate bypass** - Exclusion zones must always be enforced
3. **No auto-certify DEFCON 1-2** - High-severity must have human verification
4. **Schemas outrank implementations** - Data contracts are sacred
5. **Rules over heuristics** - Label uncertainty, never escalate

---

## 6. Key File Locations

### Backend Core
| File | Purpose |
|------|---------|
| `core/views.py` | Main API endpoints, AI orchestration |
| `core/urls.py` | URL routing configuration |
| `core/settings.py` | Django settings |
| `core/atlas_schema.py` | Atlas pipeline schema definitions |
| `core/compliance.py` | Exclusion zone enforcement |
| `core/geo_utils.py` | Geospatial calculations |
| `portal_views.py` | Admin console views |

### Frontend Core
| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry, state management |
| `lib/jobs_module.dart` | Jobs V2 integration |
| `lib/jobs_v2/api.dart` | Jobs API client |
| `lib/jobs_v2/screens/*.dart` | UI screens |

---

## 7. Environment Variables

| Variable | Description | Location |
|----------|-------------|----------|
| `GEMINI_API_KEY` | Google AI API key | `api_config.py` or env |
| `MONGODB_URI` | MongoDB connection string | `settings.py` |
| `DEBUG` | Django debug mode | `settings.py` |
| `SECRET_KEY` | Django secret key | `settings.py` |

---

## 8. Deployment

### Docker Production
```bash
cd "Server Backend"
docker-compose -f docker-compose.prod.yml up -d
```

### Local Development
```bash
# Backend
cd "Server Backend"
sh run_public.sh

# Frontend
cd "Android Frontend/Sentinel - Android"
flutter run

# Website
cd Website
npm run dev
```

---

## 9. System Governance Rules

**CRITICAL RULE**: This document (`MASTER_DESCRIPTION.md`) is the **Single Source of Truth (SSOT)** for the Sentinel System. All architectural changes, core identity updates, and metric tracking must be committed directly to this file.

**NAMING STANDARDS**: Strict adherence to [Naming_Conventions.md](Naming_Conventions.md) is required for all new code, database schemas, and API definitions.

**MERGE PROTOCOL**: See [MERGE_PROTOCOL_AND_GOVERNANCE.md](MERGE_PROTOCOL_AND_GOVERNANCE.md) for branch management rules.

---

## 10. Version History

| Date | Version | Changes |
|------|---------|---------|
| 2026-01-31 | 1.0.34 | Repository push to GitHub, documentation overhaul |
| 2026-01-30 | 1.0.33 | Atlas G3 + Jobs V2 + Admin Console merge |
| 2026-01-27 | 1.0.32 | Worker Application Lifecycle & Messaging enhancements |
| 2026-01-22 | 1.0.31 | Regression testing suite, naming conventions |
| 2026-01-21 | 1.0.30 | Jobs V2 employer verification, employer flow |
| 2026-01-08 | 1.0.0 | Golden Master release |

---

*End of Ultra Master Descriptor. System State: Canonical.*
