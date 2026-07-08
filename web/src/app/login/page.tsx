"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import Image from "next/image";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { login } from "@/lib/api/listings";
import { setToken } from "@/lib/auth/token";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      const { token } = await login(email, password);
      setToken(token);
      router.push("/");
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Login failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="grid min-h-screen lg:grid-cols-2 bg-slate-950">
      
      {/* Side banner image section (Hidden on mobile) */}
      <div className="relative hidden lg:block overflow-hidden border-r border-slate-800/80">
        <Image
          src="/images/login_side_banner.png"
          alt="RentLanka Premium Gear Rentals"
          fill
          priority
          className="object-cover object-center filter brightness-90 contrast-105"
        />
        {/* Soft solid overlay to melt it into our Slate theme */}
        <div className="absolute inset-0 bg-slate-950/50 pointer-events-none" />
      </div>

      {/* Form Container */}
      <div className="flex flex-col justify-center items-center p-6 sm:p-12">
        <div className="w-full max-w-md space-y-8 bg-slate-900/30 border border-slate-800/80 rounded-2xl p-8 backdrop-blur-md shadow-2xl">
          
          {/* Header */}
          <div className="text-center">
            <h1 className="text-3xl font-extrabold text-slate-100 tracking-tight">Welcome Back</h1>
            <p className="mt-2 text-sm text-slate-400">Sign in to manage your platform operations</p>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-6 mt-8">
            <div className="space-y-4">
              <Input
                label="Email Address"
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="bg-slate-950 border-slate-800 text-slate-100 placeholder-slate-500 focus:border-indigo-500"
              />
              <Input
                label="Password"
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="bg-slate-950 border-slate-800 text-slate-100 placeholder-slate-500 focus:border-indigo-500"
              />
            </div>

            {error && (
              <div className="p-3 bg-red-950/30 border border-red-800/40 rounded-xl text-xs text-red-400">
                {error}
              </div>
            )}

            <Button
              type="submit"
              disabled={loading}
              className="w-full py-3 bg-indigo-600 hover:bg-indigo-500 text-white font-semibold rounded-xl shadow-lg shadow-indigo-500/20 active:translate-y-0.5 transition duration-150 cursor-pointer"
            >
              {loading ? "Signing in..." : "Sign in"}
            </Button>
          </form>

          {/* Link back */}
          <p className="text-center text-xs text-slate-500 mt-6">
            Don&apos;t have an account?{" "}
            <Link href="/register" className="font-semibold text-indigo-400 hover:underline">
              Sign up
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}
