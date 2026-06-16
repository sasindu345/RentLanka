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
}

export interface AuthResponse {
  token: string;
}

export interface ApiError {
  error: string;
}
