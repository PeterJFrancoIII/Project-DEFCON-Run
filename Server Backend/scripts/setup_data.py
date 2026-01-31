"""
SYSTEM: BORDER WATCH
MODULE: setup_data.py
ROLE:   DATA INGESTION ENGINE
DESCRIPTION: 
Reads raw CSV data, calculates sector centroids, and builds the
'thailand_zones.json' geospatial database for the Intelligence Agent.
"""

import csv
import json
import os
import math

INPUT_FILE = "thailand_postal_codes_complete.csv"
OUTPUT_FILE = "thailand_zones.json"

def parse_csv():
    if not os.path.exists(INPUT_FILE):
        print(f"[ERROR] Could not find '{INPUT_FILE}'")
        print("Please ensure the CSV file is in this folder.")
        return

    print(f">> [DATA] Reading {INPUT_FILE}...")
    
    # Storage for aggregation
    # Format: { "10110": { "names": [], "lats": [], "lons": [] } }
    temp_data = {}
    
    try:
        with open(INPUT_FILE, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            count = 0
            for row in reader:
                try:
                    code = row['POSTAL_CODE'].strip()
                    prov = row['PROVINCE_ENGLISH'].strip()
                    dist = row['DISTRICT_ENGLISH'].strip()
                    lat = float(row['LATITUDE'])
                    lon = float(row['LONGITUDE'])
                    
                    if code not in temp_data:
                        temp_data[code] = {
                            "province": prov,
                            "district": dist, # Store first district found as primary label
                            "lats": [],
                            "lons": []
                        }
                    
                    temp_data[code]["lats"].append(lat)
                    temp_data[code]["lons"].append(lon)
                    count += 1
                except ValueError:
                    continue # Skip bad rows
                    
        print(f">> [DATA] Processed {count} raw entries.")
        
        # Consolidate into Centroids
        final_db = {}
        for code, data in temp_data.items():
            avg_lat = sum(data["lats"]) / len(data["lats"])
            avg_lon = sum(data["lons"]) / len(data["lons"])
            
            final_db[code] = {
                "name": f"{data['province']} ({data['district']})",
                "lat": round(avg_lat, 4),
                "lon": round(avg_lon, 4)
            }
            
        # Save to JSON
        with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
            json.dump(final_db, f, indent=2)
            
        print(f">> [SUCCESS] Generated Geospatial DB with {len(final_db)} unique sectors.")
        print(f">> [OUTPUT] Saved to {OUTPUT_FILE}")
        
    except Exception as e:
        print(f"[CRASH] Data processing failed: {e}")

if __name__ == "__main__":
    parse_csv()
