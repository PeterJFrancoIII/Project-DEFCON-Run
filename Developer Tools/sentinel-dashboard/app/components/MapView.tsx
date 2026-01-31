"use client";

import { useEffect, useRef } from "react";
import L from "leaflet";

interface FlashEvent {
    id: string;
    lat: number;
    lon: number;
    location_name: string;
    goldstein: number;
    event_description: string;
    event_code: string;
    threat_zone: "RED" | "ORANGE" | "YELLOW" | "GRAY";
    actor1: string;
    actor2: string;
    source_url?: string;
}

interface MapViewProps {
    events: FlashEvent[];
}

// Marker colors based on threat zone
const getMarkerColor = (zone: string): string => {
    switch (zone) {
        case "RED": return "#dc2626";     // red-600
        case "ORANGE": return "#f97316";  // orange-500
        case "YELLOW": return "#eab308";  // yellow-500
        default: return "#6b7280";        // gray-500
    }
};

const getZoneEmoji = (zone: string): string => {
    switch (zone) {
        case "RED": return "🔴";
        case "ORANGE": return "🟠";
        case "YELLOW": return "🟡";
        default: return "⚪";
    }
};

const createCustomIcon = (zone: string) => {
    const color = getMarkerColor(zone);
    const emoji = getZoneEmoji(zone);
    return L.divIcon({
        className: "custom-marker",
        html: `
      <div style="
        width: 32px;
        height: 32px;
        background: ${color};
        border: 3px solid white;
        border-radius: 50%;
        box-shadow: 0 2px 8px rgba(0,0,0,0.4);
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 14px;
      ">${emoji}</div>
    `,
        iconSize: [32, 32],
        iconAnchor: [16, 16],
    });
};

export default function MapView({ events }: MapViewProps) {
    const mapRef = useRef<L.Map | null>(null);
    const markersRef = useRef<L.LayerGroup | null>(null);

    useEffect(() => {
        // Initialize map centered on Thailand/Cambodia border
        if (!mapRef.current) {
            mapRef.current = L.map("map", {
                center: [14.5, 103.0], // Approx border region
                zoom: 6,
            });

            // Dark tile layer
            L.tileLayer(
                "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png",
                {
                    attribution: '&copy; <a href="https://carto.com/">CARTO</a>',
                    maxZoom: 18,
                }
            ).addTo(mapRef.current);

            markersRef.current = L.layerGroup().addTo(mapRef.current);
        }

        // Clear existing markers
        if (markersRef.current) {
            markersRef.current.clearLayers();
        }

        // Add markers for each event
        events.forEach((event) => {
            if (event.lat && event.lon && markersRef.current) {
                const marker = L.marker([event.lat, event.lon], {
                    icon: createCustomIcon(event.threat_zone),
                });

                const zoneLabel = event.threat_zone === "RED" ? "ACTIVE COMBAT"
                    : event.threat_zone === "ORANGE" ? "IMMINENT THREAT"
                        : event.threat_zone === "YELLOW" ? "CIVIL UNREST"
                            : "OTHER";

                const borderColor = event.threat_zone === "RED" ? "#dc2626"
                    : event.threat_zone === "ORANGE" ? "#f97316"
                        : event.threat_zone === "YELLOW" ? "#eab308"
                            : "#6b7280";

                marker.bindPopup(`
          <div style="min-width: 240px; font-family: system-ui, sans-serif;">
            <div style="
              background: ${borderColor}; 
              color: white; 
              padding: 6px 10px; 
              margin: -10px -10px 10px -10px;
              font-weight: bold;
              font-size: 11px;
            ">
              ${getZoneEmoji(event.threat_zone)} ${zoneLabel}
            </div>
            <div style="font-weight: bold; font-size: 14px; margin-bottom: 6px;">
              ${event.location_name}
            </div>
            <div style="font-size: 12px; color: #333; margin-bottom: 4px;">
              <strong>Event:</strong> ${event.event_description}
            </div>
            <div style="font-size: 12px; color: #333; margin-bottom: 4px;">
              <strong>Actors:</strong> ${event.actor1}${event.actor2 && event.actor2 !== "Unknown" ? ` vs ${event.actor2}` : ""}
            </div>
            <div style="font-size: 12px; color: #333; margin-bottom: 8px;">
              <strong>Code:</strong> ${event.event_code} | <strong>Goldstein:</strong> ${event.goldstein?.toFixed(1)}
            </div>
            ${event.source_url ? `
              <a href="${event.source_url}" target="_blank" style="
                font-size: 11px; 
                color: #2563eb; 
                text-decoration: none;
              ">View Source Article →</a>
            ` : ""}
          </div>
        `);

                markersRef.current.addLayer(marker);
            }
        });

        // Cleanup
        return () => {
            // Don't destroy map on cleanup to prevent re-initialization issues
        };
    }, [events]);

    return <div id="map" className="h-full w-full rounded-lg" />;
}
