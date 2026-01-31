// Next.js API Route: Proxy to Django Backend for Atlas G3 Pipeline
// This calls the Django backend which runs the actual pipeline

export async function GET(request) {
    // Try local Django server first, then VPS
    const servers = [
        'http://localhost:8000',
        'http://10.0.2.2:8000',
        'http://146.190.7.51'
    ];

    let lastError = null;

    for (const baseUrl of servers) {
        try {
            // We need a debug endpoint on Django that returns packet details
            // For now, we'll use a custom endpoint we'll create
            const response = await fetch(`${baseUrl}/api/debug/pipeline`, {
                method: 'GET',
                headers: { 'Content-Type': 'application/json' },
                // Short timeout to fail fast on unreachable servers
                signal: AbortSignal.timeout(5000)
            });

            if (response.ok) {
                const data = await response.json();
                return Response.json(data);
            }
        } catch (err) {
            lastError = err;
            continue;
        }
    }

    // If all servers fail, return mock data for UI testing
    return Response.json({
        status: 'mock',
        message: 'Django backend not reachable. Showing mock data.',
        total_processed: 5,
        total_clean: 2,
        packets: [
            {
                title: '[MOCK] Thailand-Cambodia border tensions rise',
                content_hash: 'abc12345',
                status: 'CLEAN',
                validity_score: 78,
                risk_domain: 'KINETIC',
                target_region: 'SE_ASIA',
                gate_history: ['GATE1_PASS', 'GATE2_BASE_SCORE:78', 'GATE2_BASE_ADMIT']
            },
            {
                title: '[MOCK] Artillery fire reported near Preah Vihear',
                content_hash: 'def67890',
                status: 'CLEAN',
                validity_score: 85,
                risk_domain: 'KINETIC',
                target_region: 'SE_ASIA',
                gate_history: ['GATE1_PASS', 'GATE2_BASE_SCORE:85', 'GATE2_BASE_ADMIT']
            },
            {
                title: '[MOCK] Border patrol increased - routine',
                content_hash: 'ghi11111',
                status: 'PENDING_REINFORCED',
                validity_score: 45,
                risk_domain: 'POLITICAL',
                target_region: 'SE_ASIA',
                gate_history: ['GATE1_PASS', 'GATE2_BASE_SCORE:45', 'GATE2_BASE_MAYBE']
            },
            {
                title: '[MOCK] Gaming news about explosions',
                content_hash: 'jkl22222',
                status: 'DROP',
                validity_score: 12,
                risk_domain: 'NOISE',
                target_region: 'UNKNOWN',
                gate_history: ['GATE1_PASS', 'GATE2_BASE_SCORE:12', 'GATE2_BASE_DROP']
            },
            {
                title: '[MOCK] Duplicate article - already seen',
                content_hash: 'mno33333',
                status: 'DROP',
                validity_score: 0,
                risk_domain: 'UNCLASSIFIED',
                target_region: 'UNKNOWN',
                gate_history: ['GATE1_DROP_DUPLICATE']
            }
        ]
    });
}
