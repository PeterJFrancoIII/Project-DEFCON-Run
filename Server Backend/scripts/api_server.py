"""
SYSTEM: SENTINEL
MODULE: api_server.py
ROLE:   TRAFFIC COP (V33)
"""

from flask import Flask, jsonify, request
import pymongo
import subprocess
import sys
from datetime import datetime

app = Flask(__name__)

MONGO_URI = "mongodb://localhost:27017/"
DB_NAME = "sentinel_intel"
COLLECTION_NAME = "intel_history"

# Polling Matrix (Deep Freeze)
POLLING_MATRIX = { 1: 1800, 2: 14400, 3: 43200, 4: 86400, 5: 172800 }

try:
    client = pymongo.MongoClient(MONGO_URI)
    db = client[DB_NAME]
    col = db[COLLECTION_NAME]
except: pass

@app.route('/intel', methods=['GET'])
def get_intel():
    user_zip = request.args.get('zip', '10110')
    user_country = request.args.get('country', 'TH')
    user_lang = request.args.get('lang', 'en')
    
    try:
        doc = col.find_one({"zip_code": user_zip}, {"_id": 0})
        
        if doc:
            # 1. Check Global Freshness
            timestamp_str = doc.get("timestamp")
            base_data = doc.get("languages", {}).get("en", {})
            defcon = int(base_data.get("defcon_status", 5))
            
            is_stale = False
            if not timestamp_str: is_stale = True
            else:
                try:
                    last_dt = datetime.fromisoformat(timestamp_str)
                    age = (datetime.now() - last_dt).total_seconds()
                    limit = POLLING_MATRIX.get(defcon, 172800)
                    if age > limit: is_stale = True
                except: is_stale = True

            # 2. Check Specific Language Availability
            lang_data = doc.get("languages", {}).get(user_lang)
            
            script_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "conflict_agent.py")

            if is_stale:
                # Whole record is old. Re-run English Master.
                print(f">> [SERVER] Stale Data for {user_zip}. Refreshing Master...")
                subprocess.Popen([sys.executable, script_path, "--zip", user_zip, "--country", user_country, "--lang", "en"])
                return jsonify({"status": "calculating", "message": "Updating Intel..."})
                
            elif not lang_data:
                # Record is fresh, but we don't have THIS language yet.
                # Trigger TRANSLATION only.
                print(f">> [SERVER] Missing {user_lang} for {user_zip}. Translating...")
                subprocess.Popen([sys.executable, script_path, "--zip", user_zip, "--country", user_country, "--lang", user_lang])
                return jsonify({"status": "calculating", "message": "Translating..."})
                
            else:
                # HIT! Fresh and Translated.
                return jsonify({"status": "success", "data": lang_data})
        
        else:
            # No Record at all. Start from scratch.
            script_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "conflict_agent.py")
            print(f">> [SERVER] New Sector: {user_zip}. Initializing...")
            subprocess.Popen([sys.executable, script_path, "--zip", user_zip, "--country", user_country, "--lang", "en"])
            return jsonify({"status": "calculating", "message": "Initializing..."})
            
    except Exception as e:
         return jsonify({"status": "error", "details": str(e)})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
