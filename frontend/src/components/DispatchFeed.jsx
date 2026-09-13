import React, { useState } from 'react';
import { AlertCircle, CheckCircle, Clock, MapPin, Send, ShieldCheck, UserCheck, KeyRound } from 'lucide-react';
import { useWebSocket } from '../context/WebSocketContext';

export const DispatchFeed = ({ onStartCall }) => {
  const { dispatches, centers, refreshData } = useWebSocket();
  const [selectedCenterId, setSelectedCenterId] = useState('');
  const [manualInspector, setManualInspector] = useState('Inspector Anil Sharma (Squad-4)');

  const handleManualDispatch = async (e) => {
    e.preventDefault();
    if (!selectedCenterId) return;

    try {
      const selected = centers.find(c => String(c.id) === String(selectedCenterId) || c.code === selectedCenterId);
      const res = await fetch('/api/audit-tasks/', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          task_id: `TASK-MOSJE-${Math.floor(1000 + Math.random() * 9000)}`,
          center: selected ? selected.id : centers[0].id,
          assigned_inspector: manualInspector,
          status: 'DISPATCHED',
          trigger_reason: 'Manual Unannounced Spot Audit Triggered by MoSJE Central Command',
        })
      });

      if (res.ok) {
        refreshData();
      }
    } catch (err) {
      console.error(err);
    }
  };

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
      {/* Task List */}
      <div className="lg:col-span-2 glass-card p-5 space-y-4">
        <div className="flex items-center justify-between border-b border-slate-800 pb-3">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-purple-500/10 text-purple-400 border border-purple-500/20">
              <Send className="w-5 h-5 animate-pulse" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-slate-100">Unannounced Audit Dispatch Command</h2>
              <p className="text-xs text-slate-400">Dynamic automated task dispatching triggered by AI risk scores</p>
            </div>
          </div>
          <span className="badge badge-critical">{dispatches.length} ACTIVE DISPATCHES</span>
        </div>

        <div className="space-y-3 max-h-[500px] overflow-y-auto pr-1">
          {dispatches.map(task => (
            <div key={task.id || task.task_id} className="p-4 rounded-xl bg-slate-900/80 border border-slate-800 hover:border-slate-700 transition space-y-3">
              <div className="flex items-start justify-between">
                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-mono text-xs font-bold text-cyan-400">{task.task_id}</span>
                    <span className={`badge ${
                      task.status === 'COMPLETED' ? 'badge-normal' :
                      task.status === 'IN_PROGRESS' ? 'badge-warning' : 'badge-critical'
                    }`}>
                      {task.status}
                    </span>
                  </div>
                  <h3 className="text-sm font-bold text-slate-100 mt-1">{task.center_name || 'Institute Center'}</h3>
                  <p className="text-xs text-slate-400">{task.center_district || 'District HQ'}</p>
                </div>

                {task.sha256_hash && (
                  <div className="flex items-center gap-1 text-[11px] font-mono text-emerald-400 bg-emerald-950/40 border border-emerald-800/50 px-2.5 py-1 rounded-lg">
                    <ShieldCheck className="w-3.5 h-3.5" /> SHA-256 Signed
                  </div>
                )}
              </div>

              <div className="p-2.5 rounded-lg bg-slate-950/60 text-xs text-slate-300 flex items-start gap-2">
                <AlertCircle className="w-4 h-4 text-amber-400 shrink-0 mt-0.5" />
                <span>{task.trigger_reason}</span>
              </div>

              <div className="flex items-center justify-between text-xs text-slate-400 pt-1 border-t border-slate-800/60">
                <div className="flex items-center gap-4">
                  <span className="flex items-center gap-1"><UserCheck className="w-3.5 h-3.5 text-cyan-400" /> {task.assigned_inspector}</span>
                  <span className="flex items-center gap-1"><MapPin className="w-3.5 h-3.5 text-red-400" /> {task.geo_unlocked ? 'Hardware GPS Verified' : 'Geo-Fence Locked'}</span>
                </div>
                <span className="text-slate-500">{new Date(task.dispatched_at).toLocaleTimeString()}</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Manual Unannounced Dispatch Override */}
      <div className="glass-card p-5 space-y-4">
        <h3 className="text-md font-bold text-slate-100 flex items-center gap-2 border-b border-slate-800 pb-3">
          <KeyRound className="w-4 h-4 text-cyan-400" /> Dispatch Flying Squad Audit
        </h3>

        <form onSubmit={handleManualDispatch} className="space-y-4 text-xs">
          <div>
            <label className="text-slate-300 font-semibold mb-1 block">Target Center</label>
            <select
              value={selectedCenterId}
              onChange={(e) => setSelectedCenterId(e.target.value)}
              className="w-full bg-slate-900 border border-slate-700 rounded-lg p-2.5 text-slate-200 focus:outline-none focus:border-cyan-500"
            >
              <option value="">-- Select Center --</option>
              {centers.map(c => (
                <option key={c.id} value={c.id}>
                  {c.name} ({c.code}) - Risk: {c.risk_score}%
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="text-slate-300 font-semibold mb-1 block">Assign Flying Squad Officer</label>
            <input 
              type="text"
              value={manualInspector}
              onChange={(e) => setManualInspector(e.target.value)}
              className="w-full bg-slate-900 border border-slate-700 rounded-lg p-2.5 text-slate-200 focus:outline-none focus:border-cyan-500"
            />
          </div>

          <div className="p-3 rounded-xl bg-purple-950/20 border border-purple-800/30 text-purple-300 leading-relaxed">
            Dispatching sends an immediate GPS-locked inspection task to the inspector's Flutter app. Form will only unlock on-site.
          </div>

          <button
            type="submit"
            className="w-full bg-gradient-to-r from-red-600 to-rose-600 hover:from-red-500 hover:to-rose-500 text-white font-bold py-2.5 rounded-lg shadow-lg shadow-red-500/20 transition flex items-center justify-center gap-2"
          >
            <Send className="w-4 h-4" /> Trigger Unannounced Dispatch
          </button>
        </form>
      </div>
    </div>
  );
};
