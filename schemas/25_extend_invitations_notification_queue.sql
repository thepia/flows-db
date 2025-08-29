-- =====================================================
-- EXTEND INVITATIONS FOR UNIFIED NOTIFICATION QUEUE
-- =====================================================
-- 
-- Purpose: Add notification queue fields to support unified N8N notification processor
-- Dependencies: 11_extend_invitations_for_demos.sql (existing email fields)
-- Use Case: Queue-based notification system for email, SMS, push, Discord
-- Optimization: Single N8N workflow for all notification types

-- Set schema context
SET search_path TO api, public;

-- Add unified notification queue fields to existing invitations table
ALTER TABLE api.invitations
  -- Notification queue status (extends existing email_* fields)
  ADD COLUMN IF NOT EXISTS notification_status VARCHAR(50) DEFAULT 'pending' CHECK (
    notification_status IN (
      'pending', 'processing', 'sent', 'failed', 
      'retry_scheduled', 'reminder_due', 'cancelled', 'paused'
    )
  ),
  
  -- Multi-channel delivery methods
  ADD COLUMN IF NOT EXISTS delivery_methods JSONB DEFAULT '["email"]'::jsonb, -- Array: ['email', 'sms', 'push', 'discord']
  ADD COLUMN IF NOT EXISTS delivery_status JSONB DEFAULT '{}'::jsonb, -- {email: 'sent', sms: 'pending'}
  
  -- Enhanced retry and timing logic
  ADD COLUMN IF NOT EXISTS notification_attempts INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS max_notification_attempts INTEGER DEFAULT 3,
  ADD COLUMN IF NOT EXISTS next_notification_attempt TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS last_notification_error TEXT,
  
  -- Template and content management
  ADD COLUMN IF NOT EXISTS message_template VARCHAR(100), -- 'invitation_approved', 'demo_reminder', etc.
  ADD COLUMN IF NOT EXISTS template_data JSONB DEFAULT '{}'::jsonb, -- Variables for template rendering
  ADD COLUMN IF NOT EXISTS custom_message TEXT, -- Override template with custom message
  
  -- Advanced scheduling and timing
  ADD COLUMN IF NOT EXISTS send_after TIMESTAMP WITH TIME ZONE DEFAULT NOW(), -- Delayed sending
  ADD COLUMN IF NOT EXISTS reminder_schedule JSONB, -- ["+3 days", "+7 days", "+12 days"]
  ADD COLUMN IF NOT EXISTS reminder_count INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_reminder_sent TIMESTAMP WITH TIME ZONE,
  
  -- Recipient data for multiple channels (no PII - use with JWT token)
  ADD COLUMN IF NOT EXISTS notification_metadata JSONB DEFAULT '{}'::jsonb, -- {phone_hash: 'abc123', push_token_hash: 'def456'}
  
  -- Audit and tracking
  ADD COLUMN IF NOT EXISTS notification_triggered_by VARCHAR(100), -- 'admin_approval', 'auto_reminder', 'manual_resend'
  ADD COLUMN IF NOT EXISTS notification_triggered_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS notification_completed_at TIMESTAMP WITH TIME ZONE;

-- Update existing status constraint to include new notification-aware statuses
ALTER TABLE api.invitations 
DROP CONSTRAINT IF EXISTS invitations_status_check;

ALTER TABLE api.invitations 
ADD CONSTRAINT invitations_status_check 
CHECK (status IN (
  'pending', 'used', 'expired', 'revoked', 
  'requested', 'rejected', 'approved', 'sent'
));

-- Add indexes for notification queue performance
CREATE INDEX IF NOT EXISTS idx_invitations_notification_status ON api.invitations(notification_status);
CREATE INDEX IF NOT EXISTS idx_invitations_notification_attempts ON api.invitations(notification_attempts, max_notification_attempts);
CREATE INDEX IF NOT EXISTS idx_invitations_send_after ON api.invitations(send_after) WHERE notification_status = 'pending';
CREATE INDEX IF NOT EXISTS idx_invitations_retry_scheduled ON api.invitations(next_notification_attempt) WHERE notification_status = 'retry_scheduled';
CREATE INDEX IF NOT EXISTS idx_invitations_reminder_due ON api.invitations(last_reminder_sent, reminder_count);
CREATE INDEX IF NOT EXISTS idx_invitations_template ON api.invitations(message_template);

-- Composite indexes for notification queue queries
CREATE INDEX IF NOT EXISTS idx_invitations_notification_queue ON api.invitations(
  notification_status, send_after, expires_at
) WHERE notification_status IN ('pending', 'retry_scheduled', 'reminder_due');

CREATE INDEX IF NOT EXISTS idx_invitations_delivery_status ON api.invitations 
USING GIN (delivery_status) WHERE notification_status IN ('processing', 'sent', 'failed');

-- =====================================================
-- NOTIFICATION QUEUE FUNCTIONS
-- =====================================================

-- Function to get pending notifications for N8N processor
CREATE OR REPLACE FUNCTION api.get_pending_notifications()
RETURNS TABLE (
  id UUID,
  client_id UUID,
  app_id UUID,
  jwt_token TEXT,
  notification_status VARCHAR(50),
  delivery_methods JSONB,
  delivery_status JSONB,
  message_template VARCHAR(100),
  template_data JSONB,
  custom_message TEXT,
  notification_metadata JSONB,
  notification_attempts INTEGER,
  max_notification_attempts INTEGER,
  created_at TIMESTAMP WITH TIME ZONE,
  send_after TIMESTAMP WITH TIME ZONE,
  expires_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    i.id,
    i.client_id,
    i.app_id,
    i.jwt_token,
    i.notification_status,
    i.delivery_methods,
    i.delivery_status,
    i.message_template,
    i.template_data,
    i.custom_message,
    i.notification_metadata,
    i.notification_attempts,
    i.max_notification_attempts,
    i.created_at,
    i.send_after,
    i.expires_at
  FROM api.invitations i
  WHERE i.notification_status IN ('pending', 'retry_scheduled', 'reminder_due')
    AND i.send_after <= NOW()
    AND (i.expires_at IS NULL OR i.expires_at > NOW())
    AND (i.auto_delete_at IS NULL OR i.auto_delete_at > NOW())
    AND i.notification_attempts < i.max_notification_attempts
  ORDER BY 
    CASE i.notification_status 
      WHEN 'retry_scheduled' THEN 1
      WHEN 'reminder_due' THEN 2 
      WHEN 'pending' THEN 3
      ELSE 4
    END,
    i.send_after ASC,
    i.created_at ASC;
END;
$$;

-- Function to mark notification as processing (prevent duplicate processing)
CREATE OR REPLACE FUNCTION api.mark_notification_processing(
  invitation_id UUID
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
    notification_status = 'processing',
    notification_triggered_at = NOW()
  WHERE id = invitation_id
    AND notification_status IN ('pending', 'retry_scheduled', 'reminder_due')
  RETURNING * INTO result;
  
  IF result.id IS NULL THEN
    RAISE EXCEPTION 'Invitation not found or not in processable status';
  END IF;
  
  RETURN result;
END;
$$;

-- Function to mark notification delivery success
CREATE OR REPLACE FUNCTION api.mark_notification_sent(
  invitation_id UUID,
  delivery_method VARCHAR(20),
  service_message_id TEXT DEFAULT NULL
)
RETURNS api.invitations
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result api.invitations;
  updated_delivery_status JSONB;
BEGIN
  -- Update delivery status for specific method
  SELECT 
    COALESCE(delivery_status, '{}'::jsonb) || 
    jsonb_build_object(delivery_method, jsonb_build_object(
      'status', 'sent',
      'sent_at', NOW(),
      'message_id', service_message_id
    ))
  INTO updated_delivery_status
  FROM api.invitations 
  WHERE id = invitation_id;
  
  UPDATE api.invitations
  SET 
    notification_status = 'sent',
    delivery_status = updated_delivery_status,
    notification_attempts = notification_attempts + 1,
    notification_completed_at = NOW(),
    last_notification_error = NULL,
    
    -- Legacy email fields for backward compatibility
    email_sent = CASE WHEN delivery_method = 'email' THEN true ELSE email_sent END,
    email_sent_at = CASE WHEN delivery_method = 'email' THEN NOW() ELSE email_sent_at END,
    email_id = CASE WHEN delivery_method = 'email' THEN service_message_id ELSE email_id END
  WHERE id = invitation_id
  RETURNING * INTO result;
  
  IF result.id IS NULL THEN
    RAISE EXCEPTION 'Invitation not found';
  END IF;
  
  RETURN result;
END;
$$;

-- Function to mark notification delivery failure
CREATE OR REPLACE FUNCTION api.mark_notification_failed(
  invitation_id UUID,
  delivery_method VARCHAR(20),
  error_message TEXT
)
RETURNS api.invitations
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result api.invitations;
  updated_delivery_status JSONB;
  should_retry BOOLEAN;
  retry_delay INTERVAL;
BEGIN
  -- Update delivery status for specific method
  SELECT 
    COALESCE(delivery_status, '{}'::jsonb) || 
    jsonb_build_object(delivery_method, jsonb_build_object(
      'status', 'failed',
      'failed_at', NOW(),
      'error', error_message
    ))
  INTO updated_delivery_status
  FROM api.invitations 
  WHERE id = invitation_id;
  
  -- Check if we should retry
  SELECT 
    notification_attempts + 1 < max_notification_attempts
  INTO should_retry
  FROM api.invitations 
  WHERE id = invitation_id;
  
  -- Calculate retry delay (exponential backoff: 5min, 30min, 2hours)
  retry_delay := CASE 
    WHEN should_retry THEN
      CASE (SELECT notification_attempts FROM api.invitations WHERE id = invitation_id)
        WHEN 0 THEN interval '5 minutes'
        WHEN 1 THEN interval '30 minutes'  
        WHEN 2 THEN interval '2 hours'
        ELSE interval '6 hours'
      END
    ELSE NULL
  END;
  
  UPDATE api.invitations
  SET 
    notification_status = CASE 
      WHEN should_retry THEN 'retry_scheduled'
      ELSE 'failed'
    END,
    delivery_status = updated_delivery_status,
    notification_attempts = notification_attempts + 1,
    next_notification_attempt = CASE 
      WHEN should_retry THEN NOW() + retry_delay
      ELSE NULL
    END,
    last_notification_error = error_message,
    
    -- Legacy email fields for backward compatibility
    email_attempts = CASE WHEN delivery_method = 'email' THEN notification_attempts + 1 ELSE email_attempts END,
    last_email_error = CASE WHEN delivery_method = 'email' THEN error_message ELSE last_email_error END
  WHERE id = invitation_id
  RETURNING * INTO result;
  
  IF result.id IS NULL THEN
    RAISE EXCEPTION 'Invitation not found';
  END IF;
  
  RETURN result;
END;
$$;

-- Function to queue a notification (used by admin approval)
CREATE OR REPLACE FUNCTION api.queue_notification(
  invitation_id UUID,
  template_name VARCHAR(100),
  delivery_methods_array TEXT[] DEFAULT ARRAY['email'],
  template_variables JSONB DEFAULT '{}'::jsonb,
  send_delay INTERVAL DEFAULT interval '0',
  triggered_by VARCHAR(100) DEFAULT 'system'
)
RETURNS api.invitations
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result api.invitations;
  send_time TIMESTAMP WITH TIME ZONE;
BEGIN
  send_time := NOW() + send_delay;
  
  UPDATE api.invitations
  SET 
    notification_status = 'pending',
    delivery_methods = to_jsonb(delivery_methods_array),
    delivery_status = '{}'::jsonb,
    message_template = template_name,
    template_data = template_variables,
    send_after = send_time,
    notification_attempts = 0,
    notification_triggered_by = triggered_by,
    notification_triggered_at = NOW(),
    next_notification_attempt = NULL,
    last_notification_error = NULL
  WHERE id = invitation_id
  RETURNING * INTO result;
  
  IF result.id IS NULL THEN
    RAISE EXCEPTION 'Invitation not found';
  END IF;
  
  RETURN result;
END;
$$;

-- Function to schedule reminder notifications
CREATE OR REPLACE FUNCTION api.schedule_reminder_notifications(
  invitation_id UUID,
  reminder_template VARCHAR(100) DEFAULT 'invitation_reminder',
  days_array INTEGER[] DEFAULT ARRAY[3, 7, 12]
)
RETURNS api.invitations
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result api.invitations;
  reminder_schedule_json JSONB;
BEGIN
  -- Convert days array to ISO 8601 duration strings
  SELECT jsonb_agg('+' || day_count || ' days')
  INTO reminder_schedule_json
  FROM unnest(days_array) AS day_count;
  
  UPDATE api.invitations
  SET 
    reminder_schedule = reminder_schedule_json,
    reminder_count = 0,
    message_template = COALESCE(message_template, reminder_template)
  WHERE id = invitation_id
  RETURNING * INTO result;
  
  IF result.id IS NULL THEN
    RAISE EXCEPTION 'Invitation not found';
  END IF;
  
  RETURN result;
END;
$$;

-- Function to get notification statistics for monitoring
CREATE OR REPLACE FUNCTION api.get_notification_stats()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  stats JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_notifications', COUNT(*),
    'by_status', jsonb_object_agg(
      COALESCE(notification_status, 'null'), 
      COUNT(*)
    ),
    'pending_count', COUNT(*) FILTER (WHERE notification_status = 'pending'),
    'failed_count', COUNT(*) FILTER (WHERE notification_status = 'failed'),
    'retry_scheduled_count', COUNT(*) FILTER (WHERE notification_status = 'retry_scheduled'),
    'average_attempts', ROUND(AVG(notification_attempts), 2),
    'delivery_methods_usage', (
      SELECT jsonb_object_agg(method, method_count)
      FROM (
        SELECT 
          jsonb_array_elements_text(delivery_methods) as method,
          COUNT(*) as method_count
        FROM api.invitations 
        WHERE delivery_methods IS NOT NULL
        GROUP BY jsonb_array_elements_text(delivery_methods)
      ) method_stats
    ),
    'recent_failures', (
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', id,
          'error', last_notification_error,
          'attempts', notification_attempts,
          'created_at', created_at
        )
      )
      FROM (
        SELECT id, last_notification_error, notification_attempts, created_at
        FROM api.invitations 
        WHERE notification_status = 'failed' 
          AND last_notification_error IS NOT NULL
        ORDER BY notification_triggered_at DESC 
        LIMIT 10
      ) recent_failures_sub
    ),
    'stats_generated_at', NOW()
  ) INTO stats
  FROM api.invitations
  WHERE notification_status IS NOT NULL;
  
  RETURN stats;
END;
$$;

-- =====================================================
-- ADMIN HELPER FUNCTIONS
-- =====================================================

-- Function to manually trigger notification processing (for admin interface)
CREATE OR REPLACE FUNCTION api.trigger_notification_processing(
  invitation_id UUID DEFAULT NULL,
  force_retry BOOLEAN DEFAULT FALSE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  affected_count INTEGER := 0;
  result JSONB;
BEGIN
  IF invitation_id IS NOT NULL THEN
    -- Process specific invitation
    UPDATE api.invitations
    SET 
      notification_status = 'pending',
      send_after = NOW(),
      notification_attempts = CASE WHEN force_retry THEN 0 ELSE notification_attempts END,
      last_notification_error = CASE WHEN force_retry THEN NULL ELSE last_notification_error END
    WHERE id = invitation_id
      AND notification_status IN ('failed', 'retry_scheduled', 'pending');
    
    GET DIAGNOSTICS affected_count = ROW_COUNT;
    
    result := jsonb_build_object(
      'action', 'trigger_single',
      'invitation_id', invitation_id,
      'affected', affected_count > 0,
      'triggered_at', NOW()
    );
  ELSE
    -- Process all pending notifications
    UPDATE api.invitations
    SET 
      send_after = NOW()
    WHERE notification_status IN ('pending', 'retry_scheduled')
      AND send_after > NOW();
    
    GET DIAGNOSTICS affected_count = ROW_COUNT;
    
    result := jsonb_build_object(
      'action', 'trigger_all_pending',
      'affected_count', affected_count,
      'triggered_at', NOW()
    );
  END IF;
  
  RETURN result;
END;
$$;

-- Function to cancel notification (for admin interface)
CREATE OR REPLACE FUNCTION api.cancel_notification(
  invitation_id UUID,
  reason TEXT DEFAULT 'Cancelled by admin'
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
    notification_status = 'cancelled',
    last_notification_error = reason,
    notification_completed_at = NOW()
  WHERE id = invitation_id
    AND notification_status IN ('pending', 'retry_scheduled', 'reminder_due', 'processing')
  RETURNING * INTO result;
  
  IF result.id IS NULL THEN
    RAISE EXCEPTION 'Invitation not found or not in cancellable status';
  END IF;
  
  RETURN result;
END;
$$;

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

-- Grant permissions for notification queue functions
GRANT EXECUTE ON FUNCTION api.get_pending_notifications() TO service_role;
GRANT EXECUTE ON FUNCTION api.mark_notification_processing(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION api.mark_notification_sent(UUID, VARCHAR, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION api.mark_notification_failed(UUID, VARCHAR, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION api.queue_notification(UUID, VARCHAR, TEXT[], JSONB, INTERVAL, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION api.schedule_reminder_notifications(UUID, VARCHAR, INTEGER[]) TO authenticated;
GRANT EXECUTE ON FUNCTION api.get_notification_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION api.trigger_notification_processing(UUID, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION api.cancel_notification(UUID, TEXT) TO authenticated;

-- =====================================================
-- UPDATE EXISTING VIEWS
-- =====================================================

-- Drop and recreate demo_requests_admin view to avoid column conflicts
DROP VIEW IF EXISTS api.demo_requests_admin;

-- Create updated demo_requests_admin view to include notification fields
CREATE VIEW api.demo_requests_admin AS
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
  
  -- Legacy email fields (maintained for compatibility)
  email_sent,
  email_sent_at,
  follow_up_sent,
  follow_up_sent_at,
  email_attempts,
  last_email_error,
  
  -- New notification queue fields
  notification_status,
  delivery_methods,
  delivery_status,
  message_template,
  template_data,
  notification_attempts,
  max_notification_attempts,
  next_notification_attempt,
  last_notification_error,
  send_after,
  reminder_schedule,
  reminder_count,
  last_reminder_sent,
  notification_triggered_by,
  notification_triggered_at,
  notification_completed_at,
  
  -- Metadata and audit
  retention_purpose,
  auto_delete_at,
  created_at,
  expires_at
FROM api.invitations
WHERE request_type = 'demo_request';

-- Grant permissions on updated view
GRANT SELECT ON api.demo_requests_admin TO authenticated;

-- =====================================================
-- BACKWARD COMPATIBILITY TRIGGERS
-- =====================================================

-- Trigger to maintain backward compatibility with existing email fields
CREATE OR REPLACE FUNCTION sync_legacy_email_fields()
RETURNS TRIGGER AS $$
BEGIN
  -- Sync notification_status with email_sent for backward compatibility
  IF NEW.notification_status = 'sent' AND OLD.notification_status != 'sent' THEN
    NEW.email_sent = true;
    NEW.email_sent_at = COALESCE(NEW.email_sent_at, NOW());
  END IF;
  
  -- Sync email fields to notification fields when legacy fields are updated directly
  IF NEW.email_sent = true AND OLD.email_sent = false THEN
    NEW.notification_status = 'sent';
    NEW.notification_completed_at = COALESCE(NEW.notification_completed_at, NOW());
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_sync_legacy_email_fields
  BEFORE UPDATE ON api.invitations
  FOR EACH ROW
  EXECUTE FUNCTION sync_legacy_email_fields();

-- =====================================================
-- MIGRATION NOTES
-- =====================================================

/*
MIGRATION CHECKLIST:

1. ✅ Extended invitations table with notification queue fields
2. ✅ Added comprehensive notification management functions  
3. ✅ Created indexes for optimal queue performance
4. ✅ Maintained backward compatibility with existing email fields
5. ✅ Added admin functions for manual notification management
6. ✅ Updated demo_requests_admin view with new fields
7. ✅ Granted appropriate permissions for service_role and authenticated users

NEXT STEPS:

1. Deploy this schema to Supabase database
2. Update N8N Notification Processor workflow to use api.get_pending_notifications()
3. Modify admin approval flow to use api.queue_notification()
4. Test notification queue with different delivery methods
5. Monitor notification statistics with api.get_notification_stats()

USAGE EXAMPLES:

-- Queue an email notification after approval
SELECT api.queue_notification(
  '123e4567-e89b-12d3-a456-426614174000',
  'invitation_approved',
  ARRAY['email'],
  '{"demo_duration": "14 days", "access_url": "https://demo.thepia.net"}'::jsonb
);

-- Get notifications to process in N8N
SELECT * FROM api.get_pending_notifications();

-- Mark notification as sent from N8N  
SELECT api.mark_notification_sent(
  '123e4567-e89b-12d3-a456-426614174000',
  'email',
  'sendgrid_message_id_abc123'
);

-- Check notification statistics
SELECT api.get_notification_stats();
*/