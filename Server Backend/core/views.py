# ==============================================================================
# SYSTEM: SENTINEL SERVER (VERIFIED THREATS + DATES)
# MODULE: views.py
# ROLE:   KINETIC MAPPING WITH TIME STAMPS
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

# --- CONFIGURATION ---
GEMINI_API_KEY = 'AIzaSyC8wk8UL-BirT2OckoenrEM6-iOxsMU1jA'
CSV_FILE_PATH = 'thailand_postal_codes_complete.csv'
OSINT_SOURCE_FILE = 'OSINT Sources.csv'

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
        news_text = fetch_news()

        prompt = f'''
        ACT AS A KINETIC WARFARE ANALYST.
        USER LOCATION: {geo_data['province']}, {geo_data['district']} ({user_lat}, {user_lon}).
        
        INTELLIGENCE FEED:
        {news_text}
        
        MAPPING RULES (VERIFIED & PERSISTENT):
        1. FILTER: Map ONLY threats that have STRUCK (Impacts, Explosions) and pose a PERSISTENT DANGER (e.g. Established Artillery Position, Active Drone Zone).
        2. EXCLUDE: Do not map "Warnings", "Threats to fire", or "Troop Movements" without contact.
        3. DATES: You MUST extract the Short Date (e.g. "Dec 30") of the event and include it in the data.
        
        OUTPUT JSON ONLY:
        {{
            "defcon_status": (int 1-5),
            "trend": "Stable/Falling/Rising",
            "threat_distance_km": (float distance to nearest ACTIVE threat),
            
            "tactical_overlays": [
                {{ 
                    "name": "Location Name", 
                    "type": "Artillery/Drones", 
                    "date": "MMM DD", 
                    "lat": (float), 
                    "lon": (float), 
                    "radius": (int meters) 
                }}
            ],
            
            "evacuation_point": {{ "name": "City", "lat": (float), "lon": (float), "distance_km": (float), "reason": "Reason" }},
            "roads_to_avoid": [], 
            "emergency_avoid_locations": [],
            "summary": ["1...", "2...", "3...", "4...", "5..."],
            "predictive": {{
                "defcon": (int),
                "trend": "Stable/Falling/Rising",
                "forecast_summary": ["1...", "2...", "3...", "4...", "5..."],
                "risk_probability": (int 0-100)
            }}
        }}
        '''
        
        resp = ANALYST_MODEL.generate_content(prompt)
        cleaned = resp.text.replace('```json', '').replace('```', '').strip()
        master_intel = json.loads(cleaned)
        
        # Pass User Location
        master_intel['user_location'] = { 'lat': user_lat, 'lon': user_lon }
        
        # Metadata
        master_intel['last_updated'] = datetime.datetime.utcnow().isoformat()
        master_intel['zip_code'] = zip_code
        master_intel['location_name'] = f"{geo_data['province']}, {geo_data['district']}"
        master_intel['location_geo'] = { 
            "type": "Point", 
            "coordinates": [user_lon, user_lat] 
        }

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

