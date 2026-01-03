#!/bin/bash

# ==============================================================================
# MODULE: run_public.sh
# AUTHOR: Gemini (AI Assistant)
# DATE: 2025-12-29
#
# DESCRIPTION:
# Launches Django on 0.0.0.0. This is REQUIRED for Android/iOS testing because
# standard "localhost" servers are invisible to external devices.
#
# USAGE:
# Run via terminal: sh run_public.sh
# ==============================================================================

# 1. Activate Virtual Environment
if [ -d "venv" ]; then
    source venv/bin/activate
fi

# 2. Get the specific IP your Android phone needs to use
# The diagnostic showed you are on 172.20.10.2 (likely a Hotspot or local subnet)
LAN_IP=$(ipconfig getifaddr en0)

echo "----------------------------------------------------------------"
echo "[🚀] Starting PUBLIC Django Server"
echo "     The server is now visible to other devices on this network."
echo ""
echo "     USE THIS URL IN YOUR ANDROID CODE:"
echo "     http://$LAN_IP:8000"
echo "----------------------------------------------------------------"

# 3. Run server on 0.0.0.0 (All Interfaces)
python3 manage.py runserver 0.0.0.0:8000

