import { ListingCard } from "@/components/features/ListingCard";
import { CATEGORIES, DISTRICTS } from "@/lib/constants";
import { searchListings } from "@/lib/api/listings";

interface SearchPageProps {
  searchParams: Promise<Record<string, string | undefined>>;
}

export default async function SearchPage({ searchParams }: SearchPageProps) {
  const params = await searchParams;
  const query = params.query ?? "";
  const category = params.category ?? "";
  const district = params.district ?? "";
  const minPrice = params.minPrice ? Number(params.minPrice) : undefined;
  const maxPrice = params.maxPrice ? Number(params.maxPrice) : undefined;
  const sortBy = params.sortBy ?? "newest";

  const results = await searchListings({
    query: query || undefined,
    category: category || undefined,
    district: district || undefined,
    minPrice,
    maxPrice,
    sortBy,
    pageSize: 24,
  }).catch(() => ({ items: [], total: 0, page: 1, pageSize: 24 }));

  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6">
      <h1 className="text-3xl font-bold">Search results</h1>
      <p className="mt-1 text-muted">{results.total} items found</p>

      <div className="mt-8 grid gap-8 lg:grid-cols-[260px_1fr]">
        <aside className="h-fit rounded-xl border border-border bg-card p-5">
          <form className="space-y-4">
            <label className="block text-sm font-medium">
              Search
              <input
                name="query"
                defaultValue={query}
                className="mt-1 w-full rounded-xl border border-border bg-background px-3 py-2 text-sm"
              />
            </label>
            <label className="block text-sm font-medium">
              Category
              <select
                name="category"
                defaultValue={category}
                className="mt-1 w-full rounded-xl border border-border bg-background px-3 py-2 text-sm"
              >
                <option value="">All categories</option>
                {CATEGORIES.map((c) => (
                  <option key={c} value={c}>
                    {c}
                  </option>
                ))}
              </select>
            </label>
            <label className="block text-sm font-medium">
              District
              <select
                name="district"
                defaultValue={district}
                className="mt-1 w-full rounded-xl border border-border bg-background px-3 py-2 text-sm"
              >
                <option value="">All districts</option>
                {DISTRICTS.map((d) => (
                  <option key={d} value={d}>
                    {d}
                  </option>
                ))}
              </select>
            </label>
            <div className="grid grid-cols-2 gap-2">
              <label className="block text-sm font-medium">
                Min price
                <input
                  name="minPrice"
                  type="number"
                  defaultValue={minPrice ?? ""}
                  className="mt-1 w-full rounded-xl border border-border bg-background px-3 py-2 text-sm"
                />
              </label>
              <label className="block text-sm font-medium">
                Max price
                <input
                  name="maxPrice"
                  type="number"
                  defaultValue={maxPrice ?? ""}
                  className="mt-1 w-full rounded-xl border border-border bg-background px-3 py-2 text-sm"
                />
              </label>
            </div>
            <label className="block text-sm font-medium">
              Sort by
              <select
                name="sortBy"
                defaultValue={sortBy}
                className="mt-1 w-full rounded-xl border border-border bg-background px-3 py-2 text-sm"
              >
                <option value="newest">Newest</option>
                <option value="oldest">Oldest</option>
                <option value="price_asc">Price: low to high</option>
                <option value="price_desc">Price: high to low</option>
              </select>
            </label>
            <button
              type="submit"
              className="w-full rounded-xl bg-primary py-2.5 text-sm font-semibold text-white hover:bg-primary-dark"
            >
              Apply filters
            </button>
          </form>
        </aside>

        <div>
          {results.items.length > 0 ? (
            <div className="grid gap-6 sm:grid-cols-2 xl:grid-cols-3">
              {results.items.map((listing) => (
                <ListingCard key={listing.id} listing={listing} />
              ))}
            </div>
          ) : (
            <div className="rounded-xl border border-dashed border-border p-12 text-center text-muted">
              No listings match your filters. Try adjusting your search.
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
