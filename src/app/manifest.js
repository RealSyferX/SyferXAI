export default function manifest() {
  return {
    name: 'SyferX - AI Infrastructure Management',
    short_name: 'SyferX',
    description: 'One endpoint for all your AI providers. Manage keys, monitor usage, and scale effortlessly.',
    start_url: '/',
    display: 'standalone',
    background_color: '#0a0e14',
    theme_color: '#06b6d4',
    orientation: 'portrait-primary',
    icons: [
      {
        src: '/icons/icon-192.svg',
        sizes: '192x192',
        type: 'image/svg+xml',
      },
      {
        src: '/icons/icon-512.svg',
        sizes: '512x512',
        type: 'image/svg+xml',
      },
      {
        src: '/icons/icon-512.svg',
        sizes: '512x512',
        type: 'image/svg+xml',
        purpose: 'maskable',
      },
    ],
  }
}
