import requests
import json

BASE_URL = "http://127.0.0.1:8000/jobs"

def test_admin_config():
    print("--- ADMIN CONFIG VERIFICATION ---")
    
    # 1. Update API Key (Unauthorized)
    print("[1] Testing Unauthorized Update...")
    resp = requests.post(f"{BASE_URL}/admin/config/apikey", json={
        "secret": "wrongpass",
        "key": "NEW_KEY_123"
    })
    print(f"Status: {resp.status_code}")
    if resp.status_code != 401:
        print("FAILED: Should be 401")
        return

    # 2. Update API Key (Success)
    print("[2] Testing Authorized Update...")
    resp = requests.post(f"{BASE_URL}/admin/config/apikey", json={
        "secret": "admin123",
        "key": "UPDATED_ADMIN_KEY_999"
    })
    print(f"Status: {resp.status_code} | Body: {resp.text}")
    if resp.status_code == 200:
        print("SUCCESS: Key Updated")
        
if __name__ == "__main__":
    try:
        test_admin_config()
    except Exception as e:
        print(f"ERROR: {e}")
