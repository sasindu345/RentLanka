import { apiRequest } from "@/lib/api/client";
import type {
  AdminDashboardStats,
  PaginatedUsers,
  PaginatedListings,
  UserProfile,
  BookingResponse,
  PaymentResponse,
  PayoutResponse,
  ReviewResponse,
  DisputeResponse,
} from "@/types/api";

export function getAdminDashboardStats() {
  return apiRequest<AdminDashboardStats>("/api/admin/dashboard", { auth: true });
}

export function getAdminUsers(params: { query?: string; page?: number; pageSize?: number } = {}) {
  const query = new URLSearchParams();
  Object.entries(params).forEach(([key, value]) => {
    if (value !== undefined && value !== "") {
      query.set(key, String(value));
    }
  });
  const qs = query.toString();
  return apiRequest<PaginatedUsers>(`/api/admin/users${qs ? `?${qs}` : ""}`, { auth: true });
}

export function getAdminUser(id: string) {
  return apiRequest<UserProfile>(`/api/admin/users/${id}`, { auth: true });
}

export function toggleUserBan(id: string) {
  return apiRequest<{ message: string }>(`/api/admin/users/${id}/ban`, {
    method: "PATCH",
    auth: true,
  });
}

export function overrideUserVerification(id: string, data: { level: number; isTrusted: boolean }) {
  return apiRequest<{ message: string }>(`/api/admin/users/${id}/verify-override`, {
    method: "PATCH",
    auth: true,
    body: data,
  });
}

export function getAdminListings(params: { query?: string; isPaused?: boolean; status?: string; page?: number; pageSize?: number } = {}) {
  const query = new URLSearchParams();
  Object.entries(params).forEach(([key, value]) => {
    if (value !== undefined && value !== "") {
      query.set(key, String(value));
    }
  });
  const qs = query.toString();
  return apiRequest<PaginatedListings>(`/api/admin/listings${qs ? `?${qs}` : ""}`, { auth: true });
}

export function toggleListingPause(id: string) {
  return apiRequest<{ message: string }>(`/api/admin/listings/${id}/pause`, {
    method: "PATCH",
    auth: true,
  });
}

export function deleteListing(id: string) {
  return apiRequest<void>(`/api/admin/listings/${id}`, {
    method: "DELETE",
    auth: true,
  });
}

export function getKycQueue() {
  return apiRequest<UserProfile[]>("/api/admin/kyc", { auth: true });
}

export function approveKyc(userId: string) {
  return apiRequest<{ message: string }>(`/api/admin/kyc/${userId}/approve`, {
    method: "PATCH",
    auth: true,
  });
}

export function rejectKyc(userId: string) {
  return apiRequest<{ message: string }>(`/api/admin/kyc/${userId}/reject`, {
    method: "PATCH",
    auth: true,
  });
}

export function getAdminBookings() {
  return apiRequest<BookingResponse[]>("/api/admin/bookings", { auth: true });
}

export function getAdminPayments() {
  return apiRequest<PaymentResponse[]>("/api/admin/payments", { auth: true });
}

export function getAdminPayouts() {
  return apiRequest<PayoutResponse[]>("/api/admin/payouts", { auth: true });
}

export function approveAdminPayout(id: string) {
  return apiRequest<{ message: string }>(`/api/admin/payouts/${id}/approve`, {
    method: "PATCH",
    auth: true,
  });
}

export function approveListing(id: string) {
  return apiRequest<{ message: string }>(`/api/admin/listings/${id}/approve`, {
    method: "PATCH",
    auth: true,
  });
}

export function rejectListing(id: string) {
  return apiRequest<{ message: string }>(`/api/admin/listings/${id}/reject`, {
    method: "PATCH",
    auth: true,
  });
}

export function getUserReviews(userId: string) {
  return apiRequest<ReviewResponse[]>(`/api/reviews/users/${userId}`, { auth: true });
}

export function getAdminDisputes() {
  return apiRequest<DisputeResponse[]>("/api/admin/disputes", { auth: true });
}

export function resolveDispute(id: string, data: { adminDecision: string; refundRenter: boolean }) {
  return apiRequest<DisputeResponse>(`/api/admin/disputes/${id}/resolve`, {
    method: "PATCH",
    auth: true,
    body: data,
  });
}
