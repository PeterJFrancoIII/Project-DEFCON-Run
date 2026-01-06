# ReadMe - Sentinel Defense System

> **🚀 Antigravity Quick Build & Launch Prompt**  
> For a complete, step-by-step developer guide to launching the full stack (including Mac fixes and credentials), see:  
> [DEVELOPER_ONBOARDING_LAUNCH_PROMPT.md](DEVELOPER_ONBOARDING_LAUNCH_PROMPT.md)

## 1. Backend Server (Required)
The backend powers the API, AI Agency, and Admin Console.

```bash
cd "Server Backend"
sh run_public.sh
```
*   **Port**: `8000`

## 2. Mobile Application (Flutter)
The mobile app runs on both Android and iOS from the same codebase.

### **Android**
```bash
cd "Android Frontend/Sentinel - Android"
flutter run
```
*   *Select the Android Emulator if prompted.*

### **iOS** (macOS Only)
```bash
cd "Android Frontend/Sentinel - Android"
flutter run
```
*   *Select the iOS Simulator if prompted.*
*   *Note: Requires `CocoaPods` installed (`sudo gem install cocoapods`).*

## 3. Admin Console (Mission Control)
- **URL**: `http://localhost:8000/admin_portal`
- **Creds**: See [Launch Prompt](DEVELOPER_ONBOARDING_LAUNCH_PROMPT.md).


## 4. Configuration
- **AI Models**: Configured in `Server Backend/core/views.py`.
- **API Keys**: Set `GEMINI_API_KEY` in environment or `api_config.py`.
- **Database**: Uses local MongoDB (`sentinel_intel`).

## Status (Golden Master)
- **Analyst**: `gemini-3-pro-preview`
- **Translator**: `gemini-2.5-flash-lite`
