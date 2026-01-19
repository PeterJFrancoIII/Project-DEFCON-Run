# ==============================================================================
# SYSTEM: SENTINEL FLASH TESTBED
# MODULE: intelligence.py
# ROLE:   GDELT 2.0 INTEGRATION (BigQuery)
# ==============================================================================

import datetime
import os
import sys

# Google BigQuery for GDELT data
from google.cloud import bigquery

# Add parent directory to path for db_utils import
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from core.db_utils import get_db_handle

# --- CONFIGURATION ---
INPUTS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'Developer Inputs')

# Load api_config for BigQuery credentials
try:
    sys.path.append(INPUTS_DIR)
    import api_config
    import importlib
    importlib.reload(api_config)
except Exception as e:
    print(f"[!] Error loading API Config: {e}")
    api_config = None

# --- BIGQUERY CLIENT INITIALIZATION ---
def _init_bigquery_client():
    """
    Initialize BigQuery client with service account from api_config,
    or fall back to environment credentials.
    """
    try:
        # Try to use service account path from api_config
        if api_config and hasattr(api_config, 'GOOGLE_APPLICATION_CREDENTIALS'):
            creds_path = api_config.GOOGLE_APPLICATION_CREDENTIALS
            if creds_path and os.path.exists(creds_path):
                print(f">> [BigQuery] Using service account from api_config: {creds_path}")
                return bigquery.Client.from_service_account_json(creds_path)
    except Exception as e:
        print(f">> [BigQuery] api_config credentials failed: {e}")
    
    # Fall back to default environment credentials
    print(">> [BigQuery] Using default environment credentials")
    return bigquery.Client()

# CAMEO Event Root Code descriptions for human-readable output
CAMEO_ROOT_CODES = {
    "01": "Make public statement",
    "02": "Appeal",
    "03": "Express intent to cooperate",
    "04": "Consult",
    "05": "Engage in diplomatic cooperation",
    "06": "Engage in material cooperation",
    "07": "Provide aid",
    "08": "Yield",
    "09": "Investigate",
    "10": "Demand",
    "11": "Disapprove",
    "12": "Reject",
    "13": "Threaten",
    "14": "Protest",
    "15": "Exhibit force posture",
    "16": "Reduce relations",
    "17": "Coerce",
    "18": "Assault",
    "19": "Fight",
    "20": "Use unconventional mass violence"
}

# Granular CAMEO codes for more specific descriptions
CAMEO_GRANULAR_CODES = {
    # RED ZONE - Active Kinetic Warfare
    "190": "Use conventional military force",
    "191": "Impose blockade/restrict movement",
    "192": "Occupy territory",
    "193": "Fight with small arms",
    "194": "Fight with artillery/tanks",
    "195": "Employ aerial weapons/bombing",
    "196": "Violate ceasefire",
    "200": "Use unconventional mass violence",
    "201": "Engage in mass expulsion",
    "202": "Engage in ethnic cleansing",
    "203": "Use weapons of mass destruction",
    "204": "Use WMD - specific types",
    "183": "Carry out suicide/car/roadside bombing",
    "186": "Assassinate",
    # ORANGE ZONE - Imminent Threat
    "152": "Increase military alert status",
    "154": "Mobilize armed forces",
    "138": "Threaten with military force",
    "139": "Give ultimatum",
    "1724": "Impose martial law/state of emergency",
    # YELLOW ZONE - Civil Unrest
    "145": "Protest violently/riot",
}

def get_event_description(event_code, root_code):
    """Get the most specific description for an event code."""
    # First try granular code
    if event_code in CAMEO_GRANULAR_CODES:
        return CAMEO_GRANULAR_CODES[event_code]
    # Try 3-digit prefix for 4-digit codes
    if len(event_code) >= 3:
        prefix = event_code[:3]
        if prefix in CAMEO_GRANULAR_CODES:
            return CAMEO_GRANULAR_CODES[prefix]
    # Fall back to root code
    root = str(root_code).zfill(2)
    return CAMEO_ROOT_CODES.get(root, f"Event Code {event_code}")

def get_threat_zone(event_code, root_code):
    """Categorize event into threat zones: RED, ORANGE, YELLOW, or GRAY."""
    root = str(root_code)
    code = str(event_code)
    
    # RED ZONE - Active kinetic warfare
    if root in ('18', '19', '20'):
        return "RED"
    
    # ORANGE ZONE - Imminent threat
    if root == '15':  # Force posture
        return "ORANGE"
    if code.startswith('138') or code == '139':  # Threaten force / Ultimatum
        return "ORANGE"
    if code == '1724':  # Martial law
        return "ORANGE"
    
    # YELLOW ZONE - Civil unrest
    if code.startswith('145'):  # Violent protest/riot
        return "YELLOW"
    
    return "GRAY"

def fetch_gdelt_events(hours_back=24):
    """
    Fetches kinetic/conflict events from GDELT via BigQuery.
    Filters for Thailand/Cambodia with CAMEO codes indicating material conflict.
    """
    print(f">> [GDELT-BQ] Fetching kinetic events from last {hours_back} hours...")
    
    try:
        client = _init_bigquery_client()
        
        # SQL query for GDELT events - filtered for material conflict
        # RED ZONE: 18 (Assault), 19 (Fight), 20 (Mass Violence)
        # ORANGE ZONE: 15 (Force Posture), specific threat codes
        # YELLOW ZONE: 145 (Violent Protest)
        query = """
        SELECT
            GLOBALEVENTID,
            SQLDATE,
            Actor1Name,
            Actor2Name,
            EventCode,
            EventRootCode,
            GoldsteinScale,
            AvgTone,
            SOURCEURL,
            ActionGeo_Lat,
            ActionGeo_Long,
            ActionGeo_FullName,
            ActionGeo_CountryCode
        FROM `gdelt-bq.gdeltv2.events`
        WHERE
            (ActionGeo_CountryCode = 'TH' OR ActionGeo_CountryCode = 'CB')
            AND (
                -- RED ZONE: Active Kinetic Conflict (Roots 18, 19, 20)
                EventRootCode IN ('18', '19', '20')
                
                OR 
                
                -- ORANGE ZONE: Military Posture (Root 15)
                EventRootCode = '15'
                
                OR
                
                -- ORANGE ZONE: Specific High-Threat Warnings
                EventCode LIKE '138%'   -- Threaten with military force
                OR EventCode = '139'    -- Give Ultimatum
                OR EventCode = '1724'   -- Martial Law / State of Emergency
                
                OR
                
                -- YELLOW ZONE: Violent Civil Unrest
                EventCode LIKE '145%'   -- Violent Protests / Riots
            )
            AND GoldsteinScale < -2.0   -- Confirm negative sentiment
            AND SQLDATE >= CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64)
        ORDER BY 
            CASE 
                WHEN EventRootCode IN ('19', '20') THEN 1  -- Fight/Mass Violence first
                WHEN EventRootCode = '18' THEN 2          -- Assault
                WHEN EventRootCode = '15' THEN 3          -- Force posture
                ELSE 4 
            END,
            GoldsteinScale ASC,
            SQLDATE DESC
        LIMIT 100
        """
        
        print(">> [GDELT-BQ] Executing BigQuery (material conflict filter)...")
        query_job = client.query(query)
        results = query_job.result()
        
        # Map BigQuery results to expected event structure
        kinetic_events = []
        for row in results:
            event_code = str(row.EventCode) if row.EventCode else ""
            root_code = str(row.EventRootCode) if row.EventRootCode else ""
            
            # Get detailed description and threat zone
            event_description = get_event_description(event_code, root_code)
            threat_zone = get_threat_zone(event_code, root_code)
            
            event = {
                "id": str(row.GLOBALEVENTID) if row.GLOBALEVENTID else "unknown",
                "date": str(row.SQLDATE) if row.SQLDATE else "",
                "actor1": row.Actor1Name if row.Actor1Name else "Unknown",
                "actor2": row.Actor2Name if row.Actor2Name else "Unknown",
                "event_code": event_code,
                "event_root_code": root_code,
                "event_description": event_description,
                "threat_zone": threat_zone,
                "goldstein": float(row.GoldsteinScale) if row.GoldsteinScale else 0.0,
                "tone": float(row.AvgTone) if row.AvgTone else 0.0,
                "source_url": row.SOURCEURL if row.SOURCEURL else "",
                "source_name": "GDELT-BigQuery",
                "lat": float(row.ActionGeo_Lat) if row.ActionGeo_Lat else 0.0,
                "lon": float(row.ActionGeo_Long) if row.ActionGeo_Long else 0.0,
                "location_name": row.ActionGeo_FullName if row.ActionGeo_FullName else "Unknown Location",
                "country_code": row.ActionGeo_CountryCode if row.ActionGeo_CountryCode else "",
                "fetched_at": datetime.datetime.utcnow().isoformat()
            }
            kinetic_events.append(event)
        
        # Count by zone for logging
        red_count = sum(1 for e in kinetic_events if e["threat_zone"] == "RED")
        orange_count = sum(1 for e in kinetic_events if e["threat_zone"] == "ORANGE")
        yellow_count = sum(1 for e in kinetic_events if e["threat_zone"] == "YELLOW")
        
        print(f">> [GDELT-BQ] Found {len(kinetic_events)} events: {red_count} RED, {orange_count} ORANGE, {yellow_count} YELLOW")
        return kinetic_events
        
    except Exception as e:
        print(f"[!] BigQuery Error: {e}")
        import traceback
        traceback.print_exc()
        return []


def debug_fetch_gdelt(hours_back=24):
    """
    Debug version that returns the full BigQuery pipeline data:
    - Step 1: The SQL query being executed
    - Step 2: Raw BigQuery response
    - Step 3: All events retrieved
    - Step 4: Filtered/mapped events
    """
    # The SQL query we execute - filtered for material conflict
    sql_query = """
    SELECT
        GLOBALEVENTID,
        SQLDATE,
        Actor1Name,
        Actor2Name,
        EventCode,
        EventRootCode,
        GoldsteinScale,
        AvgTone,
        SOURCEURL,
        ActionGeo_Lat,
        ActionGeo_Long,
        ActionGeo_FullName,
        ActionGeo_CountryCode
    FROM `gdelt-bq.gdeltv2.events`
    WHERE
        (ActionGeo_CountryCode = 'TH' OR ActionGeo_CountryCode = 'CB')
        AND (
            -- RED ZONE: Active Kinetic Conflict (Roots 18, 19, 20)
            EventRootCode IN ('18', '19', '20')
            OR 
            -- ORANGE ZONE: Military Posture (Root 15)
            EventRootCode = '15'
            OR
            -- ORANGE ZONE: Specific High-Threat Warnings
            EventCode LIKE '138%' OR EventCode = '139' OR EventCode = '1724'
            OR
            -- YELLOW ZONE: Violent Civil Unrest
            EventCode LIKE '145%'
        )
        AND GoldsteinScale < -2.0
        AND SQLDATE >= CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64)
    ORDER BY GoldsteinScale ASC, SQLDATE DESC
    LIMIT 50
    """
    
    debug_data = {
        "step_1_request": {
            "data_source": "Google BigQuery",
            "table": "gdelt-bq.gdeltv2.events",
            "sql_query": sql_query.strip(),
            "explanation": "Filtering for MATERIAL CONFLICT: RED (18-Assault, 19-Fight, 20-Mass Violence), ORANGE (15-Force Posture, 138-Threaten Force, 139-Ultimatum), YELLOW (145-Violent Protest). Goldstein < -2."
        },
        "step_2_raw_response": None,
        "step_3_all_events": [],
        "step_4_mapped_events": [],
        "step_5_filter_explanation": "Events filtered by CAMEO codes for kinetic warfare + Goldstein < -2.0"
    }
    
    try:
        client = _init_bigquery_client()
        
        print(">> [DEBUG] Executing BigQuery...")
        query_job = client.query(sql_query)
        results = list(query_job.result())
        
        debug_data["step_2_raw_response"] = {
            "total_rows": len(results),
            "sample_raw_rows": [
                {
                    "GLOBALEVENTID": str(row.GLOBALEVENTID),
                    "SQLDATE": str(row.SQLDATE),
                    "Actor1Name": row.Actor1Name,
                    "Actor2Name": row.Actor2Name,
                    "EventCode": str(row.EventCode),
                    "EventRootCode": str(row.EventRootCode),
                    "GoldsteinScale": float(row.GoldsteinScale) if row.GoldsteinScale else None,
                    "AvgTone": float(row.AvgTone) if row.AvgTone else None,
                    "SOURCEURL": row.SOURCEURL,
                    "ActionGeo_Lat": float(row.ActionGeo_Lat) if row.ActionGeo_Lat else None,
                    "ActionGeo_Long": float(row.ActionGeo_Long) if row.ActionGeo_Long else None,
                    "ActionGeo_FullName": row.ActionGeo_FullName
                }
                for row in results[:5]  # First 5 only
            ]
        }
        
        # Map all events
        mapped_events = []
        for row in results:
            event_code = str(row.EventCode) if row.EventCode else ""
            root_code = str(row.EventRootCode) if row.EventRootCode else ""
            
            event_description = get_event_description(event_code, root_code)
            threat_zone = get_threat_zone(event_code, root_code)
            
            event = {
                "id": str(row.GLOBALEVENTID) if row.GLOBALEVENTID else "unknown",
                "date": str(row.SQLDATE) if row.SQLDATE else "",
                "actor1": row.Actor1Name if row.Actor1Name else "Unknown",
                "actor2": row.Actor2Name if row.Actor2Name else "Unknown",
                "event_code": event_code,
                "event_root_code": root_code,
                "event_description": event_description,
                "threat_zone": threat_zone,
                "goldstein": float(row.GoldsteinScale) if row.GoldsteinScale else 0.0,
                "tone": float(row.AvgTone) if row.AvgTone else 0.0,
                "source_url": row.SOURCEURL if row.SOURCEURL else "",
                "lat": float(row.ActionGeo_Lat) if row.ActionGeo_Lat else 0.0,
                "lon": float(row.ActionGeo_Long) if row.ActionGeo_Long else 0.0,
                "location_name": row.ActionGeo_FullName if row.ActionGeo_FullName else "Unknown Location",
            }
            mapped_events.append(event)
        
        debug_data["step_3_all_events"] = mapped_events
        debug_data["step_4_mapped_events"] = mapped_events  # Same since filtering is in SQL
        
        return debug_data
        
    except Exception as e:
        import traceback
        debug_data["error"] = str(e)
        debug_data["traceback"] = traceback.format_exc()
        return debug_data


def store_event(event):
    """
    Stores a GDELT event in the flash_events MongoDB collection.
    """
    try:
        db = get_db_handle()
        col = db.flash_events
        
        # Add GeoJSON location for spatial queries
        event["location_geo"] = {
            "type": "Point",
            "coordinates": [event.get("lon", 0), event.get("lat", 0)]
        }
        
        # Add fetched timestamp
        event["fetched_at"] = datetime.datetime.utcnow().isoformat()
        
        # Upsert by GDELT event ID to avoid duplicates
        col.update_one(
            {"id": event["id"]},
            {"$set": event},
            upsert=True
        )
        
        print(f">> [DB] Stored event {event['id']} (Goldstein: {event.get('goldstein', '?')})")
        return True
        
    except Exception as e:
        print(f"[!] DB Store Error: {e}")
        return False


def run_cycle():
    """
    Main processing cycle: Fetch GDELT events -> Store in DB
    """
    print("\n" + "="*60)
    print(f">> [CYCLE] Starting at {datetime.datetime.utcnow().isoformat()}")
    print("="*60)
    
    events = fetch_gdelt_events(hours_back=24)
    
    if not events:
        print(">> [CYCLE] No events found.")
        return []
    
    stored = []
    for event in events:
        store_event(event)
        stored.append(event)
        
    print(f">> [CYCLE] Stored {len(stored)} events.")
    return stored


# --- STANDALONE TEST ---
if __name__ == "__main__":
    print("="*60)
    print("SENTINEL FLASH - GDELT Module Test")
    print("="*60)
    
    events = fetch_gdelt_events(hours_back=24)
    
    if events:
        print(f"\n>> Found {len(events)} events. Showing first 3...\n")
        for event in events[:3]:
            print(f"  - [{event.get('event_description', '?')}] {event.get('location_name', 'Unknown')}")
            print(f"    Goldstein: {event.get('goldstein', 'N/A')} | Actors: {event.get('actor1')} vs {event.get('actor2')}")
            print()
    else:
        print(">> No events found in the last 24 hours.")

