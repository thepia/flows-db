-- =====================================================
-- FIX INVITATION STATUS WORKFLOW
-- =====================================================
-- 
-- Purpose: Update mark_notification_sent to also update invitation status
-- Issue: Approved invitations should transition to 'sent' when email is sent
-- Dependencies: 25_extend_invitations_notification_queue.sql

-- Set schema context
SET search_path TO api, public;

-- Update the mark_notification_sent function to also update invitation status
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
  current_status VARCHAR(50);
BEGIN
  -- Get current invitation status
  SELECT status INTO current_status
  FROM api.invitations 
  WHERE id = invitation_id;
  
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
    -- Update invitation status from 'approved' to 'sent'
    status = CASE 
      WHEN current_status = 'approved' AND delivery_method = 'email' THEN 'sent'
      ELSE status
    END,
    
    -- Update notification queue status
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

-- Update the TabFilter configuration to reflect actual workflow
COMMENT ON FUNCTION api.mark_notification_sent IS 
'Marks a notification as sent and updates invitation status from approved to sent when email is delivered';

-- =====================================================
-- MIGRATION NOTES
-- =====================================================

/*
WORKFLOW AFTER THIS CHANGE:

1. User submits demo request → status: 'requested'
2. Admin approves → status: 'approved', notification_status: 'pending'
3. N8N processes notification → calls mark_notification_sent()
4. mark_notification_sent() → status: 'sent', notification_status: 'sent'
5. User uses invitation → status: 'used'

The 'pending' status is now effectively replaced by 'approved' in the workflow.

UI TAB MEANINGS:
- Unresolved: 'requested' (awaiting admin action)
- Requested: 'requested' only
- Approved: 'approved' (notification queued but not sent)
- Sent: 'sent' (email delivered)
- Used: 'used' (demo accessed)
- Rejected: 'rejected' (admin denied)
- Expired: 'expired' (time limit exceeded)

Note: The original 'pending' tab can be repurposed or removed since 
it doesn't fit the current workflow.
*/