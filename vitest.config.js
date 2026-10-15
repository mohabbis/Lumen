import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
export default defineConfig({
  plugins: [react()],
  test: { include: ['src/**/*.test.{js,jsx}', 'lib/**/*.test.js', 'api/**/*.test.js'], environment: 'jsdom', globals: true, setupFiles: './src/test/setup.js', css: true }
});
