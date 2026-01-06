# Sentinel Defense Technologies - Developer Onboarding & Launch Prompt

**To:** Development Team
**From:** Project Management
**Subject:** Sentinel System Source Code & Launch Instructions - **UPDATED**

### 🎯 Objective
You are being granted access to the **Sentinel Defense Technologies Information System (SDT-IS)** source code. Your primary objective is to get the full stack running locally, understand the architecture, and prepare to debug or create your own forks for feature development.

The system consists of four main components:
1.  **Server Backend**: Django + Intelligence Agents (Python)
2.  **Mobile Frontend**: Cross-platform App (Flutter)
3.  **Investor/Public Website**: React Web App (Vite)
4.  **Admin Console**: Mission Control & Data Management (Django Admin)

---

### 🛠 Prerequisites
Ensure your development environment has the following installed:
*   **Python 3.10+** (Backend)
*   **Node.js 18+ & npm** (Website)
*   **Flutter SDK 3.x** (Mobile App)
*   **MongoDB Community Edition** (Local database)
*   **Git**

---

### 🚀 Launch Instructions

#### 1. Server Backend (Core System)
**⚠️ CRITICAL**: For Mac users (Apple Silicon), follow the specific `Pillow` instructions below to avoid crash loops.

1.  Start your local MongoDB service (Default port `27017`).
2.  Navigate to `Server Backend`:
    ```bash
    cd "Server Backend"
    ```
3.  Create/Activate Virtual Environment:
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    ```
4.  **Install Dependencies with Pinned Versions**:
    *   To resolve conflicts between `Django`, `Djongo`, and `DRF`, ensure your `requirements.txt` has these exact versions:
        ```text
        Django==4.1.13
        djangorestframework==3.14.0
        sqlparse==0.2.4
        ```
    *   Run install:
        ```bash
        pip install -r requirements.txt
        ```
    *   **Mac Apple Silicon Fix**: If you encounter `ImportError: dlopen(... PIL/_imaging ...)` regarding architecture mismatch:
        ```bash
        pip install --ignore-installed --user Pillow
        ```

5.  **Database & User Setup**:
    *   Run Migrations:
        ```bash
        python manage.py migrate
        ```
    *   **Create Developer Superuser** (Run this one-liner):
        ```bash
        python3 -c "import os, django; os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings'); django.setup(); from django.contrib.auth.models import User; User.objects.create_superuser('PeterJFrancoIII', 'admin@sentinel.com', 'tawny9-kajxit-paFron*&%*&BJajbya78') if not User.objects.filter(username='PeterJFrancoIII').exists() else None"
        ```

6.  Start the Server:
    ```bash
    python manage.py runserver 0.0.0.0:8000
    ```
    *   **API**: `http://localhost:8000`

#### 2. Mobile Application (Android/iOS)
1.  Navigate to the project directory:
    ```bash
    cd "Android Frontend/Sentinel - Android"
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Run the app:
    *   **Android**: Launch an Emulator (`emulator-5554` recommended) or device.
    *   Run: `flutter run`

#### 3. Investor Website
1.  Navigate to directory:
    ```bash
    cd "Website"
    ```
2.  Install & Run:
    ```bash
    npm install
    npm run dev
    ```
    *   Access at: `http://localhost:5173` (or `3000` if 5173 is taken).

#### 4. 🛑 Admin Console (Mission Control)
Once the Backend (Step 1) is passing:

1.  **Open URL**: [http://localhost:8000/admin_portal](http://localhost:8000/admin_portal)
2.  **Login Credentials**:
    *   **Username**: `PeterJFrancoIII`
    *   **Password**: `tawny9-kajxit-paFron*&%*&BJajbya78`
3.  **2FA Setup**:
    *   Scan the QR code with Google Authenticator (or Authy).
    *   Input the 6-digit code.
    *   *Note: If this page errors with a 500, check the "Mac Apple Silicon Fix" in Step 1.*

---

### 🔑 Key Configuration
*   **API Keys**: Set `GEMINI_API_KEY` in environment variables or `Server Backend/Developer Inputs/api_config.py`.

**Go forth and build.**
