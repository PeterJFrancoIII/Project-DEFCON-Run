"""
SYSTEM: BORDER WATCH
MODULE: watchtower.py
ROLE:   ADAPTIVE SCHEDULER (DEEP FREEZE BUDGET)
DESCRIPTION:
- Ultra-low cost polling.
- DEFCON 5 updates only once every 2 days.
"""

import time
import subprocess
import sys
import pymongo
from datetime import datetime, timedelta

# CONFIGURATION
MONGO_URI = "mongodb://localhost:27017/"
DB_NAME = "BorderConflictDB"
COLLECTION_NAME = "intel_history"

# HEARTBEAT
HEARTBEAT_RATE = 60 

# DEEP FREEZE MATRIX (Seconds)
# D1: 30 mins (1800s)
# D2: 4 hours (14400s)
# D3: 12 hours (43200s)
# D4: 24 hours (86400s)
# D5: 48 hours (172800s)
POLLING_MATRIX = {
    1: 1800,
    2: 14400,
    3: 43200,
    4: 86400,
    5: 172800
}

def get_tracked_sectors():
    try:
        client = pymongo.MongoClient(MONGO_URI)
        db = client[DB_NAME]
        col = db[COLLECTION_NAME]
        
        pipeline = [
            {"$sort": {"timestamp": -1}},
            {"$group": {
                "_id": {"zip": "$data.zip_code", "lang": "$data.language"},
                "country": {"$first": "$country"},
                "defcon": {"$first": "$data.defcon_status"},
                "last_timestamp": {"$first": "$timestamp"}
            }}
        ]
        return list(col.aggregate(pipeline))
    except Exception as e:
        print(f"[WATCHTOWER] DB Error: {e}")
        return []

def run_patrol():
    print(f"\n--- [WATCHTOWER] DEEP FREEZE PATROL: {datetime.now().strftime('%H:%M:%S')} ---")
    
    sectors = get_tracked_sectors()
    if not sectors:
        print(">> No active sectors found.")
        return

    updates = 0
    
    for sector in sectors:
        data = sector['_id']
        zip_code = data.get('zip')
        lang = data.get('lang', 'en')
        country = sector['country']
        defcon = sector.get('defcon', 5)
        
        last_str = sector.get('last_timestamp')
        if not last_str: age = 999999
        else:
            try:
                last_dt = datetime.fromisoformat(last_str)
                age = (datetime.now() - last_dt).total_seconds()
            except: age = 999999

        limit = POLLING_MATRIX.get(defcon, 172800)
        
        if age > limit:
            print(f">> [UPDATE] {zip_code} ({lang}) | DEFCON {defcon} | Age: {int(age/3600)}h")
            try:
                subprocess.run([
                    sys.executable, "conflict_agent.py", 
                    "--zip", str(zip_code), 
                    "--country", str(country),
                    "--lang", str(lang)
                ], check=True)
                updates += 1
                time.sleep(2)
            except Exception as e:
                print(f"   [FAIL] {e}")

    if updates == 0: print(">> All sectors fresh.")

if __name__ == "__main__":
    print(">> WATCHTOWER: DEEP FREEZE MODE ACTIVE.")
    while True:
        run_patrol()
        time.sleep(HEARTBEAT_RATE)
