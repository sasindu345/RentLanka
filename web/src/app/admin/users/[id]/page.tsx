"use client";

import { use, useEffect, useState, useCallback } from "react";
import Link from "next/link";
import { getAdminUser, overrideUserVerification, toggleUserBan, getUserReviews } from "@/lib/api/admin";
import type { UserProfile, ReviewResponse } from "@/types/api";

export default function AdminUserDetail({ params }: { params: Promise<{ id: string }> }) {
  const { id: userId } = use(params);
  const [user, setUser] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [reviews, setReviews] = useState<ReviewResponse[]>([]);
  const [reviewsLoading, setReviewsLoading] = useState(true);
  
  // Form override states
  const [overrideLevel, setOverrideLevel] = useState<number>(0);
  const [overrideTrusted, setOverrideTrusted] = useState<boolean>(false);
  const [submitting, setSubmitting] = useState(false);
  const [banLoading, setBanLoading] = useState(false);

  const loadUser = useCallback(() => {
    setLoading(true);
    getAdminUser(userId)
      .then((res) => {
        setUser(res);
        setOverrideLevel(res.verificationLevel);
        setOverrideTrusted(res.isTrustedUser);
      })
      .catch((err) => setError(err instanceof Error ? err.message : "Failed to load user detail"))
      .finally(() => setLoading(false));
  }, [userId]);

  useEffect(() => {
    loadUser();
  }, [loadUser]);

  useEffect(() => {
    setReviewsLoading(true);
    getUserReviews(userId)
      .then((res) => setReviews(res))
      .catch((err) => console.error("Failed to load user reviews", err))
      .finally(() => setReviewsLoading(false));
  }, [userId]);

  async function handleOverride(e: React.FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    try {
      await overrideUserVerification(userId, {
        level: overrideLevel,
        isTrusted: overrideTrusted,
      });
      alert("Verification level overridden successfully.");
      loadUser();
    } catch (err) {
      alert(err instanceof Error ? err.message : "Failed to override verification");
    } finally {
      setSubmitting(false);
    }
  }

  async function handleToggleBan() {
    if (!user) return;
    if (!confirm(`Are you sure you want to ${user.isBanned ? "unban" : "ban"} this user?`)) {
      return;
    }

    setBanLoading(true);
    try {
      await toggleUserBan(userId);
      setUser((prev) => prev ? { ...prev, isBanned: !prev.isBanned } : null);
    } catch (err) {
      alert(err instanceof Error ? err.message : "Failed to update ban status");
    } finally {
      setBanLoading(false);
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-teal-500"></div>
      </div>
    );
  }

  if (error || !user) {
    return (
      <div className="space-y-4">
        <Link href="/admin/users" className="text-sm text-indigo-400 hover:underline">
          ← Back to Users List
        </Link>
        <div className="p-6 bg-red-950/20 border border-red-800/40 rounded-2xl text-red-400">
          <p className="font-semibold">Error Loading Detail</p>
          <p className="text-sm mt-1">{error || "User data is missing"}</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Breadcrumb */}
      <div>
        <Link href="/admin/users" className="text-sm text-slate-400 hover:text-indigo-400 transition flex items-center gap-1">
          <span>←</span> Back to Users List
        </Link>
        <h2 className="text-2xl font-bold mt-3 text-slate-100">
          {user.firstName} {user.lastName}
        </h2>
        <p className="text-xs text-slate-500 font-mono mt-1">ID: {user.id}</p>
      </div>

      <div className="grid gap-8 lg:grid-cols-3">
        {/* Profile Card */}
        <div className="lg:col-span-2 space-y-6">
          <div className="rounded-2xl border border-slate-800 bg-slate-900/10 p-6 backdrop-blur-md space-y-6">
            <h3 className="text-lg font-bold text-slate-200 border-b border-slate-800 pb-3">
              Account Information
            </h3>
            
            <div className="grid gap-6 sm:grid-cols-2">
              <div>
                <p className="text-xs text-slate-500 uppercase font-semibold">Email Address</p>
                <p className="text-sm text-slate-200 mt-1 font-mono">{user.email}</p>
              </div>

              <div>
                <p className="text-xs text-slate-500 uppercase font-semibold">Phone Number</p>
                <p className="text-sm text-slate-200 mt-1 font-mono">{user.phoneNumber || "Not provided"}</p>
              </div>

              <div>
                <p className="text-xs text-slate-500 uppercase font-semibold">Registration Date</p>
                <p className="text-sm text-slate-200 mt-1">
                  {new Date(user.createdAt).toLocaleDateString("en-US", {
                    year: "numeric",
                    month: "long",
                    day: "numeric",
                  })}
                </p>
              </div>

              <div>
                <p className="text-xs text-slate-500 uppercase font-semibold">Current System Role</p>
                <p className="mt-1">
                  <span className={`text-xs px-2.5 py-0.5 rounded-full font-medium ${
                    user.role === "Admin"
                      ? "bg-purple-500/10 text-purple-400 border border-purple-500/20"
                      : "bg-slate-800 text-slate-400"
                  }`}>
                    {user.role}
                  </span>
                </p>
              </div>
            </div>
          </div>

          {/* KYC Details Card (NIC Number + Doc Link) */}
          <div className="rounded-2xl border border-slate-800 bg-slate-900/10 p-6 backdrop-blur-md space-y-6">
            <h3 className="text-lg font-bold text-slate-200 border-b border-slate-800 pb-3">
              KYC / Identity Documents
            </h3>
            
            {user.verificationLevel >= 2 ? (
              <div className="space-y-6">
                <div>
                  <p className="text-xs text-slate-500 uppercase font-semibold">Submitted NIC Number</p>
                  <p className="text-sm font-semibold text-slate-200 mt-1">{user.nicNumber || "Not found"}</p>
                </div>
                
                {user.nicDocumentUrl ? (
                  <div>
                    <p className="text-xs text-slate-500 uppercase font-semibold mb-2">Uploaded Document</p>
                    <a
                      href={user.nicDocumentUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="inline-flex items-center gap-2 text-xs font-semibold px-4 py-2.5 rounded-xl border border-slate-800 bg-slate-900/60 hover:bg-slate-800/40 text-indigo-400 hover:text-indigo-300 transition duration-150"
                    >
                      📎 View Document Attachment <span>↗</span>
                    </a>
                  </div>
                ) : (
                  <p className="text-sm text-slate-500 italic">No document file URL was uploaded.</p>
                )}
              </div>
            ) : (
              <div className="py-4 text-center">
                <span className="text-3xl text-slate-600 block">📭</span>
                <p className="text-sm text-slate-500 mt-2">
                  User has not submitted National Identity Card (NIC) details yet.
                </p>
              </div>
            )}
          </div>

          {/* User Reviews Card */}
          <div className="rounded-2xl border border-slate-800 bg-slate-900/10 p-6 backdrop-blur-md space-y-6">
            <h3 className="text-lg font-bold text-slate-200 border-b border-slate-800 pb-3">
              User Reviews & Ratings
            </h3>

            {reviewsLoading ? (
              <div className="flex justify-center py-6">
                <div className="animate-spin rounded-full h-6 w-6 border-t-2 border-indigo-500"></div>
              </div>
            ) : reviews.length === 0 ? (
              <p className="text-sm text-slate-500 text-center py-4">No reviews have been left for this user yet.</p>
            ) : (
              <div className="space-y-4">
                {reviews.map((r) => (
                  <div key={r.id} className="p-4 rounded-xl border border-slate-800 bg-slate-900/30 space-y-2">
                    <div className="flex items-center justify-between">
                      <div>
                        <span className="text-sm font-semibold text-slate-200">{r.reviewerName}</span>
                        <span className="text-xs text-slate-500 ml-2">
                          ({r.isRenterReview ? "Renter Review" : "Owner Review"})
                        </span>
                      </div>
                      <div className="text-yellow-500 font-bold font-mono text-sm">
                        {"★".repeat(r.rating)}
                        {"☆".repeat(5 - r.rating)}
                      </div>
                    </div>
                    {r.comment && (
                      <p className="text-sm text-slate-300 italic">&ldquo;{r.comment}&rdquo;</p>
                    )}
                    <p className="text-[10px] text-slate-500 font-mono">
                      Date: {new Date(r.createdAt).toLocaleDateString()} · Booking ID: {r.bookingId}
                    </p>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Administration / Controls Column */}
        <div className="space-y-6">
          {/* Quick Stats Panel */}
          <div className="rounded-2xl border border-slate-800 bg-slate-900/10 p-6 backdrop-blur-md space-y-4">
            <h3 className="text-sm font-bold text-slate-400 uppercase tracking-wider">
              Status Overview
            </h3>
            <div className="flex flex-col gap-3">
              <div className="flex items-center justify-between p-3 rounded-xl bg-slate-900/40 border border-slate-800/60">
                <span className="text-xs text-slate-400 font-medium">Banned Status</span>
                {user.isBanned ? (
                  <span className="text-xs px-2.5 py-0.5 rounded-full font-bold bg-red-950/40 text-red-400 border border-red-500/20">
                    Banned
                  </span>
                ) : (
                  <span className="text-xs px-2.5 py-0.5 rounded-full font-bold bg-emerald-950/40 text-emerald-400 border border-emerald-500/20">
                    Active
                  </span>
                )}
              </div>

              <div className="flex items-center justify-between p-3 rounded-xl bg-slate-900/40 border border-slate-800/60">
                <span className="text-xs text-slate-400 font-medium">Trusted Badge</span>
                {user.isTrustedUser ? (
                  <span className="text-xs px-2.5 py-0.5 rounded-full font-bold bg-indigo-950/40 text-indigo-400 border border-indigo-500/20">
                    Trusted 🛡️
                  </span>
                ) : (
                  <span className="text-xs px-2.5 py-0.5 rounded-full font-bold bg-slate-800 text-slate-400 border border-slate-700/60">
                    Standard
                  </span>
                )}
              </div>
            </div>

            {user.role !== "Admin" && (
              <button
                disabled={banLoading}
                onClick={handleToggleBan}
                className={`w-full py-2.5 rounded-xl border font-bold text-sm transition duration-150 cursor-pointer ${
                  user.isBanned
                    ? "bg-emerald-900/20 border-emerald-800/60 text-emerald-400 hover:bg-emerald-900/30"
                    : "bg-red-900/20 border-red-800/60 text-red-400 hover:bg-red-900/30"
                }`}
              >
                {banLoading ? "Please wait..." : user.isBanned ? "Unban Account" : "Ban Account"}
              </button>
            )}
          </div>

          {/* Verification Level Override form */}
          <div className="rounded-2xl border border-slate-800 bg-slate-900/10 p-6 backdrop-blur-md space-y-4">
            <h3 className="text-sm font-bold text-slate-200 border-b border-slate-800 pb-3">
              Manual Override
            </h3>

            <form onSubmit={handleOverride} className="space-y-4">
              <label className="flex flex-col gap-1.5 text-xs text-slate-400 font-semibold uppercase">
                Verification level
                <select
                  value={overrideLevel}
                  onChange={(e) => setOverrideLevel(Number(e.target.value))}
                  className="rounded-xl border border-slate-800 bg-slate-955 px-4 py-2.5 text-sm text-slate-200 outline-none focus:border-indigo-500 transition mt-1"
                >
                  <option value={-1}>Unverified (-1)</option>
                  <option value={0}>L0: Email Verified (0)</option>
                  <option value={1}>L1: Phone Verified (1)</option>
                  <option value={2}>L2: NIC Submitted (2)</option>
                  <option value={3}>L3: Face Verified / Trusted (3)</option>
                </select>
              </label>

              <label className="flex items-center gap-3 p-3 rounded-xl border border-slate-800/60 bg-slate-900/30 cursor-pointer select-none">
                <input
                  type="checkbox"
                  checked={overrideTrusted}
                  onChange={(e) => setOverrideTrusted(e.target.checked)}
                  className="w-4 h-4 accent-indigo-500 rounded border-slate-700 bg-slate-950"
                />
                <span className="text-sm text-slate-300 font-medium">Grant Trusted User Badge</span>
              </label>

              <button
                type="submit"
                disabled={submitting}
                className="w-full py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-sm transition duration-150 cursor-pointer"
              >
                {submitting ? "Saving..." : "Save Override"}
              </button>
            </form>
          </div>
        </div>
      </div>
    </div>
  );
}
