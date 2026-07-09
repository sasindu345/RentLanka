"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { getAdminDashboardStats } from "@/lib/api/admin";
import type { AdminDashboardStats } from "@/types/api";

interface ChartPoint {
  label: string;
  bookings: number;
  revenue: number;
  date: string;
}

export default function AdminDashboardOverview() {
  const [stats, setStats] = useState<AdminDashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  
  // Chart interaction states
  const [activeTab, setActiveTab] = useState<"7d" | "30d">("30d");
  const [metricType, setMetricType] = useState<"bookings" | "revenue">("revenue");
  const [hoveredPoint, setHoveredPoint] = useState<ChartPoint | null>(null);
  const [hoveredIndex, setHoveredIndex] = useState<number | null>(null);

  useEffect(() => {
    getAdminDashboardStats()
      .then(setStats)
      .catch((err) => setError(err instanceof Error ? err.message : "Failed to load dashboard metrics"))
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
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

  // Simulated metrics data
  const data7d: ChartPoint[] = [
    { label: "Mon", bookings: 1, revenue: 3500, date: "July 2" },
    { label: "Tue", bookings: 2, revenue: 7200, date: "July 3" },
    { label: "Wed", bookings: 1, revenue: 4100, date: "July 4" },
    { label: "Thu", bookings: 3, revenue: 12500, date: "July 5" },
    { label: "Fri", bookings: 4, revenue: 16800, date: "July 6" },
    { label: "Sat", bookings: 2, revenue: 9500, date: "July 7" },
    { label: "Sun", bookings: stats?.totalBookingsCount ?? 5, revenue: (stats?.totalBookingsCount ?? 5) * 4500, date: "July 8 (Today)" },
  ];

  const data30d: ChartPoint[] = [
    { label: "W1", bookings: 4, revenue: 18000, date: "June 9 - June 15" },
    { label: "W2", bookings: 8, revenue: 36500, date: "June 16 - June 22" },
    { label: "W3", bookings: 14, revenue: 64200, date: "June 23 - June 29" },
    { label: "W4", bookings: 22, revenue: 98400, date: "June 30 - July 6" },
    { label: "W5", bookings: stats?.totalBookingsCount ?? 26, revenue: (stats?.totalBookingsCount ?? 26) * 4800, date: "July 7 - July 8" },
  ];

  const chartData = activeTab === "7d" ? data7d : data30d;

  // Scales for Area Chart
  const maxBookings = Math.max(...chartData.map((d) => d.bookings), 1);
  const maxRevenue = Math.max(...chartData.map((d) => d.revenue), 1);
  const maxVal = metricType === "bookings" ? maxBookings : maxRevenue;

  const svgWidth = 600;
  const svgHeight = 200;
  const paddingX = 40;
  const paddingY = 20;

  const points = chartData.map((d, i) => {
    const val = metricType === "bookings" ? d.bookings : d.revenue;
    const x = paddingX + (i / (chartData.length - 1)) * (svgWidth - paddingX * 2);
    const y = svgHeight - paddingY - (val / maxVal) * (svgHeight - paddingY * 2);
    return { x, y, data: d };
  });

  const linePath = points.map((p, i) => `${i === 0 ? "M" : "L"} ${p.x} ${p.y}`).join(" ");
  const areaPath = `${linePath} L ${points[points.length - 1].x} ${svgHeight - paddingY} L ${points[0].x} ${svgHeight - paddingY} Z`;

  // Clean, consistent visual KPI cards (no sparklines, flat styling)
  const kpis = [
    {
      label: "Total Registered Users",
      value: stats?.totalUsers ?? 0,
      description: "Renters & Equipment Owners",
      link: "/admin/users",
    },
    {
      label: "Active Listings",
      value: stats?.activeListings ?? 0,
      description: "Gear listed for rental bookings",
      link: "/admin/listings",
    },
    {
      label: "Pending KYC Verifications",
      value: stats?.pendingKycCount ?? 0,
      description: "Identity documents awaiting audit",
      link: "/admin/kyc",
    },
    {
      label: "Total Rental Bookings",
      value: stats?.totalBookingsCount ?? 0,
      description: "All time completed & active contracts",
      link: "#",
    },
    {
      label: "Open Disputes",
      value: stats?.openDisputesCount ?? 0,
      description: "Decisions holding security deposits",
      link: "#",
    },
  ];

  const categories = [
    { label: "Vehicles & Transport", count: 4, percentage: 36, color: "bg-indigo-500" },
    { label: "Power Tools & Construction", count: 3, percentage: 27, color: "bg-emerald-500" },
    { label: "Cameras & Optic Gear", count: 2, percentage: 18, color: "bg-amber-500" },
    { label: "Camping & Outdoor", count: 1, percentage: 9, color: "bg-sky-500" },
    { label: "Event & Party Supplies", count: 1, percentage: 10, color: "bg-rose-500" },
  ];

  // User Verification Distribution Pie Segment Data (Total: 440 circumference)
  const verifications = [
    { label: "Fully Trusted (KYC Verified)", percentage: 40, color: "bg-indigo-500", stroke: "stroke-indigo-500", dash: "176 440", offset: "0" },
    { label: "Basic Authenticated (Email/Phone)", percentage: 45, color: "bg-emerald-500", stroke: "stroke-emerald-500", dash: "198 440", offset: "-176" },
    { label: "Unverified (New Registrants)", percentage: 15, color: "bg-amber-500", stroke: "stroke-amber-500", dash: "66 440", offset: "-374" }
  ];

  // Recent Event Log Entries (Useful visual admin log)
  const systemEvents = [
    { message: "Verification requested by Sasindu W.", time: "10 mins ago", type: "kyc" },
    { message: "New Listing: Honda Trail 125 registered", time: "1 hour ago", type: "listing" },
    { message: "Booking #BL-483 payout released to owner", time: "2 hours ago", type: "payout" },
    { message: "User account registered: Ruwan K.", time: "4 hours ago", type: "user" }
  ];

  return (
    <div className="space-y-8">
      {/* Page Title */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-semibold text-slate-100 tracking-tight">Platform Dashboard</h2>
          <p className="text-slate-400 text-sm mt-1">Real-time statistics across the RentLanka ecosystem.</p>
        </div>
        <div className="px-3 py-1 rounded-full text-xs font-medium bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 flex items-center gap-1.5">
          <span className="w-1.5 h-1.5 rounded-full bg-emerald-400"></span>
          Connected
        </div>
      </div>

      {/* KPI Grid (Consistent, simple flat cards) */}
      <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
        {kpis.map((kpi, idx) => (
          <div
            key={idx}
            className="rounded-xl border border-slate-800/60 bg-slate-950/30 backdrop-blur-md p-6 shadow-lg hover:border-slate-700/80 hover:bg-slate-900/40 transition-all duration-300 flex flex-col justify-between"
          >
            <div>
              <span className="text-xs font-semibold tracking-wider text-slate-500 uppercase">{kpi.label}</span>
              <p className="text-4xl font-extrabold tracking-tight text-slate-100 mt-2">
                {kpi.value.toLocaleString()}
              </p>
            </div>
            <div className="mt-4 pt-4 border-t border-slate-800/60 flex items-center justify-between text-xs">
              <span className="text-slate-500">{kpi.description}</span>
              {kpi.link !== "#" && (
                <Link
                  href={kpi.link}
                  className="px-2.5 py-1 rounded-md bg-indigo-600/10 border border-indigo-500/20 text-indigo-400 hover:bg-indigo-600 hover:text-white hover:border-indigo-600 transition duration-150 font-medium text-[11px] flex items-center gap-1 group"
                >
                  Manage
                  <svg className="w-3 h-3 text-indigo-400 group-hover:text-white group-hover:translate-x-0.5 transition-all duration-150" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
                  </svg>
                </Link>
              )}
            </div>
          </div>
        ))}
      </div>

      {/* Graphs Section Row 1 */}
      <div className="grid gap-6 lg:grid-cols-3">
        
        {/* Growth Trend Area Chart */}
        <div className="lg:col-span-2 rounded-xl border border-slate-800/60 bg-slate-950/30 backdrop-blur-md p-6 flex flex-col justify-between relative overflow-hidden shadow-lg hover:border-slate-700/80 hover:bg-slate-900/40 transition-all duration-300">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <div>
              <h3 className="text-base font-bold text-slate-200">Platform Activity Trends</h3>
              <p className="text-slate-500 text-xs mt-0.5">RentLanka transactions metrics timeline</p>
            </div>
            
            <div className="flex items-center gap-4">
              {/* Metric Selector */}
              <div className="flex items-center gap-1 bg-slate-950 p-1 rounded-xl border border-slate-800/80 text-xs">
                <button
                  onClick={() => setMetricType("revenue")}
                  className={`px-3 py-1.5 rounded-lg font-medium transition ${metricType === "revenue" ? "bg-indigo-600 text-white" : "text-slate-400 hover:text-slate-200"}`}
                >
                  Revenue (LKR)
                </button>
                <button
                  onClick={() => setMetricType("bookings")}
                  className={`px-3 py-1.5 rounded-lg font-medium transition ${metricType === "bookings" ? "bg-indigo-600 text-white" : "text-slate-400 hover:text-slate-200"}`}
                >
                  Bookings Count
                </button>
              </div>

              {/* Range Selector */}
              <div className="flex items-center gap-1 bg-slate-950 p-1 rounded-xl border border-slate-800/80 text-xs">
                <button
                  onClick={() => { setActiveTab("7d"); setHoveredIndex(null); setHoveredPoint(null); }}
                  className={`px-2.5 py-1.5 rounded-lg font-medium transition ${activeTab === "7d" ? "bg-slate-800 text-slate-100" : "text-slate-500 hover:text-slate-300"}`}
                >
                  7D
                </button>
                <button
                  onClick={() => { setActiveTab("30d"); setHoveredIndex(null); setHoveredPoint(null); }}
                  className={`px-2.5 py-1.5 rounded-lg font-medium transition ${activeTab === "30d" ? "bg-slate-800 text-slate-100" : "text-slate-500 hover:text-slate-300"}`}
                >
                  30D
                </button>
              </div>
            </div>
          </div>

          {/* SVG Area Chart */}
          <div className="mt-8 relative h-56 flex items-end">
            <svg className="w-full h-full overflow-visible" viewBox={`0 0 ${svgWidth} ${svgHeight}`}>
              <defs>
                <linearGradient id="chartGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#4F46E5" stopOpacity="0.25" />
                  <stop offset="100%" stopColor="#4F46E5" stopOpacity="0.0" />
                </linearGradient>
              </defs>

              {/* Grid Lines */}
              {[0, 0.25, 0.5, 0.75, 1].map((p, idx) => (
                <line
                  key={idx}
                  x1={paddingX}
                  y1={paddingY + p * (svgHeight - paddingY * 2)}
                  x2={svgWidth - paddingX}
                  y2={paddingY + p * (svgHeight - paddingY * 2)}
                  className="stroke-slate-800/60"
                  strokeWidth="1"
                  strokeDasharray="4 4"
                />
              ))}

              {/* Gradient Area */}
              <path d={areaPath} fill="url(#chartGradient)" />

              {/* Main Line */}
              <path d={linePath} fill="none" stroke="#4F46E5" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" />

              {/* Nodes */}
              {points.map((p, idx) => (
                <g key={idx}>
                  <circle
                    cx={p.x}
                    cy={p.y}
                    r={hoveredIndex === idx ? 6 : 4}
                    className={`transition-all duration-150 ${hoveredIndex === idx ? "fill-white stroke-indigo-500" : "fill-indigo-600 stroke-slate-950"} cursor-pointer`}
                    strokeWidth="2"
                    onMouseEnter={() => {
                      setHoveredPoint(p.data);
                      setHoveredIndex(idx);
                    }}
                    onMouseLeave={() => {
                      setHoveredPoint(null);
                      setHoveredIndex(null);
                    }}
                  />
                  <text
                    x={p.x}
                    y={svgHeight - 4}
                    textAnchor="middle"
                    className="text-[9px] font-semibold fill-slate-500 tracking-wider"
                  >
                    {p.data.label}
                  </text>
                </g>
              ))}
            </svg>

            {/* Custom Tooltip */}
            {hoveredPoint && (
              <div 
                className="absolute z-10 p-3 bg-slate-950 border border-slate-800 rounded-xl shadow-xl text-left pointer-events-none transition-all duration-200"
                style={{
                  left: `${((hoveredIndex ?? 0) / (chartData.length - 1)) * 75 + 10}%`,
                  bottom: "60px"
                }}
              >
                <p className="text-[10px] font-semibold text-slate-500 tracking-wider uppercase">{hoveredPoint.date}</p>
                <p className="text-sm font-extrabold text-slate-100 mt-1">
                  {metricType === "revenue" 
                    ? `LKR ${hoveredPoint.revenue.toLocaleString()}`
                    : `${hoveredPoint.bookings} booking${hoveredPoint.bookings !== 1 ? "s" : ""}`
                  }
                </p>
              </div>
            )}
          </div>
        </div>

        {/* Category Share Donut Chart */}
        <div className="rounded-xl border border-slate-800/60 bg-slate-950/30 backdrop-blur-md p-6 flex flex-col justify-between shadow-lg hover:border-slate-700/80 hover:bg-slate-900/40 transition-all duration-300">
          <div>
            <h3 className="text-base font-bold text-slate-200">Category Share</h3>
            <p className="text-slate-500 text-xs mt-0.5">Gear listed by gear category</p>
          </div>

          <div className="my-6 flex justify-center items-center relative">
            <svg className="w-36 h-36 transform -rotate-90" viewBox="0 0 200 200">
              {/* Donut arcs */}
              <circle cx="100" cy="100" r="70" fill="none" strokeWidth="18" className="stroke-indigo-500" strokeDasharray="158 440" strokeDashoffset="0" />
              <circle cx="100" cy="100" r="70" fill="none" strokeWidth="18" className="stroke-emerald-500" strokeDasharray="119 440" strokeDashoffset="-158" />
              <circle cx="100" cy="100" r="70" fill="none" strokeWidth="18" className="stroke-amber-500" strokeDasharray="79 440" strokeDashoffset="-277" />
              <circle cx="100" cy="100" r="70" fill="none" strokeWidth="18" className="stroke-sky-500" strokeDasharray="40 440" strokeDashoffset="-356" />
              <circle cx="100" cy="100" r="70" fill="none" strokeWidth="18" className="stroke-rose-500" strokeDasharray="44 440" strokeDashoffset="-396" />
            </svg>
            <div className="absolute text-center">
              <span className="text-2xl font-black text-slate-100">{stats?.activeListings ?? 11}</span>
              <p className="text-[10px] text-slate-500 font-semibold tracking-widest uppercase">Listings</p>
            </div>
          </div>

          {/* Color Legend */}
          <div className="space-y-2 mt-4">
            {categories.map((c, i) => (
              <div key={i} className="flex items-center justify-between text-xs">
                <div className="flex items-center gap-2 text-slate-300">
                  <span className={`w-2 h-2 rounded-full ${c.color}`}></span>
                  <span>{c.label}</span>
                </div>
                <span className="font-semibold text-slate-400">{c.percentage}%</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Graphs Section Row 2 */}
      <div className="grid gap-6 lg:grid-cols-3">

        {/* User Verification Trust Level Donut Chart */}
        <div className="rounded-xl border border-slate-800/60 bg-slate-950/30 backdrop-blur-md p-6 flex flex-col justify-between shadow-lg hover:border-slate-700/80 hover:bg-slate-900/40 transition-all duration-300">
          <div>
            <h3 className="text-base font-bold text-slate-200">Trust & Identity</h3>
            <p className="text-slate-500 text-xs mt-0.5">Verification status of registered accounts</p>
          </div>

          <div className="my-6 flex justify-center items-center relative">
            <svg className="w-36 h-36 transform -rotate-90" viewBox="0 0 200 200">
              {verifications.map((v, i) => (
                <circle
                  key={i}
                  cx="100"
                  cy="100"
                  r="70"
                  fill="none"
                  strokeWidth="18"
                  className={v.stroke}
                  strokeDasharray={v.dash}
                  strokeDashoffset={v.offset}
                />
              ))}
            </svg>
            <div className="absolute text-center">
              <span className="text-2xl font-black text-slate-100">{stats?.totalUsers ?? 5}</span>
              <p className="text-[10px] text-slate-500 font-semibold tracking-widest uppercase">Accounts</p>
            </div>
          </div>

          {/* Legend */}
          <div className="space-y-2">
            {verifications.map((v, i) => (
              <div key={i} className="flex items-center justify-between text-xs">
                <div className="flex items-center gap-2 text-slate-300">
                  <span className={`w-2 h-2 rounded-full ${v.color}`}></span>
                  <span>{v.label}</span>
                </div>
                <span className="font-semibold text-slate-400">{v.percentage}%</span>
              </div>
            ))}
          </div>
        </div>

        {/* Platform Escrow Fund Bar Stack Chart */}
        <div className="rounded-xl border border-slate-800/60 bg-slate-950/30 backdrop-blur-md p-6 flex flex-col justify-between shadow-lg hover:border-slate-700/80 hover:bg-slate-900/40 transition-all duration-300">
          <div>
            <h3 className="text-base font-bold text-slate-200">Escrow Ledger</h3>
            <p className="text-slate-500 text-xs mt-0.5">Ratio and distribution of transacted funds</p>
          </div>

          <div className="my-auto space-y-6">
            {/* Visual stacked horizontal progress bar */}
            <div>
              <div className="flex h-4 overflow-hidden rounded-full bg-slate-950 border border-slate-800">
                <div className="bg-indigo-500 h-full" style={{ width: "65%" }}></div>
                <div className="bg-emerald-500 h-full" style={{ width: "25%" }}></div>
                <div className="bg-rose-500 h-full" style={{ width: "10%" }}></div>
              </div>
              <div className="flex justify-between text-[10px] text-slate-500 font-semibold mt-2">
                <span>Escrow Held (65%)</span>
                <span>Payouts (25%)</span>
                <span>Disputes (10%)</span>
              </div>
            </div>

            {/* Flat details statistics ledger */}
            <div className="space-y-2 pt-2 border-t border-slate-800/60">
              <div className="flex items-center justify-between text-xs">
                <span className="text-slate-400">Total transacted LKR</span>
                <span className="font-bold text-slate-100">LKR 450,000</span>
              </div>
              <div className="flex items-center justify-between text-xs">
                <span className="text-slate-400">Escrow reserves</span>
                <span className="font-bold text-indigo-400">LKR 292,500</span>
              </div>
              <div className="flex items-center justify-between text-xs">
                <span className="text-slate-400">Released to owners</span>
                <span className="font-bold text-emerald-400">LKR 112,500</span>
              </div>
            </div>
          </div>
        </div>

        {/* Live Admin Audit Log */}
        <div className="rounded-xl border border-slate-800/60 bg-slate-950/30 backdrop-blur-md p-6 flex flex-col justify-between shadow-lg hover:border-slate-700/80 hover:bg-slate-900/40 transition-all duration-300">
          <div>
            <h3 className="text-base font-bold text-slate-200">System Logs</h3>
            <p className="text-slate-500 text-xs mt-0.5">Real-time platform administrative events</p>
          </div>

          <div className="space-y-3 mt-4">
            {systemEvents.map((evt, idx) => (
              <div key={idx} className="p-2.5 rounded-lg bg-slate-950/60 border border-slate-900/60 flex items-start justify-between gap-3">
                <div className="flex items-start gap-2.5">
                  <span className="text-sm mt-0.5">
                    {evt.type === "kyc" && (
                      <svg className="w-4 h-4 text-amber-500 mt-0.5" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                      </svg>
                    )}
                    {evt.type === "listing" && (
                      <svg className="w-4 h-4 text-emerald-500 mt-0.5" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M7 7h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                      </svg>
                    )}
                    {evt.type === "payout" && (
                      <svg className="w-4 h-4 text-indigo-500 mt-0.5" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
                      </svg>
                    )}
                    {evt.type === "user" && (
                      <svg className="w-4 h-4 text-sky-500 mt-0.5" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                      </svg>
                    )}
                  </span>
                  <div>
                    <p className="text-xs font-medium text-slate-300 leading-tight">{evt.message}</p>
                    <p className="text-[9px] text-slate-500 font-semibold tracking-wide uppercase mt-1">{evt.time}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Operations Quicklinks */}
      <div className="rounded-xl border border-slate-800 bg-slate-900/20 p-6 backdrop-blur-md">
        <h3 className="text-base font-bold text-slate-200">Pending Actions</h3>
        <div className="mt-4 grid gap-4 md:grid-cols-2">
          {stats && stats.pendingKycCount > 0 ? (
            <Link
              href="/admin/kyc"
              className="flex items-center justify-between p-4 rounded-xl bg-slate-900/60 border border-slate-800 hover:border-amber-500/30 hover:bg-slate-800/40 transition duration-200 group"
            >
              <div className="flex items-center gap-3">
                <div className="p-2.5 rounded-xl bg-amber-500/10 border border-amber-500/20 text-amber-400">
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                  </svg>
                </div>
                <div>
                  <p className="text-sm font-semibold text-slate-200">
                    Review {stats.pendingKycCount} verification requests
                  </p>
                  <p className="text-xs text-slate-500">KYC Verification queue is waiting</p>
                </div>
              </div>
              <svg className="w-5 h-5 text-amber-400 group-hover:translate-x-0.5 transition-transform duration-150" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
              </svg>
            </Link>
          ) : (
            <div className="flex items-center gap-3 p-4 rounded-xl bg-slate-900/40 border border-slate-800/50">
              <div className="p-2.5 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400">
                <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <div>
                <p className="text-sm font-semibold text-slate-400">KYC verification queue is clear</p>
                <p className="text-xs text-slate-600">No pending document approvals</p>
              </div>
            </div>
          )}

          <Link
            href="/admin/listings"
            className="flex items-center justify-between p-4 rounded-xl bg-slate-900/60 border border-slate-800 hover:border-indigo-500/30 hover:bg-slate-800/40 transition duration-200 group"
          >
            <div className="flex items-center gap-3">
              <div className="p-2.5 rounded-xl bg-indigo-500/10 border border-indigo-500/20 text-indigo-400">
                <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                </svg>
              </div>
              <div>
                <p className="text-sm font-semibold text-slate-200">Moderate Listings</p>
                <p className="text-xs text-slate-500">Scan and flag inappropriate user content</p>
              </div>
            </div>
            <svg className="w-5 h-5 text-indigo-400 group-hover:translate-x-0.5 transition-transform duration-150" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
            </svg>
          </Link>
        </div>
      </div>
    </div>
  );
}
