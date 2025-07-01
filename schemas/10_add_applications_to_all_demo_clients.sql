-- =====================================================
-- ADD APPLICATIONS TO ALL DEMO CLIENTS
-- =====================================================
-- 
-- Purpose: Ensure every demo client has at least one application defined
-- Dependencies: clients table, client_applications table
-- 
-- This ensures that regardless of which client is selected,
-- there will always be application tabs to display

-- Set schema context
SET search_path TO api, public;

-- Check which demo clients exist
DO $$
DECLARE
  demo_tech_id UUID;
  test_solutions_id UUID;
  sample_industries_id UUID;
  demo_healthcare_id UUID;
  test_mfg_id UUID;
  nets_demo_id UUID;
BEGIN
  -- Get client IDs if they exist
  SELECT id INTO demo_tech_id FROM api.clients WHERE client_code = 'demo-tech';
  SELECT id INTO test_solutions_id FROM api.clients WHERE client_code = 'test-solutions';
  SELECT id INTO sample_industries_id FROM api.clients WHERE client_code = 'sample-industries';
  SELECT id INTO demo_healthcare_id FROM api.clients WHERE client_code = 'demo-healthcare';
  SELECT id INTO test_mfg_id FROM api.clients WHERE client_code = 'test-mfg';
  SELECT id INTO nets_demo_id FROM api.clients WHERE client_code = 'nets-demo';

  -- Display which clients exist
  RAISE NOTICE '========================================';
  RAISE NOTICE 'CHECKING DEMO CLIENTS';
  RAISE NOTICE '========================================';
  IF demo_tech_id IS NOT NULL THEN
    RAISE NOTICE '✓ demo-tech exists';
  ELSE
    RAISE NOTICE '✗ demo-tech NOT FOUND';
  END IF;
  
  IF test_solutions_id IS NOT NULL THEN
    RAISE NOTICE '✓ test-solutions exists';
  ELSE
    RAISE NOTICE '✗ test-solutions NOT FOUND';
  END IF;
  
  IF sample_industries_id IS NOT NULL THEN
    RAISE NOTICE '✓ sample-industries exists';
  ELSE
    RAISE NOTICE '✗ sample-industries NOT FOUND';
  END IF;
  
  IF demo_healthcare_id IS NOT NULL THEN
    RAISE NOTICE '✓ demo-healthcare exists';
  ELSE
    RAISE NOTICE '✗ demo-healthcare NOT FOUND';
  END IF;
  
  IF test_mfg_id IS NOT NULL THEN
    RAISE NOTICE '✓ test-mfg exists';
  ELSE
    RAISE NOTICE '✗ test-mfg NOT FOUND';
  END IF;
  
  IF nets_demo_id IS NOT NULL THEN
    RAISE NOTICE '✓ nets-demo exists';
  ELSE
    RAISE NOTICE '✗ nets-demo NOT FOUND';
  END IF;
  RAISE NOTICE '========================================';
END $$;

-- Add applications for Demo Tech Corp (only if client exists)
INSERT INTO api.client_applications (
  client_id,
  app_code,
  app_name,
  app_version,
  app_description,
  status,
  configuration,
  features,
  max_concurrent_users,
  created_at
)
SELECT 
  c.id,
  vals.app_code,
  vals.app_name,
  vals.app_version,
  vals.app_description,
  vals.status,
  vals.configuration,
  vals.features,
  vals.max_concurrent_users,
  vals.created_at
FROM api.clients c
CROSS JOIN (
  VALUES 
    (
      'tech-onboarding',
      'Tech Team Onboarding',
      '2.5.0',
      'Specialized onboarding for technical roles with coding assessments',
      'active',
      '{"theme": "tech", "locale": "en-US", "features": {"code_assessment": true, "github_integration": true}}'::JSONB,
      '["technical-assessments", "github-integration", "equipment-tracking", "security-clearance"]'::JSONB,
      100,
      NOW() - INTERVAL '6 months'
    ),
    (
      'tech-offboarding',
      'Secure Tech Offboarding',
      '2.2.0',
      'Security-focused offboarding for technical staff',
      'active',
      '{"theme": "tech", "locale": "en-US", "security_focused": true}'::JSONB,
      '["access-revocation", "code-review", "knowledge-transfer", "security-audit"]'::JSONB,
      100,
      NOW() - INTERVAL '6 months'
    )
) AS vals(app_code, app_name, app_version, app_description, status, configuration, features, max_concurrent_users, created_at)
WHERE c.client_code = 'demo-tech'
ON CONFLICT (client_id, app_code) DO UPDATE SET
  app_name = EXCLUDED.app_name,
  app_version = EXCLUDED.app_version,
  app_description = EXCLUDED.app_description,
  status = EXCLUDED.status,
  configuration = EXCLUDED.configuration,
  features = EXCLUDED.features,
  updated_at = NOW();

-- Add applications for Test Solutions Ltd (only if client exists)
INSERT INTO api.client_applications (
  client_id,
  app_code,
  app_name,
  app_version,
  app_description,
  status,
  configuration,
  features,
  max_concurrent_users,
  created_at
)
SELECT 
  c.id,
  vals.app_code,
  vals.app_name,
  vals.app_version,
  vals.app_description,
  vals.status,
  vals.configuration,
  vals.features,
  vals.max_concurrent_users,
  vals.created_at
FROM api.clients c
CROSS JOIN (
  VALUES 
    (
      'enterprise-onboarding',
      'Enterprise Onboarding Suite',
      '4.0.1',
      'Comprehensive enterprise onboarding with compliance tracking',
      'active',
      '{"theme": "corporate", "locale": "en-GB", "compliance": {"gdpr": true, "sox": true}}'::JSONB,
      '["compliance-tracking", "multi-department", "role-based-access", "audit-trail"]'::JSONB,
      1000,
      NOW() - INTERVAL '2 years'
    ),
    (
      'enterprise-offboarding',
      'Enterprise Exit Management',
      '3.8.0',
      'Enterprise-grade offboarding with legal compliance',
      'active',
      '{"theme": "corporate", "locale": "en-GB", "legal_compliance": true}'::JSONB,
      '["legal-compliance", "data-retention", "audit-reports", "automated-workflows"]'::JSONB,
      1000,
      NOW() - INTERVAL '2 years'
    )
) AS vals(app_code, app_name, app_version, app_description, status, configuration, features, max_concurrent_users, created_at)
WHERE c.client_code = 'test-solutions'
ON CONFLICT (client_id, app_code) DO UPDATE SET
  app_name = EXCLUDED.app_name,
  app_version = EXCLUDED.app_version,
  app_description = EXCLUDED.app_description,
  status = EXCLUDED.status,
  configuration = EXCLUDED.configuration,
  features = EXCLUDED.features,
  updated_at = NOW();

-- Add applications for Sample Industries Inc (only if client exists)
INSERT INTO api.client_applications (
  client_id,
  app_code,
  app_name,
  app_version,
  app_description,
  status,
  configuration,
  features,
  max_concurrent_users,
  created_at
)
SELECT 
  c.id,
  'basic-onboarding',
  'Basic Onboarding',
  '1.0.0',
  'Simple onboarding process for small teams',
  'active',
  '{"theme": "default", "locale": "en-US"}'::JSONB,
  '["document-upload", "basic-tasks", "email-notifications"]'::JSONB,
  25,
  NOW() - INTERVAL '1 year'
FROM api.clients c
WHERE c.client_code = 'sample-industries'
ON CONFLICT (client_id, app_code) DO UPDATE SET
  app_name = EXCLUDED.app_name,
  app_version = EXCLUDED.app_version,
  app_description = EXCLUDED.app_description,
  status = EXCLUDED.status,
  configuration = EXCLUDED.configuration,
  features = EXCLUDED.features,
  updated_at = NOW();

-- Add applications for Demo Healthcare Group (only if client exists)
INSERT INTO api.client_applications (
  client_id,
  app_code,
  app_name,
  app_version,
  app_description,
  status,
  configuration,
  features,
  max_concurrent_users,
  created_at
)
SELECT 
  c.id,
  vals.app_code,
  vals.app_name,
  vals.app_version,
  vals.app_description,
  vals.status,
  vals.configuration,
  vals.features,
  vals.max_concurrent_users,
  vals.created_at
FROM api.clients c
CROSS JOIN (
  VALUES 
    (
      'healthcare-onboarding',
      'Healthcare Staff Onboarding',
      '3.1.0',
      'Specialized onboarding for healthcare professionals with credential verification',
      'active',
      '{"theme": "healthcare", "locale": "en-US", "features": {"credential_verification": true, "hipaa_compliance": true}}'::JSONB,
      '["credential-verification", "hipaa-training", "department-rotation", "mentor-assignment"]'::JSONB,
      500,
      NOW() - INTERVAL '1 year'
    ),
    (
      'healthcare-offboarding',
      'Healthcare Departure Process',
      '2.9.0',
      'Compliant offboarding for healthcare staff',
      'active',
      '{"theme": "healthcare", "locale": "en-US", "hipaa_compliant": true}'::JSONB,
      '["patient-handover", "credential-removal", "compliance-checklist", "exit-documentation"]'::JSONB,
      500,
      NOW() - INTERVAL '1 year'
    )
) AS vals(app_code, app_name, app_version, app_description, status, configuration, features, max_concurrent_users, created_at)
WHERE c.client_code = 'demo-healthcare'
ON CONFLICT (client_id, app_code) DO UPDATE SET
  app_name = EXCLUDED.app_name,
  app_version = EXCLUDED.app_version,
  app_description = EXCLUDED.app_description,
  status = EXCLUDED.status,
  configuration = EXCLUDED.configuration,
  features = EXCLUDED.features,
  updated_at = NOW();

-- Add applications for Test Manufacturing Co (only if client exists)
INSERT INTO api.client_applications (
  client_id,
  app_code,
  app_name,
  app_version,
  app_description,
  status,
  configuration,
  features,
  max_concurrent_users,
  created_at
)
SELECT 
  c.id,
  vals.app_code,
  vals.app_name,
  vals.app_version,
  vals.app_description,
  vals.status,
  vals.configuration,
  vals.features,
  vals.max_concurrent_users,
  vals.created_at
FROM api.clients c
CROSS JOIN (
  VALUES 
    (
      'factory-onboarding',
      'Factory Worker Onboarding',
      '2.0.0',
      'Safety-focused onboarding for manufacturing facilities',
      'active',
      '{"theme": "industrial", "locale": "en-US", "safety_focused": true}'::JSONB,
      '["safety-training", "equipment-certification", "shift-assignment", "ppe-tracking"]'::JSONB,
      200,
      NOW() - INTERVAL '8 months'
    ),
    (
      'factory-offboarding',
      'Manufacturing Exit Process',
      '1.8.0',
      'Equipment return and safety compliance for departing workers',
      'active',
      '{"theme": "industrial", "locale": "en-US", "equipment_tracking": true}'::JSONB,
      '["equipment-return", "safety-clearance", "tool-inventory", "final-inspection"]'::JSONB,
      200,
      NOW() - INTERVAL '8 months'
    )
) AS vals(app_code, app_name, app_version, app_description, status, configuration, features, max_concurrent_users, created_at)
WHERE c.client_code = 'test-mfg'
ON CONFLICT (client_id, app_code) DO UPDATE SET
  app_name = EXCLUDED.app_name,
  app_version = EXCLUDED.app_version,
  app_description = EXCLUDED.app_description,
  status = EXCLUDED.status,
  configuration = EXCLUDED.configuration,
  features = EXCLUDED.features,
  updated_at = NOW();

-- Add a default Nets Demo client if it doesn't exist, with applications
INSERT INTO api.clients (
  legal_name,
  client_code,
  domain,
  tier,
  status,
  region
) VALUES (
  'Nets Demo Company',
  'nets-demo',
  'nets-demo.com',
  'enterprise',
  'active',
  'EU'
) ON CONFLICT (client_code) DO NOTHING;

-- Add applications for Nets Demo (only if client exists)
INSERT INTO api.client_applications (
  client_id,
  app_code,
  app_name,
  app_version,
  app_description,
  status,
  configuration,
  features,
  max_concurrent_users,
  created_at
)
SELECT 
  c.id,
  vals.app_code,
  vals.app_name,
  vals.app_version,
  vals.app_description,
  vals.status,
  vals.configuration,
  vals.features,
  vals.max_concurrent_users,
  vals.created_at
FROM api.clients c
CROSS JOIN (
  VALUES 
    (
      'standard-onboarding',
      'Standard Onboarding',
      '2.0.0',
      'Standard employee onboarding process',
      'active',
      '{"theme": "default", "locale": "en-US"}'::JSONB,
      '["document-management", "task-tracking", "email-notifications", "reporting"]'::JSONB,
      100,
      NOW() - INTERVAL '1 year'
    ),
    (
      'standard-offboarding',
      'Standard Offboarding',
      '2.0.0',
      'Standard employee offboarding process',
      'active',
      '{"theme": "default", "locale": "en-US"}'::JSONB,
      '["checklist-management", "asset-return", "knowledge-transfer", "exit-interview"]'::JSONB,
      100,
      NOW() - INTERVAL '1 year'
    )
) AS vals(app_code, app_name, app_version, app_description, status, configuration, features, max_concurrent_users, created_at)
WHERE c.client_code = 'nets-demo'
ON CONFLICT (client_id, app_code) DO UPDATE SET
  app_name = EXCLUDED.app_name,
  app_version = EXCLUDED.app_version,
  app_description = EXCLUDED.app_description,
  status = EXCLUDED.status,
  configuration = EXCLUDED.configuration,
  features = EXCLUDED.features,
  updated_at = NOW();

-- Update last_accessed for all applications to simulate usage
UPDATE api.client_applications 
SET 
  last_accessed = NOW() - (FLOOR(RANDOM() * 48 + 1)::INT || ' hours')::INTERVAL,
  updated_at = NOW()
WHERE client_id IN (
  SELECT id FROM api.clients 
  WHERE client_code IN ('demo-tech', 'test-solutions', 'sample-industries', 'demo-healthcare', 'test-mfg', 'nets-demo')
);

-- Display summary
DO $$
DECLARE
  client_rec RECORD;
  app_count INTEGER;
  total_apps INTEGER := 0;
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'DEMO CLIENT APPLICATIONS SUMMARY';
  RAISE NOTICE '========================================';
  
  FOR client_rec IN 
    SELECT id, client_code, legal_name 
    FROM api.clients 
    WHERE client_code IN ('demo-tech', 'test-solutions', 'sample-industries', 'demo-healthcare', 'test-mfg', 'nets-demo', 'hygge-hvidlog', 'meridian-brands')
    ORDER BY client_code
  LOOP
    SELECT COUNT(*) INTO app_count 
    FROM api.client_applications 
    WHERE client_id = client_rec.id;
    
    total_apps := total_apps + app_count;
    
    RAISE NOTICE '% (%): % applications', client_rec.client_code, client_rec.legal_name, app_count;
  END LOOP;
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Total applications across all demo clients: %', total_apps;
  RAISE NOTICE '========================================';
END $$;