const TOKEN_KEY = "rentlanka_token";

export function getToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem(TOKEN_KEY);
}

export function setToken(token: string): void {
  localStorage.setItem(TOKEN_KEY, token);
  if (typeof document !== "undefined") {
    document.cookie = `${TOKEN_KEY}=${token}; path=/; max-age=86400; SameSite=Strict; Secure`;
  }
}

export function clearToken(): void {
  localStorage.removeItem(TOKEN_KEY);
  if (typeof document !== "undefined") {
    document.cookie = `${TOKEN_KEY}=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT; SameSite=Strict; Secure`;
  }
}

export function isAuthenticated(): boolean {
  return !!getToken();
}
