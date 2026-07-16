"use client";

import { create } from "zustand";
import { persist } from "zustand/middleware";
import { THEME_CONFIG } from "@/shared/constants/config";

// null accent = use the built-in CSS default (SyferX cyan)
const useThemeStore = create(
  persist(
    (set, get) => ({
      theme: THEME_CONFIG.defaultTheme,
      accentColor: null,

      setTheme: (theme) => {
        set({ theme });
        applyTheme(theme);
      },

      toggleTheme: () => {
        const currentTheme = get().theme;
        const newTheme = currentTheme === "dark" ? "light" : "dark";
        set({ theme: newTheme });
        applyTheme(newTheme);
      },

      setAccentColor: (hex) => {
        set({ accentColor: hex || null });
        applyAccent(hex || null);
      },

      initTheme: () => {
        applyTheme(get().theme);
        applyAccent(get().accentColor);
      },
    }),
    {
      name: THEME_CONFIG.storageKey,
    }
  )
);

// Apply light/dark theme to document
function applyTheme(theme) {
  if (typeof window === "undefined") return;

  const root = document.documentElement;
  const systemTheme = window.matchMedia("(prefers-color-scheme: dark)").matches
    ? "dark"
    : "light";

  const effectiveTheme = theme === "system" ? systemTheme : theme;

  if (effectiveTheme === "dark") {
    root.classList.add("dark");
  } else {
    root.classList.remove("dark");
  }
}

// ── Accent color engine ─────────────────────────────────────
// Parse "#rrggbb" → {r,g,b}
function hexToRgb(hex) {
  const m = /^#?([0-9a-f]{6})$/i.exec(hex || "");
  if (!m) return null;
  const int = parseInt(m[1], 16);
  return { r: (int >> 16) & 255, g: (int >> 8) & 255, b: int & 255 };
}

function rgbToHex(r, g, b) {
  const c = (v) => Math.max(0, Math.min(255, Math.round(v))).toString(16).padStart(2, "0");
  return `#${c(r)}${c(g)}${c(b)}`;
}

// Mix a color toward white (amount>0) or black (amount<0), -1..1
function mix(rgb, amount) {
  const target = amount >= 0 ? 255 : 0;
  const t = Math.abs(amount);
  return {
    r: rgb.r + (target - rgb.r) * t,
    g: rgb.g + (target - rgb.g) * t,
    b: rgb.b + (target - rgb.b) * t,
  };
}

// Generate a 50..900 tonal scale from one base hex (base = 500)
function buildScale(baseHex) {
  const base = hexToRgb(baseHex);
  if (!base) return null;
  const steps = {
    50: mix(base, 0.90), 100: mix(base, 0.80), 200: mix(base, 0.60),
    300: mix(base, 0.40), 400: mix(base, 0.20), 500: base,
    600: mix(base, -0.15), 700: mix(base, -0.30), 800: mix(base, -0.45),
    900: mix(base, -0.60),
  };
  const out = {};
  for (const [k, v] of Object.entries(steps)) out[k] = rgbToHex(v.r, v.g, v.b);
  return out;
}

// Apply (or clear) the custom accent as inline CSS variable overrides
function applyAccent(hex) {
  if (typeof window === "undefined") return;
  const root = document.documentElement;
  const vars = [
    "--color-brand-50", "--color-brand-100", "--color-brand-200", "--color-brand-300",
    "--color-brand-400", "--color-brand-500", "--color-brand-600", "--color-brand-700",
    "--color-brand-800", "--color-brand-900", "--color-primary", "--color-primary-hover",
    "--color-accent",
  ];
  if (!hex) { for (const v of vars) root.style.removeProperty(v); return; }
  const scale = buildScale(hex);
  if (!scale) return;
  root.style.setProperty("--color-brand-50", scale[50]);
  root.style.setProperty("--color-brand-100", scale[100]);
  root.style.setProperty("--color-brand-200", scale[200]);
  root.style.setProperty("--color-brand-300", scale[300]);
  root.style.setProperty("--color-brand-400", scale[400]);
  root.style.setProperty("--color-brand-500", scale[500]);
  root.style.setProperty("--color-brand-600", scale[600]);
  root.style.setProperty("--color-brand-700", scale[700]);
  root.style.setProperty("--color-brand-800", scale[800]);
  root.style.setProperty("--color-brand-900", scale[900]);
  root.style.setProperty("--color-primary", scale[500]);
  root.style.setProperty("--color-primary-hover", scale[600]);
  root.style.setProperty("--color-accent", scale[500]);
}

export default useThemeStore;

