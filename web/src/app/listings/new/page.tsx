"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { CATEGORIES, DISTRICTS } from "@/lib/constants";
import {
  createListing,
  uploadListingImage,
} from "@/lib/api/listings";
import { isAuthenticated } from "@/lib/auth/token";

export default function CreateListingPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [images, setImages] = useState<string[]>([]);
  const [form, setForm] = useState({
    title: "",
    description: "",
    category: CATEGORIES[0],
    pricePerDay: "",
    securityDeposit: "",
    rules: "",
    latitude: "6.9271",
    longitude: "79.8612",
    district: DISTRICTS[0],
  });

  useEffect(() => {
    if (!isAuthenticated()) {
      router.replace("/login");
    }
  }, [router]);

  function update(field: string, value: string) {
    setForm((prev) => ({ ...prev, [field]: value }));
  }

  async function handleImageUpload(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    setError("");
    try {
      const { imageUrl } = await uploadListingImage(file);
      setImages((prev) => [...prev, imageUrl]);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Image upload failed");
    }
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      const listing = await createListing({
        title: form.title,
        description: form.description,
        category: form.category,
        pricePerDay: Number(form.pricePerDay),
        securityDeposit: Number(form.securityDeposit),
        rules: form.rules,
        latitude: Number(form.latitude),
        longitude: Number(form.longitude),
        district: form.district,
        images,
      });
      router.push(`/listings/${listing.id}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to create listing");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="mx-auto max-w-2xl px-4 py-12">
      <h1 className="text-3xl font-bold">List your gear</h1>
      <p className="mt-2 text-muted">Phone verification (Level 1) is required to publish.</p>

      <form onSubmit={handleSubmit} className="mt-8 space-y-5">
        <Input
          label="Title"
          required
          value={form.title}
          onChange={(e) => update("title", e.target.value)}
        />
        <label className="flex flex-col gap-1.5 text-sm">
          <span className="font-medium">Description</span>
          <textarea
            required
            rows={4}
            value={form.description}
            onChange={(e) => update("description", e.target.value)}
            className="rounded-xl border border-border bg-background px-4 py-2.5 outline-none focus:border-primary"
          />
        </label>

        <label className="flex flex-col gap-1.5 text-sm">
          <span className="font-medium">Category</span>
          <select
            value={form.category}
            onChange={(e) => update("category", e.target.value)}
            className="rounded-xl border border-border bg-background px-4 py-2.5"
          >
            {CATEGORIES.map((c) => (
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </select>
        </label>

        <div className="grid grid-cols-2 gap-3">
          <Input
            label="Price per day (LKR)"
            type="number"
            required
            min={0}
            value={form.pricePerDay}
            onChange={(e) => update("pricePerDay", e.target.value)}
          />
          <Input
            label="Security deposit (LKR)"
            type="number"
            required
            min={0}
            value={form.securityDeposit}
            onChange={(e) => update("securityDeposit", e.target.value)}
          />
        </div>

        <label className="flex flex-col gap-1.5 text-sm">
          <span className="font-medium">District</span>
          <select
            value={form.district}
            onChange={(e) => update("district", e.target.value)}
            className="rounded-xl border border-border bg-background px-4 py-2.5"
          >
            {DISTRICTS.map((d) => (
              <option key={d} value={d}>
                {d}
              </option>
            ))}
          </select>
        </label>

        <Input
          label="Rental rules"
          value={form.rules}
          onChange={(e) => update("rules", e.target.value)}
        />

        <div className="grid grid-cols-2 gap-3">
          <Input
            label="Latitude"
            type="number"
            step="any"
            required
            value={form.latitude}
            onChange={(e) => update("latitude", e.target.value)}
          />
          <Input
            label="Longitude"
            type="number"
            step="any"
            required
            value={form.longitude}
            onChange={(e) => update("longitude", e.target.value)}
          />
        </div>

        <label className="flex flex-col gap-1.5 text-sm">
          <span className="font-medium">Photos</span>
          <input type="file" accept="image/*" onChange={handleImageUpload} />
          {images.length > 0 && (
            <p className="text-xs text-muted">{images.length} image(s) uploaded</p>
          )}
        </label>

        {error && <p className="text-sm text-red-600">{error}</p>}

        <Button type="submit" disabled={loading} className="w-full">
          {loading ? "Publishing..." : "Publish listing"}
        </Button>
      </form>
    </div>
  );
}
