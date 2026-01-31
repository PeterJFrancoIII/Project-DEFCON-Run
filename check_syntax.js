        // --- HELPERS ---
        function formatTime(iso) {
            if (!iso) return 'N/A';
            const d = new Date(iso);
            const pad = (n) => n.toString().padStart(2, '0');
            return `${pad(d.getUTCMonth() + 1)}/${pad(d.getUTCDate())}/${d.getUTCFullYear()} ${pad(d.getUTCHours())}:${pad(d.getUTCMinutes())} UTC`;
        }

        function confirmSave() {
            return confirm("Are you sure you want to save these changes?");
        }

        // --- MAP ---
        let map, drawnItems;

        document.addEventListener('DOMContentLoaded', () => {
            initMap();
            loadZones();
            // Load other tabs data
            loadApprovals();
            loadAlerts();
            loadOSINT();
            loadPrompt();
            loadConfigAndContact();
            initThreatMap();
            // Lazy load jobs tab when clicked, or just init here if light
            const jobsTab = document.querySelector('button[data-bs-target="#jobs"]');
            jobsTab.addEventListener('shown.bs.tab', initJobsTab);
        });

        async function initJobsTab() {
            loadJobsAnalytics();
            loadJobsAccounts();
            loadJobsListings();
            loadPendingEmployers();
        }


        function initMap() {
            map = L.map('map').setView([13.7563, 100.5018], 10);
            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { attribution: 'Sentinel' }).addTo(map);
            drawnItems = new L.FeatureGroup();
            map.addLayer(drawnItems);
            const drawControl = new L.Control.Draw({
                edit: { featureGroup: drawnItems },
                draw: { polygon: false, marker: false, polyline: false, circlemarker: false, circle: true, rectangle: true }
            });
            map.addControl(drawControl);
            map.on(L.Draw.Event.CREATED, e => drawnItems.addLayer(e.layer));
        }

        async function loadZones() {
            const res = await fetch('/api/admin/zones');
            const data = await res.json();
            drawnItems.clearLayers();
            const list = document.getElementById('zone-list');
            list.innerHTML = '';
            (data.zones || []).forEach(z => {
                list.innerHTML += `<div class='border-bottom border-secondary mb-1 p-1'>${z.zone_name} <span class='badge bg-dark'>${z.shape_type}</span></div>`;
                let layer;
                if (z.shape_type === 'RECTANGLE') {
                    layer = L.rectangle([[z.bound_nw_lat, z.bound_nw_lng], [z.bound_se_lat, z.bound_se_lng]], { color: 'red' });
                } else if (z.shape_type === 'CIRCLE') {
                    layer = L.circle([z.lat_center, z.lng_center], { radius: z.radius_km * 1000, color: 'red' });
                }
                if (layer) {
                    layer.bindPopup(`<b>${z.zone_name}</b>`);
                    layer.sentinelData = z;
                    drawnItems.addLayer(layer);
                }
            });
        }

        async function saveZones() {
            if (!confirmSave()) return;
            const zones = [];
            drawnItems.eachLayer(l => {
                const z = l.sentinelData || { zone_name: "New Zone", risk_level: "HIGH" };
                if (l instanceof L.Rectangle) {
                    z.shape_type = 'RECTANGLE';
                    z.bound_nw_lat = l.getBounds().getNorthWest().lat;
                    z.bound_nw_lng = l.getBounds().getNorthWest().lng;
                    z.bound_se_lat = l.getBounds().getSouthEast().lat;
                    z.bound_se_lng = l.getBounds().getSouthEast().lng;
                } else if (l instanceof L.Circle) {
                    z.shape_type = 'CIRCLE';
                    z.lat_center = l.getLatLng().lat;
                    z.lng_center = l.getLatLng().lng;
                    z.radius_km = l.getRadius() / 1000;
                }
                zones.push(z);
            });
            await fetch('/api/admin/zones/save', { method: 'POST', body: JSON.stringify({ zones }) });
            alert('Zones Saved.');
        }

        // --- INTEL ---
        async function loadPrompt() {
            const d = await (await fetch('/api/admin/prompt')).json();
            document.getElementById('prompt-editor').value = d.content;
        }
        async function savePrompt() {
            if (!confirmSave()) return;
            await fetch('/api/admin/prompt/save', { method: 'POST', body: JSON.stringify({ content: document.getElementById('prompt-editor').value }) });
            alert('Prompt Updated.');
        }

        // --- OSINT ---
        async function loadOSINT() {
            const d = await (await fetch('/api/admin/osint')).json();
            // Display as JSON for editing
            document.getElementById('osint-editor').value = JSON.stringify(d.sources, null, 4);
        }
        async function saveOSINT() {
            if (!confirmSave()) return;
            try {
                const sources = JSON.parse(document.getElementById('osint-editor').value);
                await fetch('/api/admin/osint/save', { method: 'POST', body: JSON.stringify({ sources }) });
                alert('OSINT Sources Saved.');
            } catch (e) {
                alert("Invalid JSON Format");
            }
        }

        async function searchZips() {
            const q = document.getElementById('zip-search').value;
            const d = await (await fetch(`/api/admin/zips/search?q=${q}`)).json();
            document.getElementById('zip-results').innerHTML = d.results.map(r => `<li class="list-group-item bg-dark text-light">${r.POSTAL_CODE} - ${r.DISTRICT_ENGLISH}</li>`).join('');
        }

        // --- OPS ---
        async function loadApprovals() {
            const d = await (await fetch('/api/admin/approvals')).json();
            const t = document.getElementById('approvals-table');
            if (!d.pending.length) { t.innerHTML = '<tr><td colspan="4" class="text-center text-muted">No pending alerts.</td></tr>'; return; }
            t.innerHTML = d.pending.map(doc => `
            <tr>
                <td>${doc.zip_code}</td>
                <td>${doc.languages?.en?.location_name || 'Unknown'}</td>
                <td><small>${doc.languages?.en?.summary?.[0]}</small></td>
                <td>
                    <button class="btn btn-sm btn-success" onclick="decide('${doc.zip_code}', 'APPROVE')">Approve</button>
                    <button class="btn btn-sm btn-danger" onclick="decide('${doc.zip_code}', 'REJECT')">Reject</button>
                </td>
            </tr>
        `).join('');
        }
        async function decide(zip, action) {
            // No confirm for quick OPS action? User said "anytime you click update...". 
            // Approval is an action but technically an update. Let's ask.
            if (!confirm(`Are you sure you want to ${action} ${zip}?`)) return;

            await fetch('/api/admin/approvals/decide', { method: 'POST', body: JSON.stringify({ zip_code: zip, action }) });
            loadApprovals();
        }
        async function loadAlerts() {
            const d = await (await fetch('/api/admin/alerts')).json();
            // Use formatTime()
            document.getElementById('alerts-table').innerHTML = d.alerts.map(a => `<tr><td>${a.zip_code}</td><td>${a.languages.en.defcon_status}</td><td>${formatTime(a.languages.en.last_updated)}</td></tr>`).join('');
        }

        // --- CONFIG ---
        async function loadConfigAndContact() {
            const c = await (await fetch('/api/admin/contact')).json();
            document.getElementById('contact-editor').value = JSON.stringify(c, null, 4);
            const a = await (await fetch('/api/admin/api_config')).json();
            document.getElementById('api-config-editor').value = a.content;
            const s = await (await fetch('/api/admin/config')).json();
            document.getElementById('system-config-editor').value = JSON.stringify(s, null, 4);
        }
        async function saveSystemConfig() {
            if (!confirmSave()) return;
            await fetch('/api/admin/config/save', { method: 'POST', body: document.getElementById('system-config-editor').value });
            alert('System Config Saved.');
        }
        async function saveContact() {
            if (!confirmSave()) return;
            await fetch('/api/admin/contact/save', { method: 'POST', body: document.getElementById('contact-editor').value });
            alert('Contact Info Saved.');
        }
        async function saveApiConfig() {
            if (!confirmSave()) return;
            await fetch('/api/admin/config/save', { method: 'POST', body: JSON.stringify({ content: document.getElementById('api-config-editor').value }) });
            alert('API Config Saved.');
        }
        async function uploadLogo() {
            // Confirm upload too?
            if (!confirmSave()) return;
            const fd = new FormData();
            fd.append('logo', document.getElementById('logo-input').files[0]);
            await fetch('/api/admin/logo/upload', { method: 'POST', body: fd });
            alert('Logo Uploaded.');
            alert('Logo Uploaded.');
        }

        // --- JOBS MANAGEMENT ---
        async function loadJobsAnalytics() {
            try {
                // UPDATE: Use V2 Analytics
                const res = await fetch('/api/jobs_v2/admin/analytics?secret=sentinel-admin-v2');
                const data = await res.json();
                if (data.analytics) {
                    const stats = data.analytics;
                    // Map V2 stats to UI
                    document.getElementById('stat-jobs-total').innerText = stats.listings.total;
                    document.getElementById('stat-jobs-active').innerText = stats.listings.active;
                    document.getElementById('stat-jobs-filled').innerText = stats.listings.filled;

                    document.getElementById('stat-users-total').innerText = stats.accounts.total;
                    document.getElementById('stat-employers').innerText = stats.accounts.employers;
                    document.getElementById('stat-workers').innerText = stats.accounts.workers;
                }
            } catch (e) { console.error("Analytics Error", e); }
        }

        async function loadJobsAccounts() {
            try {
                // Using shared secret for MVP auth bypass in this bespoke view
                const res = await fetch('/api/jobs/admin/accounts?secret=admin123');
                const data = await res.json();
                const t = document.getElementById('jobs-accounts-table');

                if (!data.accounts || !data.accounts.length) {
                    t.innerHTML = '<tr><td colspan="7" class="text-center text-muted">No accounts found.</td></tr>';
                    return;
                }

                t.innerHTML = data.accounts.map(acc => {
                    const validityColor = acc.validity_score > 80 ? 'text-success' : (acc.validity_score > 50 ? 'text-warning' : 'text-danger');
                    const statusBadge = acc.status === 'banned' ? 'bg-danger' : (acc.status === 'suspended' ? 'bg-warning' : 'bg-success');

                    return `
                    <tr>
                        <td>${acc.email}</td>
                        <td>${acc.role}</td>
                        <td><span class="badge ${statusBadge}">${acc.status}</span></td>
                        <td>${acc.trust_score || 0}</td>
                        <td>${acc.report_strikes || 0}</td>
                        <td class="${validityColor} fw-bold">${acc.validity_score}%</td>
                        <td>
                            <div class="btn-group btn-group-sm">
                                <button class="btn btn-outline-warning" onclick="jobsAction('${acc.account_id}', 'SUSPEND')">Suspend</button>
                                <button class="btn btn-outline-danger" onclick="jobsAction('${acc.account_id}', 'BAN')">Ban</button>
                                <button class="btn btn-outline-primary" onclick="jobsAction('${acc.account_id}', 'REINSTATE')">Reinstate</button>
                            </div>
                        </td>
                    </tr>
                    `;
                }).join('');
            } catch (e) {
                console.error("Jobs Load Error", e);
                document.getElementById('jobs-accounts-table').innerHTML = '<tr><td colspan="7" class="text-danger">Error loading data.</td></tr>';
            }
        }

        async function jobsAction(id, action) {
            if (!confirm(`Apply ${action} to this account?`)) return;

            let duration = null;
            if (action === 'SUSPEND') {
                const d = prompt("Enter suspension duration in days:", "7");
                if (!d) return;
                duration = parseInt(d);
            }

            try {
                await fetch('/api/jobs/admin/accounts/action', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        secret: 'admin123',
                        account_id: id,
                        action: action,
                        duration_days: duration
                    })
                });
                loadJobsAccounts();
            } catch (e) {
                alert("Action failed: " + e);
            }
        }

        async function loadJobsListings() {
            try {
                async function loadJobsListings() {
                    try {
                        // UPDATE: Use V2
                        const res = await fetch('/api/jobs_v2/admin/listings?secret=sentinel-admin-v2');
                        const data = await res.json();
                        const t = document.getElementById('jobs-listings-table');

                        if (!data.listings || !data.listings.length) {
                            t.innerHTML = '<tr><td colspan="7" class="text-center text-muted">No listings found.</td></tr>';
                            return;
                        }

                        t.innerHTML = data.listings.map(job => {
                            const statusColor = job.status === 'active' ? 'text-success' : (job.status === 'suspended' ? 'text-warning' : 'text-muted');
                            const isSuspended = job.status === 'suspended';
                            const isRemoved = job.status === 'removed';

                            return `
                    <tr>
                        <td>${formatTime(job.created_at)}</td>
                        <td class="fw-bold text-white">${job.category}</td>
                        <td><small>${job.employer_id}</small></td>
                        <td>${job.pay_type}</td>
                        <td class="${statusColor}">${job.status.toUpperCase()}</td>
                        <td>${job.applicant_count || 0}</td>
                        <td>
                             ${!isSuspended && !isRemoved ? `<button class="btn btn-sm btn-outline-warning" onclick="jobsListingAction('${job.job_id}', 'SUSPEND')">Suspend</button>` : ''}
                             ${isSuspended ? `<button class="btn btn-sm btn-outline-success" onclick="jobsListingAction('${job.job_id}', 'REINSTATE')">Reinstate</button>` : ''}
                             ${!isRemoved ? `<button class="btn btn-sm btn-outline-danger" onclick="jobsListingAction('${job.job_id}', 'DELETE')">Delete</button>` : ''}
                        </td>
                    </tr>
                    `;
                        }).join('');
                    } catch (e) {
                        console.error("Listings Error", e);
                        t.innerHTML = '<tr><td colspan="7" class="text-danger">Error loading listings.</td></tr>';
                    }
                }

                async function jobsListingAction(id, action) {
                    if (!confirm(`${action} this listing?`)) return;
                    try {
                        await fetch('/api/jobs_v2/admin/listings/action?secret=sentinel-admin-v2', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({
                                job_id: id,
                                action: action
                            })
                        });
                        loadJobsListings();
                        loadJobsAnalytics(); // Refresh stats
                    } catch (e) { alert("Failed: " + e); }
                }

                async function loadPendingEmployers() {
                    try {
                        const res = await fetch('/api/jobs_v2/admin/employers/pending?secret=sentinel-admin-v2');
                        const data = await res.json();
                        const t = document.getElementById('jobs-verification-table');

                        if (!data.employers || !data.employers.length) {
                            t.innerHTML = '<tr><td colspan="5" class="text-center text-muted">No pending verifications.</td></tr>';
                            return;
                        }

                        t.innerHTML = data.employers.map(emp => `
                <tr>
                    <td>${emp.email}</td>
                    <td class="fw-bold text-white">${emp.real_name_last}, ${emp.real_name_first}</td>
                    <td>${emp.phone}</td>
                    <td>${formatTime(emp.created_at)}</td>
                    <td>
                        <button class="btn btn-sm btn-success" onclick="verifyEmployer('${emp.account_id}', 'approve')"><i class="bi bi-check-lg"></i> Approve</button>
                        <button class="btn btn-sm btn-danger margin-left-2" onclick="verifyEmployer('${emp.account_id}', 'reject')"><i class="bi bi-x-lg"></i> Reject</button>
                    </td>
                </tr>
                `).join('');
                    } catch (e) {
                        console.error("Verification Load Error", e);
                        document.getElementById('jobs-verification-table').innerHTML = '<tr><td colspan="5" class="text-danger">Error loading queue.</td></tr>';
                    }
                }

                async function verifyEmployer(id, action) {
                    if (!confirm(`Are you sure you want to ${action.toUpperCase()} this employer?`)) return;

                    try {
                        const res = await fetch('/api/jobs_v2/admin/employers/verify?secret=sentinel-admin-v2', {
                            method: 'POST',
                            body: JSON.stringify({ account_id: id, action: action })
                        });
                        const data = await res.json();

                        if (data.status === 'success') {
                            // alert(`Employer ${action}d successfully.`);
                            loadPendingEmployers();
                            loadJobsAccounts(); // Refresh accounts list too
                        } else {
                            alert("Error: " + (data.error || "Unknown error"));
                        }
                    } catch (e) {
                        alert("Connection failed: " + e);
                    }
                }

                // --- LIVE THREAT MAP ---

                async function initThreatMap() {
                    // Delay slightly to ensure tab render
                    const threatMap = L.map('threat-map').setView([13.5, 102.0], 8);
                    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                        attribution: 'Sentinel Kinetic',
                        className: 'map-tiles'
                    }).addTo(threatMap);

                    // Fix tile loading on tab switch
                    const tabEl = document.querySelector('button[data-bs-target="#live-threats"]');
                    tabEl.addEventListener('shown.bs.tab', function (event) {
                        threatMap.invalidateSize();
                    });

                    // Fetch Data
                    try {
                        const res = await fetch('/api/admin/threats');
                        const data = await res.json();

                        (data.threats || []).forEach(t => {
                            const circle = L.circle([t.lat, t.lon], {
                                color: 'red',
                                fillColor: '#f03',
                                fillOpacity: 0.5,
                                radius: t.radius || 10000
                            }).addTo(threatMap);

                            circle.bindPopup(`
                        <strong style="color:red">${t.name}</strong><br>
                        Radius: ${t.radius}m<br>
                        Last Event: ${t.last_kinetic || 'Unknown'}
                    `);
                        });
                    } catch (e) { console.error("Threat Map Error", e); }
                }

