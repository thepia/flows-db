-- Function to create invitation from n8n workflow JSON payload
-- This function accepts the complete JSON output from the n8n Code node
-- and handles all the field mapping and data transformation

CREATE OR REPLACE FUNCTION api.create_invitation_from_n8n(
  payload JSONB
) RETURNS api.invitations AS $$
DECLARE
  new_invitation api.invitations;
  client_uuid UUID;
  app_uuid UUID;
BEGIN
  -- Log the incoming payload for debugging
  RAISE LOG 'n8n payload received: %', payload;

  -- Resolve client_id from routing info or use default
  client_uuid := COALESCE(
    (payload->'routing'->>'client_id')::UUID,
    (SELECT id FROM api.clients WHERE code = 'THEPIA' LIMIT 1)
  );

  -- Resolve app_id from routing info or use default
  app_uuid := COALESCE(
    (payload->'routing'->>'app_id')::UUID,
    (SELECT id FROM api.client_applications WHERE client_id = client_uuid AND code = 'FLOWS' LIMIT 1)
  );

  -- Create the invitation record
  INSERT INTO api.invitations (
    -- Core required fields
    client_id,
    app_id,
    jwt_token_hash,
    created_by,
    expires_at,
    
    -- Optional core fields
    invitation_code,
    permissions,
    restrictions,
    status,
    max_uses,
    client_data,
    
    -- Extended demo fields
    jwt_token,
    email_hash,
    email_domain,
    retention_purpose,
    auto_delete_at,
    demo_duration,
    team_size,
    timeline,
    role,
    request_type,
    spam_score,
    spam_status,
    workflow_type,
    comment
  ) VALUES (
    -- Core required fields
    client_uuid,
    app_uuid,
    COALESCE(payload->>'jwt_token_hash', 'MISSING_JWT_HASH_' || gen_random_uuid()::TEXT),
    'n8n-automation',
    COALESCE(
      (payload->>'token_expiration')::TIMESTAMPTZ,
      NOW() + INTERVAL '14 days'
    ),
    
    -- Optional core fields
    COALESCE(payload->>'invitation_code', api.generate_invitation_code(client_uuid, app_uuid)),
    '[]'::JSONB,
    '{}'::JSONB,
    'requested',
    1,
    jsonb_build_object(
      'name', payload->>'name',
      'company', payload->>'company',
      'message', payload->>'message',
      'source', payload->>'source',
      'priority', payload->>'priority',
      'internal', COALESCE((payload->>'internal')::BOOLEAN, FALSE),
      'request_id', payload->>'formId'
    ),
    
    -- Extended demo fields
    payload->>'jwt_token',
    payload->>'email_hash',
    payload->>'email_domain',
    'demo_invitation',
    NOW() + INTERVAL '90 days',
    payload->>'demo_duration',
    payload->>'team_size',
    payload->>'timeline',
    payload->>'role',
    COALESCE(payload->>'type', 'demo'),
    COALESCE((payload->>'spamScore')::INTEGER, 0),
    COALESCE(payload->>'spamStatus', 'clean'),
    payload->>'use_case',
    payload->>'message'
  )
  RETURNING * INTO new_invitation;

  -- Log success
  RAISE LOG 'Created invitation with ID: %', new_invitation.id;

  RETURN new_invitation;
EXCEPTION
  WHEN OTHERS THEN
    -- Log the error with full details
    RAISE LOG 'Error creating invitation from n8n: % - %', SQLERRM, SQLSTATE;
    RAISE EXCEPTION 'Failed to create invitation: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users (for n8n)
GRANT EXECUTE ON FUNCTION api.create_invitation_from_n8n TO authenticated;

-- Add helpful comments
COMMENT ON FUNCTION api.create_invitation_from_n8n IS 'Creates an invitation record from n8n Code node JSON output. Handles all field mapping and defaults.';

-- Example usage from n8n:
-- In the Supabase node, use "Call a Function" operation with:
-- Function name: create_invitation_from_n8n
-- Parameters: { "payload": {{JSON.stringify($json)}} }