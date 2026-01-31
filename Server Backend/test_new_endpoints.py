
import requests
import sys

BASE_URL = "http://localhost:8000"

def test_endpoint(url, name):
    print(f"\n--- Testing {name} ({url}) ---")
    try:
        resp = requests.get(url)
        print(f"Status: {resp.status_code}")
        try:
             data = resp.json()
             print(f"Response: {str(data)[:200]}...") # Truncate
        except:
             print(f"Raw: {resp.text[:200]}...")
    except Exception as e:
        print(f"FAILED: {e}")

if __name__ == "__main__":
    test_endpoint(f"{BASE_URL}/config/public", "Public Config")
    test_endpoint(f"{BASE_URL}/intel/status", "Intel Status")
    test_endpoint(f"{BASE_URL}/admin/ops/logs?lines=10", "Server Logs")
