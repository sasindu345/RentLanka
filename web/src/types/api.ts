export interface OwnerSummary {
  id: string;
  firstName: string;
  lastName: string;
  avatarUrl: string | null;
  isTrustedUser: boolean;
  verificationLevel: number;
}

export interface Listing {
  id: string;
  ownerId: string;
  owner: OwnerSummary;
  title: string;
  description: string;
  category: string;
  pricePerDay: number;
  securityDeposit: number;
  rules: string;
  latitude: number;
  longitude: number;
  district: string;
  images: string[];
  isPaused: boolean;
  status: string;
  createdAt: string;
  updatedAt: string | null;
}

export interface PaginatedListings {
  items: Listing[];
  total: number;
  page: number;
  pageSize: number;
}

export interface UserProfile {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  phoneNumber: string;
  verificationLevel: number;
  isTrustedUser: boolean;
  avatarUrl: string | null;
  createdAt: string;
  role: string;
  isBanned: boolean;
  nicNumber: string | null;
  nicDocumentUrl: string | null;
}

export interface AuthResponse {
  token: string;
}

export interface ApiError {
  error: string;
}

export interface AdminDashboardStats {
  totalUsers: number;
  activeListings: number;
  pendingKycCount: number;
  totalBookingsCount: number;
  openDisputesCount: number;
}

export interface PaginatedUsers {
  items: UserProfile[];
  total: number;
  page: number;
  pageSize: number;
}

export interface BookingResponse {
  id: string;
  listingId: string;
  listingTitle: string;
  listingImage: string | null;
  renterId: string;
  renterName: string;
  ownerId: string;
  ownerName: string;
  startDate: string;
  endDate: string;
  totalPrice: number;
  securityDeposit: number;
  status: string;
  createdAt: string;
  updatedAt: string | null;
}

export interface PaymentResponse {
  id: string;
  bookingId: string;
  listingTitle: string;
  renterName: string;
  amount: number;
  status: string;
  transactionReference: string;
  createdAt: string;
}

export interface PayoutResponse {
  id: string;
  ownerId: string;
  ownerName: string;
  amount: number;
  bankName: string;
  accountNumber: string;
  accountName: string;
  status: string;
  createdAt: string;
  updatedAt: string | null;
}

export interface ReviewResponse {
  id: string;
  bookingId: string;
  reviewerId: string;
  reviewerName: string;
  targetUserId: string;
  rating: number;
  comment: string;
  isRenterReview: boolean;
  createdAt: string;
}

export interface DisputeResponse {
  id: string;
  bookingId: string;
  listingTitle: string;
  createdById: string;
  createdByName: string;
  reason: string;
  isResolved: boolean;
  adminDecision: string | null;
  createdAt: string;
  resolvedAt: string | null;
  resolvedByName: string | null;
}

export interface PlatformSettingResponse {
  id: string;
  commissionRate: number;
  categories: string[];
  updatedAt: string;
}
