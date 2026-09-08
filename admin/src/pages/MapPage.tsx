import { useQuery } from '@tanstack/react-query';
import { MapContainer, Marker, Popup, TileLayer } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { listTechnicianLocations } from '../api/technicians';
import { errorMessage } from '../api/client';
import { fmtRelative } from '../lib/format';

// Phnom Penh centre — matches the Flutter app's default map centre.
const CENTER: [number, number] = [11.5564, 104.9282];

function pin(available: boolean) {
  const color = available ? '#1f9d55' : '#8a93a6';
  return L.divIcon({
    className: 'tech-pin',
    html: `<span style="display:block;width:18px;height:18px;border-radius:50%;background:${color};border:3px solid #fff;box-shadow:0 1px 4px rgba(0,0,0,0.4)"></span>`,
    iconSize: [18, 18],
    iconAnchor: [9, 9],
  });
}

export function MapPage() {
  const { data, error, isLoading, dataUpdatedAt } = useQuery({
    queryKey: ['technician-locations'],
    queryFn: listTechnicianLocations,
    refetchInterval: 15_000,
  });

  return (
    <>
      <div className="page-head">
        <h1>Live map</h1>
        <span className="muted">
          {isLoading
            ? 'Loading…'
            : `${data?.length ?? 0} technician(s) · updated ${fmtRelative(
                new Date(dataUpdatedAt).toISOString(),
              )}`}
        </span>
      </div>

      {error && <p className="error-text">{errorMessage(error)}</p>}

      <div className="card map-shell">
        <MapContainer center={CENTER} zoom={13} scrollWheelZoom>
          <TileLayer
            attribution='&copy; OpenStreetMap contributors'
            url="https://tile.openstreetmap.org/{z}/{x}/{y}.png"
          />
          {data?.map((t) => (
            <Marker key={t.id} position={[t.lat, t.lng]} icon={pin(t.available)}>
              <Popup>
                <strong>{t.name}</strong>
                <br />
                {t.category}
                <br />
                {t.available ? 'Available' : 'Unavailable'}
                <br />
                <span style={{ color: '#5a6478' }}>
                  Reported {fmtRelative(t.lastLocationAt)}
                </span>
              </Popup>
            </Marker>
          ))}
        </MapContainer>
      </div>
      {data && data.length === 0 && (
        <p className="muted" style={{ marginTop: 12 }}>
          No active technician has reported a location yet. Positions arrive via{' '}
          <code>PATCH /api/technicians/&#123;id&#125;/location</code>.
        </p>
      )}
    </>
  );
}
