"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { getAdminDashboardStats } from "@/lib/api/admin";
import type { AdminDashboardStats } from "@/types/api";

export default function AdminDashboardOverview() {
  const [stats, setStats] = useState<AdminDashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    getAdminDashboardStats()
      .then(setStats)
      .catch((err) => setError(err instanceof Error ? err.message : "Failed to load dashboard metrics"))
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[300px]">
        <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-indigo-500"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-6 bg-red-950/20 border border-red-800/40 rounded-2xl text-red-400">
        <p className="font-semibold">Error Loading Overview</p>
        <p className="text-sm mt-1">{error}</p>
      </div>
    );
  }

  const kpis = [
    {
      label: "Total Users",
      value: stats?.totalUsers ?? 0,
      icon: "👥",
      color: "from-blue-500/10 to-indigo-500/10 border-blue-500/20 text-blue-400",
      description: "Registered Renters & Owners",
      link: "/admin/users",
    },
    {
      label: "Active Listings",
      value: stats?.activeListings ?? 0,
      icon: "🏷️",
      color: "from-indigo-500/10 to-violet-500/10 border-indigo-500/20 text-indigo-400",
      description: "Gear listed and open for booking",
      link: "/admin/listings",
    },
    {
      label: "Pending KYC Queue",
      value: stats?.pendingKycCount ?? 0,
      icon: "📄",
      color: "from-amber-500/10 to-orange-500/10 border-amber-500/20 text-amber-400",
      description: "NIC verification documents to review",
      link: "/admin/kyc",
    },
    {
      label: "Total Bookings",
      value: stats?.totalBookingsCount ?? 0,
      icon: "📅",
      color: "from-violet-500/10 to-purple-500/10 border-violet-500/20 text-violet-400",
      description: "Bookings created (Escrow active)",
      link: "#",
    },
    {
      label: "Open Disputes",
      value: stats?.openDisputesCount ?? 0,
      icon: "⚠️",
      color: "from-rose-500/10 to-red-500/10 border-rose-500/20 text-rose-400",
      description: "Deposit disputes under review",
      link: "#",
    },
  ];

  return (
    <div className="space-y-8">
      {/* Intro */}
      <div>
        <h2 className="text-2xl font-bold text-slate-100">Platform Health & KPIs</h2>
        <p className="text-slate-400 mt-1">Real-time statistics across the RentLanka ecosystem.</p>
      </div>

      {/* KPI Grid */}
      <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
        {kpis.map((kpi, idx) => (
          <div
            key={idx}
            className={`rounded-2xl border bg-gradient-to-br p-6 shadow-sm flex flex-col justify-between transition hover:-translate-y-1 hover:shadow-md hover:border-slate-700/60 duration-200 ${kpi.color.split(" ")[0]} ${kpi.color.split(" ")[1]} ${kpi.color.split(" ")[2]}`}
          >
            <div>
              <div className="flex items-center justify-between">
                <span className="text-sm font-medium text-slate-400">{kpi.label}</span>
                <span className="text-2xl">{kpi.icon}</span>
              </div>
              <p className="text-4xl font-extrabold tracking-tight mt-4 text-slate-100">
                {kpi.value.toLocaleString()}
              </p>
            </div>
            <div className="mt-6 pt-4 border-t border-slate-800/60 flex items-center justify-between">
              <span className="text-xs text-slate-500">{kpi.description}</span>
              {kpi.link !== "#" && (
                <Link
                  href={kpi.link}
                  className={`text-xs font-semibold hover:underline flex items-center gap-1 ${kpi.color.split(" ")[3]}`}
                >
                  Manage <span>→</span>
                </Link>
              )}
            </div>
          </div>
        ))}
      </div>

      {/* Operations Quicklinks */}
      <div className="rounded-2xl border border-slate-800 bg-slate-900/20 p-6 backdrop-blur-md">
        <h3 className="text-lg font-bold text-slate-200">Pending Actions</h3>
        <div className="mt-4 grid gap-4 md:grid-cols-2">
          {stats && stats.pendingKycCount > 0 ? (
            <Link
              href="/admin/kyc"
              className="flex items-center justify-between p-4 rounded-xl bg-slate-900/60 border border-slate-800 hover:border-amber-500/30 hover:bg-slate-800/40 transition duration-200"
            >
              <div className="flex items-center gap-3">
                <span className="text-xl">📄</span>
                <div>
                  <p className="text-sm font-semibold text-slate-200">
                    Review {stats.pendingKycCount} verification requests
                  </p>
                  <p className="text-xs text-slate-500">KYC Verification queue is waiting</p>
                </div>
              </div>
              <span className="text-amber-400 font-bold">→</span>
            </Link>
          ) : (
            <div className="flex items-center gap-3 p-4 rounded-xl bg-slate-900/40 border border-slate-800/50">
              <span className="text-xl">✅</span>
              <div>
                <p className="text-sm font-semibold text-slate-400">KYC verification queue is clear</p>
                <p className="text-xs text-slate-600">No pending document approvals</p>
              </div>
            </div>
          )}

          <Link
            href="/admin/listings"
            className="flex items-center justify-between p-4 rounded-xl bg-slate-900/60 border border-slate-800 hover:border-indigo-500/30 hover:bg-slate-800/40 transition duration-200"
          >
            <div className="flex items-center gap-3">
              <span className="text-xl">🛡️</span>
              <div>
                <p className="text-sm font-semibold text-slate-200">Moderate Listings</p>
                <p className="text-xs text-slate-500">Scan and flag inappropriate user content</p>
              </div>
            </div>
            <span className="text-indigo-400 font-bold">→</span>
          </Link>
        </div>
      </div>
    </div>
  );
}
