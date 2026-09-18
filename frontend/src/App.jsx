import React, { useState } from 'react';
import { WebSocketProvider, useWebSocket } from './context/WebSocketContext';
import { GISMap } from './components/GISMap';
import { CCTVAnalytics } from './components/CCTVAnalytics';
import { DispatchFeed } from './components/DispatchFeed';
import { WebRTCCallModal } from './components/WebRTCCallModal';
import { Shield, Map, Camera, Send, Radio, Landmark } from 'lucide-react';

function DashboardContent() {
  const { isConnected, latestAlert } = useWebSocket();
  const [activeTab, setActiveTab] = useState('gis_map');
  const [selectedCenter, setSelectedCenter] = useState(null);
  const [activeCallCenter, setActiveCallCenter] = useState(null);

  return (
    <div className="min-h-screen bg-[#070d19] text-slate-100 flex flex-col">
      
      {/* Official Government Top Bar */}
      <div className="bg-[#050914] border-b border-slate-800 text-[11px] text-slate-400 py-1.5 px-4">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-2 font-medium">
            <Landmark className="w-3.5 h-3.5 text-amber-500" />
            <span>Government of India &bull; Ministry of Social Justice and Empowerment (MoSJE)</span>
          </div>
          <span className="font-mono text-slate-500 text-[10px]">Official Audit &amp; Surveillance Portal</span>
        </div>
      </div>

      {/* Main Institutional Header Navbar */}
      <header className="border-b border-slate-800 bg-[#0f1a30]/90 backdrop-blur-md sticky top-0 z-40">
        <div className="max-w-7xl mx-auto px-4 py-3 flex items-center justify-between">
          <div className="flex items-center gap-3.5">
            <div className="w-10 h-10 rounded-lg bg-gradient-to-tr from-blue-700 via-indigo-800 to-slate-900 border border-blue-500/30 flex items-center justify-center shadow-md">
              <Shield className="w-5 h-5 text-amber-400" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-base font-bold tracking-tight text-slate-100 uppercase">MoSJE Surveillance Engine</h1>
                <span className="text-[10px] font-mono font-bold bg-blue-950 text-blue-300 border border-blue-800/80 px-2 py-0.5 rounded">
                  SIH PROTOTYPE v2.4
                </span>
              </div>
              <p className="text-[11px] text-slate-400">Automated CCTV Headcount Cross-Checking &amp; Hardware-Verified Site Boundaries</p>
            </div>
          </div>

          {/* System Status Indicator */}
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-2 text-xs bg-slate-900/90 border border-slate-700/80 px-3.5 py-1.5 rounded-lg shadow-inner">
              <span className={`pulse-dot ${isConnected ? 'green' : 'red'}`}></span>
              <span className="text-slate-200 font-semibold tracking-wide">{isConnected ? 'LIVE WEBSOCKETS CONNECTED' : 'OFFLINE'}</span>
            </div>
          </div>
        </div>
      </header>

      {/* Alert Notification Ticker Banner */}
      {latestAlert && (
        <div className="bg-red-950/80 border-b border-red-800/80 py-2 px-4 text-xs flex items-center justify-between text-red-200">
          <div className="flex items-center gap-2">
            <Radio className="w-4 h-4 text-red-400 animate-pulse" />
            <span className="font-bold">UNANNOUNCED AUDIT DISPATCH TRIGGERED:</span>
            <span>{latestAlert.center_name} spiked to Risk Score {latestAlert.risk_score}% ({latestAlert.task_id})</span>
          </div>
          <span className="font-mono text-[10px] text-red-300">{latestAlert.timestamp}</span>
        </div>
      )}

      {/* Main Application Container */}
      <main className="flex-1 max-w-7xl w-full mx-auto p-4 md:p-6 space-y-6">
        
        {/* Page Title & Subtitle */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-slate-800/80 pb-4">
          <div>
            <h2 className="text-xl font-bold text-slate-100">National Welfare Institute Monitoring Command</h2>
            <p className="text-xs text-slate-400">Continuous AI surveillance, regional GIS spatial geofencing, and automated risk-driven audit dispatches</p>
          </div>
        </div>

        {/* Standardized Government Navigation Tabs */}
        <div className="flex items-center gap-2 overflow-x-auto pb-1 border-b border-slate-800">
          <button
            onClick={() => setActiveTab('gis_map')}
            className={`flex items-center gap-2 px-5 py-2.5 rounded-lg font-bold text-xs transition-all whitespace-nowrap ${
              activeTab === 'gis_map'
                ? 'bg-blue-700 text-white shadow-md shadow-blue-900/40 border border-blue-500/50'
                : 'bg-slate-900/70 text-slate-400 hover:text-slate-200 border border-slate-800'
            }`}
          >
            <Map className="w-4 h-4" /> GIS Boundary Map
          </button>

          <button
            onClick={() => setActiveTab('cctv')}
            className={`flex items-center gap-2 px-5 py-2.5 rounded-lg font-bold text-xs transition-all whitespace-nowrap ${
              activeTab === 'cctv'
                ? 'bg-blue-700 text-white shadow-md shadow-blue-900/40 border border-blue-500/50'
                : 'bg-slate-900/70 text-slate-400 hover:text-slate-200 border border-slate-800'
            }`}
          >
            <Camera className="w-4 h-4" /> CCTV OpenCV Analytics
          </button>

          <button
            onClick={() => setActiveTab('dispatches')}
            className={`flex items-center gap-2 px-5 py-2.5 rounded-lg font-bold text-xs transition-all whitespace-nowrap ${
              activeTab === 'dispatches'
                ? 'bg-blue-700 text-white shadow-md shadow-blue-900/40 border border-blue-500/50'
                : 'bg-slate-900/70 text-slate-400 hover:text-slate-200 border border-slate-800'
            }`}
          >
            <Send className="w-4 h-4" /> Dynamic Dispatches
          </button>
        </div>

        {/* Tab Content Views */}
        {activeTab === 'gis_map' && (
          <GISMap 
            onStartCall={(center) => setActiveCallCenter(center)}
            onSelectCenter={(center) => {
              setSelectedCenter(center);
              setActiveTab('cctv');
            }}
          />
        )}

        {activeTab === 'cctv' && (
          <CCTVAnalytics selectedCenter={selectedCenter} />
        )}

        {activeTab === 'dispatches' && (
          <DispatchFeed onStartCall={(center) => setActiveCallCenter(center)} />
        )}
      </main>

      {/* Agora WebRTC Spot Call Modal */}
      {activeCallCenter && (
        <WebRTCCallModal 
          center={activeCallCenter} 
          onClose={() => setActiveCallCenter(null)} 
        />
      )}

      {/* Institutional Footer */}
      <footer className="border-t border-slate-800/80 bg-[#050914] py-5 px-4 text-center text-xs text-slate-400 space-y-1">
        <p className="font-semibold text-slate-300">&copy; Ministry of Social Justice and Empowerment (MoSJE) &bull; Government of India</p>
        <p className="text-[11px] text-slate-500">Smart India Hackathon Prototype &bull; Automated Anti-Collusion Surveillance &amp; Verification System</p>
      </footer>
    </div>
  );
}

export default function App() {
  return (
    <WebSocketProvider>
      <DashboardContent />
    </WebSocketProvider>
  );
}
