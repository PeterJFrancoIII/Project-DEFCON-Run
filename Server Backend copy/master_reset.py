# ==============================================================================
# MODULE: master_reset.py
# ROLE:   ORCHESTRATOR
# DESCRIPTION: Stops Django, Wipes DB, Restarts Mongo, Relaunches Django.
# ==============================================================================

import os
import sys
import subprocess
import time
import signal
from core.db_utils import get_db_handle
import pymongo

def run_command(cmd, shell=False):
    """Helper to run shell commands safely"""
    try:
        if shell:
            subprocess.run(cmd, shell=True, check=True)
        else:
            subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as e:
        print(f"[!] Command failed: {e}")
        # We don't exit here because sometimes 'kill' fails if no process exists, which is fine.

def kill_django():
    print("----------------------------------------------------------------")
    print("[1/5] STOPPING RUNNING SERVERS...")
    try:
        # Find PID running on port 8000 (macOS specific)
        pid = subprocess.check_output(["lsof", "-ti", ":8000"]).strip().decode('utf-8')
        if pid:
            print(f"[*] Found Django on PID {pid}. Killing it...")
            os.kill(int(pid), signal.SIGKILL)
            print("[✔] Old server stopped.")
        else:
            print("[*] No running server found on port 8000.")
    except subprocess.CalledProcessError:
        print("[*] Port 8000 is already free.")
    except Exception as e:
        print(f"[!] Error killing server: {e}")

def wipe_and_rebuild_mongo():
    print("----------------------------------------------------------------")
    print("[2/5] WIPING DATABASE...")
    try:
        # Connect to DB (Expect it to work before restart)
        db = get_db_handle()
        db.intel_history.drop()
        print("[✔] Old intelligence data deleted.")
    except:
        print("[!] DB connection failed (might be off). Proceeding to restart...")

    print("----------------------------------------------------------------")
    print("[3/5] RESTARTING MONGODB SERVICE (BREW)...")
    try:
        # Restart service to clear internal caches/locks
        # Using shell=True to handle brew environment variables better
        subprocess.run("brew services restart mongodb-community || brew services restart mongodb-bin", shell=True)
        print("[⏳] Waiting 5 seconds for Database boot...")
        time.sleep(5)
    except Exception as e:
        print(f"[!] Mongo Restart Failed: {e}")
        sys.exit(1)

    print("----------------------------------------------------------------")
    print("[4/5] REBUILDING GEOSPATIAL GRID...")
    try:
        # Re-connect now that it's restarted
        new_db = get_db_handle()
        new_db.intel_history.create_index([("location_geo", pymongo.GEOSPHERE)])
        print("[✔] 50km Radius Index created.")
    except Exception as e:
        print(f"[✖] Index Build Failed: {e}")
        sys.exit(1)

def start_django():
    print("----------------------------------------------------------------")
    print("[5/5] LAUNCHING FRESH DJANGO SERVER...")
    print("----------------------------------------------------------------")
    print(">> SERVER IS LIVE. PRESS CTRL+C TO STOP.")
    print(">> LISTENING ON: 0.0.0.0:8000 (Accessible to Android)")
    print("----------------------------------------------------------------")
    
    # Replace the current python process with the Django server
    # This means 'master_reset.py' disappears and becomes 'manage.py'
    os.execvp("python3", ["python3", "manage.py", "runserver", "0.0.0.0:8000"])

if __name__ == "__main__":
    kill_django()
    wipe_and_rebuild_mongo()
    start_django()
