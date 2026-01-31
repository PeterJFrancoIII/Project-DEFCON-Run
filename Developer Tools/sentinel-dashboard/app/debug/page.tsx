"use client";

import { useState } from "react";

const API_BASE = "http://localhost:5050";

interface PipelineData {
    step_1_request: {
        data_source: string;
        table: string;
        sql_query: string;
        explanation: string;
    };
    step_2_raw_response: {
        total_rows: number;
        sample_raw_rows: unknown[];
    } | null;
    step_3_all_events: Array<{
        id: string;
        date: string;
        actor1: string;
        actor2: string;
        event_description: string;
        goldstein: number;
        location_name: string;
        source_url: string;
    }>;
    step_4_mapped_events: Array<{
        id: string;
        date: string;
        actor1: string;
        actor2: string;
        event_description: string;
        goldstein: number;
        location_name: string;
    }>;
    step_5_filter_explanation: string;
    error?: string;
    traceback?: string;
}

export default function DebugPage() {
    const [loading, setLoading] = useState(false);
    const [hours, setHours] = useState(24);
    const [pipeline, setPipeline] = useState<PipelineData | null>(null);
    const [error, setError] = useState<string | null>(null);
    const [expandedStep, setExpandedStep] = useState<number | null>(1);

    const fetchDebugData = async () => {
        setLoading(true);
        setError(null);
        try {
            const res = await fetch(`${API_BASE}/debug?hours=${hours}`);
            const data = await res.json();
            if (data.status === "success") {
                setPipeline(data.pipeline);
            } else {
                setError(data.message || "Unknown error");
            }
        } catch (err) {
            setError("Failed to connect to API. Is the Flask server running on port 5050?");
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    const StepCard = ({
        step,
        title,
        children,
        count
    }: {
        step: number;
        title: string;
        children: React.ReactNode;
        count?: number;
    }) => (
        <div className="card mb-4">
            <button
                onClick={() => setExpandedStep(expandedStep === step ? null : step)}
                className="w-full flex items-center justify-between text-left"
            >
                <div className="flex items-center gap-3">
                    <span className="w-8 h-8 rounded-full bg-blue-600 flex items-center justify-center text-sm font-bold">
                        {step}
                    </span>
                    <h3 className="text-lg font-semibold">{title}</h3>
                </div>
                <div className="flex items-center gap-2">
                    {count !== undefined && (
                        <span className="px-2 py-1 bg-gray-700 rounded text-sm">{count} items</span>
                    )}
                    <span className="text-gray-400">{expandedStep === step ? "▼" : "▶"}</span>
                </div>
            </button>
            {expandedStep === step && (
                <div className="mt-4 pt-4 border-t border-gray-700">
                    {children}
                </div>
            )}
        </div>
    );

    return (
        <div className="min-h-screen p-6">
            {/* Header */}
            <header className="mb-6">
                <div className="flex items-center gap-4 mb-4">
                    <a href="/" className="text-blue-400 hover:underline">← Back to Dashboard</a>
                </div>
                <h1 className="text-3xl font-bold tracking-tight">🔬 Pipeline Debug</h1>
                <p className="text-gray-400 text-sm">
                    Inspect the full GDELT → Filter → AI pipeline step-by-step
                </p>
            </header>

            {/* Controls */}
            <div className="card mb-6 flex items-center gap-4">
                <label className="text-sm text-gray-400">
                    Time window:
                    <select
                        value={hours}
                        onChange={(e) => setHours(Number(e.target.value))}
                        className="ml-2 bg-gray-800 border border-gray-600 rounded px-2 py-1"
                    >
                        <option value={6}>Last 6 hours</option>
                        <option value={12}>Last 12 hours</option>
                        <option value={24}>Last 24 hours</option>
                        <option value={48}>Last 48 hours</option>
                        <option value={72}>Last 72 hours</option>
                    </select>
                </label>
                <button
                    onClick={fetchDebugData}
                    disabled={loading}
                    className="px-4 py-2 bg-blue-600 hover:bg-blue-700 disabled:bg-blue-800 disabled:cursor-wait rounded-lg font-medium transition-colors"
                >
                    {loading ? "Fetching..." : "🔍 Fetch Pipeline Data"}
                </button>
            </div>

            {/* Error */}
            {error && (
                <div className="mb-4 p-4 bg-red-900/50 border border-red-700 rounded-lg text-red-200">
                    ⚠️ {error}
                </div>
            )}

            {/* Pipeline Steps */}
            {pipeline && (
                <div>
                    {/* Step 1: Request */}
                    <StepCard step={1} title="BigQuery SQL Request">
                        <div className="space-y-3">
                            <div className="grid grid-cols-2 gap-4">
                                <div className="p-3 bg-gray-800 rounded">
                                    <span className="text-gray-400 text-sm">Data Source</span>
                                    <div className="font-mono">{pipeline.step_1_request.data_source}</div>
                                </div>
                                <div className="p-3 bg-gray-800 rounded">
                                    <span className="text-gray-400 text-sm">Table</span>
                                    <div className="font-mono text-sm">{pipeline.step_1_request.table}</div>
                                </div>
                            </div>
                            <div>
                                <span className="text-gray-400 text-sm">SQL Query:</span>
                                <pre className="mt-1 p-3 bg-gray-800 rounded text-sm overflow-x-auto whitespace-pre-wrap">
                                    {pipeline.step_1_request.sql_query}
                                </pre>
                            </div>
                            <div className="p-3 bg-blue-900/30 border border-blue-700 rounded text-sm">
                                💡 {pipeline.step_1_request.explanation}
                            </div>
                        </div>
                    </StepCard>

                    {/* Step 2: Raw Response */}
                    <StepCard
                        step={2}
                        title="Raw BigQuery Response"
                        count={pipeline.step_2_raw_response?.total_rows}
                    >
                        {pipeline.step_2_raw_response ? (
                            <div className="space-y-3">
                                <div className="p-3 bg-gray-800 rounded">
                                    <span className="text-gray-400 text-sm">Total Rows Returned</span>
                                    <div className="text-2xl font-bold">{pipeline.step_2_raw_response.total_rows}</div>
                                </div>
                                <div>
                                    <span className="text-gray-400 text-sm">Sample Raw Rows (first 5):</span>
                                    <pre className="mt-1 p-3 bg-gray-800 rounded text-xs overflow-x-auto max-h-64 overflow-y-auto">
                                        {JSON.stringify(pipeline.step_2_raw_response.sample_raw_rows, null, 2)}
                                    </pre>
                                </div>
                            </div>
                        ) : (
                            <div className="text-gray-500">No response data</div>
                        )}
                    </StepCard>

                    {/* Step 3: All Events */}
                    <StepCard
                        step={3}
                        title="Mapped Events (All)"
                        count={pipeline.step_3_all_events?.length ?? 0}
                    >
                        <div className="overflow-x-auto">
                            <table className="w-full text-sm">
                                <thead>
                                    <tr className="text-left text-gray-400 border-b border-gray-700">
                                        <th className="pb-2">ID</th>
                                        <th className="pb-2">Actors</th>
                                        <th className="pb-2">Event</th>
                                        <th className="pb-2">Goldstein</th>
                                        <th className="pb-2">Location</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {(pipeline.step_3_all_events ?? []).slice(0, 20).map((event, i) => (
                                        <tr key={i} className="border-b border-gray-800">
                                            <td className="py-2 font-mono text-xs">{event.id}</td>
                                            <td className="py-2">{event.actor1} vs {event.actor2}</td>
                                            <td className="py-2">{event.event_description}</td>
                                            <td className={`py-2 font-mono ${event.goldstein <= 0 ? 'text-red-400' : 'text-green-400'}`}>
                                                {event.goldstein.toFixed(1)}
                                            </td>
                                            <td className="py-2 text-xs">{event.location_name}</td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                            {(pipeline.step_3_all_events?.length ?? 0) > 20 && (
                                <div className="mt-2 text-gray-400 text-sm">
                                    ... and {(pipeline.step_3_all_events?.length ?? 0) - 20} more
                                </div>
                            )}
                        </div>
                    </StepCard>

                    {/* Step 4: Mapped Events */}
                    <StepCard
                        step={4}
                        title="Mapped Events (Pre-filtered in SQL)"
                        count={pipeline.step_4_mapped_events?.length ?? 0}
                    >
                        <div className="mb-3 p-3 bg-yellow-900/30 border border-yellow-700 rounded text-sm">
                            ⚡ {pipeline.step_5_filter_explanation}
                        </div>
                        {(pipeline.step_4_mapped_events?.length ?? 0) > 0 ? (
                            <div className="space-y-2">
                                {(pipeline.step_4_mapped_events ?? []).map((event, i) => (
                                    <div key={i} className="p-3 bg-gray-800 rounded flex items-start justify-between">
                                        <div>
                                            <div className="font-medium">{event.actor1} vs {event.actor2}</div>
                                            <div className="text-sm text-gray-400">{event.event_description}</div>
                                            <div className="text-xs text-gray-500 mt-1">{event.location_name}</div>
                                        </div>
                                        <div className="text-red-400 font-mono font-bold">
                                            {event.goldstein.toFixed(1)}
                                        </div>
                                    </div>
                                ))}
                            </div>
                        ) : (
                            <div className="text-gray-500 text-center py-4">
                                No events returned from BigQuery
                            </div>
                        )}
                    </StepCard>

                </div>
            )}

            {/* Empty State */}
            {!pipeline && !error && !loading && (
                <div className="text-center py-12 text-gray-500">
                    Click "Fetch Pipeline Data" to inspect the GDELT pipeline
                </div>
            )}
        </div>
    );
}
