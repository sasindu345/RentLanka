"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { clearToken, getToken } from "@/lib/auth/token";

function parseJwt(token: string) {
  try {
    const base64Url = token.split(".")[1];
    if (!base64Url) return null;
    const base64 = base64Url.replace(/-/g, "+").replace(/_/g, "/");
    return JSON.parse(atob(base64));
  } catch {
    return null;
  }
}

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const router = useRouter();
  const pathname = usePathname();
  const [adminName, setAdminName] = useState("Admin User");

  useEffect(() => {
    const token = getToken();
    if (token) {
      const payload = parseJwt(token);
      if (payload) {
        const firstName = payload.firstName || "Admin";
        const lastName = payload.lastName || "User";
        setAdminName(`${firstName} ${lastName}`);
      }
    }
  }, []);

  function handleLogout() {
    clearToken();
    router.push("/login");
    router.refresh();
  }

  const menuItems = [
    { label: "Overview", href: "/admin", icon: "📊" },
    { label: "Users List", href: "/admin/users", icon: "👥" },
    { label: "KYC Queue", href: "/admin/kyc", icon: "📄" },
    { label: "Listings Moderation", href: "/admin/listings", icon: "🏷️" },
    { label: "Bookings List", href: "/admin/bookings", icon: "📅" },
    { label: "Payments & Payouts", href: "/admin/payments", icon: "💳" },
    { label: "Disputes Queue", href: "/admin/disputes", icon: "⚠️" },
    { label: "Platform Settings", href: "/admin/settings", icon: "⚙️" },
  ];

  return (
    <div className="flex h-screen overflow-hidden bg-slate-950 text-slate-100">
      {/* Sidebar */}
      <aside className="w-64 flex-shrink-0 border-r border-slate-800 bg-slate-900/60 backdrop-blur-lg flex flex-col justify-between">
        <div>
          <div className="h-16 flex items-center px-6 border-b border-slate-800">
            <span className="text-xl font-bold bg-gradient-to-r from-indigo-400 to-violet-400 bg-clip-text text-transparent">
              RentLanka Admin
            </span>
          </div>

          <nav className="mt-6 px-4 space-y-1">
            {menuItems.map((item) => {
              const isActive = pathname === item.href || (item.href !== "/admin" && pathname.startsWith(item.href));
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={`flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all duration-200 ${
                    isActive
                      ? "bg-indigo-950/40 text-indigo-400 border-l-4 border-indigo-500 shadow-inner"
                      : "text-slate-400 hover:bg-slate-800/40 hover:text-slate-200"
                  }`}
                >
                  <span className="text-base">{item.icon}</span>
                  {item.label}
                </Link>
              );
            })}
          </nav>
        </div>

        {/* Footer in Sidebar */}
        <div className="p-4 border-t border-slate-800 bg-slate-900/40">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-9 h-9 rounded-xl bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center text-indigo-400 font-bold">
              {adminName[0]}
            </div>
            <div className="overflow-hidden">
              <p className="text-sm font-semibold truncate">{adminName}</p>
              <p className="text-xs text-slate-500 truncate">Administrator</p>
            </div>
          </div>
          <button
            onClick={handleLogout}
            className="w-full py-2.5 px-4 rounded-xl border border-slate-800 hover:border-slate-700 bg-slate-900 text-sm font-semibold text-slate-300 hover:text-slate-100 transition duration-200 flex items-center justify-center gap-2 cursor-pointer"
          >
            <span>🚪</span> Logout
          </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Header */}
        <header className="h-16 border-b border-slate-800 bg-slate-900/20 backdrop-blur-md flex items-center justify-between px-8">
          <h1 className="text-lg font-bold text-slate-200">
            {menuItems.find((item) => pathname === item.href || (item.href !== "/admin" && pathname.startsWith(item.href)))?.label || "Dashboard"}
          </h1>
          <div className="flex items-center gap-4">
            <span className="text-xs font-semibold px-2.5 py-1 rounded-full bg-indigo-500/10 text-indigo-400 border border-indigo-500/20">
              Live Environment
            </span>
          </div>
        </header>

        {/* Content Body */}
        <main className="flex-1 overflow-y-auto p-8">
          <div className="mx-auto max-w-7xl">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
}
