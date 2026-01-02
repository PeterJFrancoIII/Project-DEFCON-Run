import subprocess
import time
import os
import sys
import pymongo

def run_cmd(cmd, background=False):
    print(f">> [EXEC] {cmd}")
    if background:
        subprocess.Popen(cmd, shell=True)
    else:
        subprocess.run(cmd, shell=True)

def main():
    print("--- BORDER WATCH: NUKE & BOOT ---")
    
    # 1. CLEANUP
    print("\n>> [1/6] Cleaning Ports...")
    run_cmd("lsof -ti:27017 | xargs kill -9 2>/dev/null")
    run_cmd("lsof -ti:5001 | xargs kill -9 2>/dev/null")

    # 2. START MONGO
    print("\n>> [2/6] Starting MongoDB...")
    if not os.path.exists("mongodb_data"): os.makedirs("mongodb_data")
    run_cmd("mongod --port 27017 --dbpath ./mongodb_data > mongo_local.log 2>&1", background=True)
    
    print("   + Waiting 5s for Database initialization...")
    time.sleep(5)

    # 3. WIPE DATABASE
    print("\n>> [3/6] Wiping Stale Data...")
    try:
        client = pymongo.MongoClient("mongodb://localhost:27017/")
        db = client["BorderConflictDB"]
        db["intel_history"].delete_many({})
        print("   + [SUCCESS] Database Wiped.")
    except Exception as e:
        print(f"   + [ERROR] Wipe failed: {e}")

    # 4. RUN AGENT (DEFAULT SECTOR)
    print("\n>> [4/6] Generating Fresh Intel (Bangkok Default)...")
    run_cmd(f"{sys.executable} conflict_agent.py --zip 10110 --country TH")

    # 5. START SERVER
    print("\n>> [5/6] Starting API Server on Port 5001...")
    print("   + System Ready. Launch the App in Xcode now.")
    run_cmd(f"{sys.executable} api_server.py")

if __name__ == "__main__":
    main()
