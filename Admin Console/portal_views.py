from django.shortcuts import render
from django.http import JsonResponse, HttpResponse
from django.views.decorators.csrf import csrf_exempt
import json
import os
import csv
import sys
import shutil
from datetime import datetime
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required, user_passes_test
from django.shortcuts import redirect
from django_otp.plugins.otp_totp.models import TOTPDevice
import qrcode
import io
import base64
from core.db_utils import get_db_handle
from django.views.decorators.clickjacking import xframe_options_exempt

# --- CONFIGURATIONPaths ---
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Docker Compatibility: Check if 'web' exists (Docker), else use 'Server Backend' (Local)
if os.path.exists(os.path.join(BASE_DIR, 'web', 'Developer Inputs')):
    INPUTS_DIR = os.path.join(BASE_DIR, 'web', 'Developer Inputs')
    STATIC_DIR = os.path.join(BASE_DIR, 'web', 'core', 'static', 'core')
else:
    INPUTS_DIR = os.path.join(BASE_DIR, 'Server Backend', 'Developer Inputs')
    STATIC_DIR = os.path.join(BASE_DIR, 'Server Backend', 'core', 'static', 'core')

# --- HELPERS ---
def get_zones_csv_path(): return os.path.join(INPUTS_DIR, 'Thailand', 'Thailand_Exclusary_Zones.csv')
def get_prompt_path(): return os.path.join(INPUTS_DIR, 'analyst_system_prompt.txt')
def get_api_config_path(): return os.path.join(INPUTS_DIR, 'api_config.py')
def get_osint_path(): return os.path.join(INPUTS_DIR, 'OSINT Sources.csv')
def get_zips_path(): return os.path.join(INPUTS_DIR, 'thailand_postal_codes_complete.csv')
def get_contact_path(): return os.path.join(INPUTS_DIR, 'contact.json')

# --- VIEWS ---

def is_admin(user):
    return user.is_authenticated and user.is_staff

@csrf_exempt
def admin_login(request):
    if request.method == 'POST':
        u = request.POST.get('username')
        p = request.POST.get('password')
        user = authenticate(username=u, password=p)
        if user:
            login(request, user)
            # Check 2FA
            if not TOTPDevice.objects.filter(user=user, confirmed=True).exists():
                return redirect('setup_2fa')
            return redirect('admin_home')
        else:
            return render(request, 'login.html', {'error': 'Invalid Credentials'})
    return render(request, 'login.html')

def admin_logout(request):
    logout(request)
    return redirect('admin_login')

@login_required(login_url='/admin/login')
def setup_2fa(request):
    user = request.user
    if request.method == 'POST':
        token = request.POST.get('token')
        device = TOTPDevice.objects.filter(user=user, confirmed=False).first()
        if device and device.verify_token(token):
            device.confirmed = True
            device.save()
            return redirect('admin_home')
        return render(request, 'setup_2fa.html', {'error': 'Invalid Token', 'qr_url': request.POST.get('qr_url')})
    
    # Generate new secret if not exists or use unconfirmed one
    device, created = TOTPDevice.objects.get_or_create(user=user, confirmed=False)
    
    # Generate QR Code
    otp_url = device.config_url
    img = qrcode.make(otp_url)
    buffer = io.BytesIO()
    img.save(buffer, format="PNG")
    qr_b64 = base64.b64encode(buffer.getvalue()).decode()
    
    return render(request, 'setup_2fa.html', {'qr_url': f"data:image/png;base64,{qr_b64}"})

@login_required(login_url='/admin/login')
def admin_home(request):
    """Renders the main SPA-like portal."""
    if not request.user.is_staff: return redirect('admin_login')
    # Enforce 2FA
    if not request.user.is_verified(): # django-otp adds this
        # If user has no confirmed device, redirect to setup
        if not TOTPDevice.objects.filter(user=request.user, confirmed=True).exists():
             return redirect('setup_2fa')
        # Otherwise, if they just haven't entered it for this session (if using 2fa middleware stricty)
        # But here we assume built-in middleware handles OTP enforcement if configured, 
        # OR we just check if they have a device. 
        # For simplicity in this bespoke view:
        pass 

    return render(request, 'admin_portal.html')

@login_required(login_url='/admin/login')
@xframe_options_exempt
def admin_db_dashboard(request):
    """Renders the database dashboard."""
    if not request.user.is_staff: return redirect('admin_login')
    return render(request, 'db_dashboard.html')

# --- API: ZONES ---

@login_required
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
@login_required
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

@login_required
def api_get_prompt(request):
    try:
        with open(get_prompt_path(), 'r') as f: content = f.read()
        return JsonResponse({'content': content})
    except: return JsonResponse({'content': 'Prompt file not found.'})

@csrf_exempt
@login_required
def api_save_prompt(request):
    if request.method == 'POST':
        payload = json.loads(request.body)
        with open(get_prompt_path(), 'w') as f: f.write(payload.get('content', ''))
        return JsonResponse({'status': 'saved'})
    return JsonResponse({'error': 'POST required'})

@login_required
def api_get_osint(request):
    sources = []
    if os.path.exists(get_osint_path()):
        with open(get_osint_path(), 'r', encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            sources = list(reader)
    return JsonResponse({'sources': sources})

@csrf_exempt
@login_required
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
@login_required
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

@login_required
def api_get_contact(request):
    try:
        with open(get_contact_path(), 'r') as f: data = json.load(f)
        return JsonResponse(data)
    except: return JsonResponse({})

@csrf_exempt
@login_required
def api_save_contact(request):
    if request.method == 'POST':
        payload = json.loads(request.body)
        with open(get_contact_path(), 'w') as f: json.dump(payload, f, indent=4)
        return JsonResponse({'status': 'saved'})
    return JsonResponse({'error': 'POST required'})

@csrf_exempt
@login_required
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

@login_required
def api_get_api_config(request):
    try:
         with open(get_api_config_path(), 'r') as f: content = f.read()
    except: content = ""
    return JsonResponse({'content': content})

@csrf_exempt
@login_required
def api_save_api_config(request):
    if request.method == 'POST':
        content = json.loads(request.body).get('content')
        with open(get_api_config_path(), 'w') as f: f.write(content)
        return JsonResponse({'status': 'saved'})
    return JsonResponse({'error': 'POST'})

def get_config_path(): return os.path.join(INPUTS_DIR, 'config.json')

@login_required
def api_get_config(request):
    try:
        with open(get_config_path(), 'r') as f: data = json.load(f)
        return JsonResponse(data)
    except: return JsonResponse({})

@csrf_exempt
@login_required
def api_save_config(request):
    if request.method == 'POST':
        payload = json.loads(request.body)
        with open(get_config_path(), 'w') as f: json.dump(payload, f, indent=4)
        return JsonResponse({'status': 'saved'})
    return JsonResponse({'error': 'POST required'})

# --- API: ALERTS & APPROVALS ---

@login_required
def api_get_approvals(request):
    db = get_db_handle()
    query = {"languages.en.summary": {"$regex": "PENDING HUMAN VERIFICATION"}}
    docs = list(db.intel_history.find(query, {"_id": 0})) 
    return JsonResponse({'pending': docs})

@csrf_exempt
@login_required
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

@login_required
def api_get_active_alerts(request):
    """Get active alerts to allow manual map editing."""
    db = get_db_handle()
    # Find active docs (defcon <= 4) or recent modifications
    # For "Mapping point alerts", we usually mean overlays.
    docs = list(db.intel_history.find({"languages.en.defcon_status": {"$lte": 4}}, {"_id": 0}).limit(50))
    return JsonResponse({'alerts': docs})

@csrf_exempt
@login_required
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

# --- API: LIVE THREATS MAP ---
from core.geo_utils import HOTZONES_DATA

@login_required
def api_get_threats(request):
    """Return processed hotzones matching App logic (DB + Static files)."""
    processed = []
    seen_names = set()
    
    # helper for radius logic
    def get_radius(name, type_str):
        text = (name + " " + type_str).lower()
        if "artillery" in text or "mortar" in text: return 20000
        if "infantry" in text or "troop" in text: return 5000
        if "armor" in text or "tank" in text: return 10000
        if "rocket" in text or "missile" in text: return 40000
        if "air" in text or "strike" in text: return 50000
        return 5000

    # 1. Fetch from DB (Live Intel)
    try:
        db = get_db_handle()
        # Get all tactical overlays AND Defcon Status from English docs
        cursor = db.intel_history.find({}, {"languages.en.tactical_overlays": 1, "languages.en.defcon_status": 1, "_id": 0})
        
        # Build Set of Mock Names to Ignore
        mock_names = {z['name'] for z in HOTZONES_DATA}
        
        for doc in cursor:
            lang_data = doc.get('languages', {}).get('en', {})
            overlays = lang_data.get('tactical_overlays', [])
            defcon = lang_data.get('defcon_status', 5) # Default to Peace
            
            for ov in overlays:
                # Normalize name for deduplication
                name = ov.get('name', 'Unknown')
                
                # FILTER: Skip if this is a known Mock/Static zone
                if name in mock_names: continue
                
                if name in seen_names: continue
                
                seen_names.add(name)
                
                # Apply Story Radius Logic (DB might have different radius)
                radius = get_radius(name, ov.get('type', ''))
                
                processed.append({
                    "name": name,
                    "lat": ov.get('lat'),
                    "lon": ov.get('lon'),
                    "radius": radius,
                    "type": ov.get('type', 'Conflict Zone'),
                    "last_kinetic": ov.get('date', 'Unknown'),
                    "defcon": defcon
                })
    except Exception as e:
        print(f"Error fetching DB threats: {e}")

    # REMOVED: Static Backfill of HOTZONES_DATA per User Request (Purge Mock Data)

    return JsonResponse({'threats': processed})


@login_required
def api_get_sitrep(request):
    """Return full SITREP data for a specific zip code."""
    zip_code = request.GET.get('zip')
    if not zip_code:
        return JsonResponse({'error': 'Missing zip parameter'}, status=400)
    
    db = get_db_handle()
    doc = db.intel_history.find_one(
        {"zip_code": zip_code},
        {"_id": 0}
    )
    
    if not doc:
        return JsonResponse({'error': 'No intel data for this zip code', 'zip_code': zip_code}, status=404)
    
    lang_data = doc.get('languages', {}).get('en', {})
    
    # Build SITREP response
    sitrep = {
        'zip_code': zip_code,
        'location_name': lang_data.get('location_name', 'Unknown Location'),
        'defcon_status': lang_data.get('defcon_status', 5),
        'is_certified': lang_data.get('is_certified', True),
        'last_updated': lang_data.get('last_updated', 'Unknown'),
        'summary': lang_data.get('summary', []),
        'sitrep_entries': lang_data.get('sitrep_entries', []),
        'roads_to_avoid': lang_data.get('roads_to_avoid', []),
        'emergency_avoid_locations': lang_data.get('emergency_avoid_locations', []),
        'evacuation_point': lang_data.get('evacuation_point', {}),
        'predictive': lang_data.get('predictive', {}),
        'tactical_overlays': lang_data.get('tactical_overlays', [])
    }
    
    return JsonResponse({'status': 'success', 'sitrep': sitrep})


@login_required
def api_get_zip_defcon(request):
    """Return DEFCON status only for zip codes with actual intel data in DB."""
    db = get_db_handle()
    
    # Get all zip codes with intel from DB
    cursor = db.intel_history.find(
        {"zip_code": {"$exists": True}},
        {"zip_code": 1, "languages.en.defcon_status": 1, "_id": 0}
    )
    
    # Build map of zip codes that have intel data
    zip_defcons = {}
    for doc in cursor:
        zc = str(doc.get('zip_code', ''))
        if not zc:
            continue
        defcon = doc.get('languages', {}).get('en', {}).get('defcon_status', 5)
        zip_defcons[zc] = defcon
    
    # If no intel data exists, return empty (no simulated markers)
    if not zip_defcons:
        return JsonResponse({'zip_defcons': []})
    
    # Load postal codes CSV for coordinates - ONLY for zip codes that have intel data
    results = []
    seen_zips = set()
    csv_path = get_zips_path()
    
    if os.path.exists(csv_path):
        with open(csv_path, 'r', encoding='utf-8', errors='ignore') as f:
            reader = csv.DictReader(f)
            for row in reader:
                zip_code = row.get('POSTAL_CODE', '')
                
                # FILTER: Only include zip codes that have actual intel data
                if zip_code not in zip_defcons:
                    continue
                    
                if zip_code in seen_zips:
                    continue  # One marker per zip
                seen_zips.add(zip_code)
                
                lat = row.get('LATITUDE')
                lon = row.get('LONGITUDE')
                if not lat or not lon:
                    continue
                
                try:
                    lat = float(lat)
                    lon = float(lon)
                except:
                    continue
                
                results.append({
                    'zip_code': zip_code,
                    'lat': lat,
                    'lon': lon,
                    'defcon': zip_defcons[zip_code],
                    'district': row.get('DISTRICT_ENGLISH', '')
                })
    
    return JsonResponse({'zip_defcons': results})

