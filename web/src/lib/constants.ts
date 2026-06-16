export const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:5021";

export const CATEGORIES = [
  "Photography",
  "Tools",
  "Camping",
  "Electronics",
  "Sports",
  "Other",
] as const;

export const DISTRICTS = [
  "Colombo",
  "Gampaha",
  "Kalutara",
  "Kandy",
  "Galle",
  "Matara",
  "Jaffna",
  "Negombo",
] as const;
