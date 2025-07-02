-- Extend invitations table for demo request functionality
-- This adds demo-specific fields and email tracking to the existing api.invitations table

-- Drop existing views that depend on invitations table structure
DROP VIEW IF EXISTS api.active_invitations;
DROP VIEW IF EXISTS active_invitations; -- Handle both api schema and public schema versions
DROP VIEW IF EXISTS api.invitation_usage_summary;
DROP VIEW IF EXISTS invitation_usage_summary;

-- Add demo-specific fields to invitations table with GDPR-compliant approach
ALTER TABLE api.invitations
  ADD COLUMN IF NOT EXISTS jwt_token TEXT, -- Encrypted JWT containing PII (email, etc.)
  ADD COLUMN IF NOT EXISTS email_hash VARCHAR(64), -- SHA-256 hash for privacy-preserving lookups
  ADD COLUMN IF NOT EXISTS email_domain TEXT, -- Domain only for spam analysis (@company.com)
  ADD COLUMN IF NOT EXISTS retention_purpose TEXT, -- Legal basis for data retention
  ADD COLUMN IF NOT EXISTS auto_delete_at TIMESTAMPTZ, -- Automated GDPR deletion date
  ADD COLUMN IF NOT EXISTS demo_duration TEXT,
  ADD COLUMN IF NOT EXISTS team_size TEXT,
  ADD COLUMN IF NOT EXISTS timeline TEXT,
  ADD COLUMN IF NOT EXISTS role TEXT,
  ADD COLUMN IF NOT EXISTS request_type TEXT DEFAULT 'invitation',
  ADD COLUMN IF NOT EXISTS spam_score INTEGER DEFAULT 0 CHECK (spam_score >= 0 AND spam_score <= 100),
  ADD COLUMN IF NOT EXISTS spam_status TEXT,
  ADD COLUMN IF NOT EXISTS workflow_type TEXT,
  ADD COLUMN IF NOT EXISTS client_ip INET,
  ADD COLUMN IF NOT EXISTS user_agent TEXT,
  ADD COLUMN IF NOT EXISTS referrer TEXT,
  ADD COLUMN IF NOT EXISTS comment TEXT,
  ADD COLUMN IF NOT EXISTS email_sent BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS email_sent_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS email_id TEXT,
  ADD COLUMN IF NOT EXISTS follow_up_sent BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS follow_up_sent_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS email_attempts INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_email_error TEXT;

-- Update status constraint to include demo request statuses
ALTER TABLE api.invitations 
DROP CONSTRAINT IF EXISTS invitations_status_check;

ALTER TABLE api.invitations 
ADD CONSTRAINT invitations_status_check 
CHECK (status IN ('pending', 'used', 'expired', 'revoked', 'requested', 'rejected'));

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_invitations_request_type ON api.invitations(request_type);
CREATE INDEX IF NOT EXISTS idx_invitations_email_hash ON api.invitations(email_hash);
CREATE INDEX IF NOT EXISTS idx_invitations_email_domain ON api.invitations(email_domain);
CREATE INDEX IF NOT EXISTS idx_invitations_email_status ON api.invitations(email_sent, email_sent_at);
CREATE INDEX IF NOT EXISTS idx_invitations_spam_status ON api.invitations(spam_status, spam_score);
CREATE INDEX IF NOT EXISTS idx_invitations_auto_delete ON api.invitations(auto_delete_at) WHERE auto_delete_at IS NOT NULL;

-- Function to approve a demo request
CREATE OR REPLACE FUNCTION api.approve_demo_request(invitation_id UUID)
RETURNS api.invitations
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result api.invitations;
BEGIN
  UPDATE api.invitations
  SET 
    status = 'pending',
    updated_at = now()
  WHERE id = invitation_id
    AND request_type = 'demo_request'
    AND status = 'requested'
  RETURNING * INTO result;
  
  IF result.id IS NULL THEN
    RAISE EXCEPTION 'Demo request not found or not in requested status';
  END IF;
  
  RETURN result;
END;
$$;

-- Function to reject a demo request
CREATE OR REPLACE FUNCTION api.reject_demo_request(invitation_id UUID, reason TEXT DEFAULT NULL)
RETURNS api.invitations
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result api.invitations;
BEGIN
  UPDATE api.invitations
  SET 
    status = 'rejected',
    comment = COALESCE(comment || E'\n\nRejection reason: ' || reason, 'Rejection reason: ' || reason),
    updated_at = now()
  WHERE id = invitation_id
    AND request_type = 'demo_request'
    AND status = 'requested'
  RETURNING * INTO result;
  
  IF result.id IS NULL THEN
    RAISE EXCEPTION 'Demo request not found or not in requested status';
  END IF;
  
  RETURN result;
END;
$$;

-- Function to mark invitation email as sent
CREATE OR REPLACE FUNCTION api.mark_invitation_email_sent(
  invitation_id UUID,
  email_service_id TEXT
)
RETURNS api.invitations
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result api.invitations;
BEGIN
  UPDATE api.invitations
  SET 
    email_sent = true,
    email_sent_at = now(),
    email_id = email_service_id,
    email_attempts = email_attempts + 1,
    last_email_error = NULL,
    updated_at = now()
  WHERE id = invitation_id
  RETURNING * INTO result;
  
  IF result.id IS NULL THEN
    RAISE EXCEPTION 'Invitation not found';
  END IF;
  
  RETURN result;
END;
$$;

-- Function to mark invitation email as failed
CREATE OR REPLACE FUNCTION api.mark_invitation_email_failed(
  invitation_id UUID,
  error_message TEXT
)
RETURNS api.invitations
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result api.invitations;
BEGIN
  UPDATE api.invitations
  SET 
    email_attempts = email_attempts + 1,
    last_email_error = error_message,
    updated_at = now()
  WHERE id = invitation_id
  RETURNING * INTO result;
  
  IF result.id IS NULL THEN
    RAISE EXCEPTION 'Invitation not found';
  END IF;
  
  RETURN result;
END;
$$;

-- Function to mark follow-up email as sent
CREATE OR REPLACE FUNCTION api.mark_invitation_followup_sent(
  invitation_id UUID,
  email_service_id TEXT
)
RETURNS api.invitations
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result api.invitations;
BEGIN
  UPDATE api.invitations
  SET 
    follow_up_sent = true,
    follow_up_sent_at = now(),
    email_id = email_service_id,
    updated_at = now()
  WHERE id = invitation_id
  RETURNING * INTO result;
  
  IF result.id IS NULL THEN
    RAISE EXCEPTION 'Invitation not found';
  END IF;
  
  RETURN result;
END;
$$;

-- Function to get invitations that need email
CREATE OR REPLACE FUNCTION api.get_invitations_needing_email()
RETURNS TABLE (
  id UUID,
  email_hash VARCHAR(64),
  jwt_token TEXT,
  status VARCHAR(50),
  request_type TEXT,
  created_at TIMESTAMPTZ,
  email_attempts INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    i.id,
    i.email_hash,
    i.jwt_token,
    i.status,
    i.request_type,
    i.created_at,
    i.email_attempts
  FROM api.invitations i
  WHERE i.email_sent = false
    AND i.status IN ('pending', 'requested')
    AND i.email_attempts < 3
    AND (i.last_email_error IS NULL OR i.created_at < now() - interval '1 hour')
  ORDER BY i.created_at ASC;
END;
$$;

-- Function to get invitations that need follow-up
CREATE OR REPLACE FUNCTION api.get_invitations_needing_followup()
RETURNS TABLE (
  id UUID,
  email_hash VARCHAR(64),
  jwt_token TEXT,
  status VARCHAR(50),
  request_type TEXT,
  email_sent_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    i.id,
    i.email_hash,
    i.jwt_token,
    i.status,
    i.request_type,
    i.email_sent_at
  FROM api.invitations i
  WHERE i.email_sent = true
    AND i.follow_up_sent = false
    AND i.status = 'pending'
    AND i.email_sent_at < now() - interval '3 days'
  ORDER BY i.email_sent_at ASC;
END;
$$;

-- View for demo requests admin interface
CREATE OR REPLACE VIEW api.demo_requests_admin AS
SELECT 
  id,
  email_hash,
  email_domain,
  jwt_token,
  status,
  demo_duration,
  team_size,
  timeline,
  role,
  comment,
  spam_score,
  spam_status,
  workflow_type,
  client_ip,
  user_agent,
  referrer,
  email_sent,
  email_sent_at,
  follow_up_sent,
  follow_up_sent_at,
  email_attempts,
  last_email_error,
  retention_purpose,
  auto_delete_at,
  created_at,
  expires_at
FROM api.invitations
WHERE request_type = 'demo_request';

-- Update active_invitations view to handle new fields
CREATE OR REPLACE VIEW api.active_invitations AS
SELECT 
  id,
  email_hash,
  email_domain,
  status,
  request_type,
  demo_duration,
  team_size,
  timeline,
  role,
  comment,
  expires_at,
  auto_delete_at,
  created_at
FROM api.invitations
WHERE status IN ('pending', 'requested')
  AND (expires_at IS NULL OR expires_at > now())
  AND (auto_delete_at IS NULL OR auto_delete_at > now());

-- Recreate original invitation_usage_summary view with schema prefix
CREATE OR REPLACE VIEW api.invitation_usage_summary AS
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
FROM api.invitations i
JOIN api.clients c ON c.id = i.client_id
JOIN api.client_applications ca ON ca.id = i.app_id
GROUP BY c.id, c.client_code, c.legal_name, ca.id, ca.app_code, ca.app_name
ORDER BY c.client_code, ca.app_code;

-- Grant permissions
GRANT SELECT ON api.demo_requests_admin TO authenticated;
GRANT SELECT ON api.active_invitations TO authenticated;
GRANT SELECT ON api.invitation_usage_summary TO authenticated;

GRANT EXECUTE ON FUNCTION api.approve_demo_request(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION api.reject_demo_request(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION api.mark_invitation_email_sent(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION api.mark_invitation_email_failed(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION api.mark_invitation_followup_sent(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION api.get_invitations_needing_email() TO authenticated;
GRANT EXECUTE ON FUNCTION api.get_invitations_needing_followup() TO authenticated;

-- =====================================================
-- GDPR COMPLIANCE FUNCTIONS
-- =====================================================

-- Function to set auto-deletion date based on retention purpose
CREATE OR REPLACE FUNCTION api.set_invitation_retention(
  invitation_id UUID,
  purpose TEXT
)
RETURNS api.invitations
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result api.invitations;
  delete_date TIMESTAMPTZ;
BEGIN
  -- Calculate auto-deletion date based on purpose
  delete_date := CASE purpose
    WHEN 'demo_request_completed' THEN now() + interval '90 days'
    WHEN 'demo_request_rejected' THEN now() + interval '30 days'
    WHEN 'spam_detected' THEN now() + interval '30 days'
    WHEN 'invitation_active' THEN now() + interval '2 years'
    ELSE now() + interval '1 year' -- Default retention
  END;
  
  UPDATE api.invitations
  SET 
    retention_purpose = purpose,
    auto_delete_at = delete_date
  WHERE id = invitation_id
  RETURNING * INTO result;
  
  IF result.id IS NULL THEN
    RAISE EXCEPTION 'Invitation not found';
  END IF;
  
  RETURN result;
END;
$$;

-- Automated GDPR cleanup function
CREATE OR REPLACE FUNCTION api.gdpr_compliant_cleanup()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  deleted_count INTEGER := 0;
  updated_count INTEGER := 0;
  cleanup_summary JSONB;
BEGIN
  -- Delete invitations past their auto-deletion date
  DELETE FROM api.invitations
  WHERE auto_delete_at IS NOT NULL 
    AND auto_delete_at <= now();
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  -- Update invitations that need auto-deletion dates set
  UPDATE api.invitations
  SET 
    retention_purpose = CASE 
      WHEN status = 'rejected' AND request_type = 'demo_request' THEN 'demo_request_rejected'
      WHEN status = 'used' AND request_type = 'demo_request' THEN 'demo_request_completed'
      WHEN spam_score > 70 THEN 'spam_detected'
      WHEN request_type = 'invitation' THEN 'invitation_active'
      ELSE 'general_retention'
    END,
    auto_delete_at = CASE 
      WHEN status = 'rejected' AND request_type = 'demo_request' THEN now() + interval '30 days'
      WHEN status = 'used' AND request_type = 'demo_request' THEN now() + interval '90 days'
      WHEN spam_score > 70 THEN now() + interval '30 days'
      WHEN request_type = 'invitation' THEN now() + interval '2 years'
      ELSE now() + interval '1 year'
    END
  WHERE auto_delete_at IS NULL;
  
  GET DIAGNOSTICS updated_count = ROW_COUNT;
  
  -- Return cleanup summary
  cleanup_summary := jsonb_build_object(
    'deleted_records', deleted_count,
    'updated_retention_policies', updated_count,
    'cleanup_run_at', now(),
    'next_cleanup_recommended', now() + interval '1 day'
  );
  
  RETURN cleanup_summary;
END;
$$;

-- Function to find invitation by email hash
CREATE OR REPLACE FUNCTION api.find_invitation_by_email_hash(p_email_hash VARCHAR(64))
RETURNS api.invitations
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  invitation_record api.invitations;
BEGIN
  SELECT * INTO invitation_record
  FROM api.invitations
  WHERE email_hash = p_email_hash
    AND status IN ('pending', 'requested')
    AND (expires_at IS NULL OR expires_at > now())
    AND (auto_delete_at IS NULL OR auto_delete_at > now())
  ORDER BY created_at DESC
  LIMIT 1;
  
  RETURN invitation_record;
END;
$$;

-- Function to get retention statistics for compliance reporting
CREATE OR REPLACE FUNCTION api.get_retention_stats()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  stats JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_invitations', COUNT(*),
    'pending_deletion', COUNT(*) FILTER (WHERE auto_delete_at <= now() + interval '7 days'),
    'retention_purposes', jsonb_object_agg(
      COALESCE(retention_purpose, 'unset'), 
      COUNT(*)
    ),
    'average_retention_days', ROUND(AVG(
      EXTRACT(EPOCH FROM (auto_delete_at - created_at)) / 86400
    ), 2),
    'oldest_record_days', ROUND(
      EXTRACT(EPOCH FROM (now() - MIN(created_at))) / 86400, 2
    ),
    'report_generated_at', now()
  ) INTO stats
  FROM api.invitations;
  
  RETURN stats;
END;
$$;

-- Grant permissions for GDPR functions
GRANT EXECUTE ON FUNCTION api.set_invitation_retention(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION api.gdpr_compliant_cleanup() TO service_role;
GRANT EXECUTE ON FUNCTION api.find_invitation_by_email_hash(VARCHAR(64)) TO authenticated;
GRANT EXECUTE ON FUNCTION api.get_retention_stats() TO authenticated;