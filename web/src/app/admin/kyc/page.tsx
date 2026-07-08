"use client";

import { useEffect, useState } from "react";
import { getKycQueue, approveKyc, rejectKyc } from "@/lib/api/admin";
import type { UserProfile } from "@/types/api";

export default function AdminKycQueue() {
  const [queue, setQueue] = useState<UserProfile[]>([]);
  const [selectedUser, setSelectedUser] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [actionLoading, setActionLoading] = useState(false);

  function loadQueue() {
    setLoading(true);
    setError("");
    getKycQueue()
      .then((res) => {
        setQueue(res);
        // Default select the first item if queue has items and none selected or previous selection no longer in queue
        if (res.length > 0) {
          setSelectedUser((curr) => {
            const stillInQueue = res.find((u) => u.id === curr?.id);
            return stillInQueue ? stillInQueue : res[0];
          });
        } else {
          setSelectedUser(null);
        }
      })
      .catch((err) => setError(err instanceof Error ? err.message : "Failed to load KYC queue"))
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    loadQueue();
  }, []);

  async function handleApprove(userId: string) {
    if (!confirm("Are you sure you want to approve this KYC submission? This will elevate the user to Level 3 (Face Verification) and mark them as a Trusted User.")) {
      return;
    }

    setActionLoading(true);
    try {
      await approveKyc(userId);
      alert("KYC submission approved successfully.");
      loadQueue();
    } catch (err) {
      alert(err instanceof Error ? err.message : "Approval failed");
    } finally {
      setActionLoading(false);
    }
  }

  async function handleReject(userId: string) {
    const reason = prompt("Enter the reason for rejection (optional):");
    if (reason === null) return; // user cancelled prompt

    setActionLoading(true);
    try {
      await rejectKyc(userId);
      alert("KYC submission rejected. User has been downgraded and NIC details cleared.");
      loadQueue();
    } catch (err) {
      alert(err instanceof Error ? err.message : "Rejection failed");
    } finally {
      setActionLoading(false);
    }
  }

  return (
    <div className="space-y-6">
      {/* Intro */}
      <div>
        <h2 className="text-xl font-bold text-slate-100">NIC Document Review</h2>
        <p className="text-slate-400 text-sm mt-1">
          Review National Identity Card details and documents submitted by users.
        </p>
      </div>

      {error && (
        <div className="p-4 bg-red-950/20 border border-red-800/40 rounded-xl text-red-400 text-sm">
          {error}
        </div>
      )}

      {loading && queue.length === 0 ? (
        <div className="flex items-center justify-center min-h-[300px]">
          <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-indigo-500"></div>
        </div>
      ) : queue.length === 0 ? (
        <div className="rounded-2xl border border-dashed border-slate-800 p-12 text-center bg-slate-900/10 backdrop-blur-md">
          <span className="text-4xl">🎉</span>
          <h3 className="text-lg font-bold text-slate-200 mt-4">KYC queue is empty</h3>
          <p className="text-sm text-slate-500 mt-1">No users have pending NIC approvals.</p>
        </div>
      ) : (
        <div className="grid gap-6 md:grid-cols-3 min-h-[500px]">
          {/* Queue List (Left Side) */}
          <div className="md:col-span-1 rounded-2xl border border-slate-800 bg-slate-900/10 overflow-hidden flex flex-col">
            <div className="p-4 border-b border-slate-800 bg-slate-900/30">
              <span className="text-xs font-bold text-slate-400 uppercase tracking-wider">
                Pending Submissions ({queue.length})
              </span>
            </div>
            
            <div className="flex-1 overflow-y-auto divide-y divide-slate-800/40 max-h-[500px]">
              {queue.map((user) => {
                const isSelected = selectedUser?.id === user.id;
                return (
                  <button
                    key={user.id}
                    onClick={() => setSelectedUser(user)}
                    className={`w-full text-left p-4 transition-all duration-150 flex flex-col gap-1 cursor-pointer ${
                      isSelected
                        ? "bg-indigo-950/30 border-l-4 border-indigo-500 shadow-inner"
                        : "hover:bg-slate-900/40"
                    }`}
                  >
                    <span className="text-sm font-semibold text-slate-200">
                      {user.firstName} {user.lastName}
                    </span>
                    <span className="text-xs text-slate-400 font-mono truncate">{user.email}</span>
                    <span className="text-[10px] text-slate-500 mt-1">
                      Submitted: {new Date(user.createdAt).toLocaleDateString()}
                    </span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Review Panel (Right Side) */}
          <div className="md:col-span-2 rounded-2xl border border-slate-800 bg-slate-900/10 p-6 flex flex-col justify-between">
            {selectedUser ? (
              <div className="flex flex-col h-full justify-between gap-8">
                {/* Details Section */}
                <div className="space-y-6">
                  <div className="flex items-start justify-between border-b border-slate-800 pb-4">
                    <div>
                      <h3 className="text-lg font-bold text-slate-200">
                        {selectedUser.firstName} {selectedUser.lastName}
                      </h3>
                      <p className="text-xs text-slate-500 font-mono mt-0.5">ID: {selectedUser.id}</p>
                    </div>
                    <span className="text-xs px-2.5 py-0.5 rounded-full font-medium bg-amber-950/40 text-amber-400 border border-amber-500/20">
                      NIC Verification Level
                    </span>
                  </div>

                  <div className="grid gap-6 sm:grid-cols-2">
                    <div>
                      <p className="text-xs text-slate-500 uppercase font-semibold">NIC Number</p>
                      <p className="text-sm text-slate-200 font-semibold mt-1">
                        {selectedUser.nicNumber || "Not found"}
                      </p>
                    </div>
                    <div>
                      <p className="text-xs text-slate-500 uppercase font-semibold">Email Address</p>
                      <p className="text-sm text-slate-400 mt-1 font-mono">{selectedUser.email}</p>
                    </div>
                  </div>

                  {/* Document Attachment Visualizer */}
                  {selectedUser.nicDocumentUrl ? (
                    <div className="space-y-3">
                      <p className="text-xs text-slate-500 uppercase font-semibold">NIC Document Attachment</p>
                      <div className="p-4 rounded-xl border border-slate-800 bg-slate-950 flex flex-col items-center gap-4">
                        <div className="w-full flex items-center justify-between">
                          <span className="text-xs text-slate-400 font-medium truncate max-w-[300px]">
                            {selectedUser.nicDocumentUrl.split("/").pop()}
                          </span>
                          <a
                            href={selectedUser.nicDocumentUrl}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-xs text-indigo-400 font-bold hover:underline"
                          >
                            Open Link ↗
                          </a>
                        </div>
                        
                        {/* If it's a mock local or image URL, we can try rendering a thumbnail preview */}
                        {selectedUser.nicDocumentUrl.match(/\.(jpeg|jpg|gif|png|webp)/i) ? (
                          <div className="relative w-full max-h-[250px] overflow-hidden rounded-lg border border-slate-850 flex justify-center bg-slate-900">
                            <img
                              src={selectedUser.nicDocumentUrl}
                              alt="NIC Preview"
                              className="max-h-[250px] object-contain"
                            />
                          </div>
                        ) : (
                          <div className="w-full py-8 border border-dashed border-slate-800/80 rounded-lg flex flex-col items-center justify-center text-slate-600 bg-slate-900/30">
                            <svg className="w-8 h-8 text-slate-600" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                            </svg>
                            <span className="text-xs text-slate-500 mt-2">
                              No image preview available. Open link in a new tab.
                            </span>
                          </div>
                        )}
                      </div>
                    </div>
                  ) : (
                    <div className="p-4 rounded-xl border border-dashed border-slate-800/80 text-center text-slate-500 text-sm">
                      No document upload link was found.
                    </div>
                  )}
                </div>

                {/* Actions Section */}
                <div className="flex items-center gap-4 border-t border-slate-800 pt-6">
                  <button
                    disabled={actionLoading}
                    onClick={() => handleApprove(selectedUser.id)}
                    className="flex-1 py-3 px-4 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-sm transition duration-150 cursor-pointer disabled:opacity-50 flex items-center justify-center gap-2"
                  >
                    <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                    </svg>
                    Approve KYC
                  </button>
                  <button
                    disabled={actionLoading}
                    onClick={() => handleReject(selectedUser.id)}
                    className="flex-1 py-3 px-4 rounded-xl bg-red-950/20 hover:bg-red-950/40 border border-red-900/30 hover:border-red-800 text-red-400 font-bold text-sm transition duration-150 cursor-pointer disabled:opacity-50 flex items-center justify-center gap-2"
                  >
                    <svg className="w-4 h-4 text-red-400" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                    Reject KYC
                  </button>
                </div>
              </div>
            ) : (
              <div className="flex flex-col items-center justify-center h-full text-slate-600">
                <svg className="w-10 h-10 text-slate-700 mb-2" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
                <p className="text-sm mt-3">Select a KYC request from the queue to start reviewing.</p>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
