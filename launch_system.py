import subprocess
import time
import os
import sys

def run_cmd(cmd, background=False):
    """Executes a shell command."""
    print(f">> [EXEC] {cmd}")
    if background:
        # Run in background (for MongoDB)
        subprocess.Popen(cmd, shell=True)
    else:
        # Run and wait for finish (for Agent/Server)
        subprocess.run(cmd, shell=True)

def main():
    print("--- BORDER WATCH SYSTEM LAUNCHER ---")
    
    # 1. CLEANUP PORTS
    # We kill anything running on Port 27017 (Mongo) and 5001 (Server)
    print("\n>> [1/5] Cleaning up old processes...")
    run_cmd("lsof -ti:27017 | xargs kill -9 2>/dev/null")
    run_cmd("lsof -ti:5001 | xargs kill -9 2>/dev/null")

    # 2. PREPARE DATABASE FOLDER
    # We use a local folder './mongodb_data' to avoid 'Read-Only' permission errors on Mac
    print("\n>> [2/5] Setting up local database storage...")
    if not os.path.exists("mongodb_data"):
        os.makedirs("mongodb_data")
        print("   + Created ./mongodb_data folder")
    
    # 3. START MONGODB
    # We point --dbpath to our new local folder
    print("\n>> [3/5] Starting MongoDB (Local Mode)...")
    run_cmd("mongod --port 27017 --dbpath ./mongodb_data > mongo_local.log 2>&1", background=True)
    
    print("   + Waiting 5 seconds for Database initialization...")
    time.sleep(5)

    # 4. RUN INTELLIGENCE AGENT
    # This fetches the AI data and saves it to the DB we just started
    print("\n>> [4/5] Running Intelligence Agent...")
    run_cmd(f"{sys.executable} conflict_agent.py")

    # 5. START API SERVER
    # This keeps running so your phone can connect
    print("\n>> [5/5] Starting API Server on Port 5001...")
    print("   + Press Ctrl+C to stop the server.")
    run_cmd(f"{sys.executable} api_server.py")

if __name__ == "__main__":
    main()
