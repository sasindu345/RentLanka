'use client';

import { useEffect } from 'react';
import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

// Fix Leaflet icon resolution issues in Webpack/Next.js
const defaultIcon = L.icon({
  iconUrl: 'https://unpkg.com/leaflet@1.7.1/dist/images/marker-icon.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.7.1/dist/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
});

interface AdminMapProps {
  latitude: number;
  longitude: number;
  address?: string;
}

export default function AdminMap({ latitude, longitude, address }: AdminMapProps) {
  useEffect(() => {
    // Override default leaflet marker icon with working CDN assets
    L.Marker.prototype.options.icon = defaultIcon;
  }, []);

  // Safe fallback if coords are invalid
  const centerLat = latitude && !isNaN(latitude) ? latitude : 6.9271;
  const centerLng = longitude && !isNaN(longitude) ? longitude : 79.8612;

  return (
    <div style={{ height: '300px', width: '100%', borderRadius: '12px', overflow: 'hidden' }} className="border border-neutral-800">
      <MapContainer
        center={[centerLat, centerLng]}
        zoom={13}
        scrollWheelZoom={false}
        style={{ height: '100%', width: '100%', zIndex: 10 }}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        <Marker position={[centerLat, centerLng]}>
          <Popup>
            <div className="text-neutral-900 font-semibold p-1">
              {address || 'Equipment Pickup Location'}
              <div className="text-xs text-neutral-500 font-normal mt-1">
                Coordinates: {centerLat.toFixed(5)}, {centerLng.toFixed(5)}
              </div>
            </div>
          </Popup>
        </Marker>
      </MapContainer>
    </div>
  );
}
