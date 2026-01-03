import math

# Conflict Hotzones (Lat, Lon, Radius in Meters)
# Used for Distance Calculations in Prompt
# Conflict Hotzones (Lat, Lon, Radius in Meters)
# Used for Distance Calculations in Prompt
HOTZONES_DATA = [
    {"name": "PREAH VIHEAR (ARTILLERY)", "lat": 14.3914, "lon": 104.6804, "radius": 40000, "last_kinetic": "2025-12-15"},
    {"name": "POIPET (MORTARS)", "lat": 13.6600, "lon": 102.5000, "radius": 15000, "last_kinetic": "2025-12-28"},
    {"name": "CHONG CHOM (ROCKETS)", "lat": 14.4300, "lon": 103.4300, "radius": 35000, "last_kinetic": "2026-01-02"},
    {"name": "TRAT (NAVAL GUNS)", "lat": 11.9600, "lon": 102.8000, "radius": 25000, "last_kinetic": "2025-12-10"}
]

def haversine_distance(lat1, lon1, lat2, lon2):
    """
    Calculate the great circle distance in kilometers between two points 
    on the earth (specified in decimal degrees)
    """
    # Convert decimal degrees to radians 
    lon1, lat1, lon2, lat2 = map(math.radians, [lon1, lat1, lon2, lat2])

    # Haversine formula 
    dlon = lon2 - lon1 
    dlat = lat2 - lat1 
    a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
    c = 2 * math.asin(math.sqrt(a)) 
    r = 6371 # Radius of earth in kilometers. Use 3956 for miles
    return c * r

def get_nearest_hotzone(user_lat, user_lon):
    """Returns (DistanceKM, ZoneName) for the nearest conflict zone."""
    min_dist = 99999.0
    nearest_name = "None"
    
    for zone in HOTZONES_DATA:
        dist = haversine_distance(user_lat, user_lon, zone['lat'], zone['lon'])
        if dist < min_dist:
            min_dist = dist
            nearest_name = zone['name']
            
    return min_dist, nearest_name
