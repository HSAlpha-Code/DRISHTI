import React, { useState } from 'react';
import { WebSocketProvider, useWebSocket } from './context/WebSocketContext';
import { GISMap } from './components/GISMap';
import { CCTVAnalytics } from './components/CCTVAnalytics';
import { DispatchFeed } from './components/DispatchFeed';
import { WebRTCCallModal } from './components/WebRTCCallModal';
import { MobileAuditSimulator } from './components/MobileAuditSimulator';
import { AuditTrail } from './components/AuditTrail';
import { ShieldAlert, Map, Camera, Send, Smartphone, Lock, Radio, PhoneCall } from 'lucide-react';

function DashboardContent() {
  const { isConnected, latestAlert } = useWebSocket();
  const [activeTab, setActiveTab] = useState('gis_map');
  const [selectedCenter, setSelectedCenter] = useState(null);
  const [activeCallCenter, setActiveCallCenter] = useState(null);

  return (
    <div className="min-h-screen bg-[#0a0e17] text-slate-100 flex flex-col">
      {/* Top Header Navbar */}
      <header className="border-b border-slate-800/80 bg-slate-950/80 backdrop-blur-md sticky top-0 z-40">
        <div className="max-w-7xl mx-auto px-4 py-3 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-cyan-600 to-blue-600 p-0.5 shadow-lg shadow-cyan-500/20">
              <div className="w-full h-full bg-slate-950 rounded-[10px] flex items-center justify-center">
                <ShieldAlert className="w-5 h-5 text-cyan-400" />
              </div>
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-base font-black tracking-tight text-slate-100 uppercase">MoSJE Surveillance Engine</h1>
                <span className="text-[10px] font-mono font-bold bg-cyan-950 text-cyan-400 border border-cyan-800/60 px-2 py-0.5 rounded">
                  SIH PROTOTYPE v2.4
                </span>
              </div>
              <p className="text-[11px] text-slate-400">Automated CCTV Headcount Cross-Checking &amp; Hardware Geo-Locked Inspections</p>
            </div>
          </div>

          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2 text-xs bg-slate-900 border border-slate-800 px-3 py-1.5 rounded-full">
              <span className={`pulse-dot ${isConnected ? 'green' : 'red'}`}></span>
              <span className="text-slate-300 font-medium">{isConnected ? 'LIVE WEBSOCKETS CONNECTED' : 'OFFLINE'}</span>
            </div>
          </div>
        </div>
      </header>

      {/* Alert Notification Ticker Banner */}
      {latestAlert && (
        <div className="bg-gradient-to-r from-red-950 via-rose-900 to-red-950 border-b border-red-800/50 py-2 px-4 text-xs flex items-center justify-between text-red-200 animate-pulse">
          <div className="flex items-center gap-2">
            <Radio className="w-4 h-4 text-red-400" />
            <span className="font-bold">AUTOMATED UNANNOUNCED DISPATCH TRIGGERED:</span>
            <span>{latestAlert.center_name} spiked to Risk Score {latestAlert.risk_score}% ({latestAlert.task_id})</span>
          </div>
          <span className="font-mono text-[10px] text-red-300">{latestAlert.timestamp}</span>
        </div>
      )}

      {/* Main Container */}
      <main className="flex-1 max-w-7xl w-full mx-auto p-4 space-y-6">
        {/* Navigation Tabs Bar */}
        <div className="flex items-center gap-2 overflow-x-auto pb-1 border-b border-slate-800/60">
          <button
            onClick={() => setActiveTab('gis_map')}
            className={`flex items-center gap-2 px-4 py-2.5 rounded-xl font-semibold text-xs transition whitespace-nowrap ${
              activeTab === 'gis_map'
                ? 'bg-gradient-to-r from-cyan-600 to-blue-600 text-white shadow-lg shadow-cyan-500/20'
                : 'bg-slate-900/60 text-slate-400 hover:text-slate-200 border border-slate-800/60'
            }`}
          >
            <Map className="w-4 h-4" /> GIS Boundary Map
          </button>

          <button
            onClick={() => setActiveTab('cctv')}
            className={`flex items-center gap-2 px-4 py-2.5 rounded-xl font-semibold text-xs transition whitespace-nowrap ${
              activeTab === 'cctv'
                ? 'bg-gradient-to-r from-cyan-600 to-blue-600 text-white shadow-lg shadow-cyan-500/20'
                : 'bg-slate-900/60 text-slate-400 hover:text-slate-200 border border-slate-800/60'
            }`}
          >
            <Camera className="w-4 h-4" /> CCTV OpenCV Analytics
          </button>

          <button
            onClick={() => setActiveTab('dispatches')}
            className={`flex items-center gap-2 px-4 py-2.5 rounded-xl font-semibold text-xs transition whitespace-nowrap ${
              activeTab === 'dispatches'
                ? 'bg-gradient-to-r from-cyan-600 to-blue-600 text-white shadow-lg shadow-cyan-500/20'
                : 'bg-slate-900/60 text-slate-400 hover:text-slate-200 border border-slate-800/60'
            }`}
          >
            <Send className="w-4 h-4" /> Dynamic Dispatches
          </button>

          <button
            onClick={() => setActiveTab('mobile_app')}
            className={`flex items-center gap-2 px-4 py-2.5 rounded-xl font-semibold text-xs transition whitespace-nowrap ${
              activeTab === 'mobile_app'
                ? 'bg-gradient-to-r from-cyan-600 to-blue-600 text-white shadow-lg shadow-cyan-500/20'
                : 'bg-slate-900/60 text-slate-400 hover:text-slate-200 border border-slate-800/60'
            }`}
          >
            <Smartphone className="w-4 h-4 text-emerald-400" /> Flutter Mobile App
          </button>

          <button
            onClick={() => setActiveTab('audit_trail')}
            className={`flex items-center gap-2 px-4 py-2.5 rounded-xl font-semibold text-xs transition whitespace-nowrap ${
              activeTab === 'audit_trail'
                ? 'bg-gradient-to-r from-cyan-600 to-blue-600 text-white shadow-lg shadow-cyan-500/20'
                : 'bg-slate-900/60 text-slate-400 hover:text-slate-200 border border-slate-800/60'
            }`}
          >
            <Lock className="w-4 h-4 text-purple-400" /> SHA-256 Audit Integrity
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

        {activeTab === 'mobile_app' && (
          <MobileAuditSimulator />
        )}

        {activeTab === 'audit_trail' && (
          <AuditTrail />
        )}
      </main>

      {/* Agora WebRTC Spot Call Modal */}
      {activeCallCenter && (
        <WebRTCCallModal 
          center={activeCallCenter} 
          onClose={() => setActiveCallCenter(null)} 
        />
      )}

      {/* Footer */}
      <footer className="border-t border-slate-800/60 py-4 text-center text-xs text-slate-500">
        Smart India Hackathon Prototype &bull; Ministry of Social Justice and Empowerment (MoSJE) Monitoring Platform
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
