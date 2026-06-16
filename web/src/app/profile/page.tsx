"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/Button";
import { getCurrentUser } from "@/lib/api/listings";
import { isAuthenticated } from "@/lib/auth/token";
import type { UserProfile } from "@/types/api";

const VERIFICATION_STEPS = [
  { level: 0, label: "Email verified" },
  { level: 1, label: "Phone verified" },
  { level: 2, label: "NIC submitted" },
  { level: 3, label: "Face verified (Trusted)" },
];

export default function ProfilePage() {
  const router = useRouter();
  const [user, setUser] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!isAuthenticated()) {
      router.replace("/login");
      return;
    }
    getCurrentUser()
      .then(setUser)
      .catch(() => router.replace("/login"))
      .finally(() => setLoading(false));
  }, [router]);

  if (loading) {
    return <div className="p-16 text-center text-muted">Loading profile...</div>;
  }

  if (!user) return null;

  return (
    <div className="mx-auto max-w-2xl px-4 py-12">
      <h1 className="text-3xl font-bold">Your profile</h1>

      <div className="mt-8 rounded-xl border border-border bg-card p-6">
        <div className="flex items-center gap-4">
          <div className="flex h-16 w-16 items-center justify-center rounded-full bg-primary text-2xl font-bold text-white">
            {user.firstName[0]}
          </div>
          <div>
            <p className="text-xl font-semibold">
              {user.firstName} {user.lastName}
            </p>
            <p className="text-muted">{user.email}</p>
            <p className="text-sm text-muted">{user.phoneNumber}</p>
          </div>
        </div>
      </div>

      <div className="mt-6 rounded-xl border border-border bg-card p-6">
        <h2 className="font-semibold">Verification progress</h2>
        <ul className="mt-4 space-y-3">
          {VERIFICATION_STEPS.map((step) => {
            const done = user.verificationLevel >= step.level;
            return (
              <li key={step.level} className="flex items-center gap-3 text-sm">
                <span
                  className={`flex h-6 w-6 items-center justify-center rounded-full text-xs font-bold ${
                    done ? "bg-primary text-white" : "bg-border text-muted"
                  }`}
                >
                  {done ? "✓" : step.level + 1}
                </span>
                <span className={done ? "text-foreground" : "text-muted"}>
                  {step.label}
                </span>
              </li>
            );
          })}
        </ul>
        <p className="mt-4 text-sm text-muted">
          Complete verification via the mobile app or API to unlock booking and listing features.
        </p>
      </div>

      <div className="mt-6 flex gap-3">
        <Button href="/dashboard/owner/listings" variant="secondary">
          Owner dashboard
        </Button>
        <Button href="/saved" variant="ghost">
          Saved items
        </Button>
      </div>
    </div>
  );
}
