# Build and Output Log
**Project:** Sentinel Defense Technologies
**Last Verification:** 2026-01-08

## 1. Build Instructions

### Server Backend
```bash
cd "Server Backend"
source venv/bin/activate
pip install -r requirements.txt
# Mac Silicon Fix (if needed): pip install --ignore-installed --user Pillow
python manage.py runserver 0.0.0.0:8000
```
- **Port:** 8000
- **Admin:** `http://localhost:8000/admin_portal`
- **Credentials:** `PeterJFrancoIII` / [SecurePassword]

### Android Frontend
```bash
cd "Android Frontend/Sentinel - Android"
flutter pub get
flutter run
```
- **Target:** Emulator or Physical Device

## 2. Latest Output Verification

### Backend Tests (`test_new_endpoints.py`)
- **Public Config (`/config/public`):**
  - **Result:** SUCCESS (200 OK)
  - **Payload:** `{"donate_url": "...", "website_url": "..."}`
- **Intel Status (`/intel/status`):**
  - **Result:** SUCCESS (200 OK)
  - **Payload:** `{"stage": "Idle"}` (or "Analyst Running")
- **Server Logs (`/admin/ops/logs`):**
  - **Result:** SUCCESS (200 OK)
  - **Payload:** Returns last 200 lines of `server.log`.

### Frontend Verification
- **Logs:** Button appears on Loading Screen. Tapping opens modal with logs.
- **Status:** Text updates from "Connecting" -> "Analyst Running".
- **Drift:** No duplicate news items observed.
- **Citations:** Tapping SitRep item successfully lazy-loads citations.
- **Map:** Old threat data (>72h) correctly rendered as Grey/Stale.

## 3. Known Issues / Notes
- **Localhost:** Android Emulator requires `10.0.2.2` to reach localhost. Code handles this via `serverUrl` logic.
- **Gemini Keys:** Ensure `GEMINI_API_KEY` is set in `api_config.py`.
