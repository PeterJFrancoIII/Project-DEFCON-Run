import requests
import json
import time

BASE_URL = "http://127.0.0.1:8000/jobs"

def run_test():
    print("--- JOBS MODULE VERIFICATION ---")
    
    # 1. Register
    print("[1] Registering...")
    email = f"test_{int(time.time())}@example.com"
    resp = requests.post(f"{BASE_URL}/auth/register", json={
        "email": email,
        "password": "securePass123!",
        "role": "employer"
    })
    print(resp.status_code, resp.text)
    if resp.status_code != 200: return
    
    # 2. Login
    print("[2] Logging in...")
    resp = requests.post(f"{BASE_URL}/auth/login", json={
        "email": email,
        "password": "securePass123!"
    })
    print(resp.status_code)
    data = resp.json()
    token = data['token']
    
    headers = {"Authorization": f"Bearer {token}"}
    
    # 3. Create Listing
    print("[3] Creating Listing...")
    resp = requests.post(f"{BASE_URL}/listings/create", headers=headers, json={
        "title": "Emergency Sandbagging",
        "description": "Need 10 people for flood defense.",
        "location": {"zip": "10110", "lat": 13.75, "lon": 100.50},
        "pay": "500 THB/day"
    })
    print(resp.status_code, resp.text)
    job_id = resp.json()['job_id']
    
    # 4. Search Listings
    print("[4] Searching Listings...")
    resp = requests.get(f"{BASE_URL}/listings/search")
    print(resp.status_code)
    jobs = resp.json()['data']
    print(f"Found {len(jobs)} jobs")
    found = any(j['_id'] == job_id for j in jobs)
    print(f"Job {job_id} visible: {found}")
    
    # 5. Report Listing
    print("[5] Reporting Listing...")
    resp = requests.post(f"{BASE_URL}/report", headers=headers, json={
        "target_type": "listing",
        "target_id": job_id,
        "reason": "spam",
        "note": "This is a test report"
    })
    print(resp.status_code, resp.text)

if __name__ == "__main__":
    try:
        run_test()
    except Exception as e:
        print(f"FAILED: {e}")
