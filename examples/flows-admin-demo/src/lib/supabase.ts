import { browser } from '$app/environment';
import { createClient } from '@supabase/supabase-js';

// Fallback values for demo environment
const FALLBACK_URL = 'https://jstbkvkurjsopuwhlsvy.supabase.co';
const FALLBACK_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpzdGJrdmt1cmpzb3B1d2hsc3Z5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MDk2NjU2OCwiZXhwIjoyMDY2NTQyNTY4fQ.vSSYVzitJDrQQYer1cW-SU_ZSEUtVyIOKsogHjy3h58';

// Use Vite environment variables - these are loaded from the parent .env file
// For browser, we need to use import.meta.env with VITE_ prefix
// For server, we can use process.env directly
const supabaseUrl = browser
  ? import.meta.env.VITE_SUPABASE_URL || FALLBACK_URL
  : process.env.SUPABASE_URL || FALLBACK_URL;

// For demo purposes, we use the service role key to bypass RLS
// In production, this would use proper authentication with anon key
const supabaseServiceKey = browser
  ? import.meta.env.VITE_SUPABASE_SERVICE_ROLE_KEY || FALLBACK_SERVICE_KEY
  : process.env.SUPABASE_SERVICE_ROLE_KEY || FALLBACK_SERVICE_KEY;

// Log environment variable status for debugging
if (!browser) {
  console.log('Server-side Supabase config:', {
    url: supabaseUrl ? 'loaded' : 'missing',
    key: supabaseServiceKey ? 'loaded' : 'missing',
    envUrl: process.env.SUPABASE_URL ? 'available' : 'not available',
    envKey: process.env.SUPABASE_SERVICE_ROLE_KEY ? 'available' : 'not available'
  });
}

export const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    // For demo purposes, we'll use service role auth
    persistSession: false,
    autoRefreshToken: false,
  },
  db: {
    schema: 'api',
  },
});

// Demo client setup for admin access
// In production, this would use proper authentication
export async function setupDemoAuth() {
  // For demo purposes, we'll create a temporary auth context
  // This simulates admin access to the demo client data
  return {
    role: 'thepia_staff',
    client_code: 'nets-demo',
  };
}
