"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { getAdminUsers, toggleUserBan } from "@/lib/api/admin";
import type { UserProfile } from "@/types/api";

export default function AdminUsersList() {
  const [users, setUsers] = useState<UserProfile[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [query, setQuery] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [actionLoadingId, setActionLoadingId] = useState<string | null>(null);

  const pageSize = 15;

  function loadUsers(currentPage: number, searchQuery: string) {
    setLoading(true);
    setError("");
    getAdminUsers({ page: currentPage, pageSize, query: searchQuery })
      .then((res) => {
        setUsers(res.items);
        setTotal(res.total);
      })
      .catch((err) => setError(err instanceof Error ? err.message : "Failed to load users"))
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    const delayDebounceFn = setTimeout(() => {
      loadUsers(page, query);
    }, 300);

    return () => clearTimeout(delayDebounceFn);
  }, [page, query]);

  async function handleToggleBan(userId: string, isCurrentlyBanned: boolean) {
    if (!confirm(`Are you sure you want to ${isCurrentlyBanned ? "unban" : "ban"} this user?`)) {
      return;
    }

    setActionLoadingId(userId);
    try {
      await toggleUserBan(userId);
      setUsers((prev) =>
        prev.map((u) => (u.id === userId ? { ...u, isBanned: !u.isBanned } : u))
      );
    } catch (err) {
      alert(err instanceof Error ? err.message : "Action failed");
    } finally {
      setActionLoadingId(null);
    }
  }

  const totalPages = Math.ceil(total / pageSize);

  return (
    <div className="space-y-6">
      {/* Search and Action header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div className="relative flex-1 max-w-md">
          <input
            type="text"
            placeholder="Search users by name or email..."
            value={query}
            onChange={(e) => {
              setQuery(e.target.value);
              setPage(1);
            }}
            className="w-full rounded-xl border border-slate-800 bg-slate-900/40 px-4 py-2.5 pl-10 text-sm outline-none focus:border-indigo-500 transition"
          />
          <span className="absolute left-3 top-3.5 text-slate-500 text-sm">🔍</span>
        </div>
        <div className="text-sm text-slate-400">
          Showing <span className="font-semibold text-slate-200">{users.length}</span> of{" "}
          <span className="font-semibold text-slate-200">{total}</span> users
        </div>
      </div>

      {/* Error Message */}
      {error && (
        <div className="p-4 bg-red-950/20 border border-red-800/40 rounded-xl text-red-400 text-sm">
          {error}
        </div>
      )}

      {/* Table */}
      <div className="overflow-x-auto rounded-2xl border border-slate-800 bg-slate-900/10 backdrop-blur-md">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="border-b border-slate-800 bg-slate-900/40 text-slate-400 text-xs font-semibold uppercase">
              <th className="px-6 py-4">Name</th>
              <th className="px-6 py-4">Email</th>
              <th className="px-6 py-4">Phone</th>
              <th className="px-6 py-4">Role</th>
              <th className="px-6 py-4">Verification</th>
              <th className="px-6 py-4">Status</th>
              <th className="px-6 py-4 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800/60">
            {loading && users.length === 0 ? (
              <tr>
                <td colSpan={7} className="px-6 py-12 text-center text-slate-500">
                  <div className="inline-block animate-spin rounded-full h-6 w-6 border-t-2 border-indigo-500"></div>
                  <p className="mt-2 text-sm">Fetching user accounts...</p>
                </td>
              </tr>
            ) : users.length === 0 ? (
              <tr>
                <td colSpan={7} className="px-6 py-12 text-center text-slate-500 text-sm">
                  No users found matching your search.
                </td>
              </tr>
            ) : (
              users.map((user) => {
                const isActionLoading = actionLoadingId === user.id;
                return (
                  <tr
                    key={user.id}
                    className="hover:bg-slate-900/30 transition duration-150 text-sm"
                  >
                    <td className="px-6 py-4 font-semibold text-slate-200">
                      {user.firstName} {user.lastName}
                    </td>
                    <td className="px-6 py-4 text-slate-400 truncate max-w-[200px]">
                      {user.email}
                    </td>
                    <td className="px-6 py-4 text-slate-400 font-mono">
                      {user.phoneNumber || "Not set"}
                    </td>
                    <td className="px-6 py-4">
                      <span
                        className={`text-xs px-2.5 py-0.5 rounded-full font-medium ${
                          user.role === "Admin"
                            ? "bg-purple-500/10 text-purple-400 border border-purple-500/20"
                            : "bg-slate-800 text-slate-400"
                        }`}
                      >
                        {user.role}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      {user.verificationLevel === -1 && (
                        <span className="text-xs px-2.5 py-0.5 rounded-full font-medium bg-red-950/40 text-red-400 border border-red-500/20">
                          Unverified
                        </span>
                      )}
                      {user.verificationLevel === 0 && (
                        <span className="text-xs px-2.5 py-0.5 rounded-full font-medium bg-slate-800 text-slate-400 border border-slate-700/60">
                          Email (L0)
                        </span>
                      )}
                      {user.verificationLevel === 1 && (
                        <span className="text-xs px-2.5 py-0.5 rounded-full font-medium bg-blue-950/40 text-blue-400 border border-blue-500/20">
                          Mobile (L1)
                        </span>
                      )}
                      {user.verificationLevel === 2 && (
                        <span className="text-xs px-2.5 py-0.5 rounded-full font-medium bg-amber-950/40 text-amber-400 border border-amber-500/20 animate-pulse">
                          NIC Submitted (L2)
                        </span>
                      )}
                      {user.verificationLevel === 3 && (
                        <span className="text-xs px-2.5 py-0.5 rounded-full font-medium bg-indigo-950/40 text-indigo-400 border border-indigo-500/20">
                          Trusted (L3) 🛡️
                        </span>
                      )}
                    </td>
                    <td className="px-6 py-4">
                      {user.isBanned ? (
                        <span className="text-xs px-2.5 py-0.5 rounded-full font-semibold bg-red-900/20 text-red-400 border border-red-800/20">
                          Banned
                        </span>
                      ) : (
                        <span className="text-xs px-2.5 py-0.5 rounded-full font-semibold bg-emerald-950/30 text-emerald-400 border border-emerald-500/20">
                          Active
                        </span>
                      )}
                    </td>
                    <td className="px-6 py-4 text-right space-x-2">
                      <Link
                        href={`/admin/users/${user.id}`}
                        className="text-xs px-3 py-1.5 rounded-lg border border-slate-800 bg-slate-900 hover:border-slate-700 text-slate-300 hover:text-slate-100 transition duration-150"
                      >
                        Detail
                      </Link>
                      {user.role !== "Admin" && (
                        <button
                          disabled={isActionLoading}
                          onClick={() => handleToggleBan(user.id, user.isBanned)}
                          className={`text-xs px-3 py-1.5 rounded-lg border transition duration-150 cursor-pointer ${
                            user.isBanned
                              ? "bg-emerald-950/10 border-emerald-900/30 text-emerald-400 hover:bg-emerald-950/20 hover:border-emerald-800"
                              : "bg-red-950/10 border-red-900/30 text-red-400 hover:bg-red-950/20 hover:border-red-800"
                          }`}
                        >
                          {isActionLoading
                            ? "Wait..."
                            : user.isBanned
                            ? "Unban"
                            : "Ban"}
                        </button>
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
