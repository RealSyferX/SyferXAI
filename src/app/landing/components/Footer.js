"use client";

import Link from "next/link";

export default function Footer() {
  return (
    <footer className="border-t border-[#232d3b] bg-[#0f141c] pt-16 pb-8 px-6">
      <div className="max-w-7xl mx-auto">
        <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-5 gap-8 mb-16">
          {/* Brand */}
          <div className="col-span-2 lg:col-span-2">
            <div className="flex items-center gap-3 mb-6">
              <div className="size-6 rounded bg-linear-to-br from-[#22d3ee] to-[#0891b2] flex items-center justify-center text-white">
                <svg viewBox="0 0 32 32" className="w-4 h-4" fill="none">
                  <path d="M8 8L16 16L8 24" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"/>
                  <path d="M17 24H24" stroke="white" strokeWidth="2.5" strokeLinecap="round"/>
                </svg>
              </div>
              <h3 className="text-white text-lg font-bold">Syfer<span className="text-[#22d3ee]">X</span></h3>
            </div>
            <p className="text-gray-500 text-sm max-w-xs mb-6">
              The unified endpoint for AI generation. Connect, route, and manage your AI providers with ease.
            </p>
            <div className="flex gap-4">
              <a className="text-gray-400 hover:text-white transition-colors" href="https://github.com/SyferX/SyferX" target="_blank" rel="noopener noreferrer">
                <span className="material-symbols-outlined">code</span>
              </a>
            </div>
          </div>
          
          {/* Product */}
          <div className="flex flex-col gap-4">
            <h4 className="font-bold text-white">Product</h4>
            <a className="text-gray-400 hover:text-[#22d3ee] text-sm transition-colors" href="#features">Features</a>
            <Link className="text-gray-400 hover:text-[#22d3ee] text-sm transition-colors" href="/dashboard">Dashboard</Link>
            <a className="text-gray-400 hover:text-[#22d3ee] text-sm transition-colors" href="https://github.com/SyferX/SyferX" target="_blank" rel="noopener noreferrer">Changelog</a>
          </div>
          
          {/* Resources */}
          <div className="flex flex-col gap-4">
            <h4 className="font-bold text-white">Resources</h4>
            <a className="text-gray-400 hover:text-[#22d3ee] text-sm transition-colors" href="https://github.com/SyferX/SyferX#readme" target="_blank" rel="noopener noreferrer">Documentation</a>
            <a className="text-gray-400 hover:text-[#22d3ee] text-sm transition-colors" href="https://github.com/SyferX/SyferX" target="_blank" rel="noopener noreferrer">GitHub</a>
            <a className="text-gray-400 hover:text-[#22d3ee] text-sm transition-colors" href="https://www.npmjs.com/package/syferx" target="_blank" rel="noopener noreferrer">NPM</a>
          </div>
          
          {/* Legal */}
          <div className="flex flex-col gap-4">
            <h4 className="font-bold text-white">Legal</h4>
            <a className="text-gray-400 hover:text-[#22d3ee] text-sm transition-colors" href="https://github.com/SyferX/SyferX/blob/main/LICENSE" target="_blank" rel="noopener noreferrer">MIT License</a>
          </div>
        </div>
        
        {/* Bottom */}
        <div className="border-t border-[#232d3b] pt-8 flex flex-col md:flex-row justify-between items-center gap-4">
          <p className="text-gray-600 text-sm">© 2025 SyferX. All rights reserved.</p>
          <div className="flex gap-6">
            <a className="text-gray-600 hover:text-white text-sm transition-colors" href="https://github.com/SyferX/SyferX" target="_blank" rel="noopener noreferrer">GitHub</a>
            <a className="text-gray-600 hover:text-white text-sm transition-colors" href="https://www.npmjs.com/package/syferx" target="_blank" rel="noopener noreferrer">NPM</a>
          </div>
        </div>
      </div>
    </footer>
  );
}

