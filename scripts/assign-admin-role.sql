-- Script to assign thepia_staff role to a user
-- This script provides a simple way to promote a user to admin status

-- Usage: Replace 'user@example.com' with the actual user email
-- Run this in the Supabase SQL editor or via psql

-- ==============================================
-- Assign thepia_staff role to a user
-- ==============================================

-- Example: Assign role to a specific user
-- Uncomment and modify the email address below:

-- SELECT * FROM assign_thepia_staff_role('admin@thepia.com', 'Initial admin setup');

-- ==============================================
-- Check current user roles
-- ==============================================

-- View all current role assignments
SELECT * FROM list_user_roles();

-- ==============================================
-- Find users by email pattern (helpful for finding the right user)
-- ==============================================

-- Find existing role assignments
SELECT user_email, role, assigned_at
FROM api.user_roles 
WHERE user_email LIKE '%@thepia.com'
ORDER BY assigned_at DESC;

-- ==============================================
-- Remove role from a user (if needed)
-- ==============================================

-- Example: Remove role from a user
-- Uncomment and modify the email address below:

-- SELECT * FROM remove_user_role('user@example.com');

-- ==============================================
-- Manual role assignment (if functions don't work)
-- ==============================================

-- Direct insert into user_roles table (bypass function)
-- Use this only if the assign_thepia_staff_role function fails

/*
INSERT INTO api.user_roles (user_id, user_email, role, notes)
VALUES (
  gen_random_uuid(),
  'admin@thepia.com',
  'thepia_staff',
  'Manual assignment via script'
)
ON CONFLICT (user_email) 
DO UPDATE SET 
  role = 'thepia_staff',
  assigned_at = NOW(),
  notes = 'Manual assignment via script';
*/

-- ==============================================
-- Verification
-- ==============================================

-- After assignment, verify the role was set correctly
SELECT 
  user_email,
  role,
  assigned_at,
  notes
FROM api.user_roles
WHERE user_email = 'admin@thepia.com';  -- Replace with your email