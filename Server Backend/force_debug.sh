#!/bin/bash

# ==============================================================================
# MODULE: force_debug.sh
# AUTHOR: Gemini (AI Assistant)
# DATE: 2025-12-29
#
# DESCRIPTION:
# This script locates the Django 'settings.py' file and forcefully sets
# DEBUG = True. This is critical for development environments to ensure
# that 500 Internal Server Errors print a full traceback to the console
# instead of failing silently.
#
# FUNCTIONALITY:
# 1. search: Finds settings.py in the current directory tree.
# 2. sed: Replaces 'DEBUG = False' with 'DEBUG = True'.
#
# USAGE:
# Run via terminal: sh force_debug.sh
# ==============================================================================

echo "[➜] Searching for settings.py..."
SETTINGS_FILE=$(find . -name "settings.py" -not -path "*/venv/*" | head -n 1)

if [ -z "$SETTINGS_FILE" ]; then
    echo "[✖] Error: Could not find settings.py."
    exit 1
fi

echo "[✔] Found settings file: $SETTINGS_FILE"

# Use sed to replace DEBUG = False with DEBUG = True
# The -i '' is for macOS compatibility to edit in-place
sed -i '' 's/DEBUG = False/DEBUG = True/g' "$SETTINGS_FILE"

echo "[✔] Enforced DEBUG = True."
echo "----------------------------------------------------------------"
echo "[ACTION REQUIRED] Restart your server now:"
echo "1. Press Ctrl+C to stop the current server."
echo "2. Run: python3 manage.py runserver 0.0.0.0:8000"
echo "3. Trigger the error again from your Android app."
echo "4. Paste the new error text here."
echo "----------------------------------------------------------------"

