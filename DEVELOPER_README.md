# Developer Guide: Sentinel Defense Technologies

## Overview
This repository contains the complete source code for the Sentinel project, including the Django/Flask backend, the cross-platform Flutter frontend (Android/iOS), and the website.

## Prerequisites
Ensure you have the following installed on your development machine:
- **Python 3.10+** (for Server Backend)
- **Flutter SDK 3.x** (for Mobile App)
- **MongoDB Community Edition** (must be running locally on port 27017)
- **Docker & Docker Compose** (for containerized deployment)
- **Xcode** (Mac only, for iOS development)
- **Android Studio** (for Android development)

---

## 🚀 Quick Start

### 1. Backend Server (Django + Agents)
The backend handles API requests, runs intelligence agents, and manages data.

1.  **Navigate to directory**:
    ```bash
    cd "Server Backend"
    ```
2.  **Install Dependencies**:
    ```bash
    pip install -r requirements.txt
    ```
3.  **Database Setup**:
    - **MongoDB**: Ensure your local MongoDB service is running.
      ```bash
      # Mac (Homebrew)
      brew services start mongodb-community
      
      # Linux
      sudo systemctl start mongod
      ```
    - **Django SQLite**: Apply migrations for the admin/auth system.
      ```bash
      python3 manage.py migrate
      ```
4.  **Run Development Server**:
    ```bash
    python3 manage.py runserver 0.0.0.0:8000
    ```
    The API will be available at `http://localhost:8000`.

### 2. Mobile App (Android & iOS)
The mobile application is built with Flutter and supports both Android and iOS from a single codebase.

**Location**: `Android Frontend/Sentinel - Android`  
*(Note: Despite the parent folder name, this contains the full cross-platform Flutter project)*

1.  **Navigate to directory**:
    ```bash
    cd "Android Frontend/Sentinel - Android"
    ```
2.  **Install Packages**:
    ```bash
    flutter pub get
    ```
3.  **Run on Android**:
    - Open an Android Emulator or connect a physical device.
    - Run:
      ```bash
      flutter run
      ```
4.  **Run on iOS** (Mac only):
    - Open the iOS Simulator.
    - Run:
      ```bash
      flutter run
      ```

### 3. Backend Deployment (Docker)
For production-like environments, use Docker.

1.  **Navigate to Deployment**:
    ```bash
    cd "Server Backend/Deployment"
    ```
2.  **Build and Run**:
    ```bash
    docker-compose -f docker-compose.prod.yml up --build
    ```
    This will spin up:
    - **Web Container** (Django + Gunicorn)
    - **Nginx Container** (Reverse Proxy)

---

## 📂 Repository Structure

- **Server Backend**: Core logic, API, and Intelligence Agents.
    - `core/`: Django settings and views.
    - `scripts/`: Standalone Python scripts (`conflict_agent.py`, `api_server.py`) acting as background workers.
    - `Developer Inputs/`: Configuration files (zones, API keys).
    - `Deployment/`: Docker configurations.
- **Android Frontend**: Main Flutter project folder.
    - `Sentinel - Android/`: The actual Flutter source code (contains `android`, `ios`, `lib`).
- **iOS Frontend**: Reserved for native iOS specific modules (currently a placeholder).
- **Website**: React/Vite web application source code.

## 🔑 Configuration & API Keys

- **API Keys**: Managed in `Server Backend/Developer Inputs/api_config.py`.
    - By default, it looks for `GEMINI_API_KEY` in environment variables or falls back to the config file.
- **Database**:
    - **SQLite**: Used for Django Auth/Admin (`db.sqlite3`).
    - **MongoDB**: Used for Intelligence Data (Port 27017, DB: `sentinel_intel`).

## 🛠 Troubleshooting

- **"Connection Refused" on Android Emulator**:
    - Android Emulators access `localhost` via `10.0.2.2`. Ensure your app config points to `http://10.0.2.2:8000`.
- **MongoDB Connection Error**:
    - Verify MongoDB is running: `mongosh` or `mongo`.
- **Missing Dependencies**:
    - If a Python script fails with `ModuleNotFoundError`, run `pip install -r "Server Backend/requirements.txt"` again.
