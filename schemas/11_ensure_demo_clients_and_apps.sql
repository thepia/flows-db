-- =====================================================
-- ENSURE DEMO CLIENTS AND THEIR APPLICATIONS
-- =====================================================
-- 
-- Purpose: Create missing demo clients and ensure they all have applications
-- This is a safe script that creates what's missing without affecting existing data

-- Set schema context
SET search_path TO api, public;

-- First, create any missing demo clients
INSERT INTO api.clients (legal_name, client_code, domain, tier, status, region) VALUES
  ('Demo Tech Corp', 'demo-tech', 'demo-tech.com', 'pro', 'active', 'US'),
  ('Test Solutions Ltd', 'test-solutions', 'test-solutions.co.uk', 'enterprise', 'active', 'EU'),
  ('Sample Industries Inc', 'sample-industries', 'sample-inc.com', 'free', 'active', 'US'),
  ('Demo Healthcare Group', 'demo-healthcare', 'demo-health.org', 'enterprise', 'active', 'EU'),
  ('Test Manufacturing Co', 'test-mfg', 'test-manufacturing.com', 'pro', 'active', 'US'),
  ('Nets Demo Company', 'nets-demo', 'nets-demo.com', 'enterprise', 'active', 'EU')
ON CONFLICT (client_code) DO NOTHING;

-- Now add applications for each client (safe pattern - only if client exists)

-- Demo Tech Corp applications
INSERT INTO api.client_applications (client_id, app_code, app_name, app_version, app_description, status, configuration, features, max_concurrent_users, created_at)
SELECT c.id, 'tech-onboarding', 'Tech Team Onboarding', '2.5.0', 'Specialized onboarding for technical roles', 'active', 
  '{"theme": "tech", "locale": "en-US"}'::JSONB, '["technical-assessments", "github-integration"]'::JSONB, 100, NOW()
FROM api.clients c WHERE c.client_code = 'demo-tech'
ON CONFLICT (client_id, app_code) DO UPDATE SET app_name = EXCLUDED.app_name, updated_at = NOW();

INSERT INTO api.client_applications (client_id, app_code, app_name, app_version, app_description, status, configuration, features, max_concurrent_users, created_at)
SELECT c.id, 'tech-offboarding', 'Secure Tech Offboarding', '2.2.0', 'Security-focused offboarding for technical staff', 'active',
  '{"theme": "tech", "locale": "en-US"}'::JSONB, '["access-revocation", "code-review"]'::JSONB, 100, NOW()
FROM api.clients c WHERE c.client_code = 'demo-tech'
ON CONFLICT (client_id, app_code) DO UPDATE SET app_name = EXCLUDED.app_name, updated_at = NOW();

-- Test Solutions Ltd applications
INSERT INTO api.client_applications (client_id, app_code, app_name, app_version, app_description, status, configuration, features, max_concurrent_users, created_at)
SELECT c.id, 'enterprise-onboarding', 'Enterprise Onboarding Suite', '4.0.1', 'Comprehensive enterprise onboarding', 'active',
  '{"theme": "corporate", "locale": "en-GB"}'::JSONB, '["compliance-tracking", "multi-department"]'::JSONB, 1000, NOW()
FROM api.clients c WHERE c.client_code = 'test-solutions'
ON CONFLICT (client_id, app_code) DO UPDATE SET app_name = EXCLUDED.app_name, updated_at = NOW();

INSERT INTO api.client_applications (client_id, app_code, app_name, app_version, app_description, status, configuration, features, max_concurrent_users, created_at)
SELECT c.id, 'enterprise-offboarding', 'Enterprise Exit Management', '3.8.0', 'Enterprise-grade offboarding', 'active',
  '{"theme": "corporate", "locale": "en-GB"}'::JSONB, '["legal-compliance", "audit-reports"]'::JSONB, 1000, NOW()
FROM api.clients c WHERE c.client_code = 'test-solutions'
ON CONFLICT (client_id, app_code) DO UPDATE SET app_name = EXCLUDED.app_name, updated_at = NOW();

-- Sample Industries Inc applications
INSERT INTO api.client_applications (client_id, app_code, app_name, app_version, app_description, status, configuration, features, max_concurrent_users, created_at)
SELECT c.id, 'basic-onboarding', 'Basic Onboarding', '1.0.0', 'Simple onboarding process for small teams', 'active',
  '{"theme": "default", "locale": "en-US"}'::JSONB, '["document-upload", "basic-tasks"]'::JSONB, 25, NOW()
FROM api.clients c WHERE c.client_code = 'sample-industries'
ON CONFLICT (client_id, app_code) DO UPDATE SET app_name = EXCLUDED.app_name, updated_at = NOW();

-- Demo Healthcare Group applications
INSERT INTO api.client_applications (client_id, app_code, app_name, app_version, app_description, status, configuration, features, max_concurrent_users, created_at)
SELECT c.id, 'healthcare-onboarding', 'Healthcare Staff Onboarding', '3.1.0', 'Specialized onboarding for healthcare professionals', 'active',
  '{"theme": "healthcare", "locale": "en-US"}'::JSONB, '["credential-verification", "hipaa-training"]'::JSONB, 500, NOW()
FROM api.clients c WHERE c.client_code = 'demo-healthcare'
ON CONFLICT (client_id, app_code) DO UPDATE SET app_name = EXCLUDED.app_name, updated_at = NOW();

INSERT INTO api.client_applications (client_id, app_code, app_name, app_version, app_description, status, configuration, features, max_concurrent_users, created_at)
SELECT c.id, 'healthcare-offboarding', 'Healthcare Departure Process', '2.9.0', 'Compliant offboarding for healthcare staff', 'active',
  '{"theme": "healthcare", "locale": "en-US"}'::JSONB, '["patient-handover", "compliance-checklist"]'::JSONB, 500, NOW()
FROM api.clients c WHERE c.client_code = 'demo-healthcare'
ON CONFLICT (client_id, app_code) DO UPDATE SET app_name = EXCLUDED.app_name, updated_at = NOW();

-- Test Manufacturing Co applications
INSERT INTO api.client_applications (client_id, app_code, app_name, app_version, app_description, status, configuration, features, max_concurrent_users, created_at)
SELECT c.id, 'factory-onboarding', 'Factory Worker Onboarding', '2.0.0', 'Safety-focused onboarding for manufacturing', 'active',
  '{"theme": "industrial", "locale": "en-US"}'::JSONB, '["safety-training", "equipment-certification"]'::JSONB, 200, NOW()
FROM api.clients c WHERE c.client_code = 'test-mfg'
ON CONFLICT (client_id, app_code) DO UPDATE SET app_name = EXCLUDED.app_name, updated_at = NOW();

INSERT INTO api.client_applications (client_id, app_code, app_name, app_version, app_description, status, configuration, features, max_concurrent_users, created_at)
SELECT c.id, 'factory-offboarding', 'Manufacturing Exit Process', '1.8.0', 'Equipment return and safety compliance', 'active',
  '{"theme": "industrial", "locale": "en-US"}'::JSONB, '["equipment-return", "safety-clearance"]'::JSONB, 200, NOW()
FROM api.clients c WHERE c.client_code = 'test-mfg'
ON CONFLICT (client_id, app_code) DO UPDATE SET app_name = EXCLUDED.app_name, updated_at = NOW();

-- Nets Demo Company applications
INSERT INTO api.client_applications (client_id, app_code, app_name, app_version, app_description, status, configuration, features, max_concurrent_users, created_at)
SELECT c.id, 'standard-onboarding', 'Standard Onboarding', '2.0.0', 'Standard employee onboarding process', 'active',
  '{"theme": "default", "locale": "en-US"}'::JSONB, '["document-management", "task-tracking"]'::JSONB, 100, NOW()
FROM api.clients c WHERE c.client_code = 'nets-demo'
ON CONFLICT (client_id, app_code) DO UPDATE SET app_name = EXCLUDED.app_name, updated_at = NOW();

INSERT INTO api.client_applications (client_id, app_code, app_name, app_version, app_description, status, configuration, features, max_concurrent_users, created_at)
SELECT c.id, 'standard-offboarding', 'Standard Offboarding', '2.0.0', 'Standard employee offboarding process', 'active',
  '{"theme": "default", "locale": "en-US"}'::JSONB, '["checklist-management", "asset-return"]'::JSONB, 100, NOW()
FROM api.clients c WHERE c.client_code = 'nets-demo'
ON CONFLICT (client_id, app_code) DO UPDATE SET app_name = EXCLUDED.app_name, updated_at = NOW();

-- Update last_accessed for all applications
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