-- Immediate Fix for Admin App Invitation Visibility
-- This script fixes the specific issue where admin users cannot see invitation records

-- ==============================================
-- Problem Analysis
-- ==============================================
-- 
-- Issue: Admin app at flows.thepia.net/admin shows no invitations
-- Root Cause: RLS policy checks auth.jwt()->>'role' (returns 'authenticated')
--             but thepia_staff role is in auth.jwt()->>'user_metadata'->>'role'
-- 
-- User JWT contains:
-- {
--   "role": "authenticated",
--   "user_metadata": {
--     "role": "thepia_staff"  <-- This is where the role actually is
--   }
-- }

-- ==============================================
-- Immediate Fix: Update Invitations Policy
-- ==============================================

-- Drop the existing policy that checks wrong JWT path
DROP POLICY IF EXISTS policy_invitations_staff_access ON api.invitations;

-- Create new policy with correct JWT path
CREATE POLICY policy_invitations_staff_access ON api.invitations
  FOR ALL 
  USING (
    -- Correct path for thepia_staff role (note: -> then ->>)
    (auth.jwt()->'user_metadata'->>'role') = 'thepia_staff'
    -- Service role still works (for CLI tools)
    OR auth.jwt()->>'role' = 'service_role'
  )
  WITH CHECK (
    -- Same conditions for INSERT/UPDATE operations
    (auth.jwt()->'user_metadata'->>'role') = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

-- ==============================================
-- Verification
-- ==============================================

-- Test query that should now work for thepia_staff users:
-- SELECT COUNT(*) FROM api.invitations;

-- Expected result: Should return count of invitation records
-- Previous result: 0 records (due to RLS blocking access)

-- ==============================================
-- Comments and Documentation
-- ==============================================

COMMENT ON POLICY policy_invitations_staff_access ON api.invitations IS 
'Fixed policy: checks user_metadata.role instead of top-level role for thepia_staff access';

-- This fix should immediately restore admin app functionality without requiring:
-- - User to sign out/in again (JWT already contains correct data)
-- - Changes to client-side code  
-- - Service key distribution
-- - Complex role system modifications

-- After applying this fix:
-- 1. Refresh flows.thepia.net/admin 
-- 2. Invitations should now be visible
-- 3. Create/edit operations should work