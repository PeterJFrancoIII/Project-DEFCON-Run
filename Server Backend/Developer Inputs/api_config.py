import os

# Gemini API Key Configuration
# You can set this via environment variable or replace the string below.
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "YOUR_API_KEY_HERE")

# Google Cloud Credentials
# Path to the service account JSON key for BigQuery
GOOGLE_APPLICATION_CREDENTIALS = os.path.join(os.path.dirname(__file__), "google_creds.json")
