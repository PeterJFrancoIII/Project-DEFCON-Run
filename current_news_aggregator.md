# OSINT System Architecture: "News Aggregator" (Active)

This document outlines the active intelligence system used by the **Sentinel** mobile application. It is a "Lazy Loading" / On-Demand pipeline that generates threat reports based on the user's specific location (Zip Code).

**Status:** ACTIVE
**Type:** Zip-Code Based News Aggregator
**Trigger:** On-Demand (User Request)

---

## 1. The Client (Mobile App)
The frontend is a Flutter application that polls the backend for intelligence reports.

- **Location:** `Android Frontend/Sentinel - Android`
- **Key File:** `lib/main.dart`
- **Behavior:**
  - Determines server URL (Localhost vs. VPS).
  - Sends a GET request to `/intel` with the user's Zip Code:
    ```dart
    "$serverUrl/intel?zip=$userZip&country=$userCountry..."
    ```
  - Handles "calculating" states by polling until the report is ready.

## 2. The Backend (The Logic)
The core logic resides in a Django backend. It handles the API request, checks for cached data, and orchestrates the intelligence gathering "Mission" if needed.

- **Location:** `Server Backend/core`
- **Key Files:**
  - `views.py`: Contains the `intel_api` function which is the main entry point. It manages the `MISSION_QUEUE` and caching logic (4-hour freshness).
  - `urls.py`: Defines the routing for `/intel`.
  - `compliance.py`: Checks if the requested location is in a restricted "Exclusion Zone" before processing.

## 3. The Brain (Configuration & Inputs)
The intelligence analysis is driven by specific prompts and configuration files.

- **Location:** `Server Backend/Developer Inputs`
- **Key Files:**
  - `analyst_system_prompt.txt`: The system prompt that instructs the AI (Gemini) to act as "SENTINEL-01" and generate the JSON threat report.
  - `OSINT Sources.csv` / `thailand_postal_codes_complete.csv`: Support files for location validation and source tracking.
  - `news_index` (MongoDB): Used to store hashes of article titles/links to prevent processing the same story twice (Drift Detection).

---

## 4. Workflows

### The "Mission" (Execution Flow)
1.  **Request:** User app hits `/api/intel?zip=XXXXX`.
2.  **Safety Check:** Backend parses Zip Code and checks `compliance.py` for exclusion zones.
3.  **Cache Check:** Checks MongoDB for a report generated within the last **4 hours**.
    - **Hit:** Returns cached JSON immediately.
    - **Miss:** Returns "Calculated..." to user and starts a background thread.
4.  **Extraction:** Scrapes Google News for specific kinetic keywords in the region.
5.  **Analysis:**
    - Constructs a prompt using `analyst_system_prompt.txt`.
    - Injects User Location + Distance to Hotzones + News Headlines.
    - Sends to LLM (Gemini 3 Pro / Flash).
6.  **Delivery:** Saves result to MongoDB and returns it on the next user poll.

---

## 5. Excluded Systems (Do Not Use)
The following subsystems found in `Server Backend/sentinel_lab/` are **EXPERIMENTAL** or **DEPRECATED** and are **NOT** connected to the mobile app:
- **GDELT System:** (`intelligence.py`, `listener.py`) - An alternative global event listener.
- **Ukraine Analysis:** Experimental dashboard code for a different theater.