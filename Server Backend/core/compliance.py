import os
import csv
import math
import sys
from shapely.geometry import Point, box, Polygon

# ==============================================================================
# MODULE: compliance.py
# ROLE:   Regulatory Compliance & Exclusion Zones (Shapely Engine)
# ==============================================================================

# Map Country Code (ISO 2) to Folder Name
COUNTRY_MAP = {
    'TH': 'Thailand',
    'KH': 'Cambodia', 
    'MM': 'Myanmar',
    'LA': 'Laos'
}

class ComplianceEngine:
    _instance = None
    _zones = {} # Map country -> List of shapes

    @classmethod
    def get_instance(cls):
        if cls._instance is None:
            cls._instance = ComplianceEngine()
        return cls._instance

    def load_zones_for_country(self, country_code, inputs_dir):
        if country_code in self._zones:
            return # Already loaded
        
        folder_name = COUNTRY_MAP.get(country_code, 'Thailand')
        target_dir = os.path.join(inputs_dir, folder_name)
        
        if not os.path.exists(target_dir):
            print(f"[COMPLIANCE] Warning: Directory not found: {target_dir}")
            return

        loaded_zones = []
        
        # Look for the Shapely CSV first
        csv_files = [f for f in os.listdir(target_dir) if "Exclusary_Zones.csv" in f]
        
        for fname in csv_files:
            full_path = os.path.join(target_dir, fname)
            print(f">> [COMPLIANCE] Loading zones from {fname}")
            
            try:
                with open(full_path, 'r', encoding='utf-8', errors='ignore') as f:
                    reader = csv.DictReader(f)
                    for row in reader:
                        shape = self._create_shape(row)
                        if shape:
                            loaded_zones.append({
                                'name': row.get('zone_name', 'Unknown'),
                                'shape': shape,
                                'risk': row.get('risk_level', 'HIGH')
                            })
            except Exception as e:
                print(f"[COMPLIANCE] Error parsing {fname}: {e}")

        self._zones[country_code] = loaded_zones
        print(f">> [COMPLIANCE] Total Active Zones for {country_code}: {len(loaded_zones)}")

    def _create_shape(self, row):
        try:
            shape_type = row.get('shape_type', 'CIRCLE').strip().upper()
            
            if shape_type == 'RECTANGLE':
                # box(minx, miny, maxx, maxy)
                # minx = West (lng), maxx = East (lng)
                # miny = South (lat), maxy = North (lat)
                # CSV has NW and SE.
                # NW: (lat, lng) -> MaxY, MinX
                # SE: (lat, lng) -> MinY, MaxX
                nw_lat = float(row['bound_nw_lat'])
                nw_lng = float(row['bound_nw_lng'])
                se_lat = float(row['bound_se_lat'])
                se_lng = float(row['bound_se_lng'])
                
                return box(nw_lng, se_lat, se_lng, nw_lat)
                
            elif shape_type == 'CIRCLE':
                lat = float(row.get('lat_center') or row.get('latitude'))
                lng = float(row.get('lng_center') or row.get('longitude'))
                radius_km = float(row.get('radius_km') or row.get('radius'))
                
                # Convert KM to Degrees (Approximate)
                # 1 degree lat ~= 111 km. 1 degree lon ~= 111 * cos(lat). Assuming 111 for safety/simplicity or using simple conversion.
                deg_radius = radius_km / 111.32
                
                return Point(lng, lat).buffer(deg_radius)
                
        except Exception as e:
            print(f"[COMPLIANCE] Shape Creation Error: {e} | Row: {row}")
            return None
        return None

    def check_point(self, lat, lon, country_code):
        zones = self._zones.get(country_code, [])
        user_point = Point(lon, lat)
        
        for zone in zones:
            if zone['shape'].contains(user_point) or zone['shape'].intersects(user_point):
                return True, zone
        return False, None

# Helper Wrapper for Views/Scripts
def check_compliance(lat, lon, country_code, inputs_dir):
    engine = ComplianceEngine.get_instance()
    # Lazy Load
    engine.load_zones_for_country(country_code, inputs_dir)
    
    is_blocked, zone = engine.check_point(lat, lon, country_code)
    if is_blocked:
         print(f">> [COMPLIANCE] BLOCKED: {zone['name']}")
         return True, zone
    return False, None
