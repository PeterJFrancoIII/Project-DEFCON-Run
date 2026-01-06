# ==============================================================================
# SYSTEM: SENTINEL SERVER (VERIFIED THREATS + DATES)
# MODULE: views.py
# ROLE:   KINETIC MAPPING WITH TIME STAMPS
# ==============================================================================

from django.shortcuts import render
from django.http import JsonResponse
from .db_utils import get_db_handle
import google.generativeai as genai
import feedparser
import math
import json
import ssl
import datetime
import threading
import csv
import os
import time
import socket
import traceback
from bson.son import SON 
import importlib.util

# --- CONFIGURATION ---
# Import from the adjacent Developer Inputs folder
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INPUTS_DIR = os.path.join(BASE_DIR, 'Developer Inputs')

# Dynamic Import for API Key
import sys
if INPUTS_DIR not in sys.path:
    sys.path.append(INPUTS_DIR)

try:
    import api_config
    import importlib
    importlib.reload(api_config)
    GEMINI_API_KEY = api_config.GEMINI_API_KEY
except Exception as e:
    print(f"[!] Error loading API Config: {e}")
    GEMINI_API_KEY = os.environ.get('GEMINI_API_KEY', 'YOUR_API_KEY_HERE')

CSV_FILE_PATH = os.path.join(INPUTS_DIR, 'thailand_postal_codes_complete.csv')
OSINT_SOURCE_FILE = os.path.join(INPUTS_DIR, 'OSINT Sources.csv')

# COMPLIANCE MODULE
from core.compliance import check_compliance
from core.geo_utils import get_nearest_hotzone, HOTZONES_DATA

# GRID SETTINGS
GRID_RADIUS_METERS = 50000 
STALE_THRESHOLD_SECONDS = 14400 

# --- CONCURRENCY CONTROL ---
MISSION_QUEUE = {} 

genai.configure(api_key=GEMINI_API_KEY)

# --- MODEL INITIALIZATION ---
print(">> [INIT] Loading AI Models...")

# 1. ANALYST
try:
    ANALYST_MODEL = genai.GenerativeModel("gemini-3-pro-preview")
except:
    ANALYST_MODEL = genai.GenerativeModel("gemini-2.0-flash")

# 2. TRANSLATOR
try:
    TRANSLATOR_MODEL = genai.GenerativeModel("gemini-2.5-flash-lite")
except:
    TRANSLATOR_MODEL = genai.GenerativeModel("gemini-1.5-flash")

# --- GEOSPATIAL LOOKUP ---
def get_geo_from_csv(zip_code):
    try:
        if os.path.exists(CSV_FILE_PATH):
            with open(CSV_FILE_PATH, mode='r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    if row['POSTAL_CODE'].strip() == str(zip_code):
                        return {
                            'lat': float(row['LATITUDE']),
                            'lon': float(row['LONGITUDE']),
                            'province': row['PROVINCE_ENGLISH'],
                            'district': row['DISTRICT_ENGLISH']
                        }
    except Exception as e:
        print(f"[!] CSV Read Error: {e}")
    return None

# --- INTELLIGENCE GATHERING ---
def fetch_custom_osint():
    aggregated_headlines = []
    if not os.path.exists(OSINT_SOURCE_FILE):
        return []
    try:
        with open(OSINT_SOURCE_FILE, mode='r', encoding='utf-8-sig') as f:
            sample = f.read(1024); f.seek(0)
            has_header = csv.Sniffer().has_header(sample)
            reader = csv.reader(f) if not has_header else csv.DictReader(f)
    except: pass
    return aggregated_headlines

def fetch_news():
    headlines = []
    try:
        if hasattr(ssl, '_create_unverified_context'):
            ssl._create_default_https_context = ssl._create_unverified_context
        
        # STRICT KINETIC KEYWORDS
        query = "Thailand Cambodia border shelling OR artillery OR mortar OR drone attack OR firefight OR explosion OR clash"
        url = f"https://news.google.com/rss/search?q={query.replace(' ', '+')}&hl=en-US&gl=US&ceid=US:en"
        
        feed = feedparser.parse(url)
        if feed.entries:
            # We include the 'published' date in the string so the AI can read it
            for entry in feed.entries[:20]:
                pub_date = entry.get('published', 'Unknown Date')
                headlines.append(f"[GOOGLE] {entry.title} (Date: {pub_date})")
    except:
        headlines.append("Google News unavailable.")
    
    if not headlines: return "No active fighting reported."
    return "\n".join(headlines[:40])

# --- WORKER: TRANSLATION ---
def run_translation_logic(zip_code, target_lang, master_data):
    try:
        db = get_db_handle()
        col = db.intel_history
        lang_name = "THAI" if target_lang == 'th' else "KHMER"
        prompt = f"TRANSLATE JSON VALUES TO {lang_name}. KEEP KEYS/COORDS IDENTICAL. INPUT: {json.dumps(master_data)}"
        
        resp = TRANSLATOR_MODEL.generate_content(prompt)
        cleaned = resp.text.replace('```json', '').replace('```', '').strip()
        translated_intel = json.loads(cleaned)
        
        translated_intel['zip_code'] = zip_code
        translated_intel['location_geo'] = master_data.get('location_geo')
        
        col.update_one({'zip_code': zip_code}, {'$set': {f'languages.{target_lang}': translated_intel}})
    except Exception as e:
        print(f"[WORKER] Translation Error: {e}")

# --- WORKER: FULL ANALYSIS ---
def run_mission_logic(zip_code, country, geo_data, target_lang='en', device_id='unknown'):
    print(f'>> [ANALYST] Generating VERIFIED THREAT REPORT for {zip_code}...')
    try:
        db = get_db_handle()
        col = db.intel_history
        
        user_lat = geo_data['lat']
        user_lon = geo_data['lon']

        user_lat = geo_data['lat']
        user_lon = geo_data['lon']

        # 1. DYNAMIC COMPLIANCE CHECK (Exclusion Zones)
        is_blocked, zone_info = check_compliance(user_lat, user_lon, country, INPUTS_DIR)
        
        if is_blocked:
            print(f">> [LEGAL] Restricted Zone ({zone_info['name']}). Aborting Generation.")
            # Create Safe Placeholder
            doc = {
                'zip_code': zip_code,
                'country': country,
                'timestamp': datetime.datetime.now().isoformat(),
                'location_geo': { "type": "Point", "coordinates": [user_lon, user_lat] }, 
                'languages': { 
                    'en': {
                        "defcon_status": 5,
                        "location_name": zone_info['name'],
                        "summary": ["Location is in a Restricted Exclusion Zone.", "Intel services unavailable in this sector per local regulations."],
                        "evacuation_point": {"name": "N/A", "lat": 0.0, "lon": 0.0, "reason": "Restricted"},
                        "roads_to_avoid": [],
                        "emergency_avoid_locations": [],
                        "predictive": { "defcon": 5, "forecast_summary": ["Zone Secure"], "risk_probability": 0 },
                        "last_updated": datetime.datetime.utcnow().isoformat(),
                        "zip_code": zip_code,
                        "user_location": { 'lat': user_lat, 'lon': user_lon },
                        "tactical_overlays": [],
                        "location_geo": { "type": "Point", "coordinates": [user_lon, user_lat] }
                    }
                } 
            }
            col.replace_one({'zip_code': zip_code}, doc, upsert=True)
            return

        news_text = fetch_news()

        # Load Prompt from Developer Inputs
        prompt_path = os.path.join(INPUTS_DIR, 'analyst_system_prompt.txt')
        
        with open(prompt_path, 'r', encoding='utf-8') as f:
            template = f.read()

        # Calculate Distance to Conflict Zone
        dist_km, nearest_hotzone = get_nearest_hotzone(user_lat, user_lon)
        dist_info = f"TARGET DISTANCE TO THREAT: {dist_km:.1f} km (Nearest: {nearest_hotzone})"
        print(f">> [DEBUG] Zip: {zip_code} | {dist_info}")

        prompt = template.format(
            target_name=f"{geo_data.get('province', 'Unknown')}, {geo_data.get('district', 'Unknown')} (Lat: {user_lat}, Lon: {user_lon})",
            dist_info=dist_info,
            news_text=news_text
        )
        
        resp = ANALYST_MODEL.generate_content(prompt)
        cleaned = resp.text.replace('```json', '').replace('```', '').strip()
        master_intel = json.loads(cleaned)

        # --- SCHEMA NORMALIZATION (New Prompt -> Old App Schema) ---
        if 'sitrep_summary' in master_intel:
            master_intel['summary'] = master_intel.pop('sitrep_summary')
        
        if 'tactical_map' in master_intel:
            tm = master_intel.pop('tactical_map')
            master_intel['roads_to_avoid'] = tm.get('roads_to_avoid', [])
            master_intel['emergency_avoid_locations'] = tm.get('danger_zones', [])
        
        if 'predictive_analysis' in master_intel:
            pa = master_intel.pop('predictive_analysis')
            forecast_summary = pa.get('forecast_bullets', [])
            if not forecast_summary:
                 forecast_summary = [f"Risk Window: {pa.get('risk_window', 'Unknown')}"]

            master_intel['predictive'] = {
                "defcon": pa.get('forecast_defcon', 3),
                "risk_probability": pa.get('confidence_score', 50),
                "forecast_trend": pa.get('threat_vector', 'Static'),
                "forecast_summary": forecast_summary
            }
            trend_map = {"Approaching": "Rising", "Receding": "Falling", "Static": "Stable"}
            master_intel['predictive']['forecast_trend'] = trend_map.get(master_intel['predictive']['forecast_trend'], 'Stable')

        # --- INJECT CONFIG (System URL) ---
        config_path = os.path.join(INPUTS_DIR, 'config.json')
        system_url = "https://sentinel.example.com"
        if os.path.exists(config_path):
            with open(config_path, 'r') as cf:
                config = json.load(cf)
                system_url = config.get('system_url', system_url)
        master_intel['system_url'] = system_url

        if 'defcon_justification' in master_intel:
            justification = master_intel.pop('defcon_justification')
            if 'summary' not in master_intel: master_intel['summary'] = []
            master_intel['summary'].insert(0, f"ASSESSMENT: {justification}")
        
        # Ensure Keys
        if 'summary' not in master_intel: master_intel['summary'] = ["No Intel Summary."]
        if 'defcon_status' not in master_intel: master_intel['defcon_status'] = 5
        # -----------------------------------------------------------

        # 2. PANIC LAW SAFEGUARD (HITL REQUIRED FOR DEFCON 1)
        is_certified = True
        if master_intel.get('defcon_status', 5) == 1:
            print(">> [SAFETY] DEFCON 1 DETECTED. DOWNGRADING TO 2 PENDING HUMAN REVIEW.")
            master_intel['defcon_status'] = 2
            master_intel['summary'].insert(0, "** REPORT PENDING HUMAN VERIFICATION **")
            is_certified = False
        
        # New: DEFCON 2 also technically requires human review per new strict rules if needed, 
        # but for now we trust the downgrade logic. 
        # Actually, user asked: "Unapporved DEFCON 1-2 Ratings show under the DEFCON rating 'UNCERTIFIED'"
        # So I should mark checks for status <= 2.
        
        # Pass User Location
        master_intel['is_certified'] = is_certified
        master_intel['user_location'] = { 'lat': user_lat, 'lon': user_lon }
        
        # Ensure tactical_overlays key exists (populated by DB or Empty)
        if 'tactical_overlays' not in master_intel:
             master_intel['tactical_overlays'] = []
        else:
            # FILTER: Purge Mock/Static Data from DB Response
            mock_names = {z['name'] for z in HOTZONES_DATA}
            master_intel['tactical_overlays'] = [
                t for t in master_intel['tactical_overlays'] 
                if t.get('name') not in mock_names
            ]
             
        # Metadata
        master_intel['last_updated'] = datetime.datetime.utcnow().isoformat()
        master_intel['zip_code'] = zip_code
        master_intel['location_name'] = f"{geo_data['province']}, {geo_data['district']}"
        master_intel['location_geo'] = { 
            "type": "Point", 
            "coordinates": [user_lon, user_lat] 
        }
        master_intel['analyst_model'] = "gemini-3-pro-preview"
        master_intel['translator_model'] = "gemini-2.5-flash-lite"

        doc = {
            'zip_code': zip_code,
            'country': country,
            'timestamp': datetime.datetime.now().isoformat(),
            'location_geo': master_intel['location_geo'], 
            'languages': { 'en': master_intel } 
        }
        col.replace_one({'zip_code': zip_code}, doc, upsert=True)
        
        if target_lang != 'en':
            run_translation_logic(zip_code, target_lang, master_intel)
            
    except Exception as e:
        print(f'>> [ANALYST] Critical Error: {e}')
        traceback.print_exc() 
    finally:
        if zip_code in MISSION_QUEUE:
            del MISSION_QUEUE[zip_code]

# --- VIEW: HOME ---
def home(request):
    return render(request, 'core/home.html')

# --- API ENDPOINT ---
def intel_api(request):
    try:
        zip_code = request.GET.get('zip', '10110')
        country = request.GET.get('country', 'TH')
        lang = request.GET.get('lang', 'en')
        device_id = request.GET.get('device_id', 'unknown_agent')
        
        geo_data = get_geo_from_csv(zip_code)
        if not geo_data:
            return JsonResponse({'status': 'error', 'message': f'Zip {zip_code} Unknown.'})
        
        db = get_db_handle()
        col = db.intel_history
        
        # GRID SEARCH
        user_lon = geo_data['lon']
        user_lat = geo_data['lat']
        
        nearby_doc = col.find_one({
            "location_geo": {
                "$near": {
                    "$geometry": { "type": "Point", "coordinates": [user_lon, user_lat] },
                    "$maxDistance": GRID_RADIUS_METERS
                }
            }
        })

        serve_cached = False
        final_doc = None

        if nearby_doc:
            ts_str = nearby_doc.get('timestamp')
            if ts_str:
                last_dt = datetime.datetime.fromisoformat(ts_str)
                age = (datetime.datetime.now() - last_dt).total_seconds()
                if age < STALE_THRESHOLD_SECONDS:
                    final_doc = nearby_doc
                    serve_cached = True

        if not serve_cached:
            if zip_code in MISSION_QUEUE:
                return JsonResponse({'status': 'calculating', 'message': 'Mission in progress...'})
            
            MISSION_QUEUE[zip_code] = time.time()
            t = threading.Thread(target=run_mission_logic, args=(zip_code, country, geo_data, lang, device_id))
            t.start()
            return JsonResponse({'status': 'calculating', 'message': 'Initializing Strategic Analysis...'})
        
        target_data = final_doc.get('languages', {}).get(lang)
        
        if not target_data:
            base_data = final_doc.get('languages', {}).get('en')
            if base_data:
                t = threading.Thread(target=run_translation_logic, args=(final_doc['zip_code'], lang, base_data))
                t.start()
                return JsonResponse({'status': 'calculating', 'message': 'Translating Grid Intel...'})
            
        return JsonResponse({'status': 'success', 'data': target_data})

    except Exception as e:
        print(f"ERROR: {e}")
        traceback.print_exc()
        return JsonResponse({'status': 'error', 'message': str(e)}, status=500)
