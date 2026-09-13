import React, { useState } from 'react';
import { Camera, Users, ShieldAlert, Cpu, RefreshCw, CheckCircle2 } from 'lucide-react';
import { useWebSocket } from '../context/WebSocketContext';

export const CCTVAnalytics = ({ selectedCenter }) => {
  const { centers, triggerSampleAI } = useWebSocket();
  const center = selectedCenter || centers[1] || centers[0];
  const [samplingInterval, setSamplingInterval] = useState(5);

  if (!center) {
    return (
      <div className="glass-card p-8 text-center text-slate-400">
        Loading CCTV Engine Stream...
      </div>
    );
  }

  const discrepancy = Math.max(0, center.expected_capacity - center.current_headcount);
  const turnoutPct = Math.round((center.current_headcount / Math.max(1, center.expected_capacity)) * 100);

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
      {/* Main CCTV Feed Viewport */}
      <div className="lg:col-span-2 glass-card p-5">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-red-500/10 text-red-400 border border-red-500/20">
              <Camera className="w-5 h-5 animate-pulse" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-slate-100">{center.name} [{center.code}]</h2>
              <p className="text-xs text-slate-400">OpenCV & YOLO11 Continuous Headcount Analytics Keyframe Engine</p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <span className="badge badge-normal flex items-center gap-1">
              <Cpu className="w-3.5 h-3.5" /> 1 Frame / {samplingInterval}s
            </span>
            <button 
              onClick={triggerSampleAI}
              className="p-2 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 border border-slate-700 transition"
              title="Manual Keyframe Trigger"
            >
              <RefreshCw className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Live CCTV Video Canvas Display */}
        <div className="relative rounded-xl overflow-hidden bg-slate-950 border border-slate-800 aspect-video flex items-center justify-center">
          {center.latest_snapshot ? (
            <img 
              src={center.latest_snapshot} 
              alt="CCTV Frame AI Stream" 
              className="w-full h-full object-cover"
            />
          ) : (
            <div className="text-center p-6 space-y-3">
              <Camera className="w-12 h-12 text-slate-600 mx-auto animate-pulse" />
              <p className="text-sm text-slate-400 font-mono">Initializing OpenCV YOLO11 Stream Buffer...</p>
            </div>
          )}

          {/* AI Detection Tag Overlay */}
          <div className="absolute top-4 left-4 bg-slate-900/90 backdrop-blur-md px-3 py-1.5 rounded-lg border border-slate-700 text-xs font-mono text-cyan-400 flex items-center gap-2">
            <span className="w-2 h-2 rounded-full bg-red-500 animate-ping"></span>
            SURVEILLANCE MODE: DECOUPLED KEYFRAME SAMPLING
          </div>

          {/* Risk Level Watermark */}
          <div className="absolute top-4 right-4">
            <span className={`badge ${center.risk_score >= 65 ? 'badge-critical' : center.risk_score >= 35 ? 'badge-warning' : 'badge-normal'}`}>
              RISK SCORE: {center.risk_score}%
            </span>
          </div>

          {/* Live Headcount Overlay Banner */}
          <div className="absolute bottom-0 inset-x-0 bg-gradient-to-t from-slate-950 via-slate-950/80 to-transparent p-4 flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div>
                <span className="text-xs text-slate-400 uppercase tracking-wider block">YOLO11 Detected</span>
                <span className="text-2xl font-black text-emerald-400 font-mono">{center.current_headcount}</span>
              </div>
              <div className="h-8 w-px bg-slate-800"></div>
              <div>
                <span className="text-xs text-slate-400 uppercase tracking-wider block">Expected Register</span>
                <span className="text-2xl font-black text-slate-200 font-mono">{center.expected_capacity}</span>
              </div>
              <div className="h-8 w-px bg-slate-800"></div>
              <div>
                <span className="text-xs text-slate-400 uppercase tracking-wider block">Discrepancy</span>
                <span className={`text-2xl font-black font-mono ${discrepancy > 10 ? 'text-red-400' : 'text-amber-400'}`}>
                  {discrepancy}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Side Analytics & Risk Meter Panel */}
      <div className="space-y-6">
        <div className="glass-card p-5 space-y-4">
          <h3 className="text-md font-bold text-slate-200 flex items-center gap-2">
            <Users className="w-4 h-4 text-cyan-400" /> Attendance Turnout Analytics
          </h3>

          <div className="space-y-2">
            <div className="flex justify-between text-sm">
              <span className="text-slate-400">Capacity Utilization</span>
              <span className="font-bold text-cyan-300">{turnoutPct}%</span>
            </div>
            <div className="w-full h-2.5 bg-slate-800 rounded-full overflow-hidden">
              <div 
                className={`h-full transition-all duration-500 ${turnoutPct < 40 ? 'bg-red-500' : turnoutPct < 75 ? 'bg-amber-500' : 'bg-emerald-500'}`}
                style={{ width: `${Math.min(100, turnoutPct)}%` }}
              ></div>
            </div>
          </div>

          <div className="p-3.5 rounded-xl bg-slate-900/60 border border-slate-800 space-y-2 text-xs">
            <div className="flex items-center justify-between">
              <span className="text-slate-400">Risk Assessment</span>
              <span className="font-semibold text-slate-200">{center.risk_level}</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-slate-400">Surveillance Sampling</span>
              <span className="text-emerald-400 font-mono">1 frame / 5 sec</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-slate-400">Automated Dispatch</span>
              <span className={center.risk_score >= 65 ? 'text-red-400 font-bold' : 'text-slate-400'}>
                {center.risk_score >= 65 ? 'TRIGGERED ACTIVE' : 'INACTIVE'}
              </span>
            </div>
          </div>
        </div>

        {/* Technical Mitigation Card */}
        <div className="glass-card p-5 space-y-3">
          <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider flex items-center gap-1.5">
            <ShieldAlert className="w-4 h-4 text-amber-400" /> Anti-Collusion Mechanism
          </h3>
          <p className="text-xs text-slate-300 leading-relaxed">
            Rolling average Risk Score filter prevents false alerts from temporary frame glitches. When headcount discrepancy remains persistent, system automatically initiates unannounced inspector dispatch.
          </p>
        </div>
      </div>
    </div>
  );
};
