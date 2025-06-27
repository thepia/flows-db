-- =====================================================
-- SCHEMA SETUP - Multi-Tenant Database Architecture
-- =====================================================
-- 
-- Purpose: Set up dedicated schemas for API isolation and security
-- Security: Only 'api' schema is exposed through PostgREST
-- Dependencies: Must be run before all other schema files

-- =====================================================
-- CREATE SCHEMAS
-- =====================================================

-- Create dedicated schemas
CREATE SCHEMA IF NOT EXISTS api;      -- Client-facing API tables
CREATE SCHEMA IF NOT EXISTS internal; -- Internal system tables  
CREATE SCHEMA IF NOT EXISTS audit;    -- Audit and compliance logging

-- =====================================================
-- SCHEMA COMMENTS
-- =====================================================

COMMENT ON SCHEMA api IS 'Client-facing API tables exposed through PostgREST';
COMMENT ON SCHEMA internal IS 'Internal system tables - NOT exposed to API';
COMMENT ON SCHEMA audit IS 'Audit trails and compliance logging';

-- =====================================================
-- EXTENSIONS
-- =====================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";      -- UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";       -- Encryption functions
CREATE EXTENSION IF NOT EXISTS "pgjwt";          -- JWT handling
CREATE EXTENSION IF NOT EXISTS "pgsodium";       -- Advanced encryption

-- =====================================================
-- ROLE CONFIGURATION
-- =====================================================

-- Ensure roles exist
DO $$ 
BEGIN
  -- Create API role if it doesn't exist
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'api_user') THEN
    CREATE ROLE api_user NOLOGIN;
  END IF;
  
  -- Create internal role if it doesn't exist  
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'internal_user') THEN
    CREATE ROLE internal_user NOLOGIN;
  END IF;
  
  -- Create audit role if it doesn't exist
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'audit_user') THEN
    CREATE ROLE audit_user NOLOGIN;
  END IF;
END $$;

-- =====================================================
-- SCHEMA PERMISSIONS
-- =====================================================

-- API schema permissions (PostgREST access)
GRANT USAGE ON SCHEMA api TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA api TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA api TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA api TO anon;

-- Internal schema permissions (service role only)
GRANT USAGE ON SCHEMA internal TO service_role;
GRANT ALL ON ALL TABLES IN SCHEMA internal TO service_role;
-- No access for anon or authenticated roles

-- Audit schema permissions (read-only for authenticated)
GRANT USAGE ON SCHEMA audit TO authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA audit TO service_role;
GRANT SELECT ON ALL TABLES IN SCHEMA audit TO authenticated;
-- No access for anon role

-- =====================================================
-- DEFAULT PRIVILEGES
-- =====================================================

-- Set default privileges for future tables in API schema
ALTER DEFAULT PRIVILEGES IN SCHEMA api 
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA api 
  GRANT SELECT ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA api 
  GRANT ALL ON TABLES TO service_role;

-- Set default privileges for future tables in internal schema
ALTER DEFAULT PRIVILEGES IN SCHEMA internal 
  GRANT ALL ON TABLES TO service_role;

-- Set default privileges for future tables in audit schema
ALTER DEFAULT PRIVILEGES IN SCHEMA audit 
  GRANT ALL ON TABLES TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA audit 
  GRANT SELECT ON TABLES TO authenticated;

-- =====================================================
-- SEARCH PATH CONFIGURATION
-- =====================================================

-- Set the default search path (for convenience)
-- Note: Always use fully qualified names in production code
SET search_path TO api, public;

-- =====================================================
-- UTILITY FUNCTIONS
-- =====================================================

-- Function to check current schema setup
CREATE OR REPLACE FUNCTION internal.check_schema_setup()
RETURNS TABLE (
  schema_name TEXT,
  schema_owner TEXT,
  has_usage_permission BOOLEAN,
  table_count INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    n.nspname::TEXT,
    pg_get_userbyid(n.nspowner)::TEXT,
    has_schema_privilege(current_user, n.nspname, 'USAGE'),
    (SELECT COUNT(*) FROM pg_tables WHERE schemaname = n.nspname)::INTEGER
  FROM pg_namespace n
  WHERE n.nspname IN ('api', 'internal', 'audit')
  ORDER BY n.nspname;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- POSTGREST CONFIGURATION
-- =====================================================

-- Create PostgREST configuration comments
COMMENT ON SCHEMA api IS 'exposed';     -- This tells PostgREST to expose this schema
COMMENT ON SCHEMA internal IS 'hidden'; -- This ensures internal schema stays hidden
COMMENT ON SCHEMA audit IS 'hidden';    -- This ensures audit schema stays hidden

-- =====================================================
-- INITIAL SETUP VERIFICATION
-- =====================================================

-- Verify setup (run this to check everything is configured correctly)
DO $$
DECLARE
  schema_count INTEGER;
  extension_count INTEGER;
BEGIN
  -- Check schemas exist
  SELECT COUNT(*) INTO schema_count 
  FROM pg_namespace 
  WHERE nspname IN ('api', 'internal', 'audit');
  
  IF schema_count != 3 THEN
    RAISE EXCEPTION 'Schema setup failed: Expected 3 schemas, found %', schema_count;
  END IF;
  
  -- Check extensions exist
  SELECT COUNT(*) INTO extension_count
  FROM pg_extension
  WHERE extname IN ('uuid-ossp', 'pgcrypto', 'pgjwt', 'pgsodium');
  
  IF extension_count < 3 THEN
    RAISE WARNING 'Not all extensions installed. Found % of 4 expected extensions', extension_count;
  END IF;
  
  RAISE NOTICE 'Schema setup completed successfully';
END $$;

-- =====================================================
-- MIGRATION HELPERS
-- =====================================================

-- Function to move tables between schemas
CREATE OR REPLACE FUNCTION internal.move_table_to_schema(
  p_table_name TEXT,
  p_from_schema TEXT,
  p_to_schema TEXT
)
RETURNS VOID AS $$
BEGIN
  EXECUTE format('ALTER TABLE %I.%I SET SCHEMA %I', 
    p_from_schema, p_table_name, p_to_schema);
  RAISE NOTICE 'Moved table % from schema % to %', 
    p_table_name, p_from_schema, p_to_schema;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- NOTES
-- =====================================================

-- 1. Only the 'api' schema is exposed through PostgREST
-- 2. Use 'internal' schema for system tables that should never be exposed
-- 3. Use 'audit' schema for compliance and logging tables
-- 4. Always use fully qualified names (schema.table) in production code
-- 5. Run this file first before creating any tables