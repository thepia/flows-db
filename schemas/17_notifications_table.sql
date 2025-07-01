-- Create notifications table for the flows admin demo
-- This table was referenced in the application but never created

CREATE TABLE IF NOT EXISTS api.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES api.clients(id) ON DELETE CASCADE,
  user_id TEXT,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'info' CHECK (type IN ('info', 'warning', 'error', 'success')),
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE api.notifications ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for client isolation
CREATE POLICY "notifications_client_isolation" ON api.notifications
  FOR ALL 
  USING (client_id = current_setting('app.current_client_id')::UUID);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_notifications_client_id ON api.notifications(client_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON api.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON api.notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON api.notifications(read) WHERE read = FALSE;

-- Add trigger for updated_at
CREATE OR REPLACE FUNCTION api.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_notifications_updated_at 
  BEFORE UPDATE ON api.notifications 
  FOR EACH ROW 
  EXECUTE FUNCTION api.update_updated_at_column();