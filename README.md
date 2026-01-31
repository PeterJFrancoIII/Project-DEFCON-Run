# Sentinel Defense System

> **Civilian Protection Through AI-Verified Intelligence**

Sentinel is a real-time threat intelligence platform designed to mitigate civilian risk in high-kinetic conflict zones through AI-verified intelligence, predictive forecasting, and evacuation logistics.

---

## 🚀 Quick Start

### Prerequisites
- Python 3.9+ with pip
- Flutter SDK (3.x)
- MongoDB (running locally or remote)
- Node.js 18+ (for Website)

### 1. Backend Server (Required First)
```bash
cd "Server Backend"
sh run_public.sh
```
- **Port**: `8000`
- **Admin Console**: `http://localhost:8000/admin_portal`

### 2. Android Mobile App
```bash
cd "Android Frontend/Sentinel - Android"
flutter pub get
flutter run
```
- Select Android Emulator when prompted
- For iOS: Requires macOS with CocoaPods (`sudo gem install cocoapods`)

### 3. Website (Marketing/Landing)
```bash
cd Website
npm install
npm run dev
```
- **Port**: `5173` (Vite default)

---

## 📖 Documentation

| Document | Purpose |
|----------|---------|
| [MASTER_DESCRIPTION.md](MASTER_DESCRIPTION.md) | System architecture & technical specifications |
| [DEVELOPER_ONBOARDING_LAUNCH_PROMPT.md](DEVELOPER_ONBOARDING_LAUNCH_PROMPT.md) | Complete launch guide with credentials |
| [AI_README_LOCALHOST.md](AI_README_LOCALHOST.md) | AI agent guide for local development |
| [AI_README_DEPLOY.md](AI_README_DEPLOY.md) | AI agent guide for VPS deployment |
| [REGRESSION_TESTING_README.md](REGRESSION_TESTING_README.md) | Testing protocols and commands |
| [MERGE_PROTOCOL_AND_GOVERNANCE.md](MERGE_PROTOCOL_AND_GOVERNANCE.md) | Branch merge procedures |
| [Naming_Conventions.md](Naming_Conventions.md) | Code style and naming standards |

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    SENTINEL DEFENSE SYSTEM                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │   Android    │    │    Server    │    │    Admin     │       │
│  │   Frontend   │◄──►│   Backend    │◄──►│   Console    │       │
│  │   (Flutter)  │    │   (Django)   │    │   (Django)   │       │
│  └──────────────┘    └──────────────┘    └──────────────┘       │
│                             │                                    │
│                      ┌──────┴──────┐                             │
│                      │   MongoDB   │                             │
│                      │   (Intel)   │                             │
│                      └─────────────┘                             │
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │   Atlas G3   │    │   Jobs V2    │    │   Website    │       │
│  │  (Pipeline)  │    │   (Module)   │    │   (React)    │       │
│  └──────────────┘    └──────────────┘    └──────────────┘       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔧 Configuration

| Setting | Location | Description |
|---------|----------|-------------|
| AI Models | `Server Backend/core/views.py` | Gemini 3 Pro (Analysis), Gemini 2.5 Flash (Translation) |
| API Keys | `Server Backend/Developer Inputs/api_config.py` | `GEMINI_API_KEY` |
| Database | `sentinel_intel` (MongoDB) | Application data store |
| Sessions | `db.sqlite3` (SQLite) | Django session management |

---

## 📊 Project Metrics

| Metric | Value |
|--------|-------|
| **Version** | 1.0.34 (Production) |
| **Last Updated** | 2026-01-31 |
| **Repository** | [GitHub](https://github.com/PeterJFrancoIII/Project-DEFCON-Run) |

---

## 🛡️ Core Modules

### Intelligence System
- **Atlas G3 Pipeline**: Multi-gate news verification (Gate 1 → Gate 2 Base → Gate 2 Reinforced)
- **DEFCON Classification**: AI-assessed threat levels (1-5) with human-in-the-loop verification
- **Tactical Overlays**: Real-time threat visualization on maps

### Jobs V2
- **Employer Verification**: Admin-gated employer approval workflow
- **Application Lifecycle**: `applied` → `pending` → `accepted` → `completed`
- **Messaging Gate**: Chat unlocked only at `pending` or `accepted` status

### Admin Console
- **2FA Authentication**: TOTP-based security
- **Threat Certification**: Manual DEFCON 1-2 approval
- **Employer Management**: Verify/reject employer registrations

---

## 📜 License

Proprietary - Sentinel Defense Technologies Inc.
