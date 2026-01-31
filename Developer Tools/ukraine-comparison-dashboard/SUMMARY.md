# Ukraine Comparison Dashboard - Summary

## Overview

Built a unified Next.js dashboard comparing two intelligence systems side-by-side for Ukraine conflict monitoring.

| System | Data Source | How It Works |
|--------|-------------|--------------|
| **News Aggregator** | Google News RSS | Keyword filter → Dedup → Store (no AI) |
| **GDELT Analyzer** | BigQuery CAMEO | SQL query → Threat zones → Store |

---

## Files Created

### Dashboard Frontend (`ukraine-comparison-dashboard/`)

| File | Purpose |
|------|---------|
| `app/page.tsx` | Main comparison dashboard with side-by-side panels |
| `app/layout.tsx` | Root layout |
| `app/globals.css` | Tailwind + custom theme (dark mode, threat colors) |
| `app/components/MapView.tsx` | Leaflet map centered on Ukraine |
| `package.json` | Next.js 14, React 18, Leaflet |
| `tsconfig.json` | TypeScript config |
| `tailwind.config.js` | Tailwind setup |
| `README.md` | Quick start guide |

### Backend API (`ukraine-comparison-dashboard/backend/`)

| File | Purpose |
|------|---------|
| `api.py` | Flask API serving both systems on port 5052 |
| `requirements.txt` | Python dependencies |

---

## Files Modified

| File | Change |
|------|--------|
| `Server Backend/sentinel_lab/intelligence.py` | Changed GDELT query from Thailand/Cambodia → Ukraine (country code 'UP') |

---

## API Endpoints

### News Aggregator
- `POST /news/fetch` - Fetch Ukraine news from Google News RSS
- `GET /news/events` - Get stored articles
- `GET /news/pipeline` - Debug pipeline

### GDELT
- `POST /gdelt/fetch` - Fetch Ukraine events from BigQuery
- `GET /gdelt/events` - Get stored events
- `GET /gdelt/pipeline` - Debug pipeline

### Combined
- `GET /compare/stats` - Side-by-side stats
- `GET /health` - Health check

---

## Dashboard Features

1. **Stats Bar** - Live counts for both systems + threat zone breakdown
2. **News Panel** - Headlines with source links
3. **GDELT Panel** - Events with RED/ORANGE/YELLOW threat badges + source links
4. **Pipeline Debug** - Click "Pipeline" to see data flow
5. **Ukraine Map** - Leaflet map with color-coded event markers

---

## How News Aggregator Works (Current)

```
Google News RSS → Keyword Filter → MD5 Dedup → MongoDB → Display
```

Keywords used:
```
Ukraine war shelling OR artillery OR drone attack OR missile strike
OR explosion OR combat OR casualty Donetsk OR Luhansk OR Kherson
OR Zaporizhzhia OR Kyiv
```

**Note:** No AI analysis in dashboard version. The full Sentinel system in `views.py` uses Gemini AI for DEFCON-style threat reports.

---

## Prerequisites

- Python 3.8+ with MongoDB connection
- Node.js 18+
- BigQuery credentials in `Server Backend/Developer Inputs/google_creds.json`

---

## Startup Commands

```bash
# Terminal 1: Start Flask Backend API
cd /Users/Conor/MerrimackLocal/Project-DEFCON-Run/ukraine-comparison-dashboard/backend
python3 api.py
# Runs on http://localhost:5052

# Terminal 2: Start Next.js Dashboard
cd /Users/Conor/MerrimackLocal/Project-DEFCON-Run/ukraine-comparison-dashboard
npm run dev
# Opens on http://localhost:3001
```

---

## Tested Results

- **News Aggregator**: 21 Ukraine articles (Reuters, Kyiv Independent, DW)
- **GDELT**: 100 kinetic events (artillery, aerial weapons, conventional military force)
