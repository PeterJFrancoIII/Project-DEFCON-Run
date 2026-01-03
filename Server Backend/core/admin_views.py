from django.shortcuts import render
from django.http import JsonResponse, HttpResponse
from django.views.decorators.csrf import csrf_exempt
import json
import os
import csv
import sys
from datetime import datetime
from .db_utils import get_db_handle

# --- CONFIGURATIONPaths ---
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INPUTS_DIR = os.path.join(BASE_DIR, 'Developer Inputs')

# --- HELPERS ---
def get_zones_csv_path(country_code='TH'):
    # For now defaulting to Thailand
    return os.path.join(INPUTS_DIR, 'Thailand', 'Thailand_Exclusary_Zones.csv')

def get_prompt_path():
    # Assuming prompt is in the core views or a text file. 
    # Current implementation embeds it in views.py. We should extract it later.
    # For now, we will create a text file for it to enable editing.
    return os.path.join(INPUTS_DIR, 'analyst_prompt.txt')

def get_api_config_path():
    return os.path.join(INPUTS_DIR, 'api_config.py')

# --- VIEWS ---

def admin_home(request):
    """Renders the main SPA-like portal."""
    return render(request, 'admin_portal.html')

# --- API: ZONES ---

def api_get_zones(request):
    """Returns zones from CSV as JSON."""
    csv_path = get_zones_csv_path()
    zones = []
    if os.path.exists(csv_path):
        try:
            with open(csv_path, 'r', encoding='utf-8', errors='ignore') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    zones.append(row)
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)
    return JsonResponse({'zones': zones})

@csrf_exempt
def api_save_zones(request):
    """Overwrites CSV with new zones data."""
    if request.method == 'POST':
        try:
            payload = json.loads(request.body)
            zones = payload.get('zones', [])
            csv_path = get_zones_csv_path()
            
            # Fieldnames must match the standard
            fieldnames = ['zone_name', 'risk_level', 'shape_type', 'lat_center', 'lng_center', 'radius_km', 'bound_nw_lat', 'bound_nw_lng', 'bound_se_lat', 'bound_se_lng', 'notes']
            
            # Create Backup First
            if os.path.exists(csv_path):
                 os.rename(csv_path, csv_path + f".bak-{int(datetime.now().timestamp())}")

            with open(csv_path, 'w', newline='', encoding='utf-8') as f:
                writer = csv.DictWriter(f, fieldnames=fieldnames)
                writer.writeheader()
                for zone in zones:
                     # Ensure all fields exist
                     row = {k: zone.get(k, '') for k in fieldnames}
                     writer.writerow(row)
            
            return JsonResponse({'status': 'success', 'message': 'Zones saved successfully.'})
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)
    return JsonResponse({'error': 'POST required'}, status=400)

# --- API: APPROVALS ---

def api_get_approvals(request):
    """Fetch alerts pending verification."""
    db = get_db_handle()
    # Looking for DOCS where defcon=2 and summary contains "PENDING HUMAN VERIFICATION"
    # Actually, the requirement is "Approvals of pending DEFCON 1 or 2". 
    # My downgrade logic sets defcon=2 and adds the text.
    
    query = {
        "languages.en.summary": {"$regex": "PENDING HUMAN VERIFICATION"}
    }
    
    docs = list(db.intel_history.find(query, {"_id": 0})) # suppress ID for simpler json
    return JsonResponse({'pending': docs})

@csrf_exempt
def api_decide_approval(request):
    """Approve (Upgrade to 1) or Reject (Downgrade/Safe)."""
    if request.method == 'POST':
        payload = json.loads(request.body)
        zip_code = payload.get('zip_code')
        action = payload.get('action') # 'APPROVE' or 'REJECT'
        
        db = get_db_handle()
        
        if action == 'APPROVE':
            # 1. Update status to 1
            # 2. Remove "PENDING..." text
            db.intel_history.update_one(
                {'zip_code': zip_code},
                {
                    '$set': {'languages.en.defcon_status': 1},
                    '$pull': {'languages.en.summary': {"$regex": "PENDING HUMAN VERIFICATION"}} # This might not be easy with pull if it's a string in list
                }
            )
            # Alternative: Read, modify, save. Safer.
            doc = db.intel_history.find_one({'zip_code': zip_code})
            if doc:
                doc['languages']['en']['defcon_status'] = 1
                doc['languages']['en']['summary'] = [s for s in doc['languages']['en']['summary'] if "PENDING HUMAN VERIFICATION" not in s]
                # Add "VERIFED" note
                doc['languages']['en']['summary'].insert(0, "** COMMAND VERIFIED: WAR IMMINENT **")
                db.intel_history.replace_one({'zip_code': zip_code}, doc)
                
            return JsonResponse({'status': 'approved'})
            
        elif action == 'REJECT':
            # Downgrade to 3 or delete?
            # User might want to set radius to safe.
            # For now, just remove the Pending tag and keep at 2 (Severe) or set to 3.
            # Let's set to 3 (Significant) as rejection implies it's not THAT bad.
            doc = db.intel_history.find_one({'zip_code': zip_code})
            if doc:
                doc['languages']['en']['defcon_status'] = 3
                doc['languages']['en']['summary'] = [s for s in doc['languages']['en']['summary'] if "PENDING HUMAN VERIFICATION" not in s]
                doc['languages']['en']['summary'].insert(0, "** ALERT DISMISSED BY COMMAND **")
                db.intel_history.replace_one({'zip_code': zip_code}, doc)
            return JsonResponse({'status': 'rejected'})

    return JsonResponse({'error': 'POST required'}, status=400)

# --- API: CONFIG ---
def api_get_config(request):
    # Read api_config.py
    try:
        with open(get_api_config_path(), 'r') as f:
            content = f.read()
        return JsonResponse({'content': content})
    except: return JsonResponse({'content': ''})

@csrf_exempt
def api_save_config(request):
    if request.method == 'POST':
        payload = json.loads(request.body)
        content = payload.get('content')
        path = get_api_config_path()
        with open(path, 'w') as f:
            f.write(content)
        return JsonResponse({'status': 'saved'})
    return JsonResponse({'error': 'POST required'}, status=400)
