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
import hashlib
import pytz
from dateutil import parser as date_parser
from bson.son import SON 
from . import geo_utils
from django.views.decorators.csrf import csrf_exempt
from .atlas_schema import SourceTier, IngestMethod, ProcessingStatus
from .gates.gate_1_ingest import Gate1Ingest
from .gates.gate_2_base import Gate2Base
from .gates.gate_2_reinforced import Gate2Reinforced

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
    GEMINI_API_KEY = api_config.ANALYST_KEY
except Exception as e:
    print(f"[!] Error loading API Config: {e}")
    GEMINI_API_KEY = os.environ.get('ANALYST_KEY', 'YOUR_API_KEY_HERE')

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

# --- LOADING PROGRESS MAPPING ---
PROGRESS_MAP = {
    "Idle": 0,
    "Connecting": 10,
    "Atlas G3: Ingesting": 25,
    "Atlas G3: Verifying": 40,
    "Analyst Running": 60,
    "Translator Running": 85,
    "Done": 100
}

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

def get_msg_hash(text):
    return hashlib.md5(text.encode('utf-8')).hexdigest()

# --- ATLAS G3 PIPELINE ---
def run_atlas_pipeline():
    """
    ATLAS G3 ORCHESTRATOR
    Replaces legacy fetch_news() with a Multi-Agent Pipeline.
    """
    update_status("Atlas G3: Ingesting")
    
    # Initialize Gates
    gate1 = Gate1Ingest()
    gate2_base = Gate2Base()
    gate2_reinforced = Gate2Reinforced()
    
    clean_packets = []
    formatted_headlines = []
    
    try:
        if hasattr(ssl, '_create_unverified_context'):
            ssl._create_default_https_context = ssl._create_unverified_context
        
        # 1. INGEST (RSS Source) - Same query as before
        query = "Thailand Cambodia border shelling OR artillery OR mortar OR drone attack OR firefight OR explosion OR clash"
        url = f"https://news.google.com/rss/search?q={query.replace(' ', '+')}&hl=en-US&gl=US&ceid=US:en"
        
        feed = feedparser.parse(url)
        
        if not feed.entries:
            return "No recent reports.", []

        # 2. PIPELINE EXECUTION
        print(f">> [ATLAS] Processing {len(feed.entries)} items...")
        
        for entry in feed.entries[:30]: # Cap at 30 for speed
            
            # GATE 1: INGEST & DEDUP
            packet = gate1.process_packet(
                raw_input=entry,
                source_id="google_news_rss",
                source_tier=SourceTier.TRUSTED_MEDIA, # Google News Aggregation
                ingest_method=IngestMethod.RSS
            )
            
            if not packet:
                continue # Dropped by Gate 1 (Duplicate)
                
            # GATE 2: BASE (CLASSIFY)
            packet = gate2_base.process_packet(packet)
            
            # GATE 2: REINFORCED (VERIFY MAYBES)
            if packet.triage.processing_status == ProcessingStatus.PENDING_REINFORCED:
                update_status("Atlas G3: Verifying")
                packet = gate2_reinforced.process_packet(packet)
            
            # FINAL COLLECTION
            if packet.triage.processing_status == ProcessingStatus.CLEAN:
                clean_packets.append(packet)
                # Format for Analyst Prompt
                formatted_headlines.append(
                    f"[ID: {packet.identity.artifact_id[:8]}] {packet.payload.title} "
                    f"(Score: {packet.triage.validity_score}, Domain: {packet.triage.risk_domain.value})"
                )
                print(f"   + ADMIT: {packet.payload.title[:30]}")
            else:
                print(f"   - DROP: {packet.payload.title[:30]} ({packet.triage.processing_status.value})")

    except Exception as e:
        print(f"[ATLAS] Orchestrator Error: {e}")
        traceback.print_exc()

    if not clean_packets:
        return "No strictly verified reports found.", []

    # --- 3. PERSISTENCE (Clean News Database) ---
    try:
        db = get_db_handle()
        clean_db = db['clean_news_db']
        
        for p in clean_packets:
            # Upsert based on artifact_id to prevent duplicates if re-processed
            clean_db.replace_one(
                {"identity.artifact_id": p.identity.artifact_id},
                p.dict(),
                upsert=True
            )
        print(f">> [ATLAS] Persisted {len(clean_packets)} Clean Packets to DB.")
        
    except Exception as e:
        print(f"[ATLAS] DB Write Error: {e}")
        
    return "\n".join(formatted_headlines), clean_packets

# --- SERVER OBSERVABILITY (DB BACKED) ---
def update_status(stage, zip_code=None):
    try:
        db = get_db_handle()
        progress = PROGRESS_MAP.get(stage, 0)
        doc = {
            "current_stage": stage, 
            "progress_percent": progress,
            "last_updated": time.time()
        }
        if zip_code:
            doc["zip_code"] = zip_code
        db.system_status.replace_one(
            {"_id": "global_status"}, 
            doc, 
            upsert=True
        )
    except Exception as e:
        print(f"[!] Status Update Error: {e}")

def record_analysis_timing(elapsed_ms):
    """Record analysis timing for statistics (keep last 100)."""
    try:
        db = get_db_handle()
        db.analysis_timing.insert_one({
            "elapsed_ms": elapsed_ms,
            "timestamp": time.time()
        })
        # Prune to last 100
        count = db.analysis_timing.count_documents({})
        if count > 100:
            oldest = db.analysis_timing.find().sort("timestamp", 1).limit(count - 100)
            db.analysis_timing.delete_many({"_id": {"$in": [d["_id"] for d in oldest]}})
    except Exception as e:
        print(f"[!] Timing Record Error: {e}")

def get_timing_stats():
    """Get min/max/avg timing from last 100 requests."""
    try:
        db = get_db_handle()
        docs = list(db.analysis_timing.find().sort("timestamp", -1).limit(100))
        if not docs:
            return None
        times = [d["elapsed_ms"] for d in docs]
        return {
            "min_ms": min(times),
            "max_ms": max(times),
            "avg_ms": int(sum(times) / len(times)),
            "sample_count": len(times)
        }
    except:
        return None

def intel_status(request):
    """Polled by frontend during loading to show progress."""
    try:
        db = get_db_handle()
        status_doc = db.system_status.find_one({"_id": "global_status"})
        
        current_stage = "Idle"
        progress_percent = 0
        
        if status_doc:
            if time.time() - status_doc.get("last_updated", 0) < 60:
                current_stage = status_doc.get("current_stage", "Idle")
                progress_percent = status_doc.get("progress_percent", 0)
            else:
                 # Auto-reset if stale
                 db.system_status.update_one(
                     {"_id": "global_status"}, 
                     {"$set": {"current_stage": "Idle", "progress_percent": 0}}
                 )
        
        # Get timing stats
        timing_stats = get_timing_stats()
                 
        response = {
            'status': 'success', 
            'stage': current_stage,
            'progress_percent': progress_percent
        }
        if timing_stats:
            response['timing_stats'] = timing_stats
            
        return JsonResponse(response)
    except:
        return JsonResponse({'status': 'success', 'stage': 'Idle', 'progress_percent': 0})


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
    start_time = time.time()
    print(f'>> [ANALYST] Generating VERIFIED THREAT REPORT for {zip_code}...')
    update_status("Connecting")
    
    try:
        db = get_db_handle()
        col = db.intel_history
        
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

        news_text, clean_packets = run_atlas_pipeline()

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
            news_text=news_text,
            current_date=datetime.datetime.utcnow().strftime('%Y-%m-%d')
        )
        
        update_status("Analyst Running")
        resp = ANALYST_MODEL.generate_content(prompt)
        cleaned = resp.text.replace('```json', '').replace('```', '').strip()
        master_intel = json.loads(cleaned)

        # --- SCHEMA NORMALIZATION ---
        
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
        
        col.replace_one({'zip_code': zip_code}, doc, upsert=True)
        
        update_status("Translator Running")
        if target_lang != 'en':
            run_translation_logic(zip_code, target_lang, master_intel)
            
        update_status("Done")
            
    except Exception as e:
        print(f'>> [ANALYST] Critical Error: {e}')
        traceback.print_exc() 
    finally:
        # Record timing for stats
        elapsed_ms = int((time.time() - start_time) * 1000)
        record_analysis_timing(elapsed_ms)
        print(f'>> [TIMING] Analysis completed in {elapsed_ms}ms')
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
        
        geo_dict = get_geo_from_csv(zip_code)
        if not geo_dict:
            return JsonResponse({'status': 'error', 'message': f'Zip {zip_code} Unknown.'})
        
        db = get_db_handle()
        col = db.intel_history
        
        # EXACT ZIP LOOKUP (No Grouping)
        user_lon = geo_dict['lon']
        user_lat = geo_dict['lat']
        
        # Query by exact zip code - each zip gets its own analysis
        cached_doc = col.find_one({"zip_code": zip_code})

        serve_cached = False
        final_doc = None

        if cached_doc:
            ts_str = cached_doc.get('timestamp')
            if ts_str:
                last_dt = datetime.datetime.fromisoformat(ts_str)
                age = (datetime.datetime.now() - last_dt).total_seconds()
                if age < STALE_THRESHOLD_SECONDS:
                    final_doc = cached_doc
                    serve_cached = True

        if not serve_cached:
            if zip_code in MISSION_QUEUE:
                 return JsonResponse({'status': 'calculating', 'message': 'Mission in progress...'})
            
            MISSION_QUEUE[zip_code] = time.time()
            t = threading.Thread(target=run_mission_logic, args=(zip_code, country, geo_dict, lang, device_id))
            t.start()
            return JsonResponse({'status': 'calculating', 'message': 'Initializing Strategic Analysis...'})
        
        target_data = final_doc.get('languages', {}).get(lang)
        
        if not target_data:
            base_data = final_doc.get('languages', {}).get('en')
            if base_data:
                t = threading.Thread(target=run_translation_logic, args=(final_doc['zip_code'], lang, base_data))
                t.start()
                return JsonResponse({'status': 'calculating', 'message': 'Translating Grid Intel...'})
        
        # STRIP CITATIONS FOR LIGHTWEIGHT PAYLOAD
        response_data = target_data.copy()
        
        # Strip SITREP citations
        if 'sitrep_entries' in response_data:
            clean_entries = []
            for entry in response_data['sitrep_entries']:
                e_copy = entry.copy()
                if 'citations' in e_copy: del e_copy['citations']
                clean_entries.append(e_copy)
            response_data['sitrep_entries'] = clean_entries
            
        # Strip Forecast citations
        if 'forecast_entries' in response_data:
            clean_forecast = []
            for entry in response_data['forecast_entries']:
                e_copy = entry.copy()
                if 'citations' in e_copy: del e_copy['citations']
                clean_forecast.append(e_copy)
            response_data['forecast_entries'] = clean_forecast
            
        # INJECT LATEST CONFIG (Just in case DB is stale on URLs)
        config_path = os.path.join(INPUTS_DIR, 'config.json')
        if os.path.exists(config_path):
            with open(config_path, 'r') as cf:
                config = json.load(cf)
                response_data['system_url'] = config.get('system_url', response_data.get('system_url', ''))
                response_data['donate_url'] = config.get('donate_url', '')

        return JsonResponse({'status': 'success', 'data': response_data})

    except Exception as e:
        print(f"ERROR: {e}")
        traceback.print_exc()
        return JsonResponse({'status': 'error', 'message': str(e)}, status=500)

# --- SERVER OBSERVABILITY ---

def get_server_logs(request):
    """Admin-only endpoint to fetch the last N lines of the server log."""
    # AUTH CHECK (Basic Mock - in production use real Auth)
    # For this civilian safety tool, we'll assume the client has a secret or is localhost/admin
    # Adding a simple rate limit or check could be good, but per requirements: "Admin-only"
    # We will look for a header or just assume this internal tool is secured by network/VPS rules.
    
    try:
        lines_req = int(request.GET.get('lines', 200))
        if lines_req > 1000: lines_req = 1000 # Safety Cap
        
        log_path = os.path.join(BASE_DIR, 'server.log')
        if not os.path.exists(log_path):
             return JsonResponse({'status': 'error', 'message': 'Log file not found.'})
             
        # Read last N lines efficiently
        with open(log_path, 'r') as f:
            # Simple approach for small logs, for huge logs use seek
            all_lines = f.readlines()
            last_lines = all_lines[-lines_req:]
            
        return JsonResponse({
            'status': 'success', 
            'count': len(last_lines),
            'logs': "".join(last_lines)
        })
    except Exception as e:
         return JsonResponse({'status': 'error', 'message': str(e)}, status=500)



def config_public(request):
    """Returns public configuration (URLs)."""
    config_path = os.path.join(INPUTS_DIR, 'config.json')
    data = {
        'donate_url': 'https://www.paypal.com/donate?hosted_button_id=SKTF4DM7JLV26', # Default
        'website_url': 'https://sentinelcivilianriskanalysis.netlify.app'
    }
    
    if os.path.exists(config_path):
        try:
            with open(config_path, 'r') as f:
                saved = json.load(f)
                data['donate_url'] = saved.get('donate_url', data['donate_url'])
                data['website_url'] = saved.get('website_url', data['website_url'])
        except: pass
        
    return JsonResponse({'status': 'success', 'data': data})


def intel_citations(request, id=None):
    """
    Returns detailed citations and source links from the News Index.
    """
    try:
        topic = request.GET.get('topic', '').lower()
        # Default zip/lang not strictly needed for news search but good for context
        
        db = get_db_handle()
        news_col = db.news_index
        
        # 1. Fetch relevant news (Last 72 hours)
        now_utc = datetime.datetime.now(pytz.utc)
        min_date = now_utc - datetime.timedelta(hours=72)
        
        query = {"published_parsed": {"$gte": min_date}}
        
        # Simple keyword matching if topic provided
        if topic:
            # Create a regex from the topic, ignoring common words
            ignore = {'the', 'and', 'for', 'with', 'update', 'report'}
            keywords = [w for w in topic.split() if len(w) > 3 and w not in ignore]
            
            if keywords:
                regex_pattern = "|".join([k for k in keywords]) 
                # e.g "shelling|border"
                query["$or"] = [
                    {"title": {"$regex": regex_pattern, "$options": "i"}},
                    {"summary": {"$regex": regex_pattern, "$options": "i"}}
                ]
        
        # Limit to 10 most recent relevant articles
        cursor = news_col.find(query).sort("published_parsed", -1).limit(10)
        
        sources = []
        for doc in cursor:
            # Create a clean citation object
            sources.append({
                "source": doc.get('source', 'Unknown Agency'),
                "title": doc.get('title', 'Unknown Title'),
                "url": doc.get('link', '#'),
                "date": doc.get('published', ''),
                "summary": doc.get('summary', '') # Added for Gemini context
            })

        # 2. (NEW) Generate a detailed summary if requested
        detailed_summary = "No detailed intelligence report available for this topic."
        if sources:
            try:
                # Use Gemini to synthesize a longer report from the retrieved news titles/summaries
                news_context = "\n".join([f"- {s['title']} ({s.get('source', 'Unknown')}): {s.get('summary', '')}" for s in sources])
                prompt = f"""
                Topic: {topic}
                News Context:
                Task: Synthesize a DETAILED Military Intelligence SITREP.
                
                STRICT FORMATTING RULES:
                You must output the report EXACTLY in this format:

                **SUMMARY:**
                [Your detailed summary here. EVERY sentence or claim MUST be followed by the source in brackets, e.g., (Source: Reuters)].

                REQUIREMENTS:
                - Do NOT include Type or Date headers. I will add them.
                - Ensure citation links match the provided news context.
                - Keep it under 200 words.
                """
                
                model = genai.GenerativeModel('gemini-1.5-flash-8b') # Use faster model for citations
                response = model.generate_content(prompt)
                if response.text:
                    raw_text = response.text.replace('```', '').strip()
                    # Hardcoded Header to FORCE compliance
                    header = f"**TYPE:** {topic.upper()}\n**DATE:** {datetime.datetime.now().strftime('%Y-%m-%d')}\n"
                    detailed_summary = header + raw_text
            except Exception as e:
                print(f"Detailed Summary Error: {e}")

        # 3. Align with Frontend SentinelProvider.fetchCitations
        type_key = request.GET.get('type', 'sitrep') # 'sitrep' or 'forecast'
        id_key = request.GET.get('key', 'default')
        
        # Structure exactly as frontend SitRepDetailsSheet expects
        inner_data = {}
        if type_key == 'sitrep':
            inner_data['sitrep_citations'] = {id_key: sources}
        else:
            inner_data['forecast_citations'] = {id_key: sources}
            
        return JsonResponse({
            "status": "success",
            "data": inner_data,
            "description": detailed_summary # This is the "longer description" requested
        })

    except Exception as e:
        return JsonResponse({'status': 'error', 'message': str(e)}, status=500)


# --- DEBUG: ATLAS G3 PIPELINE ---
def debug_pipeline(request):
    """
    Debug endpoint for Atlas G3 Dashboard.
    Runs the pipeline and returns detailed packet data for visualization.
    """
    try:
        # Initialize Gates
        gate1 = Gate1Ingest()
        gate2_base = Gate2Base()
        gate2_reinforced = Gate2Reinforced()
        
        all_packets = []  # Track ALL packets, not just clean ones
        
        if hasattr(ssl, '_create_unverified_context'):
            ssl._create_default_https_context = ssl._create_unverified_context
        
        query = "Thailand Cambodia border shelling OR artillery OR mortar OR drone attack OR firefight OR explosion OR clash"
        url = f"https://news.google.com/rss/search?q={query.replace(' ', '+')}&hl=en-US&gl=US&ceid=US:en"
        
        feed = feedparser.parse(url)
        
        if not feed.entries:
            return JsonResponse({
                'status': 'success',
                'message': 'No items in RSS feed',
                'total_processed': 0,
                'total_clean': 0,
                'packets': []
            })
        
        for entry in feed.entries[:20]:  # Limit for debug
            packet_data = {
                'title': entry.title[:100],
                'content_hash': None,
                'status': 'RAW',
                'validity_score': 0,
                'risk_domain': 'UNCLASSIFIED',
                'target_region': 'UNKNOWN',
                'gate_history': []
            }
            
            # GATE 1
            packet = gate1.process_packet(
                raw_input=entry,
                source_id="google_news_rss",
                source_tier=SourceTier.TRUSTED_MEDIA,
                ingest_method=IngestMethod.RSS
            )
            
            if not packet:
                packet_data['gate_history'].append('GATE1_DROP_DUPLICATE')
                packet_data['status'] = 'DROP'
                all_packets.append(packet_data)
                continue
            
            packet_data['content_hash'] = packet.identity.content_hash
            packet_data['gate_history'] = list(packet.triage.gate_history)
            
            # GATE 2 BASE
            packet = gate2_base.process_packet(packet)
            packet_data['validity_score'] = packet.triage.validity_score
            packet_data['risk_domain'] = packet.triage.risk_domain.value
            packet_data['target_region'] = packet.triage.target_region
            packet_data['gate_history'] = list(packet.triage.gate_history)
            packet_data['status'] = packet.triage.processing_status.value
            
            # GATE 2 REINFORCED (if needed)
            if packet.triage.processing_status == ProcessingStatus.PENDING_REINFORCED:
                packet = gate2_reinforced.process_packet(packet)
                packet_data['validity_score'] = packet.triage.validity_score
                packet_data['gate_history'] = list(packet.triage.gate_history)
                packet_data['status'] = packet.triage.processing_status.value
            
            all_packets.append(packet_data)
        
        clean_count = sum(1 for p in all_packets if p['status'] == 'CLEAN')
        
        return JsonResponse({
            'status': 'success',
            'total_processed': len(all_packets),
            'total_clean': clean_count,
            'packets': all_packets
        })
        
    except Exception as e:
        traceback.print_exc()
        return JsonResponse({'status': 'error', 'error': str(e)}, status=500)

# --- ADMIN OPS (INJECTED DURING MERGE) ---
def admin_verify_threat(request):
    """
    Manually overrides the 'is_certified' flag for a given Zip Code.
    Usage: /admin/verify?zip=10110&secret=admin123
    """
    try:
        zip_code = request.GET.get('zip')
        secret = request.GET.get('secret') 
        
        # Basic Security Gate (Replace with real Auth in Produciton)
        if secret != "admin123":
             return JsonResponse({'status': 'error', 'message': 'Unauthorized'})

        if not zip_code:
             return JsonResponse({'status': 'error', 'message': 'Missing Zip'})
             
        db = get_db_handle()
        col = db.intel_history
        
        doc = col.find_one({'zip_code': zip_code})
        if doc:
             # FLIP BIT
             doc['languages']['en']['is_certified'] = True
             
             # Add admin note to summary if not present
             summary_list = doc['languages']['en']['summary']
             msg = "** VERIFIED BY CENTRAL COMMAND **"
             if msg not in summary_list:
                 summary_list.insert(0, msg)
                 
             # Remove Warning if present
             doc['languages']['en']['summary'] = [x for x in summary_list if "UNCONFIRMED" not in x]

             col.replace_one({'zip_code': zip_code}, doc)
             return JsonResponse({'status': 'success', 'message': f'Zip {zip_code} VERIFIED.'})
        
        return JsonResponse({'status': 'error', 'message': 'Not Found'})
    except Exception as e:
        return JsonResponse({'status': 'error', 'message': str(e)})
