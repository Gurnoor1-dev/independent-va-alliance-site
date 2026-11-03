import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
export default defineConfig({
  plugins: [react()],
  build: {
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (!id.includes('node_modules')) return;
          if (id.includes('react-router') || id.includes('/react/') || id.includes('react-dom')) return 'react-vendor';
          if (id.includes('framer-motion')) return 'motion-vendor';
          if (id.includes('lucide-react')) return 'icons-vendor';
          if (id.includes('@supabase')) return 'supabase-vendor';
        }
      }
    }
  }
});
