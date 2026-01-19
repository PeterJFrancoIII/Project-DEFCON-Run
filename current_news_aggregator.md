The "News Aggregator" and Analyzer is a backend pipeline that combines real-time RSS monitoring with an AI Intelligence Officer to generate threat reports. It currently resides in 
Server Backend/core/views.py
.

1. The Collector ("News Aggregator")
Source: It scrapes the Google News RSS feed directly.
Search Query: It is hardcoded to look for specific kinetic keywords in the Thailand/Cambodia region: "Thailand Cambodia border shelling OR artillery OR mortar OR drone attack OR firefight OR explosion OR clash"
Filtering & Deduplication:
Time Window: Ignores any articles older than 3 days.
Anti-Drift: It generates MD5 hashes of every article's Title and Link. It checks these against a MongoDB collection (news_index) to ensure it never processes the same story twice (Drift Detection).
2. The Brain ("The Analyzer")
Once the news is collected, the system runs a "Mission" (
run_mission_logic
):

Dynamic Compliance: First, it uses 
compliance.py
 to check if the requested location falls inside a restricted "Exclusion Zone" (defined in local CSV files). If so, it immediately blocks the request.
AI Interpretation: It constructs a massive prompt for Gemini 3 Pro (or Flash fallback). This prompt injects:
The User's specific GPS location.
The distance to the nearest known conflict "Hotzone".
The raw text of the fetched news headlines.
Strict Persona: The AI is instructed via 
analyst_system_prompt.txt
 to act as "SENTINEL-01", a Military Intelligence Officer. It must output a strict JSON report containing:
DEFCON Status (1-5): With strict rules (e.g., DEFCON 1 requires active shelling <15km).
Evacuation Points: Specific coordinates for safety.
SITREP: A 5-point Situation Report covering Political, Military, Civilian, Economic, and Diplomatic domains.
Safety Override: If the AI determines a DEFCON 1 (Critical) threat, the system automatically intervenes and downgrades it to DEFCON 2, flagging it as "PENDING HUMAN VERIFICATION" to prevent panic from false positives.
3. The Delivery
Storage: The final JSON report is saved to MongoDB (intel_history), keyed by the Zip Code.
Translation: A background worker immediately spins up a lighter model (Gemini 2.5 Flash Lite) to translate the entire intelligence report into Thai or Khmer if needed.




How it runs: On-Demand (Not a Schedule)
You are correct that it is Zip Code based, but it is not on a fixed timer/schedule (like a cron job). It operates on a "Lazy Loading" / On-Demand model triggered by the user.

Trigger: The process starts momentarily when a mobile app (or client) hits the /api/intel?zip=XXXXX endpoint.
The "Freshness" Check:
The system checks MongoDB for existing intel for that Zip Code.
Stale Threshold: It has a hardcoded setting of 4 Hours (14400 seconds).
If the data is fresh (< 4 hours old), it returns the cached report immediately.
If the request is stale or new, it kicks off the "Mission" (Scraping + AI Analysis) in a background thread and returns a "Calculating..." status to the user.
Concurrency: It has a MISSION_QUEUE in memory. If 100 users in the same Zip Code request an update at once, it only runs one extraction job and serves the result to everyone.
In summary: It doesn't "wake up" on its own. It only wakes up when a user asks for data, and only effectively "runs" the scraper once every 4 hours per location.