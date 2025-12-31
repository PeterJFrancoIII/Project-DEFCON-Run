from core.db_utils import get_db_handle
import pymongo

try:
    db = get_db_handle()
    print("[*] Creating Geospatial Index on 'intel_history'...")
    # This allows us to search for "Reports within 50km"
    db.intel_history.create_index([("location_geo", pymongo.GEOSPHERE)])
    print("[✔] Index Created Successfully. The Grid is active.")
except Exception as e:
    print(f"[!] Error: {e}")
