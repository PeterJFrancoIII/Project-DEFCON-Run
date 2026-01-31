import pymongo
client = pymongo.MongoClient("mongodb://localhost:27017/")
db = client["sentinel_intel"]
zip_code = "32110"
res = db.intel_history.delete_one({"zip_code": zip_code})
print(f"Deleted {res.deleted_count} documents for {zip_code}")
