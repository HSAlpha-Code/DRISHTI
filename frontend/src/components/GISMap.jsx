import React, { useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup, Polygon } from 'react-leaflet';
import L from 'leaflet';
import { Video, PhoneCall, Radio, Eye, Building2, ShieldAlert, CheckCircle2, MapPin, Layers } from 'lucide-react';
import { useWebSocket } from '../context/WebSocketContext';

// Custom Marker Icons generator for regional compliance
const createCustomIcon = (riskLevel, riskScore) => {
  let color = '#10b981'; // Green
  if (riskLevel === 'CRITICAL' || riskScore >= 65) color = '#ef4444'; // Red
  else if (riskLevel === 'ELEVATED' || riskScore >= 35) color = '#f59e0b'; // Amber

  const html = `
    <div style="
      background-color: ${color};
      width: 32px;
      height: 32px;
      border-radius: 50%;
      border: 3px solid #0f1a30;
      box-shadow: 0 0 12px ${color};
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
      font-weight: 800;
      font-size: 11px;
      font-family: 'Inter', sans-serif;
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

  const totalCapacity = centers.reduce((acc, c) => acc + (c.expected_capacity || 0), 0);
  const totalHeadcount = centers.reduce((acc, c) => acc + (c.current_headcount || 0), 0);
  const criticalCount = centers.filter(c => c.risk_level === 'CRITICAL' || c.risk_score >= 65).length;

  return (
    <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
      
      {/* Left Column: Square-Format GIS Map Container (1:1 Aspect Ratio) */}
      <div className="lg:col-span-7 glass-card p-5 space-y-4">
        
        {/* Header Title */}
        <div className="flex items-center justify-between border-b border-slate-800 pb-3">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-blue-950 text-blue-400 border border-blue-800/60">
              <Layers className="w-5 h-5 text-blue-400" />
            </div>
            <div>
              <h2 className="text-base font-bold text-slate-100 flex items-center gap-2">
                PostGIS Spatial GIS Map <span className="text-[10px] bg-blue-950 text-blue-300 font-mono border border-blue-800 px-2 py-0.5 rounded">Square 1:1 Format</span>
              </h2>
              <p className="text-xs text-slate-400">Hardware-verified geofenced site boundaries (Delhi NCR, Uttar Pradesh, Haryana, Maharashtra, Karnataka)</p>
            </div>
          </div>

          <button 
            onClick={triggerSampleAI}
            className="flex items-center gap-2 bg-blue-700 hover:bg-blue-600 text-white text-xs font-bold px-3.5 py-2 rounded-lg transition-all shadow-md shadow-blue-900/30"
          >
            <Eye className="w-3.5 h-3.5" /> Sample Frames
          </button>
        </div>

        {/* Square GIS Map Viewport (Equal 1:1 Aspect Ratio Height & Width) */}
        <div className="gis-square-map-container mx-auto border border-slate-700/80 shadow-2xl">
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
                          <span className="font-bold text-xs text-blue-300">{center.name}</span>
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
                            <span className="text-slate-400">Region:</span>
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
                            className="flex items-center justify-center gap-1 bg-slate-800 hover:bg-slate-700 text-white text-xs py-1.5 px-2 rounded font-semibold"
                          >
                            <Video className="w-3.5 h-3.5 text-blue-400" /> CCTV View
                          </button>

                          <button
                            onClick={() => onStartCall && onStartCall(center)}
                            className="flex items-center justify-center gap-1 bg-blue-700 hover:bg-blue-600 text-white text-xs py-1.5 px-2 rounded font-semibold shadow"
                          >
                            <PhoneCall className="w-3.5 h-3.5 text-emerald-300" /> Spot Call
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

        {/* Legend */}
        <div className="flex items-center justify-between text-xs text-slate-400 pt-2 border-t border-slate-800/80 px-1">
          <div className="flex items-center gap-4">
            <span className="flex items-center gap-1.5"><span className="w-2.5 h-2.5 rounded-full bg-emerald-500"></span> Normal (&lt;35%)</span>
            <span className="flex items-center gap-1.5"><span className="w-2.5 h-2.5 rounded-full bg-amber-500"></span> Elevated (35-64%)</span>
            <span className="flex items-center gap-1.5"><span className="w-2.5 h-2.5 rounded-full bg-red-500 animate-pulse"></span> Critical Dispatch (&gt;65%)</span>
          </div>
          <span className="font-mono text-[11px] text-slate-500">CARTO Voyager Tiles</span>
        </div>
      </div>

      {/* Right Column: Institutional Directory & Regional Metrics Panel */}
      <div className="lg:col-span-5 space-y-5">
        
        {/* Summary Stat Cards */}
        <div className="grid grid-cols-2 gap-4">
          <div className="glass-card p-4 space-y-1">
            <span className="text-xs text-slate-400 block font-semibold uppercase tracking-wider">Monitored Turnout</span>
            <div className="flex items-baseline gap-2">
              <span className="text-2xl font-bold font-mono text-emerald-400">{totalHeadcount}</span>
              <span className="text-xs text-slate-400">/ {totalCapacity} expected</span>
            </div>
            <div className="text-[11px] text-slate-500">Cross-checked via OpenCV YOLO11</div>
          </div>

          <div className="glass-card p-4 space-y-1">
            <span className="text-xs text-slate-400 block font-semibold uppercase tracking-wider">Active Dispatches</span>
            <div className="flex items-baseline gap-2">
              <span className="text-2xl font-bold font-mono text-red-400">{criticalCount}</span>
              <span className="text-xs text-slate-400">Critical center(s)</span>
            </div>
            <div className="text-[11px] text-red-400/80 font-semibold">Unannounced squad active</div>
          </div>
        </div>

        {/* Regional Institute Directory List */}
        <div className="glass-card p-5 space-y-4">
          <div className="flex items-center justify-between border-b border-slate-800 pb-3">
            <h3 className="text-sm font-bold text-slate-100 flex items-center gap-2">
              <Building2 className="w-4 h-4 text-blue-400" /> Monitored Institute Directory
            </h3>
            <span className="text-xs text-slate-400 font-mono">{centers.length} Regional Centers</span>
          </div>

          <div className="space-y-3 max-h-[380px] overflow-y-auto pr-1">
            {centers.map(c => (
              <div 
                key={c.id || c.code}
                onClick={() => onSelectCenter && onSelectCenter(c)}
                className={`p-3.5 rounded-lg border transition cursor-pointer ${
                  c.risk_level === 'CRITICAL' ? 'bg-red-950/20 border-red-800/60 hover:border-red-600' : 'bg-slate-900/60 border-slate-800 hover:border-slate-700'
                }`}
              >
                <div className="flex items-start justify-between">
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="font-mono text-xs font-bold text-blue-400">{c.code}</span>
                      <span className="text-xs text-slate-400">&bull; {c.district}, {c.state}</span>
                    </div>
                    <h4 className="text-xs font-bold text-slate-100 mt-0.5">{c.name}</h4>
                  </div>

                  <span className={`badge ${c.risk_score >= 65 ? 'badge-critical' : c.risk_score >= 35 ? 'badge-warning' : 'badge-normal'}`}>
                    {c.risk_score}%
                  </span>
                </div>

                <div className="flex items-center justify-between mt-2 pt-2 border-t border-slate-800/60 text-[11px]">
                  <span className="text-slate-400">Headcount: <b className="text-slate-200">{c.current_headcount} / {c.expected_capacity}</b></span>
                  <button 
                    onClick={(e) => { e.stopPropagation(); onStartCall && onStartCall(c); }}
                    className="text-blue-400 hover:text-blue-300 font-bold flex items-center gap-1"
                  >
                    <PhoneCall className="w-3 h-3" /> Spot Call
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>

      </div>

    </div>
  );
};
