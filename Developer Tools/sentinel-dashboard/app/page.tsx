"use client";

import { useEffect, useState, useCallback } from "react";
import dynamic from "next/dynamic";

// Dynamically import the map to avoid SSR issues with Leaflet
const MapView = dynamic(() => import("./components/MapView"), { ssr: false });

// Types
interface FlashEvent {
  id: string;
  date: string;
  location_name: string;
  lat: number;
  lon: number;
  actor1: string;
  actor2: string;
  event_code: string;
  event_root_code: string;
  event_description: string;
  threat_zone: "RED" | "ORANGE" | "YELLOW" | "GRAY";
  goldstein: number;
  tone: number;
  source_url: string;
  country_code: string;
  fetched_at: string;
}

interface Stats {
  total_events: number;
  by_event_type: Record<string, number>;
  by_goldstein: Array<{ _id: number; count: number }>;
}

const API_BASE = "http://localhost:5050";

export default function Dashboard() {
  const [events, setEvents] = useState<FlashEvent[]>([]);
  const [stats, setStats] = useState<Stats | null>(null);
  const [loading, setLoading] = useState(true);
  const [triggering, setTriggering] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdate, setLastUpdate] = useState<Date | null>(null);

  const fetchEvents = useCallback(async () => {
    try {
      const res = await fetch(`${API_BASE}/events?limit=100`);
      const data = await res.json();
      if (data.status === "success") {
        setEvents(data.events);
        setLastUpdate(new Date());
      }
    } catch (err) {
      setError("Failed to connect to API. Is the Flask server running?");
      console.error(err);
    }
  }, []);

  const fetchStats = useCallback(async () => {
    try {
      const res = await fetch(`${API_BASE}/stats`);
      const data = await res.json();
      if (data.status === "success") {
        setStats(data);
      }
    } catch (err) {
      console.error(err);
    }
  }, []);

  const triggerCycle = async () => {
    setTriggering(true);
    try {
      const res = await fetch(`${API_BASE}/trigger`, { method: "POST" });
      const data = await res.json();
      if (data.status === "success") {
        // Refresh data after trigger
        await fetchEvents();
        await fetchStats();
      }
    } catch (err) {
      setError("Trigger failed. Check API connection.");
      console.error(err);
    } finally {
      setTriggering(false);
    }
  };

  useEffect(() => {
    const init = async () => {
      setLoading(true);
      await Promise.all([fetchEvents(), fetchStats()]);
      setLoading(false);
    };
    init();

    // Auto-refresh every 30 seconds
    const interval = setInterval(() => {
      fetchEvents();
      fetchStats();
    }, 30000);

    return () => clearInterval(interval);
  }, [fetchEvents, fetchStats]);

  // Color based on threat zone
  const getThreatZoneStyle = (zone: string) => {
    switch (zone) {
      case "RED": return "bg-red-600 text-white";
      case "ORANGE": return "bg-orange-500 text-white";
      case "YELLOW": return "bg-yellow-500 text-black";
      default: return "bg-gray-500 text-white";
    }
  };

  const getThreatZoneLabel = (zone: string) => {
    switch (zone) {
      case "RED": return "🔴 KINETIC";
      case "ORANGE": return "🟠 IMMINENT";
      case "YELLOW": return "🟡 UNREST";
      default: return "⚪ OTHER";
    }
  };

  // Count events by zone
  const zoneCount = {
    RED: events.filter(e => e.threat_zone === "RED").length,
    ORANGE: events.filter(e => e.threat_zone === "ORANGE").length,
    YELLOW: events.filter(e => e.threat_zone === "YELLOW").length,
  };

  return (
    <div className="min-h-screen p-6">
      {/* Header */}
      <header className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">
            🛰️ Conflict Monitor
          </h1>
          <p className="text-gray-400 text-sm">
            GDELT Material Conflict Feed • Thailand / Cambodia
          </p>
        </div>
        <div className="flex items-center gap-4">
          <div className="text-right text-sm text-gray-400">
            {lastUpdate && (
              <>
                <span className="inline-block w-2 h-2 bg-green-500 rounded-full mr-2 animate-pulse"></span>
                Last update: {lastUpdate.toLocaleTimeString()}
              </>
            )}
          </div>
          <a
            href="/debug"
            className="px-4 py-2 bg-gray-700 hover:bg-gray-600 rounded-lg font-medium transition-colors"
          >
            🔬 Debug
          </a>
          <button
            onClick={triggerCycle}
            disabled={triggering}
            className="px-4 py-2 bg-blue-600 hover:bg-blue-700 disabled:bg-blue-800 disabled:cursor-wait rounded-lg font-medium transition-colors"
          >
            {triggering ? "Fetching..." : "⚡ Fetch Events"}
          </button>
        </div>
      </header>

      {/* Error Banner */}
      {error && (
        <div className="mb-4 p-4 bg-red-900/50 border border-red-700 rounded-lg text-red-200">
          ⚠️ {error}
        </div>
      )}

      {/* Main Grid */}
      <div className="grid grid-cols-12 gap-6">
        {/* Stats Panel */}
        <div className="col-span-12 lg:col-span-3">
          <div className="card">
            <h2 className="text-lg font-semibold mb-4">📊 Threat Summary</h2>
            {stats ? (
              <div className="space-y-4">
                <div className="text-center p-4 bg-gray-800/50 rounded-lg">
                  <div className="text-4xl font-bold">{stats.total_events}</div>
                  <div className="text-sm text-gray-400">Total Events</div>
                </div>

                {/* Threat Zone Breakdown */}
                <div>
                  <h3 className="text-sm font-medium text-gray-400 mb-2">By Threat Level</h3>
                  <div className="space-y-2">
                    <div className="flex items-center justify-between p-2 bg-red-900/30 border border-red-700/50 rounded">
                      <span className="text-red-400 font-medium">🔴 RED - Active Combat</span>
                      <span className="font-mono font-bold text-red-400">{zoneCount.RED}</span>
                    </div>
                    <div className="flex items-center justify-between p-2 bg-orange-900/30 border border-orange-700/50 rounded">
                      <span className="text-orange-400 font-medium">🟠 ORANGE - Imminent</span>
                      <span className="font-mono font-bold text-orange-400">{zoneCount.ORANGE}</span>
                    </div>
                    <div className="flex items-center justify-between p-2 bg-yellow-900/30 border border-yellow-700/50 rounded">
                      <span className="text-yellow-400 font-medium">🟡 YELLOW - Civil Unrest</span>
                      <span className="font-mono font-bold text-yellow-400">{zoneCount.YELLOW}</span>
                    </div>
                  </div>
                </div>

                {/* Event Types */}
                <div>
                  <h3 className="text-sm font-medium text-gray-400 mb-2">By Event Type</h3>
                  <div className="space-y-1 text-sm max-h-32 overflow-y-auto">
                    {Object.entries(stats.by_event_type || {}).slice(0, 8).map(([type, count]) => (
                      <div key={type} className="flex justify-between">
                        <span className="text-gray-300 truncate mr-2">{type}</span>
                        <span className="font-mono">{count}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            ) : (
              <div className="text-gray-500 text-center py-8">Loading...</div>
            )}
          </div>
        </div>

        {/* Map */}
        <div className="col-span-12 lg:col-span-5">
          <div className="card h-[500px]">
            <h2 className="text-lg font-semibold mb-4">🗺️ Event Map</h2>
            <div className="h-[calc(100%-2rem)]">
              <MapView events={events} />
            </div>
          </div>
        </div>

        {/* Event Feed */}
        <div className="col-span-12 lg:col-span-4">
          <div className="card h-[500px] flex flex-col">
            <h2 className="text-lg font-semibold mb-4">📡 Conflict Feed</h2>
            <div className="flex-1 overflow-y-auto space-y-3">
              {loading ? (
                <div className="text-gray-500 text-center py-8">Loading events...</div>
              ) : events.length === 0 ? (
                <div className="text-gray-500 text-center py-8">
                  No conflict events found. Click &quot;Fetch Events&quot; to check.
                </div>
              ) : (
                events.map((event) => (
                  <div
                    key={event.id}
                    className={`p-3 rounded-lg border transition-colors ${event.threat_zone === "RED"
                        ? "bg-red-900/20 border-red-700/50 hover:border-red-500"
                        : event.threat_zone === "ORANGE"
                          ? "bg-orange-900/20 border-orange-700/50 hover:border-orange-500"
                          : event.threat_zone === "YELLOW"
                            ? "bg-yellow-900/20 border-yellow-700/50 hover:border-yellow-500"
                            : "bg-gray-800/50 border-gray-700 hover:border-gray-600"
                      }`}
                  >
                    <div className="flex items-start justify-between gap-2">
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 mb-1 flex-wrap">
                          <span className={`px-2 py-0.5 rounded text-xs font-bold ${getThreatZoneStyle(event.threat_zone)}`}>
                            {getThreatZoneLabel(event.threat_zone)}
                          </span>
                          <span className="text-xs text-gray-400">{event.event_description}</span>
                        </div>
                        <h3 className="font-medium text-sm truncate">{event.location_name}</h3>
                        <p className="text-xs text-gray-400 mt-1">
                          {event.actor1} {event.actor2 && event.actor2 !== "Unknown" ? `vs ${event.actor2}` : ""}
                        </p>
                      </div>
                      <div className="text-right">
                        <div className="text-xs font-mono text-gray-500">
                          {event.goldstein?.toFixed(1)}
                        </div>
                      </div>
                    </div>
                    <div className="mt-2 flex items-center justify-between text-xs text-gray-500">
                      <span>Code: {event.event_code}</span>
                      {event.source_url && (
                        <a
                          href={event.source_url}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-blue-400 hover:underline"
                        >
                          Source →
                        </a>
                      )}
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
