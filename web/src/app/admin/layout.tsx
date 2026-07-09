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
  const [sidebarOpen, setSidebarOpen] = useState(false);

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

  // Close sidebar on path changes (mobile)
  useEffect(() => {
    setSidebarOpen(false);
  }, [pathname]);

  function handleLogout() {
    clearToken();
    router.push("/login");
    router.refresh();
  }

  const menuItems = [
    { label: "Dashboard Overview", href: "/admin" },
    { label: "User Management", href: "/admin/users" },
    { label: "Identity Verification", href: "/admin/kyc" },
    { label: "Listings Moderation", href: "/admin/listings" },
    { label: "Booking Records", href: "/admin/bookings" },
    { label: "Financial Ledger", href: "/admin/payments" },
    { label: "Dispute Center", href: "/admin/disputes" },
    { label: "System Settings", href: "/admin/settings" },
  ];

  const currentTitle = menuItems.find(
    (item) => pathname === item.href || (item.href !== "/admin" && pathname.startsWith(item.href))
  )?.label || "Dashboard";

  return (
    <div 
      className="flex h-screen overflow-hidden bg-slate-950 text-slate-100 relative"
      style={{
        backgroundImage: "url('/images/image.png')",
        backgroundSize: "cover",
        backgroundPosition: "bottom left",
        backgroundRepeat: "no-repeat"
      }}
    >
      {/* Dark overlay for optimal readability, preventing text contrast issues */}
      <div className="absolute inset-0 bg-slate-950/75 pointer-events-none z-0" />
      
      {/* Mobile Drawer Overlay Back Drop */}
      {sidebarOpen && (
        <div
          onClick={() => setSidebarOpen(false)}
          className="fixed inset-0 z-40 bg-slate-950/60 backdrop-blur-sm lg:hidden transition-opacity duration-300"
        />
      )}

      {/* Sidebar - Collapsible sliding drawer on mobile, static on desktop */}
      <aside
        className={`fixed inset-y-0 left-0 z-50 w-64 flex-shrink-0 border-r border-slate-800/60 bg-slate-950/40 backdrop-blur-md flex flex-col justify-between transition-transform duration-300 transform lg:translate-x-0 lg:relative z-10 ${
          sidebarOpen ? "translate-x-0" : "-translate-x-full"
        }`}
      >
        <div>
          <div className="h-16 flex items-center justify-between px-6 border-b border-slate-800/60">
            <span className="text-xl font-bold text-indigo-400">
              RentLanka Admin
            </span>
            {/* Close Button on Mobile Drawer */}
            <button
              onClick={() => setSidebarOpen(false)}
              className="lg:hidden text-slate-400 hover:text-slate-200 p-1"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <nav className="mt-6 px-4 space-y-1">
            {menuItems.map((item) => {
              const isActive = pathname === item.href || (item.href !== "/admin" && pathname.startsWith(item.href));
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={`flex items-center px-4 py-3 rounded-xl text-sm font-medium transition-all duration-200 ${
                    isActive
                      ? "bg-slate-800 text-slate-100"
                      : "text-slate-400 hover:bg-slate-800/40 hover:text-slate-200"
                  }`}
                >
                  {item.label}
                </Link>
              );
            })}
          </nav>
        </div>

        {/* Sidebar Profile Footer */}
        <div className="p-4 border-t border-slate-800/60 bg-slate-950/30">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-9 h-9 rounded-xl bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center text-indigo-400 font-bold flex-shrink-0">
              {adminName[0]}
            </div>
            <div className="overflow-hidden">
              <p className="text-sm font-semibold truncate">{adminName}</p>
              <p className="text-xs text-slate-500 truncate">Administrator</p>
            </div>
          </div>
          <button
            onClick={handleLogout}
            className="w-full py-2.5 px-4 rounded-xl border border-slate-800/60 hover:border-slate-700/60 bg-slate-900/20 backdrop-blur-sm text-sm font-semibold text-slate-300 hover:text-slate-100 hover:bg-slate-900/40 transition duration-200 flex items-center justify-center gap-2 cursor-pointer group"
          >
            <svg className="w-4 h-4 text-slate-400 group-hover:text-slate-200 transition-colors" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
            </svg>
            Logout
          </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col overflow-hidden relative z-10">
        
        {/* Responsive Header */}
        <header className="h-16 border-b border-slate-800/60 bg-slate-950/20 backdrop-blur-md flex items-center justify-between px-4 sm:px-8">
          <div className="flex items-center gap-4">
            {/* Hamburger Toggle Trigger (Visible on Mobile only) */}
            <button
              onClick={() => setSidebarOpen(true)}
              className="lg:hidden p-2 rounded-lg border border-slate-800/60 bg-slate-950/20 text-slate-400 hover:text-slate-200"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M4 6h16M4 12h16M4 18h16" />
              </svg>
            </button>
            <h1 className="text-base sm:text-lg font-bold text-slate-200">
              {currentTitle}
            </h1>
          </div>
          
          <div className="flex items-center gap-4">
            <span className="text-xs font-semibold px-2.5 py-1 rounded-full bg-indigo-500/10 text-indigo-400 border border-indigo-500/20">
              Live Environment
            </span>
          </div>
        </header>

        {/* Content Body */}
        <main className="flex-1 overflow-y-auto p-4 sm:p-8">
          <div className="mx-auto max-w-7xl">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
}
