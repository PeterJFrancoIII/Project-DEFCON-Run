"""
SYSTEM: SENTINEL
MODULE: conflict_agent.py
ROLE:   ON-DEMAND TRANSLATION ENGINE
LOGIC:  
1. Generate English Master (Heavy Compute) ONLY if missing/stale.
2. Generate Translations (Light Compute) ONLY if requested & missing.
"""

import argparse
import pymongo
import sys
import google.generativeai as genai
import json
import feedparser
import ssl
import math
import os
from datetime import datetime

# CONFIGURATION
MONGO_URI = "mongodb://localhost:27017/"
DB_NAME = "sentinel_intel"
COLLECTION_NAME = "intel_history"
try:
    from sys import path
    import os
    BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    INPUTS_DIR = os.path.join(BASE_DIR, 'Developer Inputs')
    path.append(INPUTS_DIR)
    import api_config
    GEMINI_API_KEY = api_config.GEMINI_API_KEY
except:
    GEMINI_API_KEY = os.environ.get('GEMINI_API_KEY', 'YOUR_API_KEY_HERE')

# Path relative to this script (Server Backend/scripts/conflict_agent.py)
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INPUTS_DIR = os.path.join(BASE_DIR, 'Developer Inputs')
ZONE_DB_FILE = os.path.join(INPUTS_DIR, "thailand_zones.json")

# --- SETUP PATHS ---
sys.path.append(BASE_DIR)

# DYNAMIC COMPLIANCE
from core.compliance import check_compliance

# HOTZONES
HOTZONES_DATA = [
    {"name": "PREAH VIHEAR (ARTILLERY)", "lat": 14.3914, "lon": 104.6804, "radius": 40000},
    {"name": "POIPET (MORTARS)", "lat": 13.6600, "lon": 102.5000, "radius": 15000},
    {"name": "CHONG CHOM (ROCKETS)", "lat": 14.4300, "lon": 103.4300, "radius": 35000},
    {"name": "TRAT (NAVAL GUNS)", "lat": 11.9600, "lon": 102.8000, "radius": 25000}
]

# AI SETUP
genai.configure(api_key=GEMINI_API_KEY)
try:
    MODEL = genai.GenerativeModel("gemini-3-pro-preview")
except:
    print(">> [SYSTEM] Model 'gemini-3-pro-preview' not found. Fallback to 'gemini-pro'.")
    MODEL = genai.GenerativeModel("gemini-pro")

# --- GEOSPATIAL ENGINE ---
def haversine_distance(lat1, lon1, lat2, lon2):
    try:
        R = 6371 
        dlat = math.radians(lat2 - lat1)
        dlon = math.radians(lon2 - lon1)
        a = math.sin(dlat/2) * math.sin(dlat/2) + \
            math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * \
            math.sin(dlon/2) * math.sin(dlon/2)
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
        return R * c
    except: return 9999.0

class ZoneResolver:
    @staticmethod
    def resolve_and_measure(zip_code):
        if os.path.exists(ZONE_DB_FILE):
            try:
                with open(ZONE_DB_FILE, 'r') as f:
                    db = json.load(f)
                if zip_code in db:
                    target = db[zip_code]
                    t_lat = float(target['lat'])
                    t_lon = float(target['lon'])
                    min_dist = 9999.0
                    nearest_threat = "Unknown"
                    for zone in HOTZONES_DATA:
                        dist = haversine_distance(t_lat, t_lon, zone['lat'], zone['lon'])
                        if dist < min_dist:
                            min_dist = dist
                            nearest_threat = zone['name']
                    return { "name": target['name'], "lat": t_lat, "lon": t_lon, "distance_km": round(min_dist, 1), "nearest_hotzone": nearest_threat }
            except: pass
        return { "name": f"Sector {zip_code}", "lat": 0.0, "lon": 0.0, "distance_km": -1, "nearest_hotzone": "None" }

def fetch_news():
    if hasattr(ssl, '_create_unverified_context'):
        ssl._create_default_https_context = ssl._create_unverified_context
    query = "Thailand Cambodia border conflict OR troop movement OR artillery OR OSINT"
    url = f"https://news.google.com/rss/search?q={query.replace(' ', '+')}&hl=en-US&gl=US&ceid=US:en"
    feed = feedparser.parse(url)
    if not feed.entries: return "No major reports."
    return "\n".join([entry.title for entry in feed.entries[:8]])

# --- GENERATORS ---

def generate_master_intel(zip_code, geo_info, news_text):
    """ COST: HIGH (Full Analysis). Only runs for English. """
    dist_info = ""
    if geo_info['distance_km'] > 0:
        dist_info = f"TARGET DISTANCE TO THREAT: {geo_info['distance_km']} km (Nearest: {geo_info['nearest_hotzone']})"

    # Load External Prompt
    prompt_path = os.path.join(BASE_DIR, 'Developer Inputs', 'analyst_system_prompt.txt')
    try:
        with open(prompt_path, 'r', encoding='utf-8') as f:
            template = f.read()
            
        prompt = template.format(
            target_name=f"{geo_info['name']} (Zip: {zip_code})",
            dist_info=dist_info,
            news_text=news_text
        )
    except Exception as e:
        print(f"[AGENT] Prompt Load Error: {e}")
        # Fallback minimal prompt
        prompt = f"ACT AS INTELLIGENCE OFFICER. TARGET: {zip_code}. NEWS: {news_text}. OUTPUT JSON."
    try:
        resp = MODEL.generate_content(prompt)
        text = resp.text.replace("```json", "").replace("```", "").strip()
        data = json.loads(text)

        # --- SCHEMA NORMALIZATION (New Prompt -> Old App Schema) ---
        # 1. Map 'sitrep_summary' -> 'summary'
        if 'sitrep_summary' in data:
            data['summary'] = data.pop('sitrep_summary')
        
        # 2. Map 'tactical_map' -> 'roads_to_avoid' & 'emergency_avoid_locations'
        if 'tactical_map' in data:
            tm = data.pop('tactical_map')
            data['roads_to_avoid'] = tm.get('roads_to_avoid', [])
            data['emergency_avoid_locations'] = tm.get('danger_zones', [])

        # 3. Map 'predictive_analysis' -> 'predictive'
        if 'predictive_analysis' in data:
            pa = data.pop('predictive_analysis')
            data['predictive'] = {
                "defcon": pa.get('forecast_defcon', 3),
                "risk_probability": pa.get('confidence_score', 50),
                "forecast_trend": pa.get('threat_vector', 'Static'),
                "forecast_summary": [f"Risk Window: {pa.get('risk_window', 'Unknown')}"]
            }
            # Map terminology
            trend_map = {"Approaching": "Rising", "Receding": "Falling", "Static": "Stable"}
            data['predictive']['forecast_trend'] = trend_map.get(data['predictive']['forecast_trend'], 'Stable')

        # 4. Integrate 'defcon_justification'
        if 'defcon_justification' in data:
            justification = data.pop('defcon_justification')
            if 'summary' not in data: data['summary'] = []
            data['summary'].insert(0, f"ASSESSMENT: {justification}")
        
        # Ensure Critical Keys Exist for App
        if 'summary' not in data: data['summary'] = ["No Intel Summary."]
        if 'defcon_status' not in data: data['defcon_status'] = 5

        # -----------------------------------------------------------
        
        # 1. PANIC LAW SAFEGUARD (HITL REQUIRED FOR DEFCON 1)
        if data.get('defcon_status', 5) == 1:
            print(">> [SAFETY] DEFCON 1 DETECTED. DOWNGRADING TO 2 PENDING HUMAN REVIEW.")
            data['defcon_status'] = 2
            data['summary'].insert(0, "** REPORT PENDING HUMAN VERIFICATION **")

        return data
    except Exception as e:
        print(f"[AGENT] Gen Error: {e}")
        return None

def translate_intel(master_data, target_lang_code):
    """ COST: LOW (Simple Translation). Runs for TH/KM. """
    if target_lang_code == "en": return master_data 
    
    lang_name = "THAI" if target_lang_code == "th" else "KHMER"
    
    prompt = f"""
    TRANSLATE THE JSON VALUES TO {lang_name}.
    KEEP KEYS, NUMBERS, AND COORDS UNCHANGED.
    INPUT JSON:
    {json.dumps(master_data)}
    """
    try:
        resp = MODEL.generate_content(prompt)
        return json.loads(resp.text.replace("```json", "").replace("```", "").strip())
    except Exception as e:
        print(f"[AGENT] Trans Error: {e}")
        return master_data

# --- MISSION CONTROL ---
def run_mission(zip_code, country, target_lang):
    client = pymongo.MongoClient(MONGO_URI)
    db = client[DB_NAME]
    col = db[COLLECTION_NAME]
    
    # 1. RETRIEVE DOCUMENT
    existing_doc = col.find_one({"zip_code": zip_code})
    
    master_intel = None
    needs_save = False
    
    # Init Doc if missing
    if not existing_doc:
        existing_doc = {
            "zip_code": zip_code,
            "country": country,
            "timestamp": None,
            "languages": {}
        }

    # 2. ENSURE ENGLISH MASTER EXISTS (The "Source of Truth")
    if "en" in existing_doc.get("languages", {}):
        # We have a master record.
        master_intel = existing_doc["languages"]["en"]
        # (Freshness is handled by API Server triggering a force-refresh if needed)
    else:
        # We are missing the master. Must Generate.
        print(f">> [AGENT] Generating Master Intel (EN) for {zip_code}...")
        geo_info = ZoneResolver.resolve_and_measure(zip_code)

        if not master_intel:
             # 1. DYNAMIC COMPLIANCE CHECK (Exclusion Zones)
             is_blocked, zone_info = check_compliance(geo_info['lat'], geo_info['lon'], country, INPUTS_DIR)
             if is_blocked:
                print(f">> [LEGAL] Restricted Zone ({zone_info['name']}). Aborting Generation.")
                # Create Safe Placeholder
                master_intel = {
                    "defcon_status": 5,
                    "location_name": zone_info['name'],
                    "summary": ["Location is in a Restricted Exclusion Zone.", "Intel services unavailable in this sector per local regulations."],
                    "evacuation_point": {"name": "N/A", "lat": 0.0, "lon": 0.0, "reason": "Restricted"},
                    "roads_to_avoid": [],
                    "emergency_avoid_locations": [],
                    "predictive": { "defcon": 5, "forecast_summary": ["Zone Secure"], "risk_probability": 0 }
                }

             else:
                news_text = fetch_news()
                master_intel = generate_master_intel(zip_code, geo_info, news_text)
        
        if master_intel:
            # Inject Fixed Data
            master_intel["last_updated"] = datetime.now().strftime("%Y-%m-%d %H:%M")
            master_intel["user_location"] = { "lat": geo_info['lat'], "lon": geo_info['lon'] }
            
            # DO NOT OVERWRITE with HOTZONES_DATA. Respect AI output if any.
            if "tactical_overlays" not in master_intel:
                master_intel["tactical_overlays"] = []
            
            existing_doc["languages"]["en"] = master_intel
            existing_doc["timestamp"] = datetime.now().isoformat()
            
            # FIX: Inject GeoJSON for Django $near queries
            existing_doc["location_geo"] = {
                "type": "Point",
                "coordinates": [geo_info['lon'], geo_info['lat']]
            }
            
            needs_save = True

    # 3. HANDLE TARGET LANGUAGE (ON DEMAND)
    if target_lang != "en" and master_intel:
        # Check if we ALREADY have this translation
        if target_lang in existing_doc.get("languages", {}):
            print(f">> [AGENT] {target_lang} translation already exists. Skipping AI.")
        else:
            print(f">> [AGENT] Translating Master to {target_lang}...")
            translated_data = translate_intel(master_intel, target_lang)
            
            # Re-inject data AI might have stripped
            translated_data["tactical_overlays"] = master_intel.get("tactical_overlays")
            translated_data["user_location"] = master_intel.get("user_location")
            translated_data["last_updated"] = master_intel.get("last_updated")
            # Sync trend logic
            if "predictive" in master_intel and "predictive" in translated_data:
                 translated_data["predictive"]["forecast_trend"] = master_intel["predictive"].get("forecast_trend")
            
            existing_doc["languages"][target_lang] = translated_data
            needs_save = True
        
    # 4. SAVE (Only if we generated something new)
    if needs_save:
        col.replace_one({"zip_code": zip_code}, existing_doc, upsert=True)
        print(f">> [SUCCESS] Updated DB. Languages available: {list(existing_doc['languages'].keys())}")
    else:
        print(">> [AGENT] No updates required.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--zip", default="10110")
    parser.add_argument("--country", default="TH")
    parser.add_argument("--lang", default="en")
    args = parser.parse_args()
    run_mission(args.zip, args.country, args.lang)
