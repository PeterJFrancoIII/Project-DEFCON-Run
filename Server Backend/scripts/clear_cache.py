import pymongo
import sys

try:
    client = pymongo.MongoClient("mongodb://localhost:27017/")
    db = client["sentinel_intel"]
    col = db["intel_history"]
    
    count = col.count_documents({})
    print(f">> [CACHE] Found {count} documents.")
    
    result = col.delete_many({})
    print(f">> [CACHE] Deleted {result.deleted_count} documents.")
    print(">> [CACHE] Cache cleared. Next request will trigger fresh analysis.")
    
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
