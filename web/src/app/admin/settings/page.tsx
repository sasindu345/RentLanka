"use client";

import { useEffect, useState } from "react";
import { getAdminSettings, updateAdminSettings } from "@/lib/api/admin";

export default function AdminSettingsPage() {
  const [commissionPercent, setCommissionPercent] = useState<number>(10);
  const [categories, setCategories] = useState<string[]>([]);
  const [newCategory, setNewCategory] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [errorMsg, setErrorMsg] = useState("");
  const [successMsg, setSuccessMsg] = useState("");

  useEffect(() => {
    loadSettings();
  }, []);

  async function loadSettings() {
    setLoading(true);
    setErrorMsg("");
    try {
      const res = await getAdminSettings();
      setCommissionPercent(Math.round(res.commissionRate * 100));
      setCategories(res.categories);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "Failed to load platform settings.";
      setErrorMsg(msg);
    } finally {
      setLoading(false);
    }
  }

  function handleAddCategory(e: React.FormEvent) {
    e.preventDefault();
    const tag = newCategory.trim();
    if (!tag) return;
    if (categories.some((c) => c.toLowerCase() == tag.toLowerCase())) {
      alert("Category already exists.");
      return;
    }
    setCategories((prev) => [...prev, tag]);
    setNewCategory("");
  }

  function handleRemoveCategory(categoryToRemove: string) {
    if (categories.length <= 1) {
      alert("You must keep at least one category tag.");
      return;
    }
    setCategories((prev) => prev.filter((c) => c !== categoryToRemove));
  }

  async function handleSaveSettings() {
    if (commissionPercent < 0 || commissionPercent > 100) {
      setErrorMsg("Commission percentage must be between 0 and 100.");
      return;
    }

    setSaving(true);
    setErrorMsg("");
    setSuccessMsg("");

    try {
      const rate = commissionPercent / 100;
      await updateAdminSettings({
        commissionRate: rate,
        categories,
      });
      setSuccessMsg("Platform settings saved successfully!");
      loadSettings();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "Failed to save settings.";
      setErrorMsg(msg);
    } finally {
      setSaving(false);
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[300px]">
        <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-indigo-500"></div>
        <span className="ml-3 text-slate-400 text-sm">Loading settings configuration...</span>
      </div>
    );
  }

  return (
    <div className="space-y-8 max-w-4xl">
      <div>
        <h2 className="text-xl font-bold text-slate-100">Platform Settings</h2>
        <p className="text-sm text-slate-400 mt-1">Configure global transaction fees and listing category options.</p>
      </div>

      {successMsg && (
        <div className="p-4 bg-emerald-950/30 border border-emerald-500/20 text-emerald-400 rounded-xl text-sm transition-all duration-200">
          ✅ {successMsg}
        </div>
      )}

      {errorMsg && (
        <div className="p-4 bg-rose-950/30 border border-rose-500/20 text-rose-400 rounded-xl text-sm transition-all duration-200">
          ❌ {errorMsg}
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
        {/* Financial Configuration */}
        <div className="p-6 rounded-2xl border border-slate-800 bg-slate-900/20 backdrop-blur-md space-y-6">
          <div>
            <h3 className="font-bold text-slate-200 text-lg">Escrow & Fees</h3>
            <p className="text-xs text-slate-500 mt-1">Configure platform commission charged on completed rentals.</p>
          </div>

          <div className="space-y-2">
            <label className="block text-sm font-semibold text-slate-300">
              Platform Commission Fee Percentage
            </label>
            <div className="relative rounded-xl shadow-sm">
              <input
                type="number"
                min="0"
                max="100"
                value={commissionPercent}
                onChange={(e) => setCommissionPercent(Number(e.target.value))}
                className="w-full bg-slate-900 border border-slate-800 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 rounded-xl py-3 pl-4 pr-12 text-sm text-slate-200 focus:outline-none transition"
                placeholder="10"
              />
              <div className="absolute inset-y-0 right-0 pr-4 flex items-center pointer-events-none">
                <span className="text-slate-400 text-sm font-bold">%</span>
              </div>
            </div>
            <p className="text-xs text-slate-500">
              For example, 10% means the platform takes 10% and the host receives 90% of the booking price.
            </p>
          </div>
        </div>

        {/* Categories Taxonomy */}
        <div className="p-6 rounded-2xl border border-slate-800 bg-slate-900/20 backdrop-blur-md space-y-6">
          <div>
            <h3 className="font-bold text-slate-200 text-lg">Marketplace Categories</h3>
            <p className="text-xs text-slate-500 mt-1">Manage listing categories options visible to users on the mobile client.</p>
          </div>

          {/* Add Category Input */}
          <form onSubmit={handleAddCategory} className="flex gap-2">
            <input
              type="text"
              value={newCategory}
              onChange={(e) => setNewCategory(e.target.value)}
              className="flex-1 bg-slate-900 border border-slate-800 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 rounded-xl py-2.5 px-4 text-sm text-slate-200 focus:outline-none transition"
              placeholder="e.g. Vehicles, Audio Gear"
            />
            <button
              type="submit"
              className="px-4 py-2.5 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl text-sm font-semibold transition cursor-pointer flex-shrink-0"
            >
              ➕ Add
            </button>
          </form>

          {/* Categories List */}
          <div className="space-y-2">
            <label className="block text-sm font-semibold text-slate-300">
              Active Category Tags
            </label>
            <div className="flex flex-wrap gap-2 p-3 bg-slate-900/40 border border-slate-900 rounded-xl min-h-[100px] align-top">
              {categories.map((c) => (
                <span
                  key={c}
                  className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-slate-800 text-xs font-semibold text-slate-200 border border-slate-700/50"
                >
                  {c}
                  <button
                    type="button"
                    onClick={() => handleRemoveCategory(c)}
                    className="w-4 h-4 rounded-full hover:bg-slate-700 flex items-center justify-center text-slate-400 hover:text-slate-100 transition cursor-pointer"
                  >
                    ×
                  </button>
                </span>
              ))}
            </div>
          </div>
        </div>
      </div>

      <div className="flex justify-end pt-4 border-t border-slate-900">
        <button
          onClick={handleSaveSettings}
          disabled={saving}
          className="px-6 py-3 bg-indigo-600 hover:bg-indigo-500 disabled:bg-indigo-800 text-white rounded-xl text-sm font-bold shadow-lg shadow-indigo-500/10 hover:shadow-indigo-500/20 transition cursor-pointer"
        >
          {saving ? "💾 Saving Settings..." : "💾 Save Changes"}
        </button>
      </div>
    </div>
  );
}
