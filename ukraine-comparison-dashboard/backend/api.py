# ==============================================================================
# SYSTEM: UKRAINE COMPARISON DASHBOARD
# MODULE: api.py
# ROLE:   Flask API serving BOTH News Aggregator and GDELT systems
# ==============================================================================

from flask import Flask, jsonify, request
from flask_cors import CORS
import os
import sys
import datetime
import hashlib
import feedparser
import ssl
import pytz
from dateutil import parser as date_parser

# Add parent directories to path for imports
BACKEND_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(os.path.dirname(BACKEND_DIR))
sys.path.insert(0, os.path.join(PROJECT_ROOT, 'Server Backend'))
sys.path.insert(0, os.path.join(PROJECT_ROOT, 'Server Backend', 'sentinel_lab'))

from core.db_utils import get_db_handle

# Try to import GDELT module
try:
    from intelligence import fetch_gdelt_events, debug_fetch_gdelt
    GDELT_AVAILABLE = True
except Exception as e:
    print(f"[!] GDELT module not available: {e}")
    GDELT_AVAILABLE = False

app = Flask(__name__)
CORS(app)

# =============================================================================
# UKRAINE NEWS CONFIGURATION
# =============================================================================

UKRAINE_NEWS_QUERY = (
    "Ukraine war shelling OR artillery OR drone attack OR missile strike "
    "OR explosion OR combat OR casualty Donetsk OR Luhansk OR Kherson "
    "OR Zaporizhzhia OR Kyiv"
)

# Collection names for storing data
NEWS_COLLECTION = "ukraine_news_index"
GDELT_COLLECTION = "ukraine_gdelt_events"


def get_msg_hash(text):
    """Generate MD5 hash for deduplication."""
    return hashlib.md5(text.encode('utf-8')).hexdigest()


# =============================================================================
# NEWS AGGREGATOR ENDPOINTS
# =============================================================================

@app.route('/news/fetch', methods=['POST'])
def fetch_news():
    """
    Fetch Ukraine news from Google News RSS.
    Store new articles in MongoDB with deduplication.
    """
    try:
        if hasattr(ssl, '_create_unverified_context'):
            ssl._create_default_https_context = ssl._create_unverified_context
        
        url = f"https://news.google.com/rss/search?q={UKRAINE_NEWS_QUERY.replace(' ', '+')}&hl=en-US&gl=US&ceid=US:en"
        feed = feedparser.parse(url)
        
        db = get_db_handle()
        news_col = db[NEWS_COLLECTION]
        
        now_utc = datetime.datetime.now(pytz.utc)
        min_date = now_utc - datetime.timedelta(days=3)
        
        new_articles = []
        duplicates_skipped = 0
        
        for entry in feed.entries[:50]:
            # Parse date
            try:
                pub_date = date_parser.parse(entry.get('published', str(datetime.datetime.now())))
                if pub_date.tzinfo is None:
                    pub_date = pub_date.replace(tzinfo=pytz.utc)
                else:
                    pub_date = pub_date.astimezone(pytz.utc)
            except:
                pub_date = now_utc
            
            # Skip old articles
            if pub_date < min_date:
                continue
            
            # Deduplication check
            url_hash = get_msg_hash(entry.get('link', ''))
            title_hash = get_msg_hash(entry.title.strip().lower())
            
            existing = news_col.find_one({
                "$or": [{"url_hash": url_hash}, {"title_hash": title_hash}]
            })
            
            if existing:
                duplicates_skipped += 1
                continue
            
            # Insert new article
            doc = {
                "url_hash": url_hash,
                "title_hash": title_hash,
                "title": entry.title,
                "link": entry.link,
                "source": entry.get('source', {}).get('title', 'Google News'),
                "published_at_utc": pub_date.isoformat(),
                "fetched_at": now_utc.isoformat(),
                "system": "news_aggregator"
            }
            news_col.insert_one(doc)
            new_articles.append(doc)
        
        return jsonify({
            "status": "success",
            "new_articles": len(new_articles),
            "duplicates_skipped": duplicates_skipped,
            "total_in_feed": len(feed.entries)
        })
        
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500


@app.route('/news/events', methods=['GET'])
def get_news_events():
    """Get stored news articles."""
    try:
        limit = int(request.args.get('limit', 50))
        
        db = get_db_handle()
        news_col = db[NEWS_COLLECTION]
        
        cursor = news_col.find().sort("fetched_at", -1).limit(limit)
        
        articles = []
        for doc in cursor:
            doc['_id'] = str(doc['_id'])
            articles.append(doc)
        
        return jsonify({
            "status": "success",
            "count": len(articles),
            "articles": articles
        })
        
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500


@app.route('/news/pipeline', methods=['GET'])
def news_pipeline():
    """
    Debug endpoint showing the News Aggregator pipeline:
    Step 1: RSS Query
    Step 2: Raw feed entries
    Step 3: Deduplication check
    Step 4: Final articles
    """
    try:
        if hasattr(ssl, '_create_unverified_context'):
            ssl._create_default_https_context = ssl._create_unverified_context
        
        url = f"https://news.google.com/rss/search?q={UKRAINE_NEWS_QUERY.replace(' ', '+')}&hl=en-US&gl=US&ceid=US:en"
        feed = feedparser.parse(url)
        
        db = get_db_handle()
        news_col = db[NEWS_COLLECTION]
        
        # Sample of raw entries
        raw_entries = []
        for entry in feed.entries[:10]:
            raw_entries.append({
                "title": entry.title,
                "link": entry.link,
                "published": entry.get('published', 'N/A'),
                "source": entry.get('source', {}).get('title', 'Unknown')
            })
        
        # Count stored
        total_stored = news_col.count_documents({})
        
        return jsonify({
            "status": "success",
            "pipeline": {
                "step1_query": UKRAINE_NEWS_QUERY,
                "step2_rss_url": url,
                "step3_raw_count": len(feed.entries),
                "step4_sample_entries": raw_entries,
                "step5_stored_count": total_stored
            }
        })
        
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500


# =============================================================================
# GDELT ENDPOINTS
# =============================================================================

@app.route('/gdelt/fetch', methods=['POST'])
def fetch_gdelt():
    """Trigger GDELT BigQuery fetch for Ukraine."""
    if not GDELT_AVAILABLE:
        return jsonify({"status": "error", "message": "GDELT module not available"}), 500
    
    try:
        # Fetch events (this uses BigQuery under the hood)
        hours = int(request.args.get('hours', 24))
        events = fetch_gdelt_events(hours_back=hours)
        
        # Filter for Ukraine (country code 'UP')
        ukraine_events = [e for e in events if e.get('country_code') == 'UP']
        
        # Store in MongoDB
        db = get_db_handle()
        col = db[GDELT_COLLECTION]
        
        new_count = 0
        for event in ukraine_events:
            event['system'] = 'gdelt'
            # Upsert by event ID
            result = col.update_one(
                {"id": event.get('id')},
                {"$set": event},
                upsert=True
            )
            if result.upserted_id:
                new_count += 1
        
        return jsonify({
            "status": "success",
            "total_fetched": len(events),
            "ukraine_events": len(ukraine_events),
            "new_stored": new_count
        })
        
    except Exception as e:
        import traceback
        return jsonify({
            "status": "error",
            "message": str(e),
            "traceback": traceback.format_exc()
        }), 500


@app.route('/gdelt/events', methods=['GET'])
def get_gdelt_events():
    """Get stored GDELT events for Ukraine."""
    try:
        limit = int(request.args.get('limit', 50))
        
        db = get_db_handle()
        col = db[GDELT_COLLECTION]
        
        cursor = col.find().sort("fetched_at", -1).limit(limit)
        
        events = []
        for doc in cursor:
            doc['_id'] = str(doc['_id'])
            events.append(doc)
        
        return jsonify({
            "status": "success",
            "count": len(events),
            "events": events
        })
        
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500


@app.route('/gdelt/pipeline', methods=['GET'])
def gdelt_pipeline():
    """
    Debug endpoint showing the GDELT pipeline.
    """
    if not GDELT_AVAILABLE:
        return jsonify({"status": "error", "message": "GDELT module not available"}), 500
    
    try:
        hours = int(request.args.get('hours', 24))
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


# =============================================================================
# COMPARISON ENDPOINTS
# =============================================================================

@app.route('/compare/stats', methods=['GET'])
def compare_stats():
    """Get side-by-side stats for both systems."""
    try:
        db = get_db_handle()
        
        news_count = db[NEWS_COLLECTION].count_documents({})
        gdelt_count = db[GDELT_COLLECTION].count_documents({})
        
        # Count by threat zone for GDELT
        gdelt_by_zone = {}
        if GDELT_AVAILABLE:
            for zone in ['RED', 'ORANGE', 'YELLOW', 'GRAY']:
                gdelt_by_zone[zone] = db[GDELT_COLLECTION].count_documents({"threat_zone": zone})
        
        return jsonify({
            "status": "success",
            "news_aggregator": {
                "total_articles": news_count
            },
            "gdelt": {
                "total_events": gdelt_count,
                "by_threat_zone": gdelt_by_zone,
                "available": GDELT_AVAILABLE
            }
        })
        
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500


@app.route('/health', methods=['GET'])
def health():
    """Health check."""
    return jsonify({
        "status": "ok",
        "service": "ukraine-comparison-api",
        "gdelt_available": GDELT_AVAILABLE
    })


if __name__ == "__main__":
    print("=" * 60)
    print(" UKRAINE COMPARISON DASHBOARD API")
    print(f" GDELT Available: {GDELT_AVAILABLE}")
    print(" Starting on port 5052...")
    print("=" * 60)
    app.run(host='0.0.0.0', port=5052, debug=True)
