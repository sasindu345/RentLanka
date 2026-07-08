"use client";

import { useEffect, useState } from "react";
import { getAdminDisputes, resolveDispute } from "@/lib/api/admin";
import type { DisputeResponse } from "@/types/api";

export default function DisputesPage() {
  const [disputes, setDisputes] = useState<DisputeResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedDispute, setSelectedDispute] = useState<DisputeResponse | null>(null);
  const [adminDecision, setAdminDecision] = useState("");
  const [refundRenter, setRefundRenter] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [errorMsg, setErrorMsg] = useState("");
  const [successMsg, setSuccessMsg] = useState("");

  useEffect(() => {
    loadDisputes();
  }, []);

  async function loadDisputes() {
    setLoading(true);
    try {
      const res = await getAdminDisputes();
      setDisputes(res);
    } catch {
      // Suppress fetch errors silently
    } finally {
      setLoading(false);
    }
  }

  async function handleResolve(e: React.FormEvent) {
    e.preventDefault();
    if (!selectedDispute) return;
    if (!adminDecision.trim()) {
      setErrorMsg("Please provide administrative resolution notes.");
      return;
    }

    setSubmitting(true);
    setErrorMsg("");
    setSuccessMsg("");

    try {
      await resolveDispute(selectedDispute.id, {
        adminDecision: adminDecision.trim(),
        refundRenter,
      });
      setSuccessMsg("Dispute resolved successfully!");
      setSelectedDispute(null);
      setAdminDecision("");
      loadDisputes();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "Failed to resolve dispute.";
      setErrorMsg(msg);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold text-slate-100">Disputes Moderation Center</h2>
          <p className="text-sm text-slate-400 mt-1">Review user claims and execute final resolution payouts or refunds.</p>
        </div>
        <button
          onClick={loadDisputes}
          className="inline-flex items-center gap-2 px-4 py-2 bg-slate-900 border border-slate-800 hover:border-slate-700 text-slate-300 hover:text-slate-100 rounded-xl text-sm font-semibold transition cursor-pointer"
        >
          <svg className="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 1121.21 7.89M9 11l3 3L22 4" />
          </svg>
          Refresh Queue
        </button>
      </div>

      {successMsg && (
        <div className="flex items-center gap-2 p-4 bg-emerald-950/30 border border-emerald-500/20 text-emerald-400 rounded-xl text-sm">
          <svg className="w-4 h-4 text-emerald-400 flex-shrink-0" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
          </svg>
          {successMsg}
        </div>
      )}

      {errorMsg && (
        <div className="flex items-center gap-2 p-4 bg-rose-950/30 border border-rose-500/20 text-rose-400 rounded-xl text-sm">
          <svg className="w-4 h-4 text-rose-400 flex-shrink-0" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
          </svg>
          {errorMsg}
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Disputes Queue */}
        <div className="lg:col-span-2 space-y-4">
          {loading ? (
            <div className="p-12 text-center text-slate-400 bg-slate-900/40 rounded-2xl border border-slate-900">
              <span className="inline-block animate-spin mr-2">⏳</span> Loading disputes queue...
            </div>
          ) : disputes.length === 0 ? (
            <div className="p-12 text-center text-slate-500 bg-slate-900/40 rounded-2xl border border-slate-900">
              No disputes logged in the queue.
            </div>
          ) : (
            <div className="bg-slate-900/40 rounded-2xl border border-slate-900 overflow-hidden">
              <table className="w-full text-left text-sm">
                <thead className="bg-slate-900/80 border-b border-slate-800 text-slate-400 font-semibold">
                  <tr>
                    <th className="px-6 py-4">Item</th>
                    <th className="px-6 py-4">Raised By</th>
                    <th className="px-6 py-4">Date Filed</th>
                    <th className="px-6 py-4">Status</th>
                    <th className="px-6 py-4 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-900">
                  {disputes.map((d) => (
                    <tr key={d.id} className="hover:bg-slate-900/30 transition">
                      <td className="px-6 py-4 font-medium text-slate-200">{d.listingTitle}</td>
                      <td className="px-6 py-4 text-slate-300">{d.createdByName}</td>
                      <td className="px-6 py-4 text-slate-400 text-xs">
                        {new Date(d.createdAt).toLocaleDateString()}
                      </td>
                      <td className="px-6 py-4">
                        <span
                          className={`px-2.5 py-1 rounded-full text-xs font-semibold border ${
                            d.isResolved
                              ? "bg-slate-950 border-slate-800 text-slate-500"
                              : "bg-amber-500/10 border-amber-500/20 text-amber-400"
                          }`}
                        >
                          {d.isResolved ? "Resolved" : "Open Dispute"}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-right">
                        <button
                          onClick={() => {
                            setSelectedDispute(d);
                            setAdminDecision(d.adminDecision || "");
                            setRefundRenter(true);
                          }}
                          className="px-3 py-1.5 rounded-lg bg-indigo-950/40 border border-indigo-500/20 hover:border-indigo-500/40 text-indigo-400 text-xs font-bold transition cursor-pointer"
                        >
                          Review &rarr;
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>

        {/* Detail Panel & Resolution Action */}
        <div className="bg-slate-900/40 border border-slate-900 rounded-2xl p-6 h-fit space-y-6">
          <h3 className="font-bold text-slate-200 border-b border-slate-800 pb-3">Dispute Review Panel</h3>

          {selectedDispute ? (
            <form onSubmit={handleResolve} className="space-y-4">
              <div>
                <label className="text-xs text-slate-400 uppercase tracking-wider">Item Context</label>
                <p className="text-sm font-semibold text-slate-200 mt-1">{selectedDispute.listingTitle}</p>
              </div>

              <div>
                <label className="text-xs text-slate-400 uppercase tracking-wider">Disputed Booking ID</label>
                <p className="text-xs text-slate-400 font-mono mt-1 select-all">{selectedDispute.bookingId}</p>
              </div>

              <div>
                <label className="text-xs text-slate-400 uppercase tracking-wider">Raised By</label>
                <p className="text-sm font-semibold text-slate-300 mt-1">{selectedDispute.createdByName}</p>
              </div>

              <div>
                <label className="text-xs text-slate-400 uppercase tracking-wider">Dispute Reason Claim</label>
                <div className="mt-1.5 p-3 bg-slate-950 rounded-xl text-slate-300 text-sm border border-slate-900 max-h-48 overflow-y-auto leading-relaxed">
                  {selectedDispute.reason}
                </div>
              </div>

              {!selectedDispute.isResolved ? (
                <>
                  <div className="pt-2">
                    <label className="text-xs text-slate-400 uppercase tracking-wider block mb-2">Resolution Choice</label>
                    <div className="space-y-2">
                      <label className="flex items-center gap-3 p-3 rounded-xl border border-slate-900 bg-slate-950/40 hover:bg-slate-950 transition cursor-pointer">
                        <input
                          type="radio"
                          name="resolution"
                          checked={refundRenter}
                          onChange={() => setRefundRenter(true)}
                          className="accent-indigo-500"
                        />
                        <div className="text-xs">
                          <p className="font-semibold text-slate-200">Refund Renter</p>
                          <p className="text-slate-500 mt-0.5">Return security deposit and rental fee to renter.</p>
                        </div>
                      </label>

                      <label className="flex items-center gap-3 p-3 rounded-xl border border-slate-900 bg-slate-950/40 hover:bg-slate-950 transition cursor-pointer">
                        <input
                          type="radio"
                          name="resolution"
                          checked={!refundRenter}
                          onChange={() => setRefundRenter(false)}
                          className="accent-indigo-500"
                        />
                        <div className="text-xs">
                          <p className="font-semibold text-slate-200">Payout Host</p>
                          <p className="text-slate-500 mt-0.5">Complete booking and release total earnings to host.</p>
                        </div>
                      </label>
                    </div>
                  </div>

                  <div>
                    <label className="text-xs text-slate-400 uppercase tracking-wider block mb-1.5">Administrative Decision Notes</label>
                    <textarea
                      value={adminDecision}
                      onChange={(e) => setAdminDecision(e.target.value)}
                      rows={4}
                      className="w-full p-3 text-sm bg-slate-955 border border-slate-900 rounded-xl text-slate-200 focus:outline-none focus:border-indigo-500 transition"
                      placeholder="Specify administrative decision rationale..."
                    />
                  </div>

                  <button
                    type="submit"
                    disabled={submitting}
                    className="w-full py-3 bg-indigo-600 hover:bg-indigo-500 text-white font-bold rounded-xl text-sm transition shadow-lg cursor-pointer disabled:opacity-50"
                  >
                    {submitting ? "Processing Resolution..." : "Execute Resolution Decision"}
                  </button>
                </>
              ) : (
                <div className="p-4 bg-slate-950 rounded-xl border border-slate-900 space-y-2">
                  <span className="px-2 py-0.5 rounded bg-slate-800 text-[10px] text-slate-400 font-semibold uppercase tracking-wider">
                    Resolved by {selectedDispute.resolvedByName}
                  </span>
                  <p className="text-xs text-slate-400 mt-2">Decision Decision Details:</p>
                  <p className="text-sm italic text-slate-300 mt-1">&ldquo;{selectedDispute.adminDecision}&rdquo;</p>
                </div>
              )}
            </form>
          ) : (
            <p className="text-sm text-slate-500 text-center py-12">
              Select an open dispute from the list to review claim evidence and resolve.
            </p>
          )}
        </div>
      </div>
    </div>
  );
}
