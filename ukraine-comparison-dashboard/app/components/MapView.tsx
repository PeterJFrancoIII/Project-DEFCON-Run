"use client";

import { useEffect } from "react";
import { MapContainer, TileLayer, Marker, Popup, useMap } from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";

interface GdeltEvent {
    _id: string;
    id: string;
    location_name: string;
    lat: number;
    lon: number;
    event_description: string;
    threat_zone: "RED" | "ORANGE" | "YELLOW" | "GRAY";
    goldstein: number;
    actor1?: string;
    actor2?: string;
}

interface MapViewProps {
    gdeltEvents: GdeltEvent[];
}

// Fix Leaflet default icons
const fixLeafletIcons = () => {
    // @ts-expect-error - Leaflet typing issue
    delete L.Icon.Default.prototype._getIconUrl;
    L.Icon.Default.mergeOptions({
        iconRetinaUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png",
        iconUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png",
        shadowUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png",
    });
};

// Custom marker icons by threat zone
const createIcon = (color: string) => {
    return L.divIcon({
        className: "custom-marker",
        html: `<div style="
      width: 16px;
      height: 16px;
      background: ${color};
      border: 2px solid white;
      border-radius: 50%;
      box-shadow: 0 2px 4px rgba(0,0,0,0.3);
    "></div>`,
        iconSize: [16, 16],
        iconAnchor: [8, 8],
        popupAnchor: [0, -8],
    });
};

const threatIcons = {
    RED: createIcon("#dc2626"),
    ORANGE: createIcon("#ea580c"),
    YELLOW: createIcon("#eab308"),
    GRAY: createIcon("#6b7280"),
};

// Component to auto-fit bounds when events change
function FitBounds({ events }: { events: GdeltEvent[] }) {
    const map = useMap();

    useEffect(() => {
        if (events.length > 0) {
            const validEvents = events.filter(e => e.lat && e.lon);
            if (validEvents.length > 0) {
                const bounds = L.latLngBounds(validEvents.map(e => [e.lat, e.lon]));
                map.fitBounds(bounds, { padding: [50, 50] });
            }
        }
    }, [events, map]);

    return null;
}

export default function MapView({ gdeltEvents }: MapViewProps) {
    useEffect(() => {
        fixLeafletIcons();
    }, []);

    // Center on Ukraine (roughly Donetsk area)
    const ukraineCenter: [number, number] = [48.5, 36.5];

    // Filter events with valid coordinates
    const validEvents = gdeltEvents.filter(e => e.lat && e.lon);

    return (
        <MapContainer
            center={ukraineCenter}
            zoom={6}
            style={{ height: "100%", width: "100%" }}
            scrollWheelZoom={true}
        >
            <TileLayer
                attribution='&copy; <a href="https://carto.com/">CARTO</a>'
                url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
            />

            <FitBounds events={validEvents} />

            {validEvents.map((event) => (
                <Marker
                    key={event._id}
                    position={[event.lat, event.lon]}
                    icon={threatIcons[event.threat_zone] || threatIcons.GRAY}
                >
                    <Popup>
                        <div className="text-sm">
                            <div className="font-bold mb-1">{event.location_name}</div>
                            <div className="text-gray-600 text-xs mb-1">{event.event_description}</div>
                            {event.actor1 && (
                                <div className="text-xs">
                                    {event.actor1} {event.actor2 && event.actor2 !== "Unknown" ? `vs ${event.actor2}` : ""}
                                </div>
                            )}
                            <div className="text-xs mt-1">
                                <span className={`inline-block px-1 py-0.5 rounded text-white text-[10px] ${event.threat_zone === "RED" ? "bg-red-600" :
                                        event.threat_zone === "ORANGE" ? "bg-orange-600" :
                                            event.threat_zone === "YELLOW" ? "bg-yellow-600" : "bg-gray-600"
                                    }`}>
                                    {event.threat_zone}
                                </span>
                                <span className="ml-2 font-mono">Goldstein: {event.goldstein?.toFixed(1)}</span>
                            </div>
                        </div>
                    </Popup>
                </Marker>
            ))}
        </MapContainer>
    );
}
