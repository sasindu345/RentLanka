"use client";

import { useEffect, useState } from "react";
import { getAdminBookings } from "@/lib/api/admin";
import type { BookingResponse } from "@/types/api";

export default function AdminBookingsOversight() {
  const [bookings, setBookings] = useState<BookingResponse[]>([]);
  const [filteredBookings, setFilteredBookings] = useState<BookingResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  
  // Filters
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");

  function loadBookings() {
    setLoading(true);
    setError("");
    getAdminBookings()
      .then((res) => {
        setBookings(res);
        setFilteredBookings(res);
      })
      .catch((err) => {
        setError(err instanceof Error ? err.message : "Failed to load bookings database");
      })
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    loadBookings();
  }, []);

  useEffect(() => {
    let result = bookings;

    if (statusFilter !== "all") {
      result = result.filter(b => b.status.toLowerCase() === statusFilter.toLowerCase());
    }

    if (searchQuery.trim() !== "") {
      const q = searchQuery.toLowerCase();
      result = result.filter(
        b =>
          b.listingTitle.toLowerCase().includes(q) ||
          b.renterName.toLowerCase().includes(q) ||
          b.ownerName.toLowerCase().includes(q) ||
          b.id.toLowerCase().includes(q)
      );
    }

    setFilteredBookings(result);
  }, [searchQuery, statusFilter, bookings]);

  function getStatusStyle(status: string) {
    switch (status.toLowerCase()) {
      case "pending":
        return "bg-amber-500/10 text-amber-400 border border-amber-500/20";
      case "approved":
        return "bg-blue-500/10 text-blue-400 border border-blue-500/20";
      case "paid":
        return "bg-teal-500/10 text-teal-400 border border-teal-500/20";
      case "active":
        return "bg-green-500/10 text-green-400 border border-green-500/20";
      case "completed":
        return "bg-slate-500/10 text-slate-400 border border-slate-500/20";
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
          <h2 className="text-xl font-bold text-slate-100">Platform Bookings</h2>
          <p className="text-slate-400 text-sm mt-1">
            Oversight of all rental activities, statuses, and transaction details across the platform.
          </p>
        </div>
        <button
          onClick={loadBookings}
          className="self-start px-4 py-2 bg-slate-900 border border-slate-800 hover:border-slate-700 rounded-xl text-slate-300 text-xs font-semibold hover:text-slate-100 transition duration-150 cursor-pointer"
        >
          🔄 Refresh Data
        </button>
      </div>

      {error && (
        <div className="p-4 bg-red-950/20 border border-red-800/40 rounded-xl text-red-400 text-sm">
          {error}
        </div>
      )}

      {/* Filter Bar */}
      <div className="flex flex-col md:flex-row gap-4 items-center bg-slate-900/40 border border-slate-800 p-4 rounded-2xl backdrop-blur-md">
        <div className="flex-1 w-full relative">
          <input
            type="text"
            placeholder="Search by listing, renter, owner, or booking ID..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-4 pr-10 py-2.5 bg-slate-950 border border-slate-800 focus:border-teal-500 rounded-xl text-slate-200 text-sm outline-none placeholder-slate-600 transition"
          />
        </div>
        <div className="w-full md:w-48">
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="w-full px-4 py-2.5 bg-slate-950 border border-slate-800 focus:border-teal-500 rounded-xl text-slate-200 text-sm outline-none transition cursor-pointer"
          >
            <option value="all">All Statuses</option>
            <option value="pending">Pending</option>
            <option value="approved">Approved</option>
            <option value="paid">Paid</option>
            <option value="active">Active</option>
            <option value="completed">Completed</option>
            <option value="rejected">Rejected</option>
          </select>
        </div>
      </div>

      {/* Table grid */}
      <div className="rounded-2xl border border-slate-800 bg-slate-900/10 backdrop-blur-md overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center min-h-[300px]">
            <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-teal-500"></div>
          </div>
        ) : filteredBookings.length === 0 ? (
          <div className="p-12 text-center text-slate-500">
            <span className="text-3xl">📅</span>
            <p className="mt-4 text-sm font-semibold text-slate-400">No bookings match the current filter.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full border-collapse text-left">
              <thead>
                <tr className="border-b border-slate-800 bg-slate-900/40 text-slate-400 text-xs font-bold uppercase tracking-wider">
                  <th className="px-6 py-4">Booking ID</th>
                  <th className="px-6 py-4">Listing Title</th>
                  <th className="px-6 py-4">Renter / Owner</th>
                  <th className="px-6 py-4">Rental Dates</th>
                  <th className="px-6 py-4">Financials</th>
                  <th className="px-6 py-4">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/50 text-sm text-slate-300">
                {filteredBookings.map((b) => {
                  return (
                    <tr key={b.id} className="hover:bg-slate-900/30 transition-colors">
                      <td className="px-6 py-4">
                        <span className="font-mono text-xs text-slate-500 block">
                          #{b.id.substring(0, 8)}
                        </span>
                        <span className="text-[10px] text-slate-600">
                          {new Date(b.createdAt).toLocaleDateString()}
                        </span>
                      </td>
                      <td className="px-6 py-4 font-semibold text-slate-100">
                        {b.listingTitle}
                      </td>
                      <td className="px-6 py-4 space-y-1">
                        <div className="flex items-center gap-1.5">
                          <span className="text-[10px] uppercase font-bold text-teal-500 px-1 bg-teal-950/40 rounded">R</span>
                          <span>{b.renterName}</span>
                        </div>
                        <div className="flex items-center gap-1.5">
                          <span className="text-[10px] uppercase font-bold text-amber-500 px-1 bg-amber-950/40 rounded">O</span>
                          <span>{b.ownerName}</span>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="text-slate-200">
                          {new Date(b.startDate).toLocaleDateString()} - {new Date(b.endDate).toLocaleDateString()}
                        </div>
                        <span className="text-xs text-slate-500">
                          {Math.max(1, Math.round((new Date(b.endDate).getTime() - new Date(b.startDate).getTime()) / (1000 * 3600 * 24)))} days
                        </span>
                      </td>
                      <td className="px-6 py-4 text-xs space-y-0.5">
                        <div className="flex justify-between max-w-[140px]">
                          <span className="text-slate-500">Rent Fee:</span>
                          <span className="text-slate-200">{formatPrice(b.totalPrice)}</span>
                        </div>
                        <div className="flex justify-between max-w-[140px]">
                          <span className="text-slate-500">Deposit:</span>
                          <span className="text-slate-200">{formatPrice(b.securityDeposit)}</span>
                        </div>
                        <div className="flex justify-between max-w-[140px] font-bold border-t border-slate-800/80 pt-0.5">
                          <span className="text-slate-400">Total:</span>
                          <span className="text-teal-400">{formatPrice(b.totalPrice + b.securityDeposit)}</span>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <span className={`px-2.5 py-1 rounded-full text-xs font-semibold ${getStatusStyle(b.status)}`}>
                          {b.status}
                        </span>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
