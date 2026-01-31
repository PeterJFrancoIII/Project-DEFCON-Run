
import os
import datetime
import json
import ssl
import csv
import hashlib
import time
import feedparser
import pytz
from dateutil import parser as date_parser
import google.generativeai as genai
import traceback

from core.db_utils import get_db_handle
from core.compliance import check_compliance
from core.geo_utils import get_nearest_hotzone, HOTZONES_DATA
from core import geo_utils

# --- CONFIGURATION ---
BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
INPUTS_DIR = os.path.join(BASE_DIR, 'Developer Inputs')

# API Key Loading
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

OSINT_SOURCE_FILE = os.path.join(INPUTS_DIR, 'OSINT Sources.csv')
CSV_FILE_PATH = os.path.join(INPUTS_DIR, 'thailand_postal_codes_complete.csv')

genai.configure(api_key=GEMINI_API_KEY)

# --- LOGGING ---
LOG_FILE = os.path.join(BASE_DIR, 'server.log')

def log(message):
    """Writes to stdout and server.log for the GUI CLI."""
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    formatted = f"[{timestamp}] {message}"
    print(formatted) 
    try:
        with open(LOG_FILE, "a") as f:
            f.write(formatted + "\n")
    except Exception as e:
        print(f"[!] Log Write Error: {e}")

# --- CONCURRENCY CONTROL ---
MISSION_QUEUE = {}

# --- MODEL INITIALIZATION ---
log(">> [INIT] Loading AI Models...")

try:
    ANALYST_MODEL = genai.GenerativeModel("gemini-3-pro-preview")
except:
    ANALYST_MODEL = genai.GenerativeModel("gemini-2.0-flash")

try:
    TRANSLATOR_MODEL = genai.GenerativeModel("gemini-2.5-flash-lite")
except:
    TRANSLATOR_MODEL = genai.GenerativeModel("gemini-1.5-flash")

# --- SHARED FUNCTIONS ---

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

def get_msg_hash(text):
    return hashlib.md5(text.encode('utf-8')).hexdigest()

def update_status(stage):
    try:
        db = get_db_handle()
        db.system_status.replace_one(
            {"_id": "global_status"}, 
            {"current_stage": stage, "last_updated": time.time()}, 
            upsert=True
        )
    except Exception as e:
        print(f"[!] Status Update Error: {e}")

def fetch_news():
    update_status("Fetching Sources")
    structured_news = []
    formatted_headlines = []
    
    try:
        if hasattr(ssl, '_create_unverified_context'):
            ssl._create_default_https_context = ssl._create_unverified_context
        
        # STRICT KINETIC KEYWORDS
        query = "Thailand Cambodia border shelling OR artillery OR mortar OR drone attack OR firefight OR explosion OR clash"
        url = f"https://news.google.com/rss/search?q={query.replace(' ', '+')}&hl=en-US&gl=US&ceid=US:en"
        
        feed = feedparser.parse(url)
        
        db = get_db_handle()
        news_col = db.news_index
        
        now_utc = datetime.datetime.now(pytz.utc)
        min_date = now_utc - datetime.timedelta(days=3) # Ignore news older than 3 days
        
        if feed.entries:
            for entry in feed.entries[:30]:
                # 1. Normalize Date (UTC)
                try:
                    pub_date = date_parser.parse(entry.get('published', str(datetime.datetime.now())))
                    if pub_date.tzinfo is None: 
                        pub_date = pub_date.replace(tzinfo=pytz.utc)
                    else: 
                        pub_date = pub_date.astimezone(pytz.utc)
                except:
                    pub_date = now_utc

                # 2. Check Age
                if pub_date < min_date:
                    continue

                # 3. Check Drift (Duplicate Detection)
                # We use Canonical URL (if available) or Link, plus Title Hash
                canonical = entry.get('link', '')
                title_clean = entry.title.strip().lower()
                
                url_hash = get_msg_hash(canonical)
                title_hash = get_msg_hash(title_clean)
                
                # DB LOOKUP
                # Check if we have seen this content hash before
                existing_doc = news_col.find_one({
                    "$or": [
                        {"url_hash": url_hash}, 
                        {"title_hash": title_hash}
                    ]
                })

                if existing_doc:
                    # Update 'last_seen'
                    news_col.update_one(
                        {"_id": existing_doc["_id"]}, 
                        {"$set": {"last_seen_at_utc": now_utc.isoformat()}}
                    )
                    continue 
                
                # INSERT NEW
                news_doc = {
                    "url_hash": url_hash,
                    "title_hash": title_hash,
                    "title": entry.title,
                    "link": entry.link,
                    "source": entry.get('source', {}).get('title', 'Google News'),
                    "published_at_utc": pub_date.isoformat(),
                    "first_seen_at_utc": now_utc.isoformat(),
                    "last_seen_at_utc": now_utc.isoformat(),
                    "status": "Unconfirmed" # Default label
                }
                news_col.insert_one(news_doc)
                
                news_item = {
                    "id": url_hash[:8], 
                    "title": entry.title,
                    "date": pub_date.isoformat(),
                    "source": entry.get('source', {}).get('title', 'Google News'),
                    "link": entry.link
                }
                structured_news.append(news_item)
                formatted_headlines.append(f"[ID: {news_item['id']}] {news_item['title']} ({news_item['date']})")

    except Exception as e:
        formatted_headlines.append(f"News Error: {e}")
        print(f"[!] News Fetch Error: {e}")
    
    if not formatted_headlines: 
        return "No recent kinetic reports.", []
        
    return "\n".join(formatted_headlines[:40]), structured_news[:40]

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

def run_mission_logic(zip_code, country, geo_data, target_lang='en', device_id='unknown'):
    log(f'>> [ANALYST] Generating VERIFIED THREAT REPORT for {zip_code}...')
    update_status("Connecting")
    
    try:
        db = get_db_handle()
        col = db.intel_history
        
        user_lat = geo_data['lat']
        user_lon = geo_data['lon']

        # 1. DYNAMIC COMPLIANCE CHECK (Exclusion Zones)
        is_blocked, zone_info = check_compliance(user_lat, user_lon, country, INPUTS_DIR)
        
        if is_blocked:
            log(f">> [LEGAL] Restricted Zone ({zone_info['name']}). Aborting Generation.")
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

        # Fetch Previous Context for Trend Analysis
        prev_doc = col.find_one({'zip_code': zip_code})
        prev_defcon = 5
        prev_trend = "Stable"
        prev_verified = False

        if prev_doc:
             try:
                 prev_intel = prev_doc.get('languages', {}).get('en', {})
                 prev_defcon = prev_intel.get('defcon_status', 5)
                 prev_trend = prev_intel.get('predictive', {}).get('forecast_trend', 'Stable')
                 prev_verified = prev_intel.get('is_certified', False)
             except: pass
        
        context_str = f" [PREVIOUS STATE: DEFCON {prev_defcon} ({prev_trend})]"

        news_text, structured_news_data = fetch_news()

        # Load Prompt from Developer Inputs
        prompt_path = os.path.join(INPUTS_DIR, 'analyst_system_prompt.txt')
        
        with open(prompt_path, 'r', encoding='utf-8') as f:
            template = f.read()

        # Calculate Distance to Conflict Zone
        dist_km, nearest_hotzone = get_nearest_hotzone(user_lat, user_lon)
        dist_info = f"TARGET DISTANCE TO THREAT: {dist_km:.1f} km (Nearest: {nearest_hotzone}){context_str}"
        log(f">> [DEBUG] Zip: {zip_code} | {dist_info}")

        prompt = template.format(
            target_name=f"{geo_data.get('province', 'Unknown')}, {geo_data.get('district', 'Unknown')} (Lat: {user_lat}, Lon: {user_lon})",
            dist_info=dist_info,
            news_text=news_text,
            current_date=datetime.datetime.now().strftime("%Y-%m-%d")
        )
        
        update_status("Analyst Running")
        resp = ANALYST_MODEL.generate_content(prompt)
        cleaned = resp.text.replace('```json', '').replace('```', '').strip()
        master_intel = json.loads(cleaned)

        # --- SCHEMA NORMALIZATION ---

        # 0. CALCULATE THREAT DELTA (Explicit Python Logic)
        # 5 -> 4 = Rising Threat. 4 -> 5 = Falling Threat.
        calc_trend = "Stable"
        new_defcon = master_intel.get('defcon_status', 5)
        
        if new_defcon < prev_defcon:
            calc_trend = "Rising"
        elif new_defcon > prev_defcon:
            calc_trend = "Falling"
        
        # Override AI hallucination if strictly mathematical change occurred
        if new_defcon != prev_defcon:
             if 'defcon_inputs' not in master_intel: master_intel['defcon_inputs'] = {}
             master_intel['defcon_inputs']['trend_24h'] = calc_trend
             # Also update predictive trend to match trajectory
             if 'predictive' not in master_intel: master_intel['predictive'] = {}
             master_intel['predictive']['forecast_trend'] = calc_trend

        
        # 1. Map 'sitrep_entries' -> 'summary' (For Backward Compatibility)
        if 'sitrep_entries' in master_intel:
            # Create the old array of strings for clients that don't support objects yet
            master_intel['summary'] = [
                f"**{api['topic']}**: {api['summary']}" 
                for api in master_intel['sitrep_entries']
            ]
        
        if 'tactical_map' in master_intel:
            tm = master_intel.pop('tactical_map')
            master_intel['roads_to_avoid'] = tm.get('roads_to_avoid', [])
            master_intel['emergency_avoid_locations'] = tm.get('danger_zones', [])
        
        if 'predictive_analysis' in master_intel:
            pa = master_intel.get('predictive_analysis') # Keep it for new clients
            forecast_summary = []
            
            # If forecast_entries exists (New Schema), use it to populate forecast_summary
            if 'forecast_entries' in master_intel:
                forecast_summary = [
                    f"{f['topic']}: {f['prediction']}"
                    for f in master_intel['forecast_entries']
                ]
            elif 'forecast_bullets' in pa:
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
        system_url = "https://sentinelcivilianriskanalysis.netlify.app"
        donate_url = "https://paypal.me/sentineldev"
        if os.path.exists(config_path):
            with open(config_path, 'r') as cf:
                config = json.load(cf)
                system_url = config.get('system_url', system_url)
                donate_url = config.get('donate_url', donate_url)
        master_intel['system_url'] = system_url
        master_intel['donate_url'] = donate_url

        # --- FIX: EVACUATION DISTANCE ---
        # Ensure Evac Point has a distance calculated if missing
        if 'evacuation_point' in master_intel:
             ep = master_intel['evacuation_point']
             if ep.get('lat') and ep.get('lon'):
                 try:
                     dist = geo_utils.haversine_distance(user_lat, user_lon, ep['lat'], ep['lon'])
                     master_intel['evacuation_point']['distance_km'] = round(dist, 1)
                 except: pass
             else:
                 # Fallback if AI failed to provide coordinates
                  master_intel['evacuation_point']['name'] = "Check Local Media"
                  master_intel['evacuation_point']['reason'] = "Precise Coordinates Unavailable"

        if 'defcon_justification' in master_intel:
            justification = master_intel.pop('defcon_justification')
            if 'summary' not in master_intel: master_intel['summary'] = []
            master_intel['summary'].insert(0, f"ASSESSMENT: {justification}")
        
        # Ensure Keys
        if 'summary' not in master_intel: master_intel['summary'] = ["No Intel Summary."]
        if 'defcon_status' not in master_intel: master_intel['defcon_status'] = 5
        # -----------------------------------------------------------

        # 2. PANIC LAW SAFEGUARD (HITL REQUIRED FOR DEFCON 1 & 2)
        is_certified = True
        new_defcon = master_intel.get('defcon_status', 5)
        
        if new_defcon <= 2:
            if prev_verified and prev_defcon == new_defcon:
                is_certified = True
                log(f">> [SAFETY] DEFCON {new_defcon} Verified by Persistent Approval.")
            else:
                is_certified = False
                log(f">> [SAFETY] DEFCON {new_defcon} Unconfirmed. Pending HITL.")
                master_intel['summary'].insert(0, "** ALERT: UNCONFIRMED RATING - PENDING HUMAN REVIEW **")
        
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
        
        col.replace_one({'zip_code': zip_code}, doc, upsert=True)
        
        update_status("Translator Running")
        if target_lang != 'en':
            run_translation_logic(zip_code, target_lang, master_intel)
            
        update_status("Done")
            
    except Exception as e:
        log(f'>> [ANALYST] Critical Error: {e}')
        traceback.print_exc() 
    finally:
        pass
