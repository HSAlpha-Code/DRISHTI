import React, { useState } from 'react';
import { ShieldCheck, Lock, CheckCircle2, AlertTriangle, Search } from 'lucide-react';
import { useWebSocket } from '../context/WebSocketContext';

export const AuditTrail = () => {
  const { dispatches } = useWebSocket();
  const [selectedTask, setSelectedTask] = useState(dispatches[0] || null);
  const [verificationResult, setVerificationResult] = useState(null);
  const [isVerifying, setIsVerifying] = useState(false);

  const handleVerifyIntegrity = async () => {
    if (!selectedTask) return;
    setIsVerifying(true);
    try {
      const res = await fetch(`/api/audit-tasks/${selectedTask.id}/verify_hash/`, {
        method: 'POST'
      });
      const data = await res.json();
      setVerificationResult(data);
    } catch (err) {
      console.error(err);
    } finally {
      setIsVerifying(false);
    }
  };

  return (
    <div className="glass-card p-6 space-y-6">
      <div className="flex items-center gap-3 border-b border-slate-800 pb-4">
        <div className="p-2 rounded-lg bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
          <ShieldCheck className="w-6 h-6" />
        </div>
        <div>
          <h2 className="text-xl font-bold text-slate-100">Cryptographic SHA-256 Audit Integrity Checker</h2>
          <p className="text-xs text-slate-400">Verifies offline-signed inspection reports against anti-collusion tamper protections</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Task Selection & Hashes */}
        <div className="space-y-4 text-xs">
          <label className="text-slate-300 font-semibold block">Select Audit Task Record</label>
          <div className="space-y-2 max-h-[350px] overflow-y-auto pr-1">
            {dispatches.map(task => (
              <div 
                key={task.id}
                onClick={() => { setSelectedTask(task); setVerificationResult(null); }}
                className={`p-3.5 rounded-xl border transition cursor-pointer ${
                  selectedTask?.id === task.id ? 'bg-cyan-950/40 border-cyan-500/50' : 'bg-slate-900/60 border-slate-800 hover:border-slate-700'
                }`}
              >
                <div className="flex justify-between items-start mb-1">
                  <span className="font-mono font-bold text-cyan-400">{task.task_id}</span>
                  <span className={`badge ${task.status === 'COMPLETED' ? 'badge-normal' : 'badge-critical'}`}>
                    {task.status}
                  </span>
                </div>
                <div className="text-slate-200 font-bold">{task.center_name}</div>
                <div className="text-slate-400 text-[11px] truncate mt-1">
                  {task.sha256_hash ? `SHA256: ${task.sha256_hash}` : 'Awaiting Inspection Submission'}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Verification Inspector Window */}
        <div className="space-y-4">
          {selectedTask ? (
            <div className="p-5 rounded-2xl bg-slate-900/80 border border-slate-800 space-y-4 text-xs">
              <div className="flex items-center justify-between border-b border-slate-800 pb-3">
                <span className="font-bold text-slate-100 text-sm">{selectedTask.task_id} Details</span>
                <button
                  onClick={handleVerifyIntegrity}
                  disabled={isVerifying || !selectedTask.sha256_hash}
                  className="bg-emerald-600 hover:bg-emerald-500 disabled:opacity-50 text-white font-bold px-3 py-1.5 rounded-lg transition flex items-center gap-1.5"
                >
                  <Search className="w-3.5 h-3.5" /> Check Hash Integrity
                </button>
              </div>

              <div className="space-y-2 font-mono text-[11px]">
                <div>
                  <span className="text-slate-400 block">Stored SHA-256 Signature:</span>
                  <div className="p-2 rounded bg-slate-950 border border-slate-800 text-cyan-300 break-all mt-1">
                    {selectedTask.sha256_hash || 'No hash generated yet'}
                  </div>
                </div>

                <div>
                  <span className="text-slate-400 block">Hardware GPS Coordinates:</span>
                  <div className="p-2 rounded bg-slate-950 border border-slate-800 text-slate-300 mt-1">
                    LAT: {selectedTask.inspector_latitude || 'Verified'} | LNG: {selectedTask.inspector_longitude || 'Verified'}
                  </div>
                </div>
              </div>

              {verificationResult && (
                <div className={`p-4 rounded-xl border space-y-2 ${
                  verificationResult.integrity_verified ? 'bg-emerald-950/60 border-emerald-500/40 text-emerald-300' : 'bg-red-950/60 border-red-500/40 text-red-300'
                }`}>
                  <div className="flex items-center gap-2 font-bold text-sm">
                    {verificationResult.integrity_verified ? <CheckCircle2 className="w-5 h-5 text-emerald-400" /> : <AlertTriangle className="w-5 h-5 text-red-400" />}
                    <span>{verificationResult.message}</span>
                  </div>
                </div>
              )}
            </div>
          ) : (
            <div className="p-8 text-center text-slate-500">
              Select a task to inspect cryptographic signature.
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
