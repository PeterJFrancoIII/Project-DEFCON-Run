'use client';

import { useState } from 'react';

export default function DebugDashboard() {
  const [status, setStatus] = useState('idle');
  const [results, setResults] = useState(null);
  const [error, setError] = useState(null);

  const runPipeline = async () => {
    setStatus('running');
    setError(null);
    setResults(null);

    try {
      const res = await fetch('/api/pipeline');
      const data = await res.json();

      if (data.error) {
        setError(data.error);
        setStatus('error');
      } else {
        setResults(data);
        setStatus('done');
      }
    } catch (err) {
      setError(err.message);
      setStatus('error');
    }
  };

  const getStatusText = () => {
    switch (status) {
      case 'running': return 'Pipeline Running...';
      case 'done': return 'Pipeline Complete';
      case 'error': return 'Error Occurred';
      default: return 'Ready';
    }
  };

  const gate1Packets = results?.packets?.filter(p =>
    p.gate_history?.includes('GATE1_PASS')
  ) || [];

  const gate2BasePackets = results?.packets?.filter(p =>
    p.gate_history?.some(h => h.startsWith('GATE2_BASE'))
  ) || [];

  const cleanPackets = results?.packets?.filter(p =>
    p.status === 'CLEAN'
  ) || [];

  return (
    <div className="container">
      <h1>Atlas G³ Debug Dashboard</h1>
      <p className="subtitle">Real-time pipeline visualization for OSINT ingestion</p>

      <div className="controls">
        <button onClick={runPipeline} disabled={status === 'running'}>
          {status === 'running' ? '⏳ Running...' : '▶ Run Pipeline'}
        </button>
      </div>

      <div className="status-bar">
        <div className={`status-indicator ${status}`}></div>
        <span>{getStatusText()}</span>
        {results && (
          <span style={{ marginLeft: 'auto', color: 'var(--text-secondary)' }}>
            Processed: {results.total_processed} | Clean: {results.total_clean}
          </span>
        )}
      </div>

      {error && (
        <div style={{
          background: 'rgba(255,68,102,0.1)',
          border: '1px solid var(--accent-red)',
          borderRadius: '8px',
          padding: '1rem',
          marginBottom: '2rem',
          color: 'var(--accent-red)'
        }}>
          {error}
        </div>
      )}

      <div className="pipeline-view">
        {/* Gate 1 */}
        <div className="gate-card">
          <div className="gate-header">
            <span className="gate-title">GATE 1: INGEST</span>
            <span className="gate-count">{gate1Packets.length} items</span>
          </div>
          <div className="packet-list">
            {gate1Packets.length === 0 ? (
              <div className="empty-state">No packets yet</div>
            ) : (
              gate1Packets.map((p, i) => (
                <div key={i} className={`packet-item ${p.status?.toLowerCase()}`}>
                  <div className="packet-title">{p.title}</div>
                  <div className="packet-meta">Hash: {p.content_hash?.slice(0, 8)}</div>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Gate 2 Base */}
        <div className="gate-card">
          <div className="gate-header">
            <span className="gate-title">GATE 2: CLASSIFY</span>
            <span className="gate-count">{gate2BasePackets.length} scored</span>
          </div>
          <div className="packet-list">
            {gate2BasePackets.length === 0 ? (
              <div className="empty-state">No packets yet</div>
            ) : (
              gate2BasePackets.map((p, i) => (
                <div key={i} className={`packet-item ${p.status?.toLowerCase()}`}>
                  <div className="packet-title">{p.title}</div>
                  <div className="packet-meta">
                    Score: {p.validity_score} | Domain: {p.risk_domain}
                  </div>
                  <div>
                    {p.gate_history?.map((h, j) => (
                      <span key={j} className="history-tag">{h}</span>
                    ))}
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Clean Output */}
        <div className="gate-card">
          <div className="gate-header">
            <span className="gate-title" style={{ color: 'var(--accent-green)' }}>
              CLEAN OUTPUT
            </span>
            <span className="gate-count">{cleanPackets.length} verified</span>
          </div>
          <div className="packet-list">
            {cleanPackets.length === 0 ? (
              <div className="empty-state">No clean packets</div>
            ) : (
              cleanPackets.map((p, i) => (
                <div key={i} className="packet-item clean">
                  <div className="packet-title">{p.title}</div>
                  <div className="packet-meta">
                    Score: {p.validity_score} | Region: {p.target_region}
                  </div>
                  <div>
                    {p.gate_history?.map((h, j) => (
                      <span key={j} className="history-tag">{h}</span>
                    ))}
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      </div>

      {results && (
        <div className="results-section">
          <div className="results-header">📄 Raw Pipeline Output</div>
          <pre>{JSON.stringify(results, null, 2)}</pre>
        </div>
      )}
    </div>
  );
}
