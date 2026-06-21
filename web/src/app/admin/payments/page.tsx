"use client";

import { useEffect, useState } from "react";
import { getAdminPayments, getAdminPayouts, approveAdminPayout } from "@/lib/api/admin";
import type { PaymentResponse, PayoutResponse } from "@/types/api";

export default function AdminFinancialLedger() {
  const [activeTab, setActiveTab] = useState<"payments" | "payouts">("payments");
  const [payments, setPayments] = useState<PaymentResponse[]>([]);
  const [payouts, setPayouts] = useState<PayoutResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [error, setError] = useState("");

  function loadFinancialData() {
    setLoading(true);
    setError("");
    
    Promise.all([getAdminPayments(), getAdminPayouts()])
      .then(([paymentsData, payoutsData]) => {
        setPayments(paymentsData);
        setPayouts(payoutsData);
      })
      .catch((err) => {
        setError(err instanceof Error ? err.message : "Failed to load financial records");
      })
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    loadFinancialData();
  }, []);

  async function handleApprovePayout(payoutId: string, amount: number, hostName: string) {
    if (!confirm(`Are you sure you want to approve this payout of LKR ${amount.toLocaleString()} to ${hostName}? This confirms bank transfer completion.`)) {
      return;
    }

    setActionLoading(true);
    try {
      await approveAdminPayout(payoutId);
      alert("Payout request approved successfully.");
      loadFinancialData();
    } catch (err) {
      alert(err instanceof Error ? err.message : "Payout approval failed");
    } finally {
      setActionLoading(false);
    }
  }

  function getPaymentStatusStyle(status: string) {
    switch (status.toLowerCase()) {
      case "authorized":
        return "bg-blue-500/10 text-blue-400 border border-blue-500/20";
      case "captured":
        return "bg-teal-500/10 text-teal-400 border border-teal-500/20";
      case "released":
        return "bg-green-500/10 text-green-400 border border-green-500/20";
      default:
        return "bg-slate-800 text-slate-300";
    }
  }

  function getPayoutStatusStyle(status: string) {
    switch (status.toLowerCase()) {
      case "pending":
        return "bg-amber-500/10 text-amber-400 border border-amber-500/20";
      case "paid":
        return "bg-green-500/10 text-green-400 border border-green-500/20";
      case "rejected":
        return "bg-red-500/10 text-red-400 border border-red-500/20";
      default:
        return "bg-slate-800 text-slate-300";
    }
  }

  function formatPrice(amount: number) {
    return `LKR ${amount.toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 0 })}`;
  }

  return (
    <div className="space-y-6">
      {/* Intro */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold text-slate-100">Financial Ledger</h2>
          <p className="text-slate-400 text-sm mt-1">
            Audit mock transactions on the escrow system and process withdrawal requests from hosts.
          </p>
        </div>
        <button
          onClick={loadFinancialData}
          className="self-start px-4 py-2 bg-slate-900 border border-slate-800 hover:border-slate-700 rounded-xl text-slate-300 text-xs font-semibold hover:text-slate-100 transition duration-150 cursor-pointer"
        >
          🔄 Refresh Ledger
        </button>
      </div>

      {error && (
        <div className="p-4 bg-red-950/20 border border-red-800/40 rounded-xl text-red-400 text-sm">
          {error}
        </div>
      )}

      {/* Tabs */}
      <div className="flex border-b border-slate-800">
        <button
          onClick={() => setActiveTab("payments")}
          className={`px-6 py-3 text-sm font-semibold border-b-2 transition duration-150 cursor-pointer ${
            activeTab === "payments"
              ? "border-teal-500 text-teal-400 bg-teal-950/10"
              : "border-transparent text-slate-400 hover:text-slate-200"
          }`}
        >
          💳 Escrow Payments Log ({payments.length})
        </button>
        <button
          onClick={() => setActiveTab("payouts")}
          className={`px-6 py-3 text-sm font-semibold border-b-2 transition duration-150 cursor-pointer ${
            activeTab === "payouts"
              ? "border-teal-500 text-teal-400 bg-teal-950/10"
              : "border-transparent text-slate-400 hover:text-slate-200"
          }`}
        >
          💰 Host Withdrawal Requests ({payouts.length})
        </button>
      </div>

      {/* Tables Grid */}
      <div className="rounded-2xl border border-slate-800 bg-slate-900/10 backdrop-blur-md overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center min-h-[300px]">
            <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-teal-500"></div>
          </div>
        ) : activeTab === "payments" ? (
          /* ESCROW PAYMENTS */
          payments.length === 0 ? (
            <div className="p-12 text-center text-slate-500">No payment logs found on the database.</div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full border-collapse text-left">
                <thead>
                  <tr className="border-b border-slate-800 bg-slate-900/40 text-slate-400 text-xs font-bold uppercase tracking-wider">
                    <th className="px-6 py-4">Transaction Details</th>
                    <th className="px-6 py-4">Booking Details</th>
                    <th className="px-6 py-4">Renter Name</th>
                    <th className="px-6 py-4">Total Authorized</th>
                    <th className="px-6 py-4">Transaction Reference</th>
                    <th className="px-6 py-4">Escrow Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800/50 text-sm text-slate-300">
                  {payments.map((p) => (
                    <tr key={p.id} className="hover:bg-slate-900/20 transition-colors">
                      <td className="px-6 py-4">
                        <span className="font-mono text-xs text-slate-500 block">#{p.id.substring(0, 8)}</span>
                        <span className="text-[10px] text-slate-650">{new Date(p.createdAt).toLocaleDateString()}</span>
                      </td>
                      <td className="px-6 py-4">
                        <span className="font-semibold text-slate-200 block">{p.listingTitle}</span>
                        <span className="font-mono text-xs text-slate-500">Booking: #{p.bookingId.substring(0, 8)}</span>
                      </td>
                      <td className="px-6 py-4">{p.renterName}</td>
                      <td className="px-6 py-4 font-bold text-teal-400">{formatPrice(p.amount)}</td>
                      <td className="px-6 py-4">
                        <span className="font-mono text-xs bg-slate-950 px-2 py-1 border border-slate-850 rounded text-slate-400">
                          {p.transactionReference}
                        </span>
                      </td>
                      <td className="px-6 py-4">
                        <span className={`px-2.5 py-1 rounded-full text-xs font-semibold ${getPaymentStatusStyle(p.status)}`}>
                          {p.status}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )
        ) : (
          /* HOST WITHDRAWALS */
          payouts.length === 0 ? (
            <div className="p-12 text-center text-slate-500">No payout requests submitted yet.</div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full border-collapse text-left">
                <thead>
                  <tr className="border-b border-slate-800 bg-slate-900/40 text-slate-400 text-xs font-bold uppercase tracking-wider">
                    <th className="px-6 py-4">Payout Details</th>
                    <th className="px-6 py-4">Host Name</th>
                    <th className="px-6 py-4">Withdrawal Amount</th>
                    <th className="px-6 py-4">Bank Details</th>
                    <th className="px-6 py-4">Status</th>
                    <th className="px-6 py-4 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800/50 text-sm text-slate-300">
                  {payouts.map((po) => (
                    <tr key={po.id} className="hover:bg-slate-900/20 transition-colors">
                      <td className="px-6 py-4">
                        <span className="font-mono text-xs text-slate-500 block">#{po.id.substring(0, 8)}</span>
                        <span className="text-[10px] text-slate-650">{new Date(po.createdAt).toLocaleDateString()}</span>
                      </td>
                      <td className="px-6 py-4 font-semibold text-slate-200">{po.ownerName}</td>
                      <td className="px-6 py-4 font-bold text-emerald-400">{formatPrice(po.amount)}</td>
                      <td className="px-6 py-4 text-xs space-y-0.5">
                        <div><span className="text-slate-500">Bank:</span> <span className="font-semibold text-slate-300">{po.bankName}</span></div>
                        <div><span className="text-slate-500">Acc No:</span> <span className="font-mono font-semibold text-slate-300">{po.accountNumber}</span></div>
                        <div><span className="text-slate-500">Acc Name:</span> <span className="font-semibold text-slate-300">{po.accountName}</span></div>
                      </td>
                      <td className="px-6 py-4">
                        <span className={`px-2.5 py-1 rounded-full text-xs font-semibold ${getPayoutStatusStyle(po.status)}`}>
                          {po.status}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-right">
                        {po.status.toLowerCase() === "pending" ? (
                          <button
                            disabled={actionLoading}
                            onClick={() => handleApprovePayout(po.id, po.amount, po.ownerName)}
                            className="px-3.5 py-1.5 bg-teal-500 hover:bg-teal-600 disabled:opacity-50 text-slate-950 font-bold text-xs rounded-xl shadow-lg transition duration-150 cursor-pointer"
                          >
                            💸 Confirm Transfer
                          </button>
                        ) : (
                          <span className="text-slate-500 text-xs">-</span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )
        )}
      </div>
    </div>
  );
}
