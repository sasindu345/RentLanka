import { apiRequest, apiUpload } from "@/lib/api/client";
import type {
  AuthResponse,
  Listing,
  PaginatedListings,
  UserProfile,
} from "@/types/api";

export interface SearchParams {
  query?: string;
  category?: string;
  district?: string;
  lat?: number;
  lon?: number;
  distanceMeters?: number;
  minPrice?: number;
  maxPrice?: number;
  page?: number;
  pageSize?: number;
  sortBy?: string;
}

export function login(email: string, password: string) {
  return apiRequest<AuthResponse>("/api/auth/login", {
    method: "POST",
    body: { email, password },
  });
}

export function register(data: {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  phoneNumber: string;
}) {
  return apiRequest<{ userId: string; message: string }>("/api/auth/register", {
    method: "POST",
    body: data,
  });
}

export function getCurrentUser() {
  return apiRequest<UserProfile>("/api/users/me", { auth: true });
}

export function searchListings(params: SearchParams = {}) {
  const query = new URLSearchParams();
  Object.entries(params).forEach(([key, value]) => {
    if (value !== undefined && value !== "") {
      query.set(key, String(value));
    }
  });
  const qs = query.toString();
  return apiRequest<PaginatedListings>(
    `/api/listings/search${qs ? `?${qs}` : ""}`
  );
}

export function getListing(id: string) {
  return apiRequest<Listing>(`/api/listings/${id}`, { auth: true });
}

export function getMyListings() {
  return apiRequest<Listing[]>("/api/listings/mine", { auth: true });
}

export function createListing(data: Record<string, unknown>) {
  return apiRequest<Listing>("/api/listings", {
    method: "POST",
    auth: true,
    body: data,
  });
}

export function updateListing(id: string, data: Record<string, unknown>) {
  return apiRequest<Listing>(`/api/listings/${id}`, {
    method: "PUT",
    auth: true,
    body: data,
  });
}

export function deleteListing(id: string) {
  return apiRequest<void>(`/api/listings/${id}`, {
    method: "DELETE",
    auth: true,
  });
}

export function toggleListingPause(id: string) {
  return apiRequest<Listing>(`/api/listings/${id}/pause`, {
    method: "PATCH",
    auth: true,
  });
}

export function getWishlist(page = 1) {
  return apiRequest<PaginatedListings>(
    `/api/wishlist?page=${page}`,
    { auth: true }
  );
}

export function addToWishlist(listingId: string) {
  return apiRequest<{ message: string }>(`/api/wishlist/${listingId}`, {
    method: "POST",
    auth: true,
  });
}

export function removeFromWishlist(listingId: string) {
  return apiRequest<void>(`/api/wishlist/${listingId}`, {
    method: "DELETE",
    auth: true,
  });
}

export function uploadListingImage(file: File) {
  return apiUpload<{ imageUrl: string }>("/api/file/listing-image", file);
}

export function formatPrice(amount: number) {
  return `LKR ${amount.toLocaleString("en-LK", { minimumFractionDigits: 0 })}`;
}
