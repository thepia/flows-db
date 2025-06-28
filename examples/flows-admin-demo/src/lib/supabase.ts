import { browser } from '$app/environment';
import { createClient } from '@supabase/supabase-js';

// Demo environment - using parent project's .env
const supabaseUrl = browser
  ? 'https://jstbkvkurjsopuwhlsvy.supabase.co'
  : process.env.SUPABASE_URL || 'https://jstbkvkurjsopuwhlsvy.supabase.co';

// For demo purposes, we use the service role key to bypass RLS
// In production, this would use proper authentication with anon key
const supabaseServiceKey = browser
  ? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpzdGJrdmt1cmpzb3B1d2hsc3Z5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MDk2NjU2OCwiZXhwIjoyMDY2NTQyNTY4fQ.vSSYVzitJDrQQYer1cW-SU_ZSEUtVyIOKsogHjy3h58'
  : process.env.SUPABASE_SERVICE_ROLE_KEY ||
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpzdGJrdmt1cmpzb3B1d2hsc3Z5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MDk2NjU2OCwiZXhwIjoyMDY2NTQyNTY4fQ.vSSYVzitJDrQQYer1cW-SU_ZSEUtVyIOKsogHjy3h58';

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
