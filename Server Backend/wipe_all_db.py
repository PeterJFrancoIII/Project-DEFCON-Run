from core.db_utils import get_db_handle
import pymongo

def wipe():
    print("Connecting to MongoDB...")
    db = get_db_handle()
    
    collections = ['intel_history', 'news_index', 'system_status', 'intel_cache']
    
    for col in collections:
        print(f"Dropping {col}...")
        db[col].drop()
        
    print("Re-creating indexes...")
    # Geospatial index for distance calcs
    db.intel_history.create_index([("location_geo", pymongo.GEOSPHERE)])
    
    # News index for sorting/dedup
    db.news_index.create_index([("published_parsed", pymongo.DESCENDING)])
    db.news_index.create_index([("link_hash", pymongo.ASCENDING)], unique=True)
    
    print("Database Wiped & Ready.")

if __name__ == "__main__":
    wipe()
