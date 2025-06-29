import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig, loadEnv } from 'vite';
import restart from 'vite-plugin-restart';

export default defineConfig(({ mode }) => {
  // Load env file from current directory
  const env = loadEnv(mode, process.cwd(), '');
  
  return {
    plugins: [
      sveltekit(),
      restart({
        restart: [
          // Restart when database schemas change
          '../../schemas/*.sql',
          // Restart when scripts change  
          '../../scripts/*.js',
          '../../scripts/*.cjs',
          '../../scripts/*.ts',
          // Restart when environment files change
          '.env',
          '.env.local',
          '.env.development',
          // Restart when Supabase config changes
          'src/lib/supabase.ts',
          'src/lib/supabase.js',
          // Restart when vite config itself changes
          'vite.config.ts',
          'vite.config.js',
          // Restart when package.json changes (dependencies)
          'package.json',
          // Restart when demo data configurations change
          'src/lib/mockData/*.js',
          'src/lib/services/demoDataGenerator.ts'
        ]
      })
    ],
    define: {
      // Make environment variables available in the build
      'process.env.SUPABASE_URL': JSON.stringify(env.SUPABASE_URL),
      'process.env.SUPABASE_SERVICE_ROLE_KEY': JSON.stringify(env.SUPABASE_SERVICE_ROLE_KEY),
    },
  };
});
