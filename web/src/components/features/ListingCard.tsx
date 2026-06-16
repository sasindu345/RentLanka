import Link from "next/link";
import Image from "next/image";
import { formatPrice } from "@/lib/api/listings";
import type { Listing } from "@/types/api";

interface ListingCardProps {
  listing: Listing;
}

export function ListingCard({ listing }: ListingCardProps) {
  const imageUrl = listing.images[0] ?? null;

  return (
    <Link
      href={`/listings/${listing.id}`}
      className="group overflow-hidden rounded-xl border border-border bg-card shadow-sm transition hover:shadow-md"
    >
      <div className="relative aspect-[4/3] bg-border">
        {imageUrl ? (
          <Image
            src={imageUrl}
            alt={listing.title}
            fill
            className="object-cover transition group-hover:scale-105"
            sizes="(max-width: 768px) 100vw, 33vw"
            unoptimized
          />
        ) : (
          <div className="flex h-full items-center justify-center text-muted">
            No image
          </div>
        )}
        {listing.owner.isTrustedUser && (
          <span className="absolute left-3 top-3 rounded-full bg-primary px-2 py-0.5 text-xs font-medium text-white">
            Trusted
          </span>
        )}
      </div>
      <div className="p-4">
        <p className="text-xs font-medium uppercase tracking-wide text-primary">
          {listing.category}
        </p>
        <h3 className="mt-1 line-clamp-1 text-lg font-semibold">{listing.title}</h3>
        <p className="mt-1 text-sm text-muted">{listing.district}</p>
        <p className="mt-2 font-semibold">
          {formatPrice(listing.pricePerDay)}
          <span className="text-sm font-normal text-muted"> / day</span>
        </p>
      </div>
    </Link>
  );
}
