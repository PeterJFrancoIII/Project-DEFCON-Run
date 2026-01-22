"use client";

import { useEffect, useState, useCallback } from "react";
import dynamic from "next/dynamic";

// Dynamically import map to avoid SSR issues
const MapView = dynamic(() => import("./components/MapView"), { ssr: false });

// Types
interface NewsArticle {
    _id: string;
    title: string;
    link: string;
    source: string;
    published_at_utc: string;
    fetched_at: string;
}

interface GdeltEvent {
    _id: string;
    id: string;
    date: string;
    location_name: string;
    lat: number;
    lon: number;
    actor1: string;
    actor2: string;
    event_description: string;
    threat_zone: "RED" | "ORANGE" | "YELLOW" | "GRAY";
    goldstein: number;
    source_url: string;
}

interface PipelineData {
    [key: string]: unknown;
}

interface CompareStats {
    news_aggregator: { total_articles: number };
    gdelt: { total_events: number; by_threat_zone: Record<string, number>; available: boolean };
}

const API_BASE = "http://localhost:5052";

export default function Dashboard() {
    // News Aggregator state
    const [newsArticles, setNewsArticles] = useState<NewsArticle[]>([]);
    const [newsFetching, setNewsFetching] = useState(false);
    const [newsPipeline, setNewsPipeline] = useState<PipelineData | null>(null);
    const [showNewsPipeline, setShowNewsPipeline] = useState(false);

    // GDELT state
    const [gdeltEvents, setGdeltEvents] = useState<GdeltEvent[]>([]);
    const [gdeltFetching, setGdeltFetching] = useState(false);
    const [gdeltPipeline, setGdeltPipeline] = useState<PipelineData | null>(null);
    const [showGdeltPipeline, setShowGdeltPipeline] = useState(false);

    // Shared state
    const [stats, setStats] = useState<CompareStats | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [lastUpdate, setLastUpdate] = useState<Date | null>(null);

    // Fetch functions
    const fetchNewsEvents = useCallback(async () => {
        try {
            const res = await fetch(`${API_BASE}/news/events?limit=30`);
            const data = await res.json();
            if (data.status === "success") {
                setNewsArticles(data.articles);
            }
        } catch (err) {
            console.error("News fetch error:", err);
        }
    }, []);

    const fetchGdeltEvents = useCallback(async () => {
        try {
            const res = await fetch(`${API_BASE}/gdelt/events?limit=30`);
            const data = await res.json();
            if (data.status === "success") {
                setGdeltEvents(data.events);
            }
        } catch (err) {
            console.error("GDELT fetch error:", err);
        }
    }, []);

    const fetchStats = useCallback(async () => {
        try {
            const res = await fetch(`${API_BASE}/compare/stats`);
            const data = await res.json();
            if (data.status === "success") {
                setStats(data);
            }
        } catch (err) {
            console.error("Stats fetch error:", err);
        }
    }, []);

    const triggerNewsFetch = async () => {
        setNewsFetching(true);
        try {
            const res = await fetch(`${API_BASE}/news/fetch`, { method: "POST" });
            const data = await res.json();
            if (data.status === "success") {
                await fetchNewsEvents();
                await fetchStats();
                setLastUpdate(new Date());
            }
        } catch (err) {
            setError("News fetch failed. Is the API running?");
            console.error(err);
        } finally {
            setNewsFetching(false);
        }
    };

    const triggerGdeltFetch = async () => {
        setGdeltFetching(true);
        try {
            const res = await fetch(`${API_BASE}/gdelt/fetch?hours=24`, { method: "POST" });
            const data = await res.json();
            if (data.status === "success") {
                await fetchGdeltEvents();
                await fetchStats();
                setLastUpdate(new Date());
            } else {
                setError(data.message || "GDELT fetch failed");
            }
        } catch (err) {
            setError("GDELT fetch failed. Is BigQuery configured?");
            console.error(err);
        } finally {
            setGdeltFetching(false);
        }
    };

    const fetchNewsPipeline = async () => {
        try {
            const res = await fetch(`${API_BASE}/news/pipeline`);
            const data = await res.json();
            if (data.status === "success") {
                setNewsPipeline(data.pipeline);
                setShowNewsPipeline(true);
            }
        } catch (err) {
            console.error(err);
        }
    };

    const fetchGdeltPipeline = async () => {
        try {
            const res = await fetch(`${API_BASE}/gdelt/pipeline?hours=24`);
            const data = await res.json();
            if (data.status === "success") {
                setGdeltPipeline(data.pipeline);
                setShowGdeltPipeline(true);
            }
        } catch (err) {
            console.error(err);
        }
    };

    // Initial load
    useEffect(() => {
        const init = async () => {
            setLoading(true);
            try {
                await Promise.all([fetchNewsEvents(), fetchGdeltEvents(), fetchStats()]);
                setLastUpdate(new Date());
            } catch (err) {
                setError("Failed to connect to API. Is it running on port 5052?");
            }
            setLoading(false);
        };
        init();
    }, [fetchNewsEvents, fetchGdeltEvents, fetchStats]);

    // Threat zone helpers
    const getThreatBadge = (zone: string) => {
        switch (zone) {
            case "RED": return <span className="badge badge-red">🔴 KINETIC</span>;
            case "ORANGE": return <span className="badge badge-orange">🟠 IMMINENT</span>;
            case "YELLOW": return <span className="badge badge-yellow">🟡 UNREST</span>;
            default: return <span className="badge badge-gray">⚪ OTHER</span>;
        }
    };

    const getThreatClass = (zone: string) => {
        switch (zone) {
            case "RED": return "threat-red";
            case "ORANGE": return "threat-orange";
            case "YELLOW": return "threat-yellow";
            default: return "";
        }
    };

    return (
        <div className="min-h-screen p-6">
            {/* Header */}
            <header className="mb-6 flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight">
                        🇺🇦 Ukraine Intel Comparison
                    </h1>
                    <p className="text-gray-400 text-sm">
                        News Aggregator vs GDELT • Donbas / Kherson / Zaporizhzhia / Kyiv
                    </p>
                </div>
                <div className="text-right text-sm text-gray-400">
                    {lastUpdate && (
                        <>
                            <span className="inline-block w-2 h-2 bg-green-500 rounded-full mr-2 animate-pulse"></span>
                            Last update: {lastUpdate.toLocaleTimeString()}
                        </>
                    )}
                </div>
            </header>

            {/* Error Banner */}
            {error && (
                <div className="mb-4 p-4 bg-red-900/50 border border-red-700 rounded-lg text-red-200 flex justify-between items-center">
                    <span>⚠️ {error}</span>
                    <button onClick={() => setError(null)} className="text-red-300 hover:text-white">✕</button>
                </div>
            )}

            {/* Stats Bar */}
            {stats && (
                <div className="grid grid-cols-2 md:grid-cols-5 gap-4 mb-6">
                    <div className="card text-center">
                        <div className="text-2xl font-bold text-green-400">{stats.news_aggregator.total_articles}</div>
                        <div className="text-xs text-gray-400">News Articles</div>
                    </div>
                    <div className="card text-center">
                        <div className="text-2xl font-bold text-indigo-400">{stats.gdelt.total_events}</div>
                        <div className="text-xs text-gray-400">GDELT Events</div>
                    </div>
                    <div className="card text-center">
                        <div className="text-2xl font-bold text-red-400">{stats.gdelt.by_threat_zone?.RED || 0}</div>
                        <div className="text-xs text-gray-400">🔴 Kinetic</div>
                    </div>
                    <div className="card text-center">
                        <div className="text-2xl font-bold text-orange-400">{stats.gdelt.by_threat_zone?.ORANGE || 0}</div>
                        <div className="text-xs text-gray-400">🟠 Imminent</div>
                    </div>
                    <div className="card text-center">
                        <div className="text-2xl font-bold text-yellow-400">{stats.gdelt.by_threat_zone?.YELLOW || 0}</div>
                        <div className="text-xs text-gray-400">🟡 Unrest</div>
                    </div>
                </div>
            )}

            {/* Main Grid */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
                {/* News Aggregator Panel */}
                <div className="card panel-news">
                    <div className="flex items-center justify-between mb-4">
                        <h2 className="text-lg font-semibold text-green-400">
                            📰 News Aggregator
                        </h2>
                        <div className="flex gap-2">
                            <button onClick={fetchNewsPipeline} className="btn btn-secondary text-sm">
                                🔧 Pipeline
                            </button>
                            <button onClick={triggerNewsFetch} disabled={newsFetching} className="btn btn-news">
                                {newsFetching ? "Fetching..." : "⚡ Fetch News"}
                            </button>
                        </div>
                    </div>
                    <p className="text-xs text-gray-500 mb-3">Google News RSS → Dedup → Store</p>

                    {/* Pipeline Debug */}
                    {showNewsPipeline && newsPipeline && (
                        <div className="mb-4 p-3 bg-black/30 rounded-lg text-xs font-mono overflow-x-auto">
                            <div className="flex justify-between mb-2">
                                <span className="text-green-400 font-bold">Pipeline Debug</span>
                                <button onClick={() => setShowNewsPipeline(false)} className="text-gray-500 hover:text-white">✕</button>
                            </div>
                            <pre className="text-gray-300 whitespace-pre-wrap">
                                {JSON.stringify(newsPipeline, null, 2)}
                            </pre>
                        </div>
                    )}

                    {/* News Feed */}
                    <div className="max-h-[400px] overflow-y-auto space-y-2">
                        {loading ? (
                            <div className="text-gray-500 text-center py-8">Loading...</div>
                        ) : newsArticles.length === 0 ? (
                            <div className="text-gray-500 text-center py-8">
                                No articles yet. Click &quot;Fetch News&quot; to start.
                            </div>
                        ) : (
                            newsArticles.map((article) => (
                                <div key={article._id} className="feed-item">
                                    <h3 className="font-medium text-sm mb-1 line-clamp-2">{article.title}</h3>
                                    <div className="flex justify-between text-xs text-gray-500">
                                        <span>{article.source}</span>
                                        {article.link && (
                                            <a href={article.link} target="_blank" rel="noopener noreferrer" className="text-blue-400 hover:underline">
                                                Source →
                                            </a>
                                        )}
                                    </div>
                                </div>
                            ))
                        )}
                    </div>
                </div>

                {/* GDELT Panel */}
                <div className="card panel-gdelt">
                    <div className="flex items-center justify-between mb-4">
                        <h2 className="text-lg font-semibold text-indigo-400">
                            🛰️ GDELT Analyzer
                        </h2>
                        <div className="flex gap-2">
                            <button onClick={fetchGdeltPipeline} className="btn btn-secondary text-sm">
                                🔧 Pipeline
                            </button>
                            <button onClick={triggerGdeltFetch} disabled={gdeltFetching} className="btn btn-gdelt">
                                {gdeltFetching ? "Fetching..." : "⚡ Fetch GDELT"}
                            </button>
                        </div>
                    </div>
                    <p className="text-xs text-gray-500 mb-3">BigQuery CAMEO → Filter → Threat Zone</p>

                    {/* Pipeline Debug */}
                    {showGdeltPipeline && gdeltPipeline && (
                        <div className="mb-4 p-3 bg-black/30 rounded-lg text-xs font-mono overflow-x-auto">
                            <div className="flex justify-between mb-2">
                                <span className="text-indigo-400 font-bold">Pipeline Debug</span>
                                <button onClick={() => setShowGdeltPipeline(false)} className="text-gray-500 hover:text-white">✕</button>
                            </div>
                            <pre className="text-gray-300 whitespace-pre-wrap">
                                {JSON.stringify(gdeltPipeline, null, 2)}
                            </pre>
                        </div>
                    )}

                    {/* GDELT Feed */}
                    <div className="max-h-[400px] overflow-y-auto space-y-2">
                        {loading ? (
                            <div className="text-gray-500 text-center py-8">Loading...</div>
                        ) : !stats?.gdelt?.available ? (
                            <div className="text-yellow-500 text-center py-8">
                                ⚠️ GDELT module not available. Check BigQuery setup.
                            </div>
                        ) : gdeltEvents.length === 0 ? (
                            <div className="text-gray-500 text-center py-8">
                                No events yet. Click &quot;Fetch GDELT&quot; to start.
                            </div>
                        ) : (
                            gdeltEvents.map((event) => (
                                <div key={event._id} className={`feed-item ${getThreatClass(event.threat_zone)}`}>
                                    <div className="flex items-center gap-2 mb-1">
                                        {getThreatBadge(event.threat_zone)}
                                        <span className="text-xs text-gray-400">{event.event_description}</span>
                                    </div>
                                    <h3 className="font-medium text-sm">{event.location_name}</h3>
                                    <div className="flex justify-between text-xs text-gray-500 mt-1">
                                        <span>{event.actor1} {event.actor2 && event.actor2 !== "Unknown" ? `vs ${event.actor2}` : ""}</span>
                                        <div className="flex items-center gap-2">
                                            <span className="font-mono">{event.goldstein?.toFixed(1)}</span>
                                            {event.source_url && (
                                                <a href={event.source_url} target="_blank" rel="noopener noreferrer" className="text-blue-400 hover:underline">
                                                    Source →
                                                </a>
                                            )}
                                        </div>
                                    </div>
                                </div>
                            ))
                        )}
                    </div>
                </div>
            </div>

            {/* Map View */}
            <div className="card">
                <h2 className="text-lg font-semibold mb-4">🗺️ Ukraine Conflict Map</h2>
                <div className="h-[400px] rounded-lg overflow-hidden">
                    <MapView gdeltEvents={gdeltEvents} />
                </div>
            </div>
        </div>
    );
}
