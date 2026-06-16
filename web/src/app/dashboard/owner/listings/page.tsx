"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { Button } from "@/components/ui/Button";
import {
  deleteListing,
  formatPrice,
  getMyListings,
  toggleListingPause,
} from "@/lib/api/listings";
import { isAuthenticated } from "@/lib/auth/token";
import type { Listing } from "@/types/api";

export default function OwnerListingsPage() {
  const router = useRouter();
  const [listings, setListings] = useState<Listing[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!isAuthenticated()) {
      router.replace("/login");
      return;
    }
    getMyListings()
      .then(setListings)
      .catch(() => router.replace("/login"))
      .finally(() => setLoading(false));
  }, [router]);

  async function handlePause(id: string) {
    const updated = await toggleListingPause(id);
    setListings((prev) => prev.map((l) => (l.id === id ? updated : l)));
  }

  async function handleDelete(id: string) {
    if (!confirm("Delete this listing?")) return;
    await deleteListing(id);
    setListings((prev) => prev.filter((l) => l.id !== id));
  }

  if (loading) {
    return <div className="p-16 text-center text-muted">Loading your listings...</div>;
  }

  return (
    <div className="mx-auto max-w-5xl px-4 py-12">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Owner dashboard</h1>
          <p className="mt-1 text-muted">Manage your listed equipment</p>
        </div>
        <Button href="/listings/new" variant="secondary">
          + New listing
        </Button>
      </div>

      {listings.length === 0 ? (
        <div className="mt-12 rounded-xl border border-dashed border-border p-12 text-center">
          <p className="text-muted">You haven&apos;t listed any gear yet.</p>
          <Button href="/listings/new" className="mt-4">
            Create your first listing
          </Button>
        </div>
      ) : (
        <div className="mt-8 overflow-hidden rounded-xl border border-border">
          <table className="w-full text-left text-sm">
            <thead className="bg-card">
              <tr>
                <th className="px-4 py-3 font-medium">Title</th>
                <th className="px-4 py-3 font-medium">Category</th>
                <th className="px-4 py-3 font-medium">Price/day</th>
                <th className="px-4 py-3 font-medium">Status</th>
                <th className="px-4 py-3 font-medium">Actions</th>
              </tr>
            </thead>
            <tbody>
              {listings.map((listing) => (
                <tr key={listing.id} className="border-t border-border">
                  <td className="px-4 py-3">
                    <Link href={`/listings/${listing.id}`} className="font-medium hover:text-primary">
                      {listing.title}
                    </Link>
                  </td>
                  <td className="px-4 py-3 text-muted">{listing.category}</td>
                  <td className="px-4 py-3">{formatPrice(listing.pricePerDay)}</td>
                  <td className="px-4 py-3">
                    <span
                      className={`rounded-full px-2 py-0.5 text-xs font-medium ${
                        listing.isPaused
                          ? "bg-orange-100 text-orange-700"
                          : "bg-green-100 text-green-700"
                      }`}
                    >
                      {listing.isPaused ? "Paused" : "Active"}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex gap-2">
                      <button
                        onClick={() => handlePause(listing.id)}
                        className="text-primary hover:underline"
                      >
                        {listing.isPaused ? "Resume" : "Pause"}
                      </button>
                      <button
                        onClick={() => handleDelete(listing.id)}
                        className="text-red-600 hover:underline"
                      >
                        Delete
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
