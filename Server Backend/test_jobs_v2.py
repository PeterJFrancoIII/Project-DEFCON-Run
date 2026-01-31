
import requests
import json
import time

BASE_URL = "http://127.0.0.1:8000/api/jobs_v2"
ADMIN_SECRET = "sentinel-admin-v2"

def print_result(name, r):
    status = "SUCCESS" if r.status_code in [200, 201] else "FAILED"
    print(f"[{status}] {name}: {r.status_code}")
    if status == "FAILED":
        print(f"Response: {r.text}")
        return None
    return r.json()

def run_tests():
    print("=== STARTING JOBS V2 STRICT BACKEND TESTS ===")
    
    # 1. Register Employer (Strict: Real Name + Phone)
    employer_data = {
        "email": "employer_strict@sentinel.com",
        "password": "password123",
        "phone": "+15550001001",
        "real_name_first": "John",
        "real_name_last": "Doe",
        "role": "employer",
        "organization_name": "Test Security Corp",
        "organization_type": "Security"
    }
    r = requests.post(f"{BASE_URL}/auth/register", json=employer_data)
    emp_res = print_result("Register Employer", r)
    if not emp_res:
         # Login if exists
        r = requests.post(f"{BASE_URL}/auth/login", json={"email": employer_data["email"], "password": employer_data["password"]})
        emp_res = print_result("Login Existing Employer", r)
        
    emp_token = emp_res["token"]
    emp_id = emp_res["account_id"]
    
    # 2. Register Worker (Strict: Real Name + Phone)
    worker_data = {
        "email": "worker_strict@sentinel.com",
        "password": "password123",
        "phone": "+15550002002",
        "real_name_first": "Jane",
        "real_name_last": "Smith",
        "role": "worker"
    }
    r = requests.post(f"{BASE_URL}/auth/register", json=worker_data)
    worker_res = print_result("Register Worker", r)
    if not worker_res:
         # Login if exists
        r = requests.post(f"{BASE_URL}/auth/login", json={"email": worker_data["email"], "password": worker_data["password"]})
        worker_res = print_result("Login Existing Worker", r)
        
    worker_token = worker_res["token"]
    worker_id = worker_res["account_id"]
    
    # 3. Check Verification Status (Employer should be pending/unverified initially)
    headers = {"Authorization": f"Bearer {emp_token}"}
    r = requests.get(f"{BASE_URL}/auth/profile", headers=headers)
    profile = print_result("Get Employer Profile", r)
    print(f"Employer Verified: {profile['profile']['verified']} (Trust Score: {profile['profile'].get('trust_score')})")
    
    # 4. Admin Verify Employer (Boost Trust Score)
    verify_data = {
        "account_id": emp_id,
        "action": "approve"
    }
    r = requests.post(f"{BASE_URL}/admin/employers/verify?secret={ADMIN_SECRET}", json=verify_data)
    print_result("Admin Verify Employer", r)
    
    # 5. Employer Create Listing (Strict Schema)
    listing_data = {
        "category": "Security",
        "pay_type": "hourly", # cash | hourly | daily
        "pay_range": {"min": 25, "max": 35, "currency": "USD"},
        "start_time": "2026-01-22T08:00:00Z",
        "duration": "8h",
        "description": "Urgent security needed for Sector 7 checkpoint.",
        "location": {
            "lat": 40.7128,
            "lon": -74.0060,
            "accuracy": 10
        }
    }
    r = requests.post(f"{BASE_URL}/listings/create", json=listing_data, headers=headers)
    listing_res = print_result("Create Listing", r)
    if listing_res:
        job_id = listing_res["job_id"]
        
        # 6. Worker Search Listings (Lazy Load)
        worker_headers = {"Authorization": f"Bearer {worker_token}"}
        # Search by lat/lon
        r = requests.get(f"{BASE_URL}/listings/search?lat=40.71&lon=-74.00&radius_km=10", headers=worker_headers)
        search_res = print_result("Search Listings", r)
        print(f"Found {len(search_res.get('listings', []))} listings nearby")
        
        # 7. Worker Apply
        r = requests.post(f"{BASE_URL}/listings/{job_id}/apply", json={}, headers=worker_headers)
        print_result("Worker Apply", r)
        
        # 8. Employer Assign Worker
        assign_data = {
            "worker_id": worker_id
        }
        r = requests.post(f"{BASE_URL}/listings/{job_id}/assign", json=assign_data, headers=headers)
        print_result("Assign Worker", r)
    
    print("=== TESTS COMPLETED ===")

if __name__ == "__main__":
    try:
        run_tests()
    except Exception as e:
        print(f"Test Execution Failed: {e}")
