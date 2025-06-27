-- =====================================================
-- CLIENT APPLICATIONS TABLE
-- =====================================================
-- 
-- Purpose: Application configurations per client
-- Security: Client-isolated via RLS policies
-- Dependencies: clients table (foreign key)

-- Set schema context
SET search_path TO api, public;

CREATE TABLE IF NOT EXISTS api.client_applications (
  -- Primary identifier
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Client relationship
  client_id UUID NOT NULL REFERENCES api.clients(id) ON DELETE CASCADE,
  
  -- Application identification
  app_code VARCHAR(50) NOT NULL,
  app_name VARCHAR(255) NOT NULL,
  app_version VARCHAR(20) DEFAULT '1.0.0',
  app_description TEXT,
  
  -- Status and configuration
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'maintenance', 'deprecated')),
  configuration JSONB DEFAULT '{}',
  features JSONB DEFAULT '[]',
  
  -- Security settings
  allowed_domains TEXT[],
  cors_origins TEXT[],
  ip_whitelist INET[],
  require_invitation BOOLEAN DEFAULT TRUE,
  
  -- Access control
  permissions JSONB DEFAULT '{}',
  user_roles JSONB DEFAULT '[]',
  
  -- Usage limits
  max_concurrent_users INTEGER DEFAULT 50,
  max_file_size_mb INTEGER DEFAULT 50,
  session_timeout_minutes INTEGER DEFAULT 60,
  
  -- Deployment settings
  cdn_config JSONB DEFAULT '{}',
  build_config JSONB DEFAULT '{}',
  environment_variables JSONB DEFAULT '{}',
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_deployed TIMESTAMP WITH TIME ZONE,
  last_accessed TIMESTAMP WITH TIME ZONE,
  
  -- Constraints
  UNIQUE(client_id, app_code),
  CONSTRAINT valid_app_code CHECK (app_code ~ '^[a-z0-9-]+$'),
  CONSTRAINT valid_version CHECK (app_version ~ '^\d+\.\d+\.\d+(-[a-zA-Z0-9-]+)?$')
);

-- =====================================================
-- INDEXES
-- =====================================================

-- Primary lookup indexes
CREATE INDEX IF NOT EXISTS idx_client_applications_client_id ON client_applications(client_id);
CREATE INDEX IF NOT EXISTS idx_client_applications_app_code ON client_applications(app_code);
CREATE INDEX IF NOT EXISTS idx_client_applications_status ON client_applications(status);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_client_applications_client_app ON client_applications(client_id, app_code);
CREATE INDEX IF NOT EXISTS idx_client_applications_client_status ON client_applications(client_id, status);
CREATE INDEX IF NOT EXISTS idx_client_applications_active ON client_applications(status) WHERE status = 'active';

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_client_applications_last_accessed ON client_applications(last_accessed);
CREATE INDEX IF NOT EXISTS idx_client_applications_created_at ON client_applications(created_at);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Update timestamp on row changes
CREATE OR REPLACE FUNCTION update_client_applications_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_client_applications_updated_at ON client_applications;
CREATE TRIGGER trigger_client_applications_updated_at
  BEFORE UPDATE ON client_applications
  FOR EACH ROW
  EXECUTE FUNCTION update_client_applications_updated_at();

-- Auto-generate app name from app code if not provided
CREATE OR REPLACE FUNCTION generate_app_name()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.app_name IS NULL OR NEW.app_name = '' THEN
    NEW.app_name = INITCAP(REPLACE(NEW.app_code, '-', ' ')) || ' App';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_generate_app_name ON client_applications;
CREATE TRIGGER trigger_generate_app_name
  BEFORE INSERT ON client_applications
  FOR EACH ROW
  EXECUTE FUNCTION generate_app_name();

-- Validate configuration JSON schemas
CREATE OR REPLACE FUNCTION validate_app_configuration()
RETURNS TRIGGER AS $$
BEGIN
  -- Validate that configuration contains required fields
  IF NOT (NEW.configuration ? 'theme' AND NEW.configuration ? 'locale') THEN
    RAISE EXCEPTION 'Application configuration must include theme and locale settings';
  END IF;
  
  -- Validate features array contains only known features
  IF NEW.features IS NOT NULL THEN
    -- This could be expanded to validate against a known feature list
    IF jsonb_array_length(NEW.features) > 20 THEN
      RAISE EXCEPTION 'Too many features enabled (maximum 20)';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_validate_app_configuration ON client_applications;
CREATE TRIGGER trigger_validate_app_configuration
  BEFORE INSERT OR UPDATE ON client_applications
  FOR EACH ROW
  EXECUTE FUNCTION validate_app_configuration();

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS on the client_applications table
ALTER TABLE client_applications ENABLE ROW LEVEL SECURITY;

-- Policy: Thepia staff can access all application data
DROP POLICY IF EXISTS policy_client_applications_staff_access ON client_applications;
CREATE POLICY policy_client_applications_staff_access ON client_applications
  FOR ALL 
  USING (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  )
  WITH CHECK (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

-- Policy: API servers can access applications for specific clients
DROP POLICY IF EXISTS policy_client_applications_api_access ON client_applications;
CREATE POLICY policy_client_applications_api_access ON client_applications
  FOR ALL
  USING (
    client_id::text = auth.jwt()->>'client_id'
    OR EXISTS (
      SELECT 1 FROM api.clients 
      WHERE clients.id = client_applications.client_id 
        AND clients.client_code = auth.jwt()->>'client_code'
    )
  )
  WITH CHECK (
    client_id::text = auth.jwt()->>'client_id'
    OR EXISTS (
      SELECT 1 FROM api.clients 
      WHERE clients.id = client_applications.client_id 
        AND clients.client_code = auth.jwt()->>'client_code'
    )
  );

-- Policy: Read-only access for application users
DROP POLICY IF EXISTS policy_client_applications_user_read ON client_applications;
CREATE POLICY policy_client_applications_user_read ON client_applications
  FOR SELECT
  USING (
    status = 'active'
    AND (
      auth.jwt()->>'app_id' = id::text
      OR (
        client_id::text = auth.jwt()->>'client_id'
        AND app_code = auth.jwt()->>'app_code'
      )
    )
  );

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to get application by client and app code
CREATE OR REPLACE FUNCTION get_client_application(
  p_client_code TEXT,
  p_app_code TEXT
)
RETURNS client_applications AS $$
DECLARE
  app_record client_applications;
BEGIN
  SELECT ca.* INTO app_record
  FROM client_applications ca
  JOIN api.clients c ON c.id = ca.client_id
  WHERE c.client_code = p_client_code
    AND ca.app_code = p_app_code
    AND ca.status = 'active'
    AND c.status = 'active';
  
  RETURN app_record;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update application access tracking
CREATE OR REPLACE FUNCTION track_app_access(
  p_client_id UUID,
  p_app_code TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE client_applications
  SET 
    last_accessed = NOW(),
    updated_at = NOW()
  WHERE client_id = p_client_id
    AND app_code = p_app_code;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get application configuration
CREATE OR REPLACE FUNCTION get_app_config(
  p_client_code TEXT,
  p_app_code TEXT
)
RETURNS JSONB AS $$
DECLARE
  config_result JSONB := '{}'::JSONB;
  app_record client_applications;
  client_record clients;
BEGIN
  -- Get client information
  SELECT * INTO client_record FROM api.clients WHERE client_code = p_client_code;
  IF NOT FOUND THEN
    RETURN '{"error": "Client not found"}'::JSONB;
  END IF;
  
  -- Get application information
  SELECT * INTO app_record 
  FROM client_applications 
  WHERE client_id = client_record.id AND app_code = p_app_code;
  
  IF NOT FOUND THEN
    RETURN '{"error": "Application not found"}'::JSONB;
  END IF;
  
  -- Build configuration response
  config_result := jsonb_build_object(
    'client', jsonb_build_object(
      'code', client_record.client_code,
      'name', client_record.legal_name,
      'domain', client_record.domain,
      'tier', client_record.tier,
      'region', client_record.region
    ),
    'application', jsonb_build_object(
      'code', app_record.app_code,
      'name', app_record.app_name,
      'version', app_record.app_version,
      'status', app_record.status,
      'configuration', app_record.configuration,
      'features', app_record.features,
      'permissions', app_record.permissions
    ),
    'security', jsonb_build_object(
      'allowed_domains', app_record.allowed_domains,
      'cors_origins', app_record.cors_origins,
      'require_invitation', app_record.require_invitation
    ),
    'limits', jsonb_build_object(
      'max_concurrent_users', app_record.max_concurrent_users,
      'max_file_size_mb', app_record.max_file_size_mb,
      'session_timeout_minutes', app_record.session_timeout_minutes
    )
  );
  
  RETURN config_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to validate app permissions
CREATE OR REPLACE FUNCTION check_app_permission(
  p_client_id UUID,
  p_app_code TEXT,
  p_permission TEXT,
  p_user_roles JSONB DEFAULT '[]'::JSONB
)
RETURNS BOOLEAN AS $$
DECLARE
  app_permissions JSONB;
  required_roles JSONB;
BEGIN
  -- Get application permissions
  SELECT permissions INTO app_permissions
  FROM client_applications
  WHERE client_id = p_client_id AND app_code = p_app_code;
  
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;
  
  -- Check if permission exists in app configuration
  IF NOT (app_permissions ? p_permission) THEN
    RETURN FALSE;
  END IF;
  
  -- Get required roles for this permission
  required_roles := app_permissions->p_permission->'required_roles';
  
  -- If no roles required, permission is granted
  IF required_roles IS NULL OR jsonb_array_length(required_roles) = 0 THEN
    RETURN TRUE;
  END IF;
  
  -- Check if user has any of the required roles
  RETURN EXISTS (
    SELECT 1 
    FROM jsonb_array_elements_text(p_user_roles) user_role
    WHERE jsonb_array_elements_text(required_roles) = user_role
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- VIEWS
-- =====================================================

-- View for active applications with client information
CREATE OR REPLACE VIEW active_client_applications AS
SELECT 
  ca.id,
  ca.client_id,
  c.client_code,
  c.legal_name as client_name,
  c.domain as client_domain,
  ca.app_code,
  ca.app_name,
  ca.app_version,
  ca.status,
  ca.configuration,
  ca.features,
  ca.last_accessed,
  ca.created_at
FROM client_applications ca
JOIN api.clients c ON c.id = ca.client_id
WHERE ca.status = 'active' 
  AND c.status = 'active';

-- =====================================================
-- SAMPLE DATA (for development)
-- =====================================================

-- Note: Uncomment for development/testing environments only
/*
-- Insert sample applications for test clients
INSERT INTO client_applications (
  client_id,
  app_code,
  app_name,
  app_version,
  app_description,
  configuration,
  features,
  allowed_domains,
  cors_origins
) 
SELECT 
  c.id,
  'offboarding',
  'Employee Offboarding',
  '1.0.0',
  'Streamlined employee offboarding process with digital workflows',
  '{"theme": "corporate", "locale": "en-US", "branding": {"primary_color": "#2563eb"}}'::JSONB,
  '["document-capture", "task-management", "notifications"]'::JSONB,
  ARRAY[c.domain],
  ARRAY['https://' || c.domain, 'https://app.' || c.domain]
FROM clients c
WHERE c.client_code IN ('test-client', 'demo-corp');
*/

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE client_applications IS 'Application configurations and settings for each client';
COMMENT ON COLUMN client_applications.app_code IS 'Unique application identifier within client (lowercase, alphanumeric, hyphens)';
COMMENT ON COLUMN client_applications.configuration IS 'Application-specific configuration settings as JSON';
COMMENT ON COLUMN client_applications.features IS 'Array of enabled features for this application';
COMMENT ON COLUMN client_applications.allowed_domains IS 'Array of domains allowed to access this application';
COMMENT ON COLUMN client_applications.cors_origins IS 'Array of CORS origins for API access';
COMMENT ON COLUMN client_applications.permissions IS 'Role-based permissions configuration as JSON';
COMMENT ON COLUMN client_applications.cdn_config IS 'CDN and deployment configuration settings';
COMMENT ON COLUMN client_applications.environment_variables IS 'Environment-specific variables for the application';