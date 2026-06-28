"use client";

import { useEffect, useState } from "react";
import {
  getAdminListings,
  toggleListingPause,
  deleteListing,
  approveListing,
  rejectListing,
} from "@/lib/api/admin";
import type { Listing } from "@/types/api";

export default function AdminListingsModeration() {
  const [activeTab, setActiveTab] = useState<"pending" | "moderated">("pending");
  const [listings, setListings] = useState<Listing[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [query, setQuery] = useState("");
  const [pausedFilter, setPausedFilter] = useState<string>("all");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [actionLoadingId, setActionLoadingId] = useState<string | null>(null);

  const pageSize = 15;

  function loadListings(
    currentPage: number,
    searchQuery: string,
    tab: "pending" | "moderated",
    filterState: string
  ) {
    setLoading(true);
    setError("");

    const isPaused =
      tab === "moderated"
        ? filterState === "paused"
          ? true
          : filterState === "active"
          ? false
          : undefined
        : undefined;

    const status = tab === "pending" ? "PendingApproval" : undefined;

    getAdminListings({
      page: currentPage,
      pageSize,
      query: searchQuery,
      isPaused,
      status,
    })
      .then((res) => {
        if (tab === "moderated") {
          // Only show Approved or Rejected, excluding PendingApproval
          setListings(res.items.filter((l) => l.status !== "PendingApproval"));
        } else {
          setListings(res.items);
        }
        setTotal(res.total);
      })
      .catch((err) => setError(err instanceof Error ? err.message : "Failed to load listings"))
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    const delayDebounceFn = setTimeout(() => {
      loadListings(page, query, activeTab, pausedFilter);
    }, 300);

    return () => clearTimeout(delayDebounceFn);
  }, [page, query, activeTab, pausedFilter]);

  async function handleApprove(listingId: string) {
    setActionLoadingId(listingId);
    try {
      await approveListing(listingId);
      setListings((prev) => prev.filter((l) => l.id !== listingId));
      setTotal((t) => Math.max(0, t - 1));
    } catch (err) {
      alert(err instanceof Error ? err.message : "Approval failed");
    } finally {
      setActionLoadingId(null);
    }
  }

  async function handleReject(listingId: string) {
    if (!confirm("Are you sure you want to reject this listing?")) {
      return;
    }
    setActionLoadingId(listingId);
    try {
      await rejectListing(listingId);
      setListings((prev) => prev.filter((l) => l.id !== listingId));
      setTotal((t) => Math.max(0, t - 1));
    } catch (err) {
      alert(err instanceof Error ? err.message : "Rejection failed");
    } finally {
      setActionLoadingId(null);
    }
  }

  async function handleTogglePause(listingId: string) {
    setActionLoadingId(listingId);
    try {
      await toggleListingPause(listingId);
      setListings((prev) =>
        prev.map((l) => (l.id === listingId ? { ...l, isPaused: !l.isPaused } : l))
      );
    } catch (err) {
      alert(err instanceof Error ? err.message : "Action failed");
    } finally {
      setActionLoadingId(null);
    }
  }

  async function handleDeleteListing(listingId: string) {
    if (
      !confirm(
        "Are you sure you want to delete this listing? This soft-deletes it and takes it off the platform permanently."
      )
    ) {
      return;
    }

    setActionLoadingId(listingId);
    try {
      await deleteListing(listingId);
      setListings((prev) => prev.filter((l) => l.id !== listingId));
      setTotal((t) => Math.max(0, t - 1));
    } catch (err) {
      alert(err instanceof Error ? err.message : "Failed to delete listing");
    } finally {
      setActionLoadingId(null);
    }
  }

  const totalPages = Math.ceil(total / pageSize);

  return (
    <div className="space-y-6">
      {/* Page Tabs */}
      <div className="flex border-b border-slate-800">
        <button
          onClick={() => {
            setActiveTab("pending");
            setPage(1);
          }}
          className={`px-6 py-3 text-sm font-semibold border-b-2 transition cursor-pointer ${
            activeTab === "pending"
              ? "border-teal-500 text-teal-400"
              : "border-transparent text-slate-400 hover:text-slate-200"
          }`}
        >
          Pending Verification Queue
        </button>
        <button
          onClick={() => {
            setActiveTab("moderated");
            setPage(1);
          }}
          className={`px-6 py-3 text-sm font-semibold border-b-2 transition cursor-pointer ${
            activeTab === "moderated"
              ? "border-teal-500 text-teal-400"
              : "border-transparent text-slate-400 hover:text-slate-200"
          }`}
        >
          Active & Moderated Listings
        </button>
      </div>

      {/* Search and Filters */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div className="flex flex-wrap gap-3 flex-1 max-w-2xl">
          <div className="relative flex-1 min-w-[200px]">
            <input
              type="text"
              placeholder="Search listings by title..."
              value={query}
              onChange={(e) => {
                setQuery(e.target.value);
                setPage(1);
              }}
              className="w-full rounded-xl border border-slate-800 bg-slate-900/40 px-4 py-2.5 pl-10 text-sm outline-none focus:border-teal-500 transition"
            />
            <span className="absolute left-3 top-3.5 text-slate-500 text-sm">🔍</span>
          </div>

          {activeTab === "moderated" && (
            <select
              value={pausedFilter}
              onChange={(e) => {
                setPausedFilter(e.target.value);
                setPage(1);
              }}
              className="rounded-xl border border-slate-800 bg-slate-900/40 px-4 py-2.5 text-sm text-slate-300 outline-none focus:border-teal-500 transition"
            >
              <option value="all">All Statuses</option>
              <option value="active">Active Only</option>
              <option value="paused">Paused Only</option>
            </select>
          )}
        </div>

        <div className="text-sm text-slate-400">
          Showing <span className="font-semibold text-slate-200">{listings.length}</span> of{" "}
          <span className="font-semibold text-slate-200">{total}</span> listings
        </div>
      </div>

      {/* Error Message */}
      {error && (
        <div className="p-4 bg-red-950/20 border border-red-800/40 rounded-xl text-red-400 text-sm">
          {error}
        </div>
      )}

      {/* Listings Table */}
      <div className="overflow-x-auto rounded-2xl border border-slate-800 bg-slate-900/10 backdrop-blur-md">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="border-b border-slate-800 bg-slate-900/40 text-slate-400 text-xs font-semibold uppercase">
              <th className="px-6 py-4">Image</th>
              <th className="px-6 py-4">Title</th>
              <th className="px-6 py-4">Owner</th>
              <th className="px-6 py-4">Category</th>
              <th className="px-6 py-4">Price / Day</th>
              <th className="px-6 py-4">District</th>
              <th className="px-6 py-4">Status</th>
              <th className="px-6 py-4 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800/60">
            {loading && listings.length === 0 ? (
              <tr>
                <td colSpan={8} className="px-6 py-12 text-center text-slate-500">
                  <div className="inline-block animate-spin rounded-full h-6 w-6 border-t-2 border-teal-500"></div>
                  <p className="mt-2 text-sm">Loading platform listings...</p>
                </td>
              </tr>
            ) : listings.length === 0 ? (
              <tr>
                <td colSpan={8} className="px-6 py-12 text-center text-slate-500 text-sm">
                  No listings found matching your search.
                </td>
              </tr>
            ) : (
              listings.map((listing) => {
                const isActionLoading = actionLoadingId === listing.id;
                const coverImage = listing.images && listing.images.length > 0 ? listing.images[0] : null;

                return (
                  <tr
                    key={listing.id}
                    className="hover:bg-slate-900/30 transition duration-150 text-sm"
                  >
                    <td className="px-6 py-4">
                      {coverImage ? (
                        <img
                          src={coverImage}
                          alt={listing.title}
                          className="w-12 h-12 object-cover rounded-lg border border-slate-800 bg-slate-950"
                        />
                      ) : (
                        <div className="w-12 h-12 bg-slate-900 border border-slate-850 rounded-lg flex items-center justify-center text-slate-600 text-xs">
                          No Pic
                        </div>
                      )}
                    </td>
                    <td className="px-6 py-4 font-semibold text-slate-200">
                      <div className="truncate max-w-[200px]">{listing.title}</div>
                      <span className="text-[10px] text-slate-500 block font-mono truncate max-w-[200px]">
                        ID: {listing.id}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-slate-400">
                      <div>
                        {listing.owner.firstName} {listing.owner.lastName}
                      </div>
                      <span className="text-[10px] text-slate-500 block">
                        KYC Level {listing.owner.verificationLevel}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-slate-400">{listing.category}</td>
                    <td className="px-6 py-4 font-semibold text-teal-400 font-mono">
                      LKR {listing.pricePerDay.toLocaleString()}
                    </td>
                    <td className="px-6 py-4 text-slate-400">{listing.district}</td>
                    <td className="px-6 py-4">
                      {listing.status === "PendingApproval" ? (
                        <span className="text-xs px-2.5 py-0.5 rounded-full font-semibold bg-amber-950/40 text-amber-400 border border-amber-500/20">
                          Pending Verification
                        </span>
                      ) : listing.status === "Rejected" ? (
                        <span className="text-xs px-2.5 py-0.5 rounded-full font-semibold bg-rose-950/40 text-rose-400 border border-rose-500/20">
                          Rejected
                        </span>
                      ) : listing.isPaused ? (
                        <span className="text-xs px-2.5 py-0.5 rounded-full font-semibold bg-slate-950/40 text-slate-400 border border-slate-500/20">
                          Paused
                        </span>
                      ) : (
                        <span className="text-xs px-2.5 py-0.5 rounded-full font-semibold bg-emerald-950/30 text-emerald-400 border border-emerald-500/20">
                          Active
                        </span>
                      )}
                    </td>
                    <td className="px-6 py-4 text-right space-x-2">
                      {listing.status === "PendingApproval" ? (
                        <>
                          <button
                            disabled={isActionLoading}
                            onClick={() => handleApprove(listing.id)}
                            className="text-xs px-3 py-1.5 rounded-lg border bg-emerald-950/10 border-emerald-900/30 text-emerald-400 hover:bg-emerald-950/20 hover:border-emerald-800 transition duration-150 cursor-pointer"
                          >
                            Approve
                          </button>
                          <button
                            disabled={isActionLoading}
                            onClick={() => handleReject(listing.id)}
                            className="text-xs px-3 py-1.5 rounded-lg border bg-rose-950/10 border-rose-900/30 text-rose-400 hover:bg-rose-950/20 hover:border-rose-800 transition duration-150 cursor-pointer"
                          >
                            Reject
                          </button>
                        </>
                      ) : (
                        <>
                          <button
                            disabled={isActionLoading}
                            onClick={() => handleTogglePause(listing.id)}
                            className={`text-xs px-3 py-1.5 rounded-lg border transition duration-150 cursor-pointer ${
                              listing.isPaused
                                ? "bg-emerald-950/10 border-emerald-900/30 text-emerald-400 hover:bg-emerald-950/20 hover:border-emerald-800"
                                : "bg-amber-950/10 border-amber-900/30 text-amber-400 hover:bg-amber-950/20 hover:border-amber-800"
                            }`}
                          >
                            {isActionLoading
                              ? "Wait..."
                              : listing.isPaused
                              ? "Activate"
                              : "Pause"}
                          </button>
                          <button
                            disabled={isActionLoading}
                            onClick={() => handleDeleteListing(listing.id)}
                            className="text-xs px-3 py-1.5 rounded-lg border bg-red-950/10 border-red-900/30 text-red-400 hover:bg-red-950/20 hover:border-red-800 transition duration-150 cursor-pointer"
                          >
                            {isActionLoading ? "..." : "Delete"}
                          </button>
                        </>
                      )}
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between border-t border-slate-800 pt-4">
          <button
            disabled={page === 1}
            onClick={() => setPage((p) => Math.max(1, p - 1))}
            className="px-4 py-2 text-sm rounded-lg border border-slate-800 hover:bg-slate-900 disabled:opacity-40 transition cursor-pointer"
          >
            Previous
          </button>
          <div className="text-sm text-slate-400">
            Page <span className="font-semibold text-slate-200">{page}</span> of{" "}
            <span className="font-semibold text-slate-200">{totalPages}</span>
          </div>
          <button
            disabled={page === totalPages}
            onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
            className="px-4 py-2 text-sm rounded-lg border border-slate-800 hover:bg-slate-900 disabled:opacity-40 transition cursor-pointer"
          >
            Next
          </button>
        </div>
      )}
    </div>
  );
}
