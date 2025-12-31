# ==============================================================================
# SYSTEM: SENTINEL SERVER
# MODULE: db_utils.py
# ROLE:   DATABASE CONNECTION MANAGER (MACOS LOCALHOST FIX)
# ==============================================================================

from pymongo import MongoClient
import sys

def get_db_handle():
    """
    Establishes a connection to the local MongoDB instance.
    """
    try:
        # FIX: We use 'localhost' instead of 'db' because we are not in Docker.
        client = MongoClient(
            host='localhost', 
            port=27017, 
            serverSelectionTimeoutMS=5000
        )
        # Test connection immediately
        client.admin.command('ping')
        return client['sentinel_db']

    except Exception as e:
        print("\n[!] CRITICAL DATABASE ERROR")
        print(f"    Could not connect to MongoDB at localhost:27017")
        print(f"    Error: {e}")
        print("    SUGGESTION: Run 'brew services start mongodb-community'")
        sys.exit(1)
