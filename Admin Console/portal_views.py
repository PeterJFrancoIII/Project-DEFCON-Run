from django.shortcuts import render
from django.http import JsonResponse, HttpResponse
from django.views.decorators.csrf import csrf_exempt
import json
import os
import csv
import sys
import shutil
from datetime import datetime
from core.db_utils import get_db_handle

# --- CONFIGURATIONPaths ---
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INPUTS_DIR = os.path.join(BASE_DIR, 'Server Backend', 'Developer Inputs')
STATIC_DIR = os.path.join(BASE_DIR, 'Server Backend', 'core', 'static', 'core') # Adjust as needed

# --- HELPERS ---
def get_zones_csv_path(): return os.path.join(INPUTS_DIR, 'Thailand', 'Thailand_Exclusary_Zones.csv')
def get_prompt_path(): return os.path.join(INPUTS_DIR, 'analyst_system_prompt.txt')
def get_api_config_path(): return os.path.join(INPUTS_DIR, 'api_config.py')
def get_osint_path(): return os.path.join(INPUTS_DIR, 'OSINT Sources.csv')
def get_zips_path(): return os.path.join(INPUTS_DIR, 'thailand_postal_codes_complete.csv')
def get_contact_path(): return os.path.join(INPUTS_DIR, 'contact.json')

# --- VIEWS ---

def admin_home(request):
    """Renders the main SPA-like portal."""
    return render(request, 'admin_portal.html')

# --- API: ZONES ---

def api_get_zones(request):
    csv_path = get_zones_csv_path()
    zones = []
    if os.path.exists(csv_path):
        try:
            with open(csv_path, 'r', encoding='utf-8', errors='ignore') as f:
                reader = csv.DictReader(f)
                zones = list(reader)
        except Exception as e: return JsonResponse({'error': str(e)}, status=500)
    return JsonResponse({'zones': zones})

@csrf_exempt
def api_save_zones(request):
    if request.method == 'POST':
        try:
            payload = json.loads(request.body)
            zones = payload.get('zones', [])
            csv_path = get_zones_csv_path()
            fieldnames = ['zone_name', 'risk_level', 'shape_type', 'lat_center', 'lng_center', 'radius_km', 'bound_nw_lat', 'bound_nw_lng', 'bound_se_lat', 'bound_se_lng', 'notes']
            
            # Backup
            if os.path.exists(csv_path):
                 shutil.copy(csv_path, csv_path + f".bak-{int(datetime.now().timestamp())}")

            with open(csv_path, 'w', newline='', encoding='utf-8') as f:
                writer = csv.DictWriter(f, fieldnames=fieldnames)
                writer.writeheader()
                for zone in zones:
                     row = {k: zone.get(k, '') for k in fieldnames}
                     writer.writerow(row)
            return JsonResponse({'status': 'success'})
        except Exception as e: return JsonResponse({'error': str(e)}, status=500)
    return JsonResponse({'error': 'POST required'}, status=400)

# --- API: INTELLIGENCE (Prompt, OSINT, Zips) ---

def api_get_prompt(request):
    try:
        with open(get_prompt_path(), 'r') as f: content = f.read()
        return JsonResponse({'content': content})
    except: return JsonResponse({'content': 'Prompt file not found.'})

@csrf_exempt
def api_save_prompt(request):
    if request.method == 'POST':
        payload = json.loads(request.body)
        with open(get_prompt_path(), 'w') as f: f.write(payload.get('content', ''))
        return JsonResponse({'status': 'saved'})
    return JsonResponse({'error': 'POST required'})

def api_get_osint(request):
    sources = []
    if os.path.exists(get_osint_path()):
        with open(get_osint_path(), 'r', encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            sources = list(reader)
    return JsonResponse({'sources': sources})

@csrf_exempt
def api_save_osint(request):
    if request.method == 'POST':
        payload = json.loads(request.body)
        sources = payload.get('sources', [])
        # Assume CSV format: Source, URL, Type
        fieldnames = ['Source', 'URL', 'Type'] 
        with open(get_osint_path(), 'w', newline='', encoding='utf-8-sig') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            for s in sources: writer.writerow(s)
        return JsonResponse({'status': 'saved'})
    return JsonResponse({'error': 'POST required'})

@csrf_exempt
def api_search_zips(request):
    """Search zips (don't load all)."""
    q = request.GET.get('q', '').strip()
    results = []
    if not q: return JsonResponse({'results': []})
    
    with open(get_zips_path(), 'r', encoding='utf-8', errors='ignore') as f:
        reader = csv.DictReader(f)
        count = 0
        for row in reader:
            # Search by POSTAL_CODE or DISTRICT
            if q in row.get('POSTAL_CODE', '') or q.lower() in row.get('DISTRICT_ENGLISH', '').lower():
                results.append(row)
                count += 1
                if count > 50: break
    return JsonResponse({'results': results})

# --- API: ASSETS & CONFIG (Contact, Logos, API Key) ---

def api_get_contact(request):
    try:
        with open(get_contact_path(), 'r') as f: data = json.load(f)
        return JsonResponse(data)
    except: return JsonResponse({})

@csrf_exempt
def api_save_contact(request):
    if request.method == 'POST':
        payload = json.loads(request.body)
        with open(get_contact_path(), 'w') as f: json.dump(payload, f, indent=4)
        return JsonResponse({'status': 'saved'})
    return JsonResponse({'error': 'POST required'})

@csrf_exempt
def api_upload_logo(request):
    if request.method == 'POST' and request.FILES.get('logo'):
        f = request.FILES['logo']
        # Save to static/core/img/logo_custom.png
        target = os.path.join(STATIC_DIR, 'img', 'logo_custom.png')
        os.makedirs(os.path.dirname(target), exist_ok=True)
        with open(target, 'wb+') as dest:
            for chunk in f.chunks(): dest.write(chunk)
        return JsonResponse({'status': 'uploaded'})
    return JsonResponse({'error': 'File required'}, status=400)

def api_get_api_config(request):
    try:
         with open(get_api_config_path(), 'r') as f: content = f.read()
    except: content = ""
    return JsonResponse({'content': content})

@csrf_exempt
def api_save_api_config(request):
    if request.method == 'POST':
        content = json.loads(request.body).get('content')
        with open(get_api_config_path(), 'w') as f: f.write(content)
        return JsonResponse({'status': 'saved'})
    return JsonResponse({'error': 'POST'})

# --- API: ALERTS & APPROVALS ---

def api_get_approvals(request):
    db = get_db_handle()
    query = {"languages.en.summary": {"$regex": "PENDING HUMAN VERIFICATION"}}
    docs = list(db.intel_history.find(query, {"_id": 0})) 
    return JsonResponse({'pending': docs})

@csrf_exempt
def api_decide_approval(request):
    if request.method == 'POST':
        payload = json.loads(request.body)
        zip_code = payload.get('zip_code')
        action = payload.get('action')
        db = get_db_handle()
        doc = db.intel_history.find_one({'zip_code': zip_code})
        
        if doc and action == 'APPROVE':
            doc['languages']['en']['defcon_status'] = 1
            doc['languages']['en']['summary'] = [s for s in doc['languages']['en']['summary'] if "PENDING" not in s]
            doc['languages']['en']['summary'].insert(0, "** COMMAND VERIFIED: WAR IMMINENT **")
            db.intel_history.replace_one({'zip_code': zip_code}, doc)
            
        elif doc and action == 'REJECT':
            doc['languages']['en']['defcon_status'] = 3
            doc['languages']['en']['summary'] = [s for s in doc['languages']['en']['summary'] if "PENDING" not in s]
            doc['languages']['en']['summary'].insert(0, "** ALERT DISMISSED BY COMMAND **")
            db.intel_history.replace_one({'zip_code': zip_code}, doc)
            
        return JsonResponse({'status': 'done'})
    return JsonResponse({'error': 'POST'})

def api_get_active_alerts(request):
    """Get active alerts to allow manual map editing."""
    db = get_db_handle()
    # Find active docs (defcon <= 4) or recent modifications
    # For "Mapping point alerts", we usually mean overlays.
    docs = list(db.intel_history.find({"languages.en.defcon_status": {"$lte": 4}}, {"_id": 0}).limit(50))
    return JsonResponse({'alerts': docs})

@csrf_exempt
def api_save_alert_map(request):
    """Update active alert coordinates/radius."""
    if request.method == 'POST':
        payload = json.loads(request.body)
        zip_code = payload.get('zip_code')
        updates = payload.get('updates') # {lat, lon, radius...}
        db = get_db_handle()
        # This is a basic update. In full system we might need upsert.
        # Minimal impl:
        db.intel_history.update_one({'zip_code': zip_code}, {'$set': updates})
        return JsonResponse({'status': 'updated'})
    return JsonResponse({'error': 'POST'})
