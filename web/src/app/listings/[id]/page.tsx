import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Button } from "@/components/ui/Button";
import { formatPrice, getListing } from "@/lib/api/listings";

interface ListingDetailPageProps {
  params: Promise<{ id: string }>;
}

export default async function ListingDetailPage({ params }: ListingDetailPageProps) {
  const { id } = await params;

  let listing;
  try {
    listing = await getListing(id);
  } catch {
    notFound();
  }

  const mainImage = listing.images[0] ?? null;

  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6">
      <div className="grid gap-8 lg:grid-cols-[1fr_360px]">
        <div>
          <div className="relative aspect-[16/10] overflow-hidden rounded-xl bg-border">
            {mainImage ? (
              <Image
                src={mainImage}
                alt={listing.title}
                fill
                className="object-cover"
                priority
                unoptimized
              />
            ) : (
              <div className="flex h-full items-center justify-center text-muted">
                No images uploaded
              </div>
            )}
          </div>

          {listing.images.length > 1 && (
            <div className="mt-3 grid grid-cols-4 gap-2">
              {listing.images.slice(1, 5).map((img, i) => (
                <div key={i} className="relative aspect-square overflow-hidden rounded-lg bg-border">
                  <Image src={img} alt="" fill className="object-cover" unoptimized />
                </div>
              ))}
            </div>
          )}

          <div className="mt-8">
            <p className="text-sm font-medium uppercase tracking-wide text-primary">
              {listing.category} · {listing.district}
            </p>
            <h1 className="mt-2 text-3xl font-bold">{listing.title}</h1>
            <p className="mt-4 whitespace-pre-wrap text-muted">{listing.description}</p>

            {listing.rules && (
              <div className="mt-6 rounded-xl bg-card p-5">
                <h2 className="font-semibold">Rental rules</h2>
                <p className="mt-2 text-sm text-muted">{listing.rules}</p>
              </div>
            )}

            <div className="mt-6 flex items-center gap-3 rounded-xl border border-border p-4">
              <div className="flex h-12 w-12 items-center justify-center rounded-full bg-primary text-lg font-bold text-white">
                {listing.owner.firstName[0]}
              </div>
              <div>
                <p className="font-semibold">
                  {listing.owner.firstName} {listing.owner.lastName}
                  {listing.owner.isTrustedUser && (
                    <span className="ml-2 rounded-full bg-primary/10 px-2 py-0.5 text-xs text-primary">
                      Trusted
                    </span>
                  )}
                </p>
                <p className="text-sm text-muted">Listing owner</p>
              </div>
            </div>
          </div>
        </div>

        <aside className="h-fit rounded-xl border border-border bg-card p-6 shadow-sm lg:sticky lg:top-24">
          <p className="text-2xl font-bold">
            {formatPrice(listing.pricePerDay)}
            <span className="text-base font-normal text-muted"> / day</span>
          </p>
          <p className="mt-1 text-sm text-muted">
            Security deposit: {formatPrice(listing.securityDeposit)}
          </p>

          <div className="mt-6 rounded-xl border border-dashed border-border p-4 text-center text-sm text-muted">
            Booking &amp; availability calendar coming in Phase 4
          </div>

          <Button href="/login" className="mt-4 w-full">
            Sign in to book
          </Button>

          <Link
            href={`/listings/new`}
            className="mt-3 block text-center text-sm text-primary hover:underline"
          >
            List your own gear
          </Link>
        </aside>
      </div>
    </div>
  );
}
