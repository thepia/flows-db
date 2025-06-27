-- Add multiple demo clients for settings testing
INSERT INTO api.clients (legal_name, client_code, domain, tier, status, region) VALUES
  ('Demo Tech Corp', 'demo-tech', 'demo-tech.com', 'pro', 'active', 'US'),
  ('Test Solutions Ltd', 'test-solutions', 'test-solutions.co.uk', 'enterprise', 'active', 'EU'),
  ('Sample Industries Inc', 'sample-industries', 'sample-inc.com', 'free', 'active', 'US'),
  ('Demo Healthcare Group', 'demo-healthcare', 'demo-health.org', 'enterprise', 'active', 'EU'),
  ('Test Manufacturing Co', 'test-mfg', 'test-manufacturing.com', 'pro', 'active', 'US')
ON CONFLICT (client_code) DO NOTHING;