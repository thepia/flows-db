-- User Role Management System
-- This schema adds the missing role assignment functionality to properly support
-- JWT-based access control with thepia_staff roles

-- ==============================================
-- User Roles Table (Simplified)
-- ==============================================

-- Store user roles that get embedded in JWT claims during authentication
-- Note: Using simplified approach due to auth schema access limitations
CREATE TABLE IF NOT EXISTS api.user_roles (
  user_id UUID PRIMARY KEY,
  user_email TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('thepia_staff', 'service_role', 'authenticated')),
  assigned_by_email TEXT,
  assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  notes TEXT,
  
  -- Ensure only one role per user
  CONSTRAINT unique_user_role UNIQUE (user_id),
  CONSTRAINT unique_user_email UNIQUE (user_email)
);

-- Enable RLS on user_roles table
ALTER TABLE api.user_roles ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Only thepia_staff can view/modify user roles
CREATE POLICY policy_user_roles_staff_access ON api.user_roles
  FOR ALL 
  USING (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  )
  WITH CHECK (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

-- ==============================================
-- Role Assignment Functions (Simplified)
-- ==============================================

-- Function to assign thepia_staff role to a user by email
CREATE OR REPLACE FUNCTION assign_thepia_staff_role(target_user_email TEXT, assigner_notes TEXT DEFAULT NULL)
RETURNS TABLE(success BOOLEAN, message TEXT, user_email TEXT) AS $$
DECLARE
  current_user_email TEXT;
BEGIN
  -- Get current user email from JWT
  SELECT auth.jwt()->>'email' INTO current_user_email;
  
  -- Insert or update role
  INSERT INTO api.user_roles (user_id, user_email, role, assigned_by_email, notes)
  VALUES (gen_random_uuid(), target_user_email, 'thepia_staff', current_user_email, assigner_notes)
  ON CONFLICT (user_email) 
  DO UPDATE SET 
    role = 'thepia_staff', 
    assigned_by_email = current_user_email,
    assigned_at = NOW(),
    notes = assigner_notes;
  
  RETURN QUERY SELECT TRUE, 'Successfully assigned thepia_staff role to ' || target_user_email, target_user_email;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to remove role from a user
CREATE OR REPLACE FUNCTION remove_user_role(target_user_email TEXT)
RETURNS TABLE(success BOOLEAN, message TEXT) AS $$
DECLARE
  rows_affected INTEGER;
BEGIN
  -- Remove role
  DELETE FROM api.user_roles WHERE user_email = target_user_email;
  GET DIAGNOSTICS rows_affected = ROW_COUNT;
  
  IF rows_affected > 0 THEN
    RETURN QUERY SELECT TRUE, 'Successfully removed role from ' || target_user_email;
  ELSE
    RETURN QUERY SELECT FALSE, 'No role found for user: ' || target_user_email;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to list all user roles (for admin interface)
CREATE OR REPLACE FUNCTION list_user_roles()
RETURNS TABLE(
  user_id UUID,
  user_email TEXT,
  role TEXT,
  assigned_by_email TEXT,
  assigned_at TIMESTAMP WITH TIME ZONE,
  notes TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ur.user_id,
    ur.user_email,
    ur.role,
    ur.assigned_by_email,
    ur.assigned_at,
    ur.notes
  FROM api.user_roles ur
  ORDER BY ur.assigned_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check user role by email
CREATE OR REPLACE FUNCTION get_user_role(check_user_email TEXT)
RETURNS TEXT AS $$
DECLARE
  user_role TEXT;
BEGIN
  SELECT role INTO user_role 
  FROM api.user_roles 
  WHERE user_email = check_user_email;
  
  RETURN COALESCE(user_role, 'authenticated');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==============================================
-- Permissions and Grants
-- ==============================================

-- Grant access to functions
GRANT EXECUTE ON FUNCTION assign_thepia_staff_role(TEXT, TEXT) TO service_role, authenticated;
GRANT EXECUTE ON FUNCTION remove_user_role(TEXT) TO service_role, authenticated;
GRANT EXECUTE ON FUNCTION list_user_roles() TO service_role, authenticated;
GRANT EXECUTE ON FUNCTION get_user_role(TEXT) TO service_role, authenticated, anon;

-- Grant table access
GRANT ALL ON api.user_roles TO service_role;
GRANT SELECT ON api.user_roles TO authenticated;

-- ==============================================
-- Initial Setup
-- ==============================================

-- Create an initial thepia_staff user if one doesn't exist
-- This should be run manually with appropriate email after deployment
-- Example: SELECT assign_thepia_staff_role('admin@thepia.com', 'Initial admin user');

COMMENT ON TABLE api.user_roles IS 'Stores user role assignments for JWT claim population';
COMMENT ON FUNCTION assign_thepia_staff_role IS 'Assigns thepia_staff role to a user by email';
COMMENT ON FUNCTION remove_user_role IS 'Removes role assignment from a user';
COMMENT ON FUNCTION list_user_roles IS 'Lists all user role assignments';
COMMENT ON FUNCTION get_user_role IS 'Gets user role by email address';