-- =====================================================
-- DETAILED DEMO COMPANIES
-- =====================================================
-- 
-- Purpose: Add the two comprehensive demo companies designed for prospect demonstrations
-- Dependencies: clients table (existing)
-- 
-- Companies:
-- 1. Hygge & Hvidløg A/S (Danish sustainable food tech)
-- 2. Meridian Brands International (Singapore consumer products)

-- Set schema context
SET search_path TO api, public;

-- Insert the detailed demo companies
INSERT INTO api.clients (
  legal_name, 
  client_code, 
  domain, 
  tier, 
  status, 
  region,
  created_at,
  updated_at
) VALUES
  -- Hygge & Hvidløg A/S - Danish Sustainable Food Technology
  (
    'Hygge & Hvidløg A/S',
    'hygge-hvidlog',
    'hygge-hvidlog.dk',
    'enterprise',
    'active',
    'EU',
    NOW() - INTERVAL '2 years',
    NOW()
  ),
  
  -- Meridian Brands International - Singapore Consumer Products
  (
    'Meridian Brands International',
    'meridian-brands',
    'meridianbrands.com.sg',
    'enterprise', 
    'active',
    'APAC',
    NOW() - INTERVAL '5 years',
    NOW()
  )
ON CONFLICT (client_code) DO UPDATE SET
  legal_name = EXCLUDED.legal_name,
  domain = EXCLUDED.domain,
  tier = EXCLUDED.tier,
  status = EXCLUDED.status,
  region = EXCLUDED.region,
  updated_at = NOW();

-- Add sample applications for each demo company
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
) VALUES
  -- Hygge & Hvidløg A/S Applications
  (
    (SELECT id FROM api.clients WHERE client_code = 'hygge-hvidlog'),
    'employee-onboarding',
    'Employee Onboarding',
    '2.1.0',
    'Comprehensive onboarding for sustainable food technology company with multilingual support',
    'active',
    '{"theme": "hygge", "locale": "da-DK", "branding": {"primary_color": "#2F5233", "secondary_color": "#8FBC8F", "accent_color": "#DAA520"}, "features": {"multilingual": true, "sustainability_training": true, "remote_onboarding": true}}'::JSONB,
    '["document-capture", "task-management", "video-onboarding", "multilingual-support", "sustainability-training", "remote-work-setup"]'::JSONB,
    200,
    NOW() - INTERVAL '18 months'
  ),
  (
    (SELECT id FROM api.clients WHERE client_code = 'hygge-hvidlog'),
    'knowledge-offboarding', 
    'Knowledge Transfer & Offboarding',
    '1.8.0',
    'Knowledge preservation and sustainable transition processes',
    'active',
    '{"theme": "hygge", "locale": "da-DK", "knowledge_retention": true, "sustainability_focus": true}'::JSONB,
    '["knowledge-transfer", "documentation", "mentorship-matching", "sustainable-transition"]'::JSONB,
    150,
    NOW() - INTERVAL '1 year'
  ),
  
  -- Meridian Brands International Applications  
  (
    (SELECT id FROM api.clients WHERE client_code = 'meridian-brands'),
    'rapid-onboarding',
    'Rapid Market Onboarding',
    '3.2.1', 
    'Fast-paced onboarding for high-velocity consumer products environment',
    'active',
    '{"theme": "corporate", "locale": "en-SG", "branding": {"primary_color": "#1E3A8A", "secondary_color": "#3B82F6", "accent_color": "#F59E0B"}, "features": {"rapid_deployment": true, "multi_region": true, "mobile_first": true}}'::JSONB,
    '["mobile-onboarding", "rapid-deployment", "multi-region", "digital-signatures", "automated-workflows", "performance-tracking"]'::JSONB,
    500,
    NOW() - INTERVAL '2 years'
  ),
  (
    (SELECT id FROM api.clients WHERE client_code = 'meridian-brands'),
    'transition-management',
    'Global Transition Management', 
    '2.7.0',
    'High-volume offboarding and transition management for fast-paced environment',
    'active',
    '{"theme": "corporate", "locale": "en-SG", "high_volume": true, "automated_workflows": true}'::JSONB,
    '["bulk-operations", "automated-handover", "knowledge-capture", "exit-analytics", "compliance-tracking"]'::JSONB,
    300,
    NOW() - INTERVAL '1.5 years'
  )
ON CONFLICT (client_id, app_code) DO UPDATE SET
  app_name = EXCLUDED.app_name,
  app_version = EXCLUDED.app_version,
  app_description = EXCLUDED.app_description,
  status = EXCLUDED.status,
  configuration = EXCLUDED.configuration,
  features = EXCLUDED.features,
  max_concurrent_users = EXCLUDED.max_concurrent_users,
  updated_at = NOW();

-- Update last_accessed for applications to simulate usage
UPDATE api.client_applications 
SET 
  last_accessed = NOW() - INTERVAL '2 hours',
  updated_at = NOW()
WHERE client_id IN (
  SELECT id FROM api.clients 
  WHERE client_code IN ('hygge-hvidlog', 'meridian-brands')
);

-- Add comments for documentation
COMMENT ON TABLE api.clients IS 'Client organizations with demo companies for prospect demonstrations';

-- Display summary
DO $$
DECLARE
  hygge_id UUID;
  meridian_id UUID;
  hygge_apps INTEGER;
  meridian_apps INTEGER;
BEGIN
  -- Get client IDs
  SELECT id INTO hygge_id FROM api.clients WHERE client_code = 'hygge-hvidlog';
  SELECT id INTO meridian_id FROM api.clients WHERE client_code = 'meridian-brands';
  
  -- Count applications
  SELECT COUNT(*) INTO hygge_apps FROM api.client_applications WHERE client_id = hygge_id;
  SELECT COUNT(*) INTO meridian_apps FROM api.client_applications WHERE client_id = meridian_id;
  
  -- Display summary
  RAISE NOTICE '====================================';
  RAISE NOTICE 'DETAILED DEMO COMPANIES CREATED';
  RAISE NOTICE '====================================';
  RAISE NOTICE 'Hygge & Hvidløg A/S: % (% applications)', hygge_id, hygge_apps;
  RAISE NOTICE 'Meridian Brands International: % (% applications)', meridian_id, meridian_apps;
  RAISE NOTICE '====================================';
END $$;