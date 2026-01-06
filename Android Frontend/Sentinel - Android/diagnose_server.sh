#!/bin/bash

# ==============================================================================
# MODULE: diagnose_server.sh
# AUTHOR: Gemini (AI Assistant)
# DATE: 2025-12-29
#
# DESCRIPTION:
# This script performs a network level diagnostic on the local machine to 
# determine why a web server (specifically Django) might be unreachable.
#
# FUNCTIONALITY:
# 1. Port Scanning: Uses 'lsof' (List Open Files) to check if any process is 
#    actually listening on TCP port 8000. This confirms if the server is running.
# 2. Local Reachability: Uses 'curl' to attempt a raw HTTP connection to 
#    127.0.0.1:8000. This bypasses browser caches and verify the network stack.
# 3. IP Address Identification: Fetches the LAN IP address (en0) to assist 
#    the user if they are trying to connect from a different device (mobile/laptop).
#
# USAGE:
# Run via terminal: sh diagnose_server.sh
# ==============================================================================

# --- Configuration ---
PORT="8000"

echo "----------------------------------------------------------------"
echo "[?] DIAGNOSTIC: Checking Port $PORT status..."
echo "----------------------------------------------------------------"

# --- Step 1: Check if anything is listening on Port 8000 ---
# 'lsof -i' lists network files. ':8000' filters for that port.
# '-t' returns only the PID (Process ID), making it easy to check existence.
PID=$(lsof -ti :$PORT)

if [ -z "$PID" ]; then
    echo "[✖] RESULT: Nothing is listening on port $PORT."
    echo "    CAUSE: The Django server is NOT running."
    echo "    FIX:   Go back to your terminal and run './run_local.sh'"
    echo "           Keep that terminal window OPEN."
else
    echo "[✔] RESULT: Process $PID is listening on port $PORT."
    
    # --- Step 2: Test Connection via Curl ---
    echo "    [➜] Attempting internal connection via curl..."
    
    # curl -I fetches headers only (lighter weight).
    # --max-time 2 prevents it from hanging if the server is stuck.
    if curl --output /dev/null --silent --head --fail --max-time 2 "http://127.0.0.1:$PORT"; then
        echo "    [✔] Connection SUCCESSFUL. The server is reachable locally."
    else
        echo "    [!] Connection FAILED even though the port is open."
        echo "        Check if your Django 'ALLOWED_HOSTS' setting includes '127.0.0.1'."
    fi
fi

# --- Step 3: Provide LAN IP for External/Simulator Access ---
# If the user is on a phone/simulator, they need the LAN IP, not localhost.
echo "----------------------------------------------------------------"
echo "[ℹ] CONTEXT CHECK:"
echo "    Are you testing from a Phone, Simulator, or Virtual Machine?"
echo "    If YES, '127.0.0.1' will NOT work."
echo "    You must use your LAN IP Address below:"
echo ""
# ipconfig getifaddr en0 gets the Wi-Fi IP on macOS standardly.
LAN_IP=$(ipconfig getifaddr en0)
echo "    http://$LAN_IP:$PORT"
echo "----------------------------------------------------------------"

