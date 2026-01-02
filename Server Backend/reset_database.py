# ==============================================================================
# MODULE: reset_database.py
# DESCRIPTION: Wipes the intelligence database and resets the Geospatial Index.
# ==============================================================================

from core.db_utils import get_db_handle
import pymongo
import sys

def reset_system():
    print("----------------------------------------------------------------")
    print("[!] DANGER: INITIATING DATABASE RESET")
    print("----------------------------------------------------------------")
    
    try:
        # 1. Connect
        db = get_db_handle()
        
        # 2. Count existing records
        count = db.intel_history.count_documents({})
        print(f"[*] Found {count} old records.")
        
        # 3. Drop the collection (Deletes Data AND Indexes)
        print("[*] Dropping 'intel_history' collection...")
        db.intel_history.drop()
        print("[✔] Collection wiped.")
        
        # 4. Re-create the Geospatial Index (Required for 50km logic)
        print("[*] Re-creating 2dsphere Index on 'location_geo'...")
        db.intel_history.create_index([("location_geo", pymongo.GEOSPHERE)])
        print("[✔] Index created successfully.")
        
        print("----------------------------------------------------------------")
        print("[✔] SYSTEM CLEAN. READY FOR AI REPOPULATION.")
        print("----------------------------------------------------------------")

    except Exception as e:
        print(f"[✖] FAILED: {e}")
        sys.exit(1)

if __name__ == "__main__":
    reset_system()
