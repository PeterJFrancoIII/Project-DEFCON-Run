# Master System Governance & Technical Context (MASTER_DESCRIPTION.md)

## 📝 Governance Protocol
This file is the **Ultimate Source of Truth** for the Sentinel System. It defines the system's identity, its modular architecture, and its restoration protocols. 

### Maintenance Rules:
- **Synchronization**: Update this file at the end of every work session.
- **Precision**: Descriptions must reflect the actual code state, not intended designs.
- **Self-Definition**: The system describes its own purpose and operational logic.

---

# System Identity: Sentinel Defense System
I am **Sentinel**, a decentralized, AI-driven civilian defense intelligence framework. My purpose is to mitigate risk for non-combatants in high-kinetic conflict zones by providing real-time threat analysis, predictive forecasting, and verified evacuation logistics.

## 🏗 Modular Architecture

### 1. Server Backend (`/Server Backend`)
- **Purpose**: I act as the central intelligence node. 
- **Core Operations**: I fetch OSINT/News data, deduplicate threats using cryptographic hashing (MD5), and orchestrate analyst models (Gemini) to generate situational reports.
- **Stack**: Python, Django 4.1.13, Djongo, MongoDB.

### 2. Mobile Frontend (`/Android Frontend`, `/iOS Frontend`)
- **Purpose**: I am the tactical interface for the user.
- **Core Operations**: I visualize threat pins on interactive maps, display structured SITREPs, and provide server observability (logs/status) to the user.
- **Stack**: Flutter (Dart).

### 3. Investor Relations Website (`/Website`)
- **Purpose**: I serve as the public/corporate landing page.
- **Core Operations**: I present the project's safety mission and provide institutional transparency.
- **Stack**: React, Vite, TailwindCSS.

### 4. Admin Portal (`/Admin Console`)
- **Purpose**: I am the command-and-control dashboard.
- **Core Operations**: I allow human-in-the-loop (HITL) review for DEFCON levels and sensitive intelligence overrides.
- **Stack**: Django Template System.

---

# 🛠 Rebuild from Zero (restoration)

If I am completely wiped, follow these steps to restore me to operational capacity:

### Phase 1: Persistence Layer
1. Install MongoDB Community Edition.
2. Initialize the `sentinel_db` database.
3. Ensure the `news_index` and `system_status` collections are ready.

### Phase 2: Intelligence Node
1. Navigate to `/Server Backend`.
2. Run `pip install -r requirements.txt`.
3. Configure `GEMINI_API_KEY` in environment variables.
4. Execute `python manage.py migrate` (via Djongo).
5. Launch via `sh run_public.sh`.

### Phase 3: tactical Interface
1. Navigate to `/Android Frontend/Sentinel - Android`.
2. Run `flutter pub get`.
3. Ensure an Android Emulator is running (Loopback: `10.0.2.2`).
4. Execute `flutter run`.

### Phase 4: Public Presence
1. Navigate to `/Website`.
2. Run `npm install`.
3. Execute `npm run dev`.

---
*End of Master Description - System State: Canonical & Verified.*
