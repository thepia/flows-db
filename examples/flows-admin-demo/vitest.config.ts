import { defineConfig } from 'vitest/config';
import { sveltekit } from '@sveltejs/kit/vite';

export default defineConfig({
  plugins: [sveltekit()],
  test: {
    include: [
      'tests/unit/**/*.{test,spec}.{js,ts}',
      'src/lib/tests/**/*.{test,spec}.{js,ts}'
    ],
    environment: 'jsdom',
    globals: true,
    setupFiles: ['tests/setup.ts', 'src/lib/tests/setup.ts'],
    coverage: {
      reporter: ['text', 'json', 'html'],
      include: ['src/lib/**/*.{js,ts,svelte}'],
      exclude: [
        'src/lib/tests/**',
        'src/lib/**/*.test.{js,ts}',
        'src/lib/**/*.spec.{js,ts}',
        'src/lib/types.ts'
      ]
    }
  },
  resolve: {
    alias: {
      '$lib': new URL('./src/lib', import.meta.url).pathname,
      '$app': new URL('./node_modules/@sveltejs/kit/src/runtime/app', import.meta.url).pathname
    }
  }
});