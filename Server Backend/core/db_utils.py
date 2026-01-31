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
        # FIX: Support Docker hostname via env var, default to localhost
        import os
        host = os.getenv('MONGO_HOST', 'localhost')
        client = MongoClient(
            host=host, 
            port=27017, 
            serverSelectionTimeoutMS=5000
        )
        # Test connection immediately
        client.admin.command('ping')
        return client['sentinel_intel']

    except Exception as e:
        print("\n[!] CRITICAL DATABASE ERROR")
        print(f"    Could not connect to MongoDB at localhost:27017")
        print(f"    Error: {e}")
        print("    SUGGESTION: Run 'brew services start mongodb-community'")
        sys.exit(1)
