import Link from "next/link";
import { ListingCard } from "@/components/features/ListingCard";
import { Button } from "@/components/ui/Button";
import { CATEGORIES } from "@/lib/constants";
import { searchListings } from "@/lib/api/listings";

export default async function HomePage() {
  const trending = await searchListings({ pageSize: 8, sortBy: "newest" }).catch(
    () => ({ items: [], total: 0, page: 1, pageSize: 8 })
  );

  return (
    <div>
      <section className="bg-gradient-to-br from-primary/10 via-background to-accent/10">
        <div className="mx-auto max-w-7xl px-4 py-16 sm:px-6 sm:py-24">
          <h1 className="max-w-2xl text-4xl font-bold tracking-tight sm:text-5xl">
            Rent the gear you need. Earn from what you own.
          </h1>
          <p className="mt-4 max-w-xl text-lg text-muted">
            Sri Lanka&apos;s trusted marketplace for cameras, tools, camping equipment, and more.
          </p>
          <form action="/search" method="get" className="mt-8 flex max-w-xl gap-2">
            <input
              name="query"
              placeholder="What do you want to rent?"
              className="flex-1 rounded-xl border border-border bg-background px-4 py-3 outline-none focus:border-primary"
            />
            <Button type="submit">Search</Button>
          </form>
        </div>
      </section>

      <section className="mx-auto max-w-7xl px-4 py-12 sm:px-6">
        <h2 className="text-2xl font-bold">Browse by category</h2>
        <div className="mt-6 grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-6">
          {CATEGORIES.map((category) => (
            <Link
              key={category}
              href={`/search?category=${encodeURIComponent(category)}`}
              className="rounded-xl border border-border bg-card p-4 text-center font-medium transition hover:border-primary hover:shadow-sm"
            >
              {category}
            </Link>
          ))}
        </div>
      </section>

      <section className="mx-auto max-w-7xl px-4 pb-16 sm:px-6">
        <div className="flex items-center justify-between">
          <h2 className="text-2xl font-bold">Latest listings</h2>
          <Link href="/search" className="text-sm font-medium text-primary hover:underline">
            View all
          </Link>
        </div>
        {trending.items.length > 0 ? (
          <div className="mt-6 grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
            {trending.items.map((listing) => (
              <ListingCard key={listing.id} listing={listing} />
            ))}
          </div>
        ) : (
          <div className="mt-6 rounded-xl border border-dashed border-border p-12 text-center text-muted">
            <p>No listings yet. Be the first to list your gear!</p>
            <Button href="/listings/new" variant="secondary" className="mt-4">
              List an item
            </Button>
          </div>
        )}
      </section>
    </div>
  );
}
