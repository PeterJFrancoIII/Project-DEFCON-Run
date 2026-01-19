# ==============================================================================
# SYSTEM: SENTINEL FLASH TESTBED
# MODULE: api.py
# ROLE:   FLASK REST API FOR DASHBOARD
# ==============================================================================

from flask import Flask, jsonify, request
from flask_cors import CORS
import os
import sys

# Add parent directory to path for db_utils import
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from core.db_utils import get_db_handle

from intelligence import run_cycle

app = Flask(__name__)
CORS(app)  # Allow cross-origin requests from Next.js


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint."""
    return jsonify({"status": "ok", "service": "sentinel-flash-api"})


@app.route('/events', methods=['GET'])
def get_events():
    """
    Returns the latest events from the flash_events collection.
    Query params:
      - limit: Max events to return (default 50)
      - defcon: Filter by DEFCON level (optional)
    """
    try:
        limit = int(request.args.get('limit', 50))
        defcon_filter = request.args.get('defcon')
        
        db = get_db_handle()
        col = db.flash_events
        
        query = {}
        if defcon_filter:
            query["defcon"] = int(defcon_filter)
        
        cursor = col.find(query).sort("fetched_at", -1).limit(limit)
        
        events = []
        for doc in cursor:
            doc['_id'] = str(doc['_id'])  # Convert ObjectId for JSON
            events.append(doc)
        
        return jsonify({
            "status": "success",
            "count": len(events),
            "events": events
        })
        
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500


@app.route('/stats', methods=['GET'])
def get_stats():
    """
    Returns aggregate statistics for the dashboard.
    """
    try:
        db = get_db_handle()
        col = db.flash_events
        
        # Count by event type (CAMEO description)
        event_pipeline = [
            {"$group": {"_id": "$event_description", "count": {"$sum": 1}}},
            {"$sort": {"count": -1}}
        ]
        event_type_counts = list(col.aggregate(event_pipeline))
        
        # Count by Goldstein ranges
        goldstein_pipeline = [
            {"$bucket": {
                "groupBy": "$goldstein",
                "boundaries": [-10, -7, -5, -3, -1, 0],
                "default": "other",
                "output": {"count": {"$sum": 1}}
            }}
        ]
        try:
            goldstein_counts = list(col.aggregate(goldstein_pipeline))
        except:
            goldstein_counts = []  # Fallback if bucket fails
        
        # Total events
        total = col.count_documents({})
        
        return jsonify({
            "status": "success",
            "total_events": total,
            "by_event_type": {str(e["_id"]): e["count"] for e in event_type_counts if e["_id"]},
            "by_goldstein": goldstein_counts
        })
        
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500


@app.route('/trigger', methods=['POST'])
def trigger_cycle():
    """
    Manually triggers an intelligence cycle.
    """
    try:
        results = run_cycle()
        return jsonify({
            "status": "success",
            "message": f"Processed {len(results)} events",
            "events_processed": len(results)
        })
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500


@app.route('/clear', methods=['POST'])
def clear_events():
    """
    Clears all events from the flash_events collection.
    USE WITH CAUTION - for testing only.
    """
    try:
        db = get_db_handle()
        result = db.flash_events.delete_many({})
        return jsonify({
            "status": "success",
            "deleted": result.deleted_count
        })
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500


@app.route('/debug', methods=['GET'])
def debug_pipeline():
    """
    Returns the full GDELT pipeline data for debugging:
    - Step 1: SQL Query
    - Step 2: Raw BigQuery response
    - Step 3: All events parsed
    - Step 4: Mapped events
    """
    try:
        hours = int(request.args.get('hours', 24))
        
        from intelligence import debug_fetch_gdelt
        
        debug_data = debug_fetch_gdelt(hours_back=hours)
        
        return jsonify({
            "status": "success",
            "pipeline": debug_data
        })
        
    except Exception as e:
        import traceback
        return jsonify({
            "status": "error", 
            "message": str(e),
            "traceback": traceback.format_exc()
        }), 500


if __name__ == "__main__":
    print("="*60)
    print("SENTINEL FLASH API - Starting on port 5050")
    print("="*60)
    app.run(host='0.0.0.0', port=5050, debug=True)
