import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'

// Proxy must match Express PORT (see web/server/.env). If API uses 3002, set VITE_API_PROXY_TARGET=http://localhost:3002 in web/client/.env
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  const apiTarget = env.VITE_API_PROXY_TARGET || 'http://localhost:3001'

  return {
    plugins: [react()],
    server: {
      port: 5174,
      strictPort: false,
      proxy: {
        '/api': {
          target: apiTarget,
          changeOrigin: true,
        },
      },
    },
  }
})
