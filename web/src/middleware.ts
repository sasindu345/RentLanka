import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

function parseJwt(token: string) {
  try {
    const base64Url = token.split(".")[1];
    if (!base64Url) return null;
    const base64 = base64Url.replace(/-/g, "+").replace(/_/g, "/");
    const jsonPayload = decodeURIComponent(
      atob(base64)
        .split("")
        .map((c) => "%" + ("00" + c.charCodeAt(0).toString(16)).slice(-2))
        .join("")
    );
    return JSON.parse(jsonPayload);
  } catch {
    return null;
  }
}

export function middleware(request: NextRequest) {
  const token = request.cookies.get("rentlanka_token")?.value;
  const isLoginPage = request.nextUrl.pathname === "/login";
  const isAdminPath = request.nextUrl.pathname.startsWith("/admin");

  let isAdmin = false;
  if (token) {
    const payload = parseJwt(token);
    if (payload) {
      const exp = payload.exp;
      const isExpired = exp ? Date.now() >= exp * 1000 : false;
      const role =
        payload["http://schemas.microsoft.com/ws/2008/06/identity/claims/role"] ||
        payload["role"];
      
      if (!isExpired && role === "Admin") {
        isAdmin = true;
      }
    }
  }

  // Redirect non-admins trying to access admin paths to login
  if (isAdminPath && !isAdmin) {
    const loginUrl = new URL("/login", request.url);
    return NextResponse.redirect(loginUrl);
  }

  // Redirect logged-in admins trying to access login page to dashboard
  if (isLoginPage && isAdmin) {
    const adminUrl = new URL("/admin", request.url);
    return NextResponse.redirect(adminUrl);
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/admin/:path*", "/admin", "/login"],
};
