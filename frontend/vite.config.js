import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  define: {
    __BUILD_SHA__: JSON.stringify(process.env.GITHUB_SHA || 'local'),
    __BUILD_TIME__: JSON.stringify(new Date().toISOString()),
  },
  test: { environment: 'node' },
})
