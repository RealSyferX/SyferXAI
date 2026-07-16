"use client";

export default function HeroSection() {
  return (
    <section className="relative pt-36 pb-24 px-6 min-h-[92vh] flex flex-col items-center justify-center overflow-hidden">
      {/* Dual glow effect */}
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[1000px] h-[520px] bg-[#06b6d4]/12 rounded-full blur-[130px] pointer-events-none"></div>
      <div className="absolute top-40 left-1/3 w-[420px] h-[420px] bg-[#0891b2]/10 rounded-full blur-[120px] pointer-events-none"></div>

      <div className="relative z-10 max-w-4xl w-full text-center flex flex-col items-center gap-8">
        {/* Version badge */}
        <div className="inline-flex items-center gap-2 rounded-full border border-[#22d3ee]/30 bg-[#131a24]/60 px-4 py-1.5 text-xs font-medium text-[#22d3ee] backdrop-blur-sm">
          <span className="flex h-2 w-2 rounded-full bg-[#22d3ee] animate-pulse"></span>
          v1.0 is now live &middot; open source
        </div>

        {/* Main heading */}
        <h1 className="text-5xl md:text-7xl font-black leading-[1.05] tracking-tight">
          One Endpoint for <br/>
          <span className="bg-gradient-to-r from-[#22d3ee] via-[#38bdf8] to-[#0891b2] bg-clip-text text-transparent">All AI Providers</span>
        </h1>

        {/* Description */}
        <p className="text-lg md:text-xl text-gray-400 max-w-2xl mx-auto font-light leading-relaxed">
          SyferX is a unified AI endpoint proxy with a web dashboard. Route Claude, OpenAI, Gemini and 40+ providers through one local API &mdash; with smart fallback, round-robin, and usage tracking.
        </p>

        {/* CTA Buttons */}
        <div className="flex flex-wrap items-center justify-center gap-4 w-full">
          <button type="button" className="h-13 px-8 py-3.5 rounded-xl bg-gradient-to-r from-[#06b6d4] to-[#0891b2] hover:from-[#22d3ee] hover:to-[#06b6d4] text-white text-base font-bold transition-all shadow-[0_8px_24px_-6px_rgba(6,182,212,0.5)] hover:shadow-[0_10px_30px_-6px_rgba(6,182,212,0.65)] hover:-translate-y-0.5 flex items-center gap-2">
            <span className="material-symbols-outlined">rocket_launch</span>
            Get Started
          </button>
          <a 
            href="https://github.com/SyferX/SyferX" 
            target="_blank" 
            rel="noopener noreferrer"
            className="h-13 px-8 py-3.5 rounded-xl border border-[#232d3b] bg-[#131a24]/70 hover:bg-[#1a222e] hover:border-[#22d3ee]/40 text-white text-base font-bold transition-all backdrop-blur-sm flex items-center gap-2"
          >
            <span className="material-symbols-outlined">code</span>
            View on GitHub
          </a>
        </div>

        {/* Trust stats row */}
        <div className="mt-6 flex flex-wrap items-center justify-center gap-x-10 gap-y-4">
          {[
            { value: "40+", label: "Providers" },
            { value: "100%", label: "Local & Private" },
            { value: "0ms", label: "Vendor Lock-in" },
            { value: "MIT", label: "Open Source" },
          ].map((s) => (
            <div key={s.label} className="flex flex-col items-center">
              <span className="text-2xl md:text-3xl font-black bg-gradient-to-r from-[#22d3ee] to-[#0891b2] bg-clip-text text-transparent">{s.value}</span>
              <span className="text-xs text-gray-500 uppercase tracking-wider mt-0.5">{s.label}</span>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

