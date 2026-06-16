"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { ListingCard } from "@/components/features/ListingCard";
import { getWishlist } from "@/lib/api/listings";
import { isAuthenticated } from "@/lib/auth/token";
import type { Listing } from "@/types/api";

export default function SavedPage() {
  const router = useRouter();
  const [items, setItems] = useState<Listing[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!isAuthenticated()) {
      router.replace("/login");
      return;
    }
    getWishlist()
      .then((data) => setItems(data.items))
      .catch(() => router.replace("/login"))
      .finally(() => setLoading(false));
  }, [router]);

  if (loading) {
    return <div className="p-16 text-center text-muted">Loading saved items...</div>;
  }

  return (
    <div className="mx-auto max-w-7xl px-4 py-12 sm:px-6">
      <h1 className="text-3xl font-bold">Saved items</h1>
      <p className="mt-1 text-muted">Equipment you&apos;ve bookmarked for later</p>

      {items.length > 0 ? (
        <div className="mt-8 grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {items.map((listing) => (
            <ListingCard key={listing.id} listing={listing} />
          ))}
        </div>
      ) : (
        <div className="mt-12 rounded-xl border border-dashed border-border p-12 text-center text-muted">
          No saved items yet. Browse listings and save your favourites.
        </div>
      )}
    </div>
  );
}
