#!/bin/bash

# Ensure we have the key
if [ -z "$GEMINI_API_KEY" ]; then
    echo "ERROR: Please run 'export GEMINI_API_KEY=your_key_here' before starting."
    exit 1
fi

echo "--- BORDER WATCH AGENT ACTIVE ---"
echo "KEY DETECTED: ${GEMINI_API_KEY:0:5}..."

while true; do
    echo "[$(date)] Pinging Google AI Studio..."
    python3 manage.py fetch_evac_intel
    echo "[$(date)] Cycle complete. Sleeping 24h..."
    sleep 86400
done
