-- Fix JWT Role Path in RLS Policies
-- Update all RLS policies to check user_metadata.role instead of top-level role

-- ==============================================
-- Fix Invitations Table Policies
-- ==============================================

-- Drop existing policies
DROP POLICY IF EXISTS policy_invitations_staff_access ON api.invitations;

-- Recreate with correct JWT path
CREATE POLICY policy_invitations_staff_access ON api.invitations
  FOR ALL 
  USING (
    auth.jwt()->>'user_metadata'->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  )
  WITH CHECK (
    auth.jwt()->>'user_metadata'->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

-- ==============================================
-- Fix User Roles Table Policies  
-- ==============================================

-- Drop existing policies
DROP POLICY IF EXISTS policy_user_roles_staff_access ON api.user_roles;

-- Recreate with correct JWT path
CREATE POLICY policy_user_roles_staff_access ON api.user_roles
  FOR ALL 
  USING (
    auth.jwt()->>'user_metadata'->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  )
  WITH CHECK (
    auth.jwt()->>'user_metadata'->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

-- ==============================================
-- Fix Clients Table Policies
-- ==============================================

-- Drop existing policies
DROP POLICY IF EXISTS policy_clients_staff_access ON api.clients;

-- Recreate with correct JWT path
CREATE POLICY policy_clients_staff_access ON api.clients
  FOR ALL 
  USING (
    auth.jwt()->>'user_metadata'->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  )
  WITH CHECK (
    auth.jwt()->>'user_metadata'->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

-- ==============================================
-- Fix Client Applications Table Policies
-- ==============================================

-- Drop existing policies
DROP POLICY IF EXISTS policy_client_applications_staff_access ON api.client_applications;

-- Recreate with correct JWT path
CREATE POLICY policy_client_applications_staff_access ON api.client_applications
  FOR ALL 
  USING (
    auth.jwt()->>'user_metadata'->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  )
  WITH CHECK (
    auth.jwt()->>'user_metadata'->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

-- ==============================================
-- Verification Query
-- ==============================================

-- Test the JWT path (should return 'thepia_staff' for your user)
-- SELECT auth.jwt()->>'user_metadata'->>'role' AS detected_role;

COMMENT ON SCHEMA api IS 'Updated RLS policies to use correct JWT user_metadata.role path';

-- ==============================================
-- Additional Common Tables (if they exist)
-- ==============================================

-- Fix any people table policies
DROP POLICY IF EXISTS policy_people_staff_access ON api.people;
CREATE POLICY policy_people_staff_access ON api.people
  FOR ALL 
  USING (
    auth.jwt()->>'user_metadata'->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  )
  WITH CHECK (
    auth.jwt()->>'user_metadata'->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

-- Fix any employees table policies  
DROP POLICY IF EXISTS policy_employees_staff_access ON api.employees;
CREATE POLICY policy_employees_staff_access ON api.employees
  FOR ALL 
  USING (
    auth.jwt()->>'user_metadata'->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  )
  WITH CHECK (
    auth.jwt()->>'user_metadata'->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

-- Note: Some policies may fail if tables don't exist - that's expected