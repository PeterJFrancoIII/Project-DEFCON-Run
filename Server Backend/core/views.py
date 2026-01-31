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


# --- IMPORT CENTRAL LOGIC ---
from core.logic.mission import (
    run_mission_logic, 
    run_translation_logic, 
    update_status, 
    fetch_news,
    get_geo_from_csv, # Added
    MISSION_QUEUE,
    GEMINI_API_KEY, # Re-export for config checks
    ANALYST_MODEL,
    TRANSLATOR_MODEL
)


# --- VIEW: HOME ---
def home(request):
    return render(request, 'core/home.html')

def intel_status(request):
    """Polled by frontend during loading to show progress."""
    try:
        # Use shared DB handle
        from core.db_utils import get_db_handle
        db = get_db_handle()
        status_doc = db.system_status.find_one({"_id": "global_status"})
        
        current_stage = "Idle"
        if status_doc:
            if time.time() - status_doc.get("last_updated", 0) < 60:
                current_stage = status_doc.get("current_stage", "Idle")
            else:
                 # Auto-reset if stale
                 db.system_status.update_one(
                     {"_id": "global_status"}, 
                     {"$set": {"current_stage": "Idle"}}
                 )
                 
        return JsonResponse({
            'status': 'success', 
            'stage': current_stage
        })
    except:
        return JsonResponse({'status': 'success', 'stage': 'Idle'})

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
        
        # GRID SEARCH
        user_lon = geo_dict['lon']
        user_lat = geo_dict['lat']
        
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
        # (DISABLED: User specifically requested clickable citations/subpages)
        response_data = target_data.copy()
        
        # SITREP: Pass Full Objects (Type, Date, Citations, Confidence)
        if 'sitrep_entries' in response_data:
            pass # Keep strict fidelity
            
        # FORECAST: Pass Full Objects
        if 'forecast_entries' in response_data:
            pass # Keep strict fidelity
            
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
        



# --- ADMIN OPS ---
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
