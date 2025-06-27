-- =====================================================
-- INVITATIONS TABLE - JWT-Based Invitation System
-- =====================================================
-- 
-- Purpose: General invitation system for all Flows applications
-- Use Cases: Onboarding, offboarding, access grants, form submissions, etc.
-- Security: All PII (including dual emails) encrypted in JWT tokens, minimal metadata in DB
-- Dependencies: clients, client_applications tables

-- Set schema context
SET search_path TO api, public;

CREATE TABLE IF NOT EXISTS api.invitations (
  -- Primary identifier
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Client and application relationship
  client_id UUID NOT NULL REFERENCES api.clients(id) ON DELETE CASCADE,
  app_id UUID NOT NULL REFERENCES api.client_applications(id) ON DELETE CASCADE,
  
  -- Invitation identification
  invitation_code VARCHAR(100) UNIQUE NOT NULL,
  jwt_token_hash VARCHAR(64) UNIQUE NOT NULL, -- SHA-256 hash of JWT for lookup
  
  -- Configuration (no PII here - all in encrypted JWT)
  permissions JSONB DEFAULT '[]',
  restrictions JSONB DEFAULT '{}', -- IP, device, time restrictions
  
  -- Usage tracking
  status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'used', 'expired', 'revoked')),
  max_uses INTEGER DEFAULT 1,
  used_count INTEGER DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  first_used_at TIMESTAMP WITH TIME ZONE,
  last_used_at TIMESTAMP WITH TIME ZONE,
  revoked_at TIMESTAMP WITH TIME ZONE,
  
  -- Audit trail
  created_by VARCHAR(255) NOT NULL, -- Thepia staff user ID who created invitation
  used_by_user_id VARCHAR(255), -- Auth0 user ID of person who used invitation
  revoked_by VARCHAR(255), -- Thepia staff user ID who revoked invitation
  revocation_reason TEXT,
  
  -- Security metadata (no PII)
  ip_restrictions JSONB, -- Allowed IP ranges
  device_fingerprint_hash VARCHAR(64), -- Hashed device fingerprint
  require_mfa BOOLEAN DEFAULT FALSE,
  
  -- Technical metadata
  client_data JSONB DEFAULT '{}', -- Non-PII client-specific data
  usage_metadata JSONB DEFAULT '{}', -- Usage statistics and metadata
  
  -- Constraints
  CONSTRAINT valid_invitation_code CHECK (invitation_code ~ '^[A-Z0-9-]+$'),
  CONSTRAINT valid_expires_at CHECK (expires_at > created_at),
  CONSTRAINT valid_used_count CHECK (used_count >= 0 AND used_count <= max_uses),
  CONSTRAINT valid_jwt_hash CHECK (length(jwt_token_hash) = 64)
);

-- =====================================================
-- INDEXES
-- =====================================================

-- Primary lookup indexes
CREATE INDEX IF NOT EXISTS idx_invitations_client_id ON invitations(client_id);
CREATE INDEX IF NOT EXISTS idx_invitations_app_id ON invitations(app_id);
CREATE INDEX IF NOT EXISTS idx_invitations_invitation_code ON invitations(invitation_code);
CREATE INDEX IF NOT EXISTS idx_invitations_jwt_token_hash ON invitations(jwt_token_hash);

-- Status and lifecycle indexes
CREATE INDEX IF NOT EXISTS idx_invitations_status ON invitations(status);
CREATE INDEX IF NOT EXISTS idx_invitations_expires_at ON invitations(expires_at);
CREATE INDEX IF NOT EXISTS idx_invitations_created_at ON invitations(created_at);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_invitations_client_status ON invitations(client_id, status);
CREATE INDEX IF NOT EXISTS idx_invitations_app_status ON invitations(app_id, status);
CREATE INDEX IF NOT EXISTS idx_invitations_status_expires ON invitations(status, expires_at);

-- Performance indexes for cleanup operations
CREATE INDEX IF NOT EXISTS idx_invitations_expired ON invitations(expires_at) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_invitations_pending ON invitations(status, created_at) WHERE status = 'pending';

-- Audit indexes
CREATE INDEX IF NOT EXISTS idx_invitations_created_by ON invitations(created_by);
CREATE INDEX IF NOT EXISTS idx_invitations_used_by ON invitations(used_by_user_id);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Auto-update status when expiration time passes
CREATE OR REPLACE FUNCTION update_invitation_status()
RETURNS TRIGGER AS $$
BEGIN
  -- Mark as expired if past expiration date
  IF NEW.expires_at <= NOW() AND NEW.status = 'pending' THEN
    NEW.status = 'expired';
  END IF;
  
  -- Mark as used if used_count reaches max_uses
  IF NEW.used_count >= NEW.max_uses AND NEW.status = 'pending' THEN
    NEW.status = 'used';
    IF NEW.last_used_at IS NULL THEN
      NEW.last_used_at = NOW();
    END IF;
  END IF;
  
  -- Set first_used_at timestamp
  IF NEW.used_count > 0 AND OLD.used_count = 0 THEN
    NEW.first_used_at = NOW();
    NEW.last_used_at = NOW();
  END IF;
  
  -- Update last_used_at when use count increases
  IF NEW.used_count > OLD.used_count THEN
    NEW.last_used_at = NOW();
  END IF;
  
  -- Set revoked_at timestamp
  IF NEW.status = 'revoked' AND OLD.status != 'revoked' THEN
    NEW.revoked_at = NOW();
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_invitation_status
  BEFORE UPDATE ON invitations
  FOR EACH ROW
  EXECUTE FUNCTION update_invitation_status();

-- Generate invitation code if not provided
CREATE OR REPLACE FUNCTION generate_invitation_code()
RETURNS TRIGGER AS $$
DECLARE
  client_code TEXT;
  app_code TEXT;
  random_suffix TEXT;
BEGIN
  IF NEW.invitation_code IS NULL OR NEW.invitation_code = '' THEN
    -- Get client and app codes
    SELECT c.client_code, ca.app_code 
    INTO client_code, app_code
    FROM clients c
    JOIN client_applications ca ON ca.client_id = c.id
    WHERE c.id = NEW.client_id AND ca.id = NEW.app_id;
    
    -- Generate random suffix
    random_suffix := UPPER(substring(gen_random_uuid()::text from 1 for 6));
    
    -- Create invitation code: CLIENT-APP-RANDOM
    NEW.invitation_code = UPPER(client_code) || '-' || UPPER(app_code) || '-' || random_suffix;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_generate_invitation_code
  BEFORE INSERT ON invitations
  FOR EACH ROW
  EXECUTE FUNCTION generate_invitation_code();

-- Validate JWT token hash format
CREATE OR REPLACE FUNCTION validate_jwt_hash()
RETURNS TRIGGER AS $$
BEGIN
  -- Ensure JWT hash is a valid SHA-256 (64 hex characters)
  IF NEW.jwt_token_hash !~ '^[a-f0-9]{64}$' THEN
    RAISE EXCEPTION 'JWT token hash must be a valid SHA-256 hash (64 hex characters)';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_jwt_hash
  BEFORE INSERT OR UPDATE ON invitations
  FOR EACH ROW
  EXECUTE FUNCTION validate_jwt_hash();

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS on the invitations table
ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;

-- Policy: Thepia staff can access all invitations
CREATE POLICY policy_invitations_staff_access ON invitations
  FOR ALL 
  USING (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  )
  WITH CHECK (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

-- Policy: API servers can access invitations for specific clients
CREATE POLICY policy_invitations_api_access ON invitations
  FOR ALL
  USING (
    client_id::text = auth.jwt()->>'client_id'
    OR EXISTS (
      SELECT 1 FROM clients 
      WHERE clients.id = invitations.client_id 
        AND clients.client_code = auth.jwt()->>'client_code'
    )
  )
  WITH CHECK (
    client_id::text = auth.jwt()->>'client_id'
    OR EXISTS (
      SELECT 1 FROM clients 
      WHERE clients.id = invitations.client_id 
        AND clients.client_code = auth.jwt()->>'client_code'
    )
  );

-- Policy: Invitation holders can read their own invitation
CREATE POLICY policy_invitations_holder_read ON invitations
  FOR SELECT
  USING (
    jwt_token_hash = auth.jwt()->>'jti_hash'
    OR invitation_code = auth.jwt()->>'invitation_code'
  );

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to find invitation by JWT hash
CREATE OR REPLACE FUNCTION find_invitation_by_jwt_hash(p_jwt_hash TEXT)
RETURNS invitations AS $$
DECLARE
  invitation_record invitations;
BEGIN
  SELECT * INTO invitation_record
  FROM invitations
  WHERE jwt_token_hash = p_jwt_hash
    AND status = 'pending'
    AND expires_at > NOW();
  
  RETURN invitation_record;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to use an invitation
CREATE OR REPLACE FUNCTION use_invitation(
  p_jwt_hash TEXT,
  p_user_id TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  invitation_record invitations;
  result JSONB;
BEGIN
  -- Find and lock the invitation
  SELECT * INTO invitation_record
  FROM invitations
  WHERE jwt_token_hash = p_jwt_hash
    AND status = 'pending'
    AND expires_at > NOW()
  FOR UPDATE;
  
  IF NOT FOUND THEN
    RETURN '{"success": false, "error": "Invitation not found, already used, or expired"}'::JSONB;
  END IF;
  
  -- Check if invitation can still be used
  IF invitation_record.used_count >= invitation_record.max_uses THEN
    RETURN '{"success": false, "error": "Invitation has reached maximum usage limit"}'::JSONB;
  END IF;
  
  -- Update invitation usage
  UPDATE invitations
  SET 
    used_count = used_count + 1,
    last_used_at = NOW(),
    used_by_user_id = COALESCE(p_user_id, used_by_user_id),
    status = CASE 
      WHEN used_count + 1 >= max_uses THEN 'used'
      ELSE 'pending'
    END
  WHERE id = invitation_record.id;
  
  -- Return success result
  result := jsonb_build_object(
    'success', true,
    'invitation_id', invitation_record.id,
    'invitation_code', invitation_record.invitation_code,
    'remaining_uses', invitation_record.max_uses - invitation_record.used_count - 1,
    'expires_at', invitation_record.expires_at
  );
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to revoke an invitation
CREATE OR REPLACE FUNCTION revoke_invitation(
  p_invitation_id UUID,
  p_revoked_by TEXT,
  p_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE invitations
  SET 
    status = 'revoked',
    revoked_at = NOW(),
    revoked_by = p_revoked_by,
    revocation_reason = p_reason
  WHERE id = p_invitation_id
    AND status IN ('pending', 'used');
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to cleanup expired invitations
CREATE OR REPLACE FUNCTION cleanup_expired_invitations()
RETURNS INTEGER AS $$
DECLARE
  expired_count INTEGER;
BEGIN
  UPDATE invitations
  SET status = 'expired'
  WHERE status = 'pending'
    AND expires_at <= NOW();
  
  GET DIAGNOSTICS expired_count = ROW_COUNT;
  
  RETURN expired_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get invitation statistics
CREATE OR REPLACE FUNCTION get_invitation_stats(
  p_client_id UUID DEFAULT NULL,
  p_app_id UUID DEFAULT NULL,
  p_date_from TIMESTAMP DEFAULT NULL,
  p_date_to TIMESTAMP DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  result JSONB;
  total_count INTEGER;
  pending_count INTEGER;
  used_count INTEGER;
  expired_count INTEGER;
  revoked_count INTEGER;
BEGIN
  -- Build base query conditions
  WITH invitation_stats AS (
    SELECT 
      COUNT(*) as total,
      COUNT(*) FILTER (WHERE status = 'pending') as pending,
      COUNT(*) FILTER (WHERE status = 'used') as used,
      COUNT(*) FILTER (WHERE status = 'expired') as expired,
      COUNT(*) FILTER (WHERE status = 'revoked') as revoked
    FROM invitations
    WHERE (p_client_id IS NULL OR client_id = p_client_id)
      AND (p_app_id IS NULL OR app_id = p_app_id)
      AND (p_date_from IS NULL OR created_at >= p_date_from)
      AND (p_date_to IS NULL OR created_at <= p_date_to)
  )
  SELECT 
    jsonb_build_object(
      'total_invitations', total,
      'pending_invitations', pending,
      'used_invitations', used,
      'expired_invitations', expired,
      'revoked_invitations', revoked,
      'usage_rate', CASE WHEN total > 0 THEN ROUND((used::DECIMAL / total) * 100, 2) ELSE 0 END
    )
  INTO result
  FROM invitation_stats;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- VIEWS
-- =====================================================

-- View for active invitations with client and app information
CREATE OR REPLACE VIEW active_invitations AS
SELECT 
  i.id,
  i.invitation_code,
  i.status,
  i.created_at,
  i.expires_at,
  i.used_count,
  i.max_uses,
  c.client_code,
  c.legal_name as client_name,
  ca.app_code,
  ca.app_name,
  i.created_by,
  i.permissions,
  i.restrictions
FROM invitations i
JOIN clients c ON c.id = i.client_id
JOIN client_applications ca ON ca.id = i.app_id
WHERE i.status = 'pending'
  AND i.expires_at > NOW()
  AND c.status = 'active'
  AND ca.status = 'active';

-- View for invitation usage statistics
CREATE OR REPLACE VIEW invitation_usage_summary AS
SELECT 
  c.client_code,
  c.legal_name as client_name,
  ca.app_code,
  ca.app_name,
  COUNT(*) as total_invitations,
  COUNT(*) FILTER (WHERE i.status = 'pending') as pending_invitations,
  COUNT(*) FILTER (WHERE i.status = 'used') as used_invitations,
  COUNT(*) FILTER (WHERE i.status = 'expired') as expired_invitations,
  COUNT(*) FILTER (WHERE i.status = 'revoked') as revoked_invitations,
  ROUND(
    CASE WHEN COUNT(*) > 0 
    THEN (COUNT(*) FILTER (WHERE i.status = 'used')::DECIMAL / COUNT(*)) * 100 
    ELSE 0 END, 2
  ) as usage_rate_percent
FROM invitations i
JOIN clients c ON c.id = i.client_id
JOIN client_applications ca ON ca.id = i.app_id
GROUP BY c.id, c.client_code, c.legal_name, ca.id, ca.app_code, ca.app_name
ORDER BY c.client_code, ca.app_code;

-- =====================================================
-- PERIODIC CLEANUP JOB
-- =====================================================

-- Function to be called by cron job for maintenance
CREATE OR REPLACE FUNCTION invitation_maintenance()
RETURNS JSONB AS $$
DECLARE
  expired_count INTEGER;
  old_count INTEGER;
  result JSONB;
BEGIN
  -- Mark expired invitations
  expired_count := cleanup_expired_invitations();
  
  -- Delete old expired/revoked invitations (older than 90 days)
  DELETE FROM invitations
  WHERE status IN ('expired', 'revoked')
    AND created_at < NOW() - INTERVAL '90 days';
  
  GET DIAGNOSTICS old_count = ROW_COUNT;
  
  -- Return maintenance summary
  result := jsonb_build_object(
    'expired_invitations', expired_count,
    'deleted_old_invitations', old_count,
    'maintenance_run_at', NOW()
  );
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE invitations IS 'General invitation system for all Flows applications with JWT-based security - all PII including dual emails encrypted in tokens';
COMMENT ON COLUMN invitations.invitation_code IS 'Human-readable invitation code (e.g., ACME-ONBOARD-A1B2C3, CORP-SURVEY-X9Y8Z7)';
COMMENT ON COLUMN invitations.jwt_token_hash IS 'SHA-256 hash of the JWT token containing encrypted PII (company email, private email, personal details)';
COMMENT ON COLUMN invitations.permissions IS 'Array of permissions granted by this invitation (form access, application features, etc.)';
COMMENT ON COLUMN invitations.restrictions IS 'Access restrictions (IP ranges, time windows, device limits, usage limits) as JSON';
COMMENT ON COLUMN invitations.client_data IS 'Non-PII client-specific metadata for invitation context';
COMMENT ON COLUMN invitations.usage_metadata IS 'Analytics and usage tracking for invitation effectiveness';