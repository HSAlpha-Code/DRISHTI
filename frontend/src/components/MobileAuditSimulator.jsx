import React, { useState } from 'react';
import { Smartphone, Lock, Unlock, MapPin, ShieldCheck, FileCheck, CheckCircle2, AlertOctagon, Camera, RefreshCw } from 'lucide-react';
import { useWebSocket } from '../context/WebSocketContext';

export const MobileAuditSimulator = () => {
  const { centers, dispatches, refreshData } = useWebSocket();
  const [selectedTask, setSelectedTask] = useState(dispatches[0] || null);
  
  // Simulated inspector GPS location state
  const [gpsSimMode, setGpsSimMode] = useState('INSIDE'); // 'INSIDE' or 'OUTSIDE'
  const [isUnlocked, setIsUnlocked] = useState(false);
  const [isVerifyingGps, setIsVerifyingGps] = useState(false);
  const [reportResult, setReportResult] = useState(null);

  // Form State
  const [beneficiaryCount, setBeneficiaryCount] = useState('42');
  const [registerMatches, setRegisterMatches] = useState('YES');
  const [notes, setNotes] = useState('On-site verification completed. Beneficiaries interviewed.');
  const [sha256Hash, setSha256Hash] = useState('');

  const targetCenter = selectedTask ? centers.find(c => c.id === selectedTask.center || c.name === selectedTask.center_name) || centers[0] : centers[0];

  const handleVerifyGPS = async () => {
    if (!targetCenter) return;
    setIsVerifyingGps(true);
    setReportResult(null);

    // Simulate GPS coordinates inside vs outside boundary polygon
    const lat = gpsSimMode === 'INSIDE' ? targetCenter.latitude : targetCenter.latitude + 0.05;
    const lng = gpsSimMode === 'INSIDE' ? targetCenter.longitude : targetCenter.longitude + 0.05;

    try {
      const res = await fetch(`/api/centers/${targetCenter.id || 1}/verify_gps_boundary/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ latitude: lat, longitude: lng })
      });
      const data = await res.json();
      setIsUnlocked(data.unlocked);
    } catch (err) {
      console.error(err);
      setIsUnlocked(gpsSimMode === 'INSIDE');
    } finally {
      setIsVerifyingGps(false);
    }
  };

  const handleCalculateSHA256 = async () => {
    const payloadStr = JSON.stringify({
      beneficiaryCount,
      registerMatches,
      notes,
      centerCode: targetCenter?.code,
      timestamp: new Date().toISOString()
    });
    
    // Calculate SHA-256 hash using Web Crypto API
    const msgBuffer = new TextEncoder().encode(payloadStr);
    const hashBuffer = await crypto.subtle.digest('SHA-256', msgBuffer);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
    
    setSha256Hash(hashHex);
    return hashHex;
  };

  const handleSubmitReport = async (e) => {
    e.preventDefault();
    if (!selectedTask || !isUnlocked) return;

    const hash = await handleCalculateSHA256();
    const lat = gpsSimMode === 'INSIDE' ? targetCenter.latitude : targetCenter.latitude + 0.05;
    const lng = gpsSimMode === 'INSIDE' ? targetCenter.longitude : targetCenter.longitude + 0.05;

    try {
      const res = await fetch(`/api/audit-tasks/${selectedTask.id}/submit_signed_report/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          latitude: lat,
          longitude: lng,
          payload: { beneficiaryCount, registerMatches, notes },
          sha256_hash: hash,
          photo_watermark: `/media/watermark_gps_${targetCenter?.code}.jpg`
        })
      });

      const data = await res.json();
      setReportResult(data);
      if (res.ok) {
        refreshData();
      }
    } catch (err) {
      console.error(err);
    }
  };

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
      {/* Mobile Device Mockup Frame */}
      <div className="lg:col-span-1 flex justify-center">
        <div className="w-full max-w-[360px] bg-slate-950 border-4 border-slate-800 rounded-[38px] p-4 shadow-2xl space-y-4 relative overflow-hidden">
          
          {/* Phone Top Notch */}
          <div className="w-28 h-4 bg-slate-800 rounded-full mx-auto mb-2"></div>

          {/* App Header */}
          <div className="bg-slate-900 p-3 rounded-xl border border-slate-800 flex items-center justify-between text-xs">
            <div className="flex items-center gap-2">
              <Smartphone className="w-4 h-4 text-cyan-400" />
              <span className="font-bold text-slate-100">Flutter Inspector App</span>
            </div>
            <span className="text-[10px] font-mono text-emerald-400">v2.4 Geo-Locked</span>
          </div>

          {/* GPS Boundary Unlock Status Bar */}
          <div className={`p-3 rounded-xl border text-xs font-semibold flex items-center justify-between transition ${
            isUnlocked 
              ? 'bg-emerald-950/50 border-emerald-500/40 text-emerald-300' 
              : 'bg-red-950/50 border-red-500/40 text-red-300'
          }`}>
            <div className="flex items-center gap-2">
              {isUnlocked ? <Unlock className="w-4 h-4 text-emerald-400" /> : <Lock className="w-4 h-4 text-red-400" />}
              <span>{isUnlocked ? 'Hardware GPS Verified' : 'Site Geo-Fence Locked'}</span>
            </div>

            <button 
              onClick={handleVerifyGPS}
              disabled={isVerifyingGps}
              className="text-[11px] bg-slate-800 hover:bg-slate-700 px-2 py-1 rounded text-slate-200"
            >
              {isVerifyingGps ? 'Checking...' : 'Verify GPS'}
            </button>
          </div>

          {/* GPS Simulation Switcher */}
          <div className="p-2.5 rounded-xl bg-slate-900/60 border border-slate-800 text-xs space-y-2">
            <span className="text-slate-400 block font-semibold">Simulate Inspector Position:</span>
            <div className="grid grid-cols-2 gap-2">
              <button
                type="button"
                onClick={() => { setGpsSimMode('INSIDE'); setIsUnlocked(false); }}
                className={`py-1.5 px-2 rounded font-medium text-[11px] ${gpsSimMode === 'INSIDE' ? 'bg-cyan-600 text-white' : 'bg-slate-800 text-slate-400'}`}
              >
                On-Site (&lt; 50m)
              </button>
              <button
                type="button"
                onClick={() => { setGpsSimMode('OUTSIDE'); setIsUnlocked(false); }}
                className={`py-1.5 px-2 rounded font-medium text-[11px] ${gpsSimMode === 'OUTSIDE' ? 'bg-red-600 text-white' : 'bg-slate-800 text-slate-400'}`}
              >
                Off-Site (&gt; 5km)
              </button>
            </div>
          </div>

          {/* Dynamic Inspection Checklist Form */}
          <form onSubmit={handleSubmitReport} className="space-y-3 text-xs">
            <div>
              <label className="text-slate-400 block mb-1">Select Audit Task</label>
              <select
                value={selectedTask?.id || ''}
                onChange={(e) => {
                  const t = dispatches.find(d => String(d.id) === e.target.value);
                  setSelectedTask(t);
                  setIsUnlocked(false);
                }}
                className="w-full bg-slate-900 border border-slate-800 rounded-lg p-2 text-slate-200"
              >
                {dispatches.map(t => (
                  <option key={t.id} value={t.id}>{t.task_id} - {t.center_name}</option>
                ))}
              </select>
            </div>

            <div>
              <label className="text-slate-400 block mb-1">Physical Headcount Counted</label>
              <input 
                type="number"
                disabled={!isUnlocked}
                value={beneficiaryCount}
                onChange={(e) => setBeneficiaryCount(e.target.value)}
                className="w-full bg-slate-900 border border-slate-800 rounded-lg p-2 text-slate-200 disabled:opacity-50"
              />
            </div>

            <div>
              <label className="text-slate-400 block mb-1">Inspector Notes</label>
              <textarea
                rows={2}
                disabled={!isUnlocked}
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                className="w-full bg-slate-900 border border-slate-800 rounded-lg p-2 text-slate-200 disabled:opacity-50"
              ></textarea>
            </div>

            {/* EXIF Watermarking Preview */}
            <div className="p-2 rounded-lg bg-slate-900 border border-slate-800 flex items-center justify-between text-[11px]">
              <span className="text-slate-400 flex items-center gap-1"><Camera className="w-3.5 h-3.5 text-cyan-400" /> EXIF Geo-Watermark</span>
              <span className="text-emerald-400 font-mono">LAT: {targetCenter?.latitude?.toFixed(4)}</span>
            </div>

            <button
              type="submit"
              disabled={!isUnlocked}
              className={`w-full py-2.5 rounded-lg font-bold transition flex items-center justify-center gap-2 ${
                isUnlocked 
                  ? 'bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white shadow-lg shadow-emerald-500/20' 
                  : 'bg-slate-800 text-slate-500 cursor-not-allowed'
              }`}
            >
              <ShieldCheck className="w-4 h-4" /> Sign &amp; Submit SHA-256 Report
            </button>
          </form>

        </div>
      </div>

      {/* Flutter App Features & Cryptographic Signature Details */}
      <div className="lg:col-span-2 space-y-6">
        <div className="glass-card p-5 space-y-4">
          <div className="flex items-center gap-3 border-b border-slate-800 pb-3">
            <div className="p-2 rounded-lg bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
              <FileCheck className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-slate-100">Flutter Mobile App Architecture</h2>
              <p className="text-xs text-slate-400">Offline-first local SQLite storage with SHA-256 payload signatures</p>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs">
            <div className="p-3.5 rounded-xl bg-slate-900/60 border border-slate-800 space-y-2">
              <span className="font-bold text-cyan-400 flex items-center gap-1.5">
                <MapPin className="w-4 h-4 text-cyan-400" /> Geo-Fencing Enforcement
              </span>
              <p className="text-slate-300 leading-relaxed">
                Uses mobile hardware GPS to cross-check inspector coordinates against GeoDjango PostGIS site boundary polygons before unlocking inspection input fields.
              </p>
            </div>

            <div className="p-3.5 rounded-xl bg-slate-900/60 border border-slate-800 space-y-2">
              <span className="font-bold text-purple-400 flex items-center gap-1.5">
                <ShieldCheck className="w-4 h-4 text-purple-400" /> Offline SHA-256 Signing
              </span>
              <p className="text-slate-300 leading-relaxed">
                Inspectors operating in low-network rural areas store reports in local SQLite databases, signed with local SHA-256 payload hashes to prevent local tampering prior to auto-sync.
              </p>
            </div>
          </div>

          {reportResult && (
            <div className={`p-4 rounded-xl border space-y-2 text-xs ${
              reportResult.status === 'SUCCESS' ? 'bg-emerald-950/60 border-emerald-500/40 text-emerald-200' : 'bg-red-950/60 border-red-500/40 text-red-200'
            }`}>
              <div className="flex items-center gap-2 font-bold text-sm">
                {reportResult.status === 'SUCCESS' ? <CheckCircle2 className="w-5 h-5 text-emerald-400" /> : <AlertOctagon className="w-5 h-5 text-red-400" />}
                <span>{reportResult.message}</span>
              </div>
              {reportResult.sha256_hash && (
                <div className="p-2 rounded bg-slate-950 font-mono text-[11px] break-all text-cyan-300 border border-slate-800">
                  SHA-256: {reportResult.sha256_hash}
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
