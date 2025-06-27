-- =====================================================
-- CLIENTS TABLE - Master Client Registry
-- =====================================================
-- 
-- Purpose: Central registry of all client installations
-- Security: RLS enabled, staff-only access
-- Dependencies: None (foundation table)

-- Set schema context
SET search_path TO api, public;

CREATE TABLE IF NOT EXISTS api.clients (
  -- Primary identifier
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Client identification
  client_code VARCHAR(50) UNIQUE NOT NULL,
  legal_name VARCHAR(255) NOT NULL,
  domain VARCHAR(255) UNIQUE NOT NULL,
  
  -- Configuration
  region VARCHAR(10) DEFAULT 'EU' CHECK (region IN ('EU', 'US', 'APAC')),
  tier VARCHAR(20) DEFAULT 'free' CHECK (tier IN ('free', 'pro', 'enterprise')),
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'deactivated')),
  
  -- Contact information
  setup_email VARCHAR(255),
  billing_contact VARCHAR(255),
  technical_contact VARCHAR(255),
  
  -- Business metadata
  industry VARCHAR(100),
  company_size VARCHAR(20) CHECK (company_size IN ('startup', 'small', 'medium', 'large', 'enterprise')),
  country_code VARCHAR(2), -- ISO 3166-1 alpha-2
  
  -- Configuration settings
  settings JSONB DEFAULT '{}',
  features JSONB DEFAULT '[]',
  
  -- Usage tracking
  max_users INTEGER DEFAULT 100,
  max_storage_gb INTEGER DEFAULT 1,
  current_users INTEGER DEFAULT 0,
  current_storage_mb INTEGER DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_active TIMESTAMP WITH TIME ZONE,
  activated_at TIMESTAMP WITH TIME ZONE,
  
  -- Constraints
  CONSTRAINT valid_client_code CHECK (client_code ~ '^[a-z0-9-]+$'),
  CONSTRAINT valid_domain CHECK (domain ~ '^[a-z0-9.-]+\.(thepia\.net|thepia\.com)$'),
  CONSTRAINT valid_email_format CHECK (
    setup_email IS NULL OR setup_email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
  )
);

-- =====================================================
-- INDEXES
-- =====================================================

-- Primary lookup indexes
CREATE INDEX IF NOT EXISTS idx_clients_client_code ON clients(client_code);
CREATE INDEX IF NOT EXISTS idx_clients_domain ON clients(domain);
CREATE INDEX IF NOT EXISTS idx_clients_status ON clients(status);

-- Query optimization indexes
CREATE INDEX IF NOT EXISTS idx_clients_tier ON clients(tier);
CREATE INDEX IF NOT EXISTS idx_clients_region ON clients(region);
CREATE INDEX IF NOT EXISTS idx_clients_created_at ON clients(created_at);
CREATE INDEX IF NOT EXISTS idx_clients_last_active ON clients(last_active);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_clients_status_tier ON clients(status, tier);
CREATE INDEX IF NOT EXISTS idx_clients_region_status ON clients(region, status);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Update timestamp on row changes
CREATE OR REPLACE FUNCTION update_clients_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_clients_updated_at
  BEFORE UPDATE ON clients
  FOR EACH ROW
  EXECUTE FUNCTION update_clients_updated_at();

-- Auto-generate setup email from client code
CREATE OR REPLACE FUNCTION generate_setup_email()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.setup_email IS NULL THEN
    NEW.setup_email = 'installation+' || NEW.client_code || '@thepia.net';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_generate_setup_email
  BEFORE INSERT ON clients
  FOR EACH ROW
  EXECUTE FUNCTION generate_setup_email();

-- Set activation timestamp when status becomes active
CREATE OR REPLACE FUNCTION set_activation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'active' AND (OLD.status IS NULL OR OLD.status != 'active') THEN
    NEW.activated_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_activation_timestamp
  BEFORE INSERT OR UPDATE ON clients
  FOR EACH ROW
  EXECUTE FUNCTION set_activation_timestamp();

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS on the clients table
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

-- Policy: Only Thepia staff can access client data
CREATE POLICY policy_clients_staff_access ON clients
  FOR ALL 
  USING (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  )
  WITH CHECK (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

-- Policy: API servers can read specific client data
CREATE POLICY policy_clients_api_read ON clients
  FOR SELECT
  USING (
    auth.jwt()->>'client_id' = id::text
    OR auth.jwt()->>'client_code' = client_code
  );

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to get client by code
CREATE OR REPLACE FUNCTION get_client_by_code(p_client_code TEXT)
RETURNS clients AS $$
DECLARE
  client_record clients;
BEGIN
  SELECT * INTO client_record
  FROM clients
  WHERE client_code = p_client_code
    AND status = 'active';
  
  RETURN client_record;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update client usage stats
CREATE OR REPLACE FUNCTION update_client_usage(
  p_client_id UUID,
  p_user_count INTEGER DEFAULT NULL,
  p_storage_mb INTEGER DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE clients
  SET 
    current_users = COALESCE(p_user_count, current_users),
    current_storage_mb = COALESCE(p_storage_mb, current_storage_mb),
    last_active = NOW(),
    updated_at = NOW()
  WHERE id = p_client_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check tier limits
CREATE OR REPLACE FUNCTION check_client_limits(
  p_client_id UUID,
  p_check_users BOOLEAN DEFAULT FALSE,
  p_check_storage BOOLEAN DEFAULT FALSE
)
RETURNS JSONB AS $$
DECLARE
  client_record clients;
  result JSONB := '{"within_limits": true, "warnings": []}'::JSONB;
BEGIN
  SELECT * INTO client_record FROM clients WHERE id = p_client_id;
  
  IF NOT FOUND THEN
    RETURN '{"error": "Client not found"}'::JSONB;
  END IF;
  
  -- Check user limits
  IF p_check_users AND client_record.current_users >= client_record.max_users THEN
    result := jsonb_set(result, '{within_limits}', 'false'::JSONB);
    result := jsonb_set(result, '{warnings}', 
      result->'warnings' || jsonb_build_array('User limit exceeded'));
  END IF;
  
  -- Check storage limits (convert GB to MB for comparison)
  IF p_check_storage AND client_record.current_storage_mb >= (client_record.max_storage_gb * 1024) THEN
    result := jsonb_set(result, '{within_limits}', 'false'::JSONB);
    result := jsonb_set(result, '{warnings}', 
      result->'warnings' || jsonb_build_array('Storage limit exceeded'));
  END IF;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- SAMPLE DATA (for development)
-- =====================================================

-- Note: Uncomment for development/testing environments only
/*
INSERT INTO clients (
  client_code,
  legal_name,
  domain,
  region,
  tier,
  industry,
  company_size,
  country_code
) VALUES 
(
  'test-client',
  'Test Client Corporation',
  'test-client.thepia.net',
  'EU',
  'free',
  'technology',
  'startup',
  'DK'
),
(
  'demo-corp',
  'Demo Corporation Limited',
  'demo-corp.thepia.net',
  'US',
  'pro',
  'manufacturing',
  'medium',
  'US'
);
*/

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE clients IS 'Master registry of all client installations with configuration and usage tracking';
COMMENT ON COLUMN clients.client_code IS 'Unique identifier used in subdomains and file paths (lowercase, alphanumeric, hyphens)';
COMMENT ON COLUMN clients.legal_name IS 'Official legal name of the client organization';
COMMENT ON COLUMN clients.domain IS 'Fully qualified domain name for client access (must be *.thepia.net or *.thepia.com)';
COMMENT ON COLUMN clients.setup_email IS 'Email address for setup communications (auto-generated if not provided)';
COMMENT ON COLUMN clients.settings IS 'Client-specific configuration settings as JSON';
COMMENT ON COLUMN clients.features IS 'Array of enabled features for this client';
COMMENT ON COLUMN clients.current_users IS 'Current number of active users for this client';
COMMENT ON COLUMN clients.current_storage_mb IS 'Current storage usage in megabytes';