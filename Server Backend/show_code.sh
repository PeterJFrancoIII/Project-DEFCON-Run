#!/bin/bash

# ==============================================================================
# MODULE: show_code.sh
# DESCRIPTION: Locates and displays the views.py file so we can debug the logic.
# ==============================================================================

echo "----------------------------------------------------------------"
echo "[1] Searching for the 'intel' view..."

# Find the views.py file, excluding the virtual environment
VIEWS_FILE=$(find . -name "views.py" -not -path "*/venv/*" | head -n 1)

if [ -z "$VIEWS_FILE" ]; then
    echo "[✖] Could not find views.py."
    exit 1
fi

echo "[✔] Found file: $VIEWS_FILE"
echo "----------------------------------------------------------------"
echo "[2] Displaying Code Content:"
echo "----------------------------------------------------------------"

# Print the file content to screen
cat "$VIEWS_FILE"

echo "----------------------------------------------------------------"
echo "[END OF FILE]"
