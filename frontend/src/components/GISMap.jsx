import React, { useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup, Polygon } from 'react-leaflet';
import L from 'leaflet';
import { Video, AlertTriangle, ShieldCheck, PhoneCall, Radio, Eye } from 'lucide-react';
import { useWebSocket } from '../context/WebSocketContext';

// Custom Marker Icons generator
const createCustomIcon = (riskLevel, riskScore) => {
  let color = '#10b981';
  if (riskLevel === 'CRITICAL' || riskScore >= 65) color = '#ef4444';
  else if (riskLevel === 'ELEVATED' || riskScore >= 35) color = '#f59e0b';

  const html = `
    <div style="
      background-color: ${color};
      width: 32px;
      height: 32px;
      border-radius: 50%;
      border: 3px solid #0f172a;
      box-shadow: 0 0 15px ${color};
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
      font-weight: 800;
      font-size: 11px;
    ">
      ${Math.round(riskScore)}%
    </div>
  `;

  return L.divIcon({
    html: html,
    className: 'custom-leaflet-marker',
    iconSize: [32, 32],
    iconAnchor: [16, 16]
  });
};

export const GISMap = ({ onStartCall, onSelectCenter }) => {
  const { centers, triggerSampleAI } = useWebSocket();
  const [activeCenter, setActiveCenter] = useState(null);

  const getPolygonColor = (c) => {
    if (c.risk_level === 'CRITICAL' || c.risk_score >= 65) return '#ef4444';
    if (c.risk_level === 'ELEVATED' || c.risk_score >= 35) return '#f59e0b';
    return '#10b981';
  };

  return (
    <div className="glass-card p-4 relative" style={{ height: '620px', width: '100%' }}>
      <div className="flex items-center justify-between mb-3 px-2">
        <div className="flex items-center gap-3">
          <div className="p-2 rounded-lg bg-cyan-500/10 text-cyan-400 border border-cyan-500/20">
            <Radio className="w-5 h-5 animate-pulse" />
          </div>
          <div>
            <h2 className="text-lg font-bold text-slate-100">Live PostGIS Site Boundary GIS Map</h2>
            <p className="text-xs text-slate-400">Hardware-verified geofenced institutes with automated risk-based surveillance</p>
          </div>
        </div>

        <button 
          onClick={triggerSampleAI}
          className="flex items-center gap-2 bg-gradient-to-r from-cyan-600 to-blue-600 hover:from-cyan-500 hover:to-blue-500 text-white text-xs font-semibold px-4 py-2 rounded-lg transition-all shadow-lg shadow-cyan-500/20"
        >
          <Eye className="w-4 h-4" /> Trigger AI Sampling Frame
        </button>
      </div>

      <div style={{ height: '530px', borderRadius: '12px', overflow: 'hidden' }}>
        <MapContainer 
          center={[22.5, 78.9]} 
          zoom={5} 
          style={{ height: '100%', width: '100%' }}
        >
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>, &copy; <a href="https://carto.com/attributions">CARTO</a>'
            url="https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png?key=cb1_3jax_1_3c756737513244642051f009"
            subdomains="abcd"
            maxZoom={20}
          />

          {centers.map(center => {
            const polygonCoords = (center.boundary_geojson || []).map(pt => [pt[1], pt[0]]);
            const color = getPolygonColor(center);

            return (
              <React.Fragment key={center.id || center.code}>
                {polygonCoords.length > 0 && (
                  <Polygon 
                    positions={polygonCoords}
                    pathOptions={{
                      color: color,
                      fillColor: color,
                      fillOpacity: 0.25,
                      weight: 2,
                      dashArray: center.risk_level === 'CRITICAL' ? '5, 5' : '1'
                    }}
                  />
                )}

                <Marker 
                  position={[center.latitude, center.longitude]}
                  icon={createCustomIcon(center.risk_level, center.risk_score)}
                  eventHandlers={{
                    click: () => setActiveCenter(center)
                  }}
                >
                  <Popup>
                    <div className="p-1 max-w-xs text-slate-100">
                      <div className="flex items-center justify-between gap-2 border-b border-slate-700 pb-2 mb-2">
                        <span className="font-bold text-sm text-cyan-300">{center.name}</span>
                        <span className={`badge ${center.risk_score >= 65 ? 'badge-critical' : center.risk_score >= 35 ? 'badge-warning' : 'badge-normal'}`}>
                          {center.risk_level}
                        </span>
                      </div>

                      <div className="space-y-1 text-xs text-slate-300 mb-3">
                        <div className="flex justify-between">
                          <span className="text-slate-400">Center Code:</span>
                          <span className="font-mono text-slate-200">{center.code}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-slate-400">District:</span>
                          <span>{center.district}, {center.state}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-slate-400">CCTV Headcount:</span>
                          <span className="font-bold text-amber-400">{center.current_headcount} / {center.expected_capacity} present</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-slate-400">Risk Score:</span>
                          <span className="font-bold text-red-400">{center.risk_score}%</span>
                        </div>
                      </div>

                      <div className="grid grid-cols-2 gap-2 pt-1">
                        <button
                          onClick={() => onSelectCenter && onSelectCenter(center)}
                          className="flex items-center justify-center gap-1 bg-slate-700 hover:bg-slate-600 text-white text-xs py-1.5 px-2 rounded font-medium"
                        >
                          <Video className="w-3.5 h-3.5 text-cyan-400" /> CCTV View
                        </button>

                        <button
                          onClick={() => onStartCall && onStartCall(center)}
                          className="flex items-center justify-center gap-1 bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-500 hover:to-indigo-500 text-white text-xs py-1.5 px-2 rounded font-medium shadow-md shadow-purple-500/20"
                        >
                          <PhoneCall className="w-3.5 h-3.5 text-green-300" /> Spot Call
                        </button>
                      </div>
                    </div>
                  </Popup>
                </Marker>
              </React.Fragment>
            );
          })}
        </MapContainer>
      </div>
    </div>
  );
};
