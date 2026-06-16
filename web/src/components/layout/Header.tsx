"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { Button } from "@/components/ui/Button";
import { getToken, clearToken } from "@/lib/auth/token";
import { getCurrentUser } from "@/lib/api/listings";
import type { UserProfile } from "@/types/api";

export function Header() {
  const [user, setUser] = useState<UserProfile | null>(null);

  useEffect(() => {
    if (!getToken()) return;
    getCurrentUser()
      .then(setUser)
      .catch(() => clearToken());
  }, []);

  function handleLogout() {
    clearToken();
    setUser(null);
    window.location.href = "/";
  }

  return (
    <header className="sticky top-0 z-50 border-b border-border bg-background/95 backdrop-blur">
      <div className="mx-auto flex max-w-7xl items-center gap-6 px-4 py-4 sm:px-6">
        <Link href="/" className="text-xl font-bold text-primary">
          RentLanka
        </Link>

        <form action="/search" method="get" className="hidden flex-1 md:block">
          <input
            name="query"
            placeholder="Search cameras, tools, camping gear..."
            className="w-full rounded-xl border border-border bg-card px-4 py-2.5 text-sm outline-none focus:border-primary"
          />
        </form>

        <nav className="ml-auto flex items-center gap-3">
          <Button href="/listings/new" variant="secondary" className="hidden sm:inline-flex">
            List your gear
          </Button>

          {user ? (
            <div className="group relative">
              <button className="flex h-9 w-9 items-center justify-center rounded-full bg-primary text-sm font-bold text-white">
                {user.firstName[0]}
              </button>
              <div className="invisible absolute right-0 mt-2 w-48 rounded-xl border border-border bg-background py-2 opacity-0 shadow-lg transition group-hover:visible group-hover:opacity-100">
                <Link href="/profile" className="block px-4 py-2 text-sm hover:bg-card">
                  Profile
                </Link>
                <Link href="/saved" className="block px-4 py-2 text-sm hover:bg-card">
                  Saved
                </Link>
                <Link href="/dashboard/owner/listings" className="block px-4 py-2 text-sm hover:bg-card">
                  Owner Dashboard
                </Link>
                <button
                  onClick={handleLogout}
                  className="block w-full px-4 py-2 text-left text-sm hover:bg-card"
                >
                  Logout
                </button>
              </div>
            </div>
          ) : (
            <>
              <Button href="/login" variant="ghost">
                Log in
              </Button>
              <Button href="/register">Sign up</Button>
            </>
          )}
        </nav>
      </div>
    </header>
  );
}
