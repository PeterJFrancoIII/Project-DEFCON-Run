import os
import csv
import math

# ==============================================================================
# MODULE: compliance.py
# ROLE:   Regulatory Compliance & Exclusion Zones
# ==============================================================================

# Map Country Code (ISO 2) to Folder Name
COUNTRY_MAP = {
    'TH': 'Thailand',
    'KH': 'Cambodia', 
    'MM': 'Myanmar',
    'LA': 'Laos'
}

def haversine_distance(lat1, lon1, lat2, lon2):
    try:
        R = 6371 # Earth Radius in km
        dlat = math.radians(lat2 - lat1)
        dlon = math.radians(lon2 - lon1)
        a = math.sin(dlat/2) * math.sin(dlat/2) + \
            math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * \
            math.sin(dlon/2) * math.sin(dlon/2)
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
        return R * c
    except: return 9999.0

import re

def parse_rtf_csv_lines(file_path):
    """
    Parses a messy RTF file that contains CSV data.
    """
    clean_lines = []
    capture = False
    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
            
        for line in lines:
            # 1. Cleaning: Remove RTF control words (e.g., \f0, \par, \cf0)
            # Regex: Backslash + alphanumeric words + optional space
            clean = re.sub(r'\\[a-z0-9]+ ?', '', line).strip()
            
            # 2. Cleaning: Remove braces and lingering backslashes
            clean = clean.replace('{', '').replace('}', '').replace('\\', '').strip()
            
            # 3. Detect Header to start capturing
            if 'zone_name,latitude' in clean:
                capture = True
            
            if capture and clean:
                clean_lines.append(clean)
            
    except Exception as e:
        print(f"[COMPLIANCE] File Read Error {file_path}: {e}")
        
    return clean_lines

def load_zones_from_file(file_path):
    zones = []
    lines = parse_rtf_csv_lines(file_path)
    if not lines: return []

    try:
        # Assume first valid line is header
        reader = csv.DictReader(lines)
        for row in reader:
            # Flexible Key Matching
            lat = row.get('latitude') or row.get('lat')
            lon = row.get('longitude') or row.get('lon')
            rad = row.get('radius_km') or row.get('radius')
            name = row.get('zone_name') or row.get('name') or "Restricted Zone"
            
            if lat and lon and rad:
                zones.append({
                    'name': name,
                    'lat': float(lat),
                    'lon': float(lon),
                    'radius_km': float(rad),
                    'risk': row.get('risk_level', 'HIGH')
                })
    except Exception as e:
        print(f"[COMPLIANCE] CSV Parse Error {file_path}: {e}")
        
    return zones

def check_compliance(lat, lon, country_code, inputs_dir):
    """
    Returns (is_blocked, zone_details)
    """
    folder_name = COUNTRY_MAP.get(country_code, 'Thailand') # Default to Thailand folder if unknown? or just fail safe.
    target_dir = os.path.join(inputs_dir, folder_name)
    
    if not os.path.exists(target_dir):
        # Fallback: maybe the folder doesn't exist yet for other countries
        return False, None
    
    # 1. Scan for Zone Files
    zone_files = [f for f in os.listdir(target_dir) if "Exclusary_Zones" in f]
    
    for fname in zone_files:
        full_path = os.path.join(target_dir, fname)
        zones = load_zones_from_file(full_path)
        
        for zone in zones:
            dist = haversine_distance(lat, lon, zone['lat'], zone['lon'])
            if dist <= zone['radius_km']:
                print(f">> [COMPLIANCE] BLOCKED: {zone['name']} (Dist: {dist:.2f}km <= {zone['radius_km']}km)")
                return True, zone
                
    return False, None
