import pymongo
import json
from datetime import datetime

class DateTimeEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, datetime):
            return o.isoformat()
        return super().default(o)

def inspect_db():
    client = pymongo.MongoClient("mongodb://localhost:27017/")
    db = client["sentinel_intel"]
    
    print(f"Database: {db.name}")
    print(f"Collections: {db.list_collection_names()}")
    
    for col_name in db.list_collection_names():
        print(f"\n--- Collection: {col_name} ---")
        col = db[col_name]
        count = col.count_documents({})
        print(f"Count: {count}")
        
        cursor = col.find().limit(5)
        for doc in cursor:
            # Remove ID for cleaner print
            if '_id' in doc: del doc['_id']
            print(json.dumps(doc, indent=2, cls=DateTimeEncoder))

if __name__ == "__main__":
    try:
        inspect_db()
    except Exception as e:
        print(f"Error: {e}")
