
import os
import sys
import argparse
import time

# Add Server Backend to Path to find 'core'
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.db_utils import get_db_handle
from core.logic.mission import run_mission_logic, run_translation_logic, fetch_news, get_geo_from_csv 
# from core.views import get_geo_from_csv # Deprecated import

def main():
    parser = argparse.ArgumentParser(description="Sentinel Conflict Agent (CLI)")
    parser.add_argument('--zip', type=str, default="10110", help="Target Zip Code")
    parser.add_argument('--country', type=str, default="TH", help="Target Country")
    parser.add_argument('--lang', type=str, default="en", help="Target Language")
    parser.add_argument('--force', action='store_true', help="Force regeneration (ignore cache)")
    
    args = parser.parse_args()
    
    print(f">> [AGENT] Starting Mission for Zip: {args.zip} ({args.country})")
    
    # Check if Intel Exists
    db = get_db_handle()
    col = db.intel_history
    doc = col.find_one({'zip_code': args.zip})
    
    needs_generation = True
    
    if doc and not args.force:
        print(">> [AGENT] Found existing intelligence.")
        ts = doc.get('timestamp')
        # Check staleness (Optional CLI logic)
        print(f">> [AGENT] Timestamp: {ts}")
        
        # If lang is missing, just translate
        if args.lang not in doc.get('languages', {}):
             print(f">> [AGENT] Target language '{args.lang}' missing. running translation...")
             base_data = doc.get('languages', {}).get('en')
             if base_data:
                 run_translation_logic(args.zip, args.lang, base_data)
                 needs_generation = False
             else:
                 print(">> [AGENT] Base EN missing. Regenerating full mission.")
                 needs_generation = True
        else:
            needs_generation = False
            print(">> [AGENT] Intelligence is fresh enough or cached. Use --force to regenerate.")

    if needs_generation:
        # Resolve Geo
        geo_data = get_geo_from_csv(args.zip)
        if not geo_data:
            print(f"!! [ERROR] Zip Code {args.zip} not found in CSV.")
            return

        print(">> [AGENT] Running Canonical Mission Logic...")
        run_mission_logic(
            zip_code=args.zip,
            country=args.country,
            geo_data=geo_data,
            target_lang=args.lang,
            device_id="CLI_AGENT"
        )
        print(">> [AGENT] Mission Complete.")

if __name__ == "__main__":
    main()
