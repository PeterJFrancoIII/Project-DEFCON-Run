# AI Protocol: LocalHost Envrionment

**OBJECTIVE**: Initialize the full Sentinel Defense System on a local machine (macOS) for development and testing.

## 1. System Check & Configuration
**Warning**: Ensure these files are configured BEFORE starting runtimes.

### Backend Config
- **File**: `Server Backend/Developer Inputs/api_config.py`
- **Action**: Ensure `GEMINI_API_KEY` is set to a valid Development Key.

### Mobile Config
- **File**: `Android Frontend/Sentinel - Android/lib/main.dart`
- **Action**: **No Action Required**.
  - The app now automatically attempts to connect to the **VPS** first.
  - If unreachable (e.g., local dev), it falls back to **Localhost (10.0.2.2)**.

## 2. Launch Sequence (Execute in Order)

### Component A: Backend Server
**Terminal 1**:
```bash
cd "Server Backend"
# Launches Django on 0.0.0.0:8000 (accessible to Emulator)
sh run_public.sh
```
*   **Success Indicator**: `Starting development server at http://0.0.0.0:8000/`

### Component B: Website
**Terminal 2**:
```bash
cd "Website"
npm run dev
```
*   **Success Indicator**: `Local: http://localhost:3000/`

### Component C: Mobile App (Android)
**Terminal 3**:
```bash
cd "Android Frontend/Sentinel - Android"
# 1. List Emulators
flutter emulators
# 2. Launch Emulator (Example ID)
flutter emulators --launch Medium_Phone_API_36.1
# 3. Run App (Wait for Emulator to boot)
flutter run
```

## 3. Verification Protocol
1.  **Backend Health**: Visit `http://localhost:8000/admin_portal`.
2.  **App Connectivity**: App should display "INITIALIZE UPLINK" -> "GATHERING INTEL" -> "DEFCON [X]".
    *   *If stuck on "GATHERING INTEL"*: Check Backend Terminal for `403` or `400` errors (API Key issues).
