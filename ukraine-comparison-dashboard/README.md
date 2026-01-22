# Ukraine Comparison Dashboard

Compare the **News Aggregator** (Google News RSS + Gemini AI) vs **GDELT** (BigQuery CAMEO codes) systems side-by-side for Ukraine conflict monitoring.

## Quick Start

### 1. Start Backend API

```bash
cd backend
pip install -r requirements.txt
python api.py
# Runs on http://localhost:5052
```

### 2. Start Next.js Dashboard

```bash
npm install
npm run dev
# Opens on http://localhost:3001
```

## Architecture

| System | Source | What It Does |
|--------|--------|--------------|
| News Aggregator | Google News RSS | Scrapes news headlines with Ukraine keywords |
| GDELT | BigQuery | Queries CAMEO conflict events for Ukraine |

## Endpoints

- **News:** `/news/fetch`, `/news/events`, `/news/pipeline`
- **GDELT:** `/gdelt/fetch`, `/gdelt/events`, `/gdelt/pipeline`
- **Compare:** `/compare/stats`

## Requirements

- Python 3.8+ with MongoDB connection
- Node.js 18+
- Google Cloud BigQuery credentials (for GDELT)
