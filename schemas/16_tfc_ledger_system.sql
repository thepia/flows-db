-- =====================================================
-- THEPIA FLOW CREDITS (TFC) LEDGER SYSTEM
-- =====================================================
-- 
-- Purpose: Complete TFC financial management with admin access and account contacts
-- Pricing: 150 EUR/CHF base with bulk discounts (25% at 500+, 30% at 2500+)
-- Business Model: Pay-per-process-initiated (not subscription)
-- Features: Full ledger, payment tracking, admin access, account management
-- Dependencies: clients table

-- Set schema context
SET search_path TO api, public;

-- =====================================================
-- ACCOUNT CONTACT MANAGEMENT
-- =====================================================

CREATE TABLE IF NOT EXISTS api.account_contacts (
  -- Primary identifier
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Client relationship
  client_id UUID NOT NULL REFERENCES api.clients(id) ON DELETE CASCADE,
  
  -- Contact information
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL,
  phone VARCHAR(50),
  job_title VARCHAR(150),
  department VARCHAR(100),
  
  -- Contact role and permissions
  contact_type VARCHAR(30) NOT NULL CHECK (contact_type IN ('primary', 'billing', 'technical', 'admin', 'emergency')),
  is_primary_contact BOOLEAN DEFAULT FALSE,
  can_purchase_credits BOOLEAN DEFAULT FALSE,
  can_view_billing BOOLEAN DEFAULT FALSE,
  can_manage_users BOOLEAN DEFAULT FALSE,
  receive_low_balance_alerts BOOLEAN DEFAULT TRUE,
  receive_usage_reports BOOLEAN DEFAULT FALSE,
  
  -- Language and communication preferences
  preferred_language VARCHAR(10) DEFAULT 'en' CHECK (preferred_language IN ('en', 'de', 'fr', 'it')),
  preferred_currency VARCHAR(3) DEFAULT 'EUR' CHECK (preferred_currency IN ('EUR', 'CHF')),
  
  -- Status and lifecycle
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending_verification')),
  email_verified BOOLEAN DEFAULT FALSE,
  last_login TIMESTAMP WITH TIME ZONE,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT unique_primary_contact_per_client UNIQUE (client_id) DEFERRABLE INITIALLY DEFERRED,
  CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Only one primary contact per client
CREATE UNIQUE INDEX IF NOT EXISTS idx_one_primary_contact_per_client 
ON account_contacts (client_id) 
WHERE is_primary_contact = TRUE;

-- =====================================================
-- ADMIN ACCESS MANAGEMENT
-- =====================================================

CREATE TABLE IF NOT EXISTS api.admin_access (
  -- Primary identifier
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Client and contact relationship
  client_id UUID NOT NULL REFERENCES api.clients(id) ON DELETE CASCADE,
  contact_id UUID NOT NULL REFERENCES api.account_contacts(id) ON DELETE CASCADE,
  
  -- Access level and permissions
  access_level VARCHAR(20) NOT NULL CHECK (access_level IN ('owner', 'admin', 'manager', 'viewer', 'billing_only')),
  
  -- Specific permissions
  can_purchase_credits BOOLEAN DEFAULT FALSE,
  can_view_billing BOOLEAN DEFAULT FALSE,
  can_view_usage_analytics BOOLEAN DEFAULT FALSE,
  can_manage_account_settings BOOLEAN DEFAULT FALSE,
  can_manage_users BOOLEAN DEFAULT FALSE,
  can_initiate_workflows BOOLEAN DEFAULT FALSE,
  can_cancel_workflows BOOLEAN DEFAULT FALSE,
  can_download_reports BOOLEAN DEFAULT FALSE,
  can_manage_integrations BOOLEAN DEFAULT FALSE,
  
  -- TFC-specific permissions
  can_set_auto_replenish BOOLEAN DEFAULT FALSE,
  can_modify_credit_thresholds BOOLEAN DEFAULT FALSE,
  can_request_refunds BOOLEAN DEFAULT FALSE,
  can_view_credit_transactions BOOLEAN DEFAULT FALSE,
  
  -- Access control
  ip_restrictions JSONB, -- Array of allowed IP ranges
  session_timeout_minutes INTEGER DEFAULT 480, -- 8 hours default
  require_2fa BOOLEAN DEFAULT FALSE,
  
  -- Status and lifecycle
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'pending_approval', 'revoked')),
  granted_by UUID REFERENCES api.account_contacts(id),
  granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_access TIMESTAMP WITH TIME ZONE,
  access_expires_at TIMESTAMP WITH TIME ZONE,
  
  -- Audit trail
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT unique_contact_access_per_client UNIQUE (client_id, contact_id)
);

-- =====================================================
-- TFC LEDGER - PAYMENT TRACKING
-- =====================================================

CREATE TABLE IF NOT EXISTS api.tfc_payments (
  -- Primary identifier
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Client and payment relationship
  client_id UUID NOT NULL REFERENCES api.clients(id) ON DELETE CASCADE,
  contact_id UUID REFERENCES api.account_contacts(id), -- Who initiated payment
  
  -- Payment details
  payment_amount DECIMAL(12,2) NOT NULL,
  currency VARCHAR(3) NOT NULL DEFAULT 'EUR' CHECK (currency IN ('EUR', 'CHF')),
  payment_method VARCHAR(30) NOT NULL CHECK (payment_method IN ('credit_card', 'bank_transfer', 'invoice', 'purchase_order', 'stripe', 'paypal', 'sepa', 'wire')),
  
  -- Payment gateway information
  payment_gateway VARCHAR(50), -- 'stripe', 'paypal', 'manual', etc.
  gateway_transaction_id VARCHAR(255),
  gateway_payment_intent_id VARCHAR(255),
  gateway_fee_amount DECIMAL(8,2), -- Gateway processing fee
  
  -- Payment status and lifecycle
  payment_status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded', 'disputed')),
  
  -- Timestamps for payment lifecycle
  initiated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  processed_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE,
  failed_at TIMESTAMP WITH TIME ZONE,
  
  -- Failure and error tracking
  failure_reason TEXT,
  gateway_error_code VARCHAR(100),
  gateway_error_message TEXT,
  retry_count INTEGER DEFAULT 0,
  
  -- Invoice and billing
  invoice_number VARCHAR(100),
  invoice_generated_at TIMESTAMP WITH TIME ZONE,
  invoice_sent_at TIMESTAMP WITH TIME ZONE,
  invoice_pdf_url TEXT,
  
  -- Payment reference information
  reference_number VARCHAR(255), -- Customer's PO number or reference
  payment_description TEXT,
  
  -- Audit trail
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT positive_payment_amount CHECK (payment_amount > 0),
  CONSTRAINT valid_completed_payment CHECK (
    (payment_status = 'completed' AND completed_at IS NOT NULL) OR 
    (payment_status != 'completed')
  )
);

-- =====================================================
-- TFC LEDGER - CREDIT TRANSACTIONS (UPDATED)
-- =====================================================

CREATE TABLE IF NOT EXISTS api.tfc_credit_transactions (
  -- Primary identifier
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Client relationship
  client_id UUID NOT NULL REFERENCES api.clients(id) ON DELETE CASCADE,
  
  -- Transaction type and details
  transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('purchase', 'usage', 'refund', 'adjustment', 'bonus', 'expiration')),
  
  -- TFC credit details
  credit_amount INTEGER NOT NULL, -- Positive for purchase/bonus, negative for usage
  price_per_credit DECIMAL(10,2) NOT NULL DEFAULT 150.00, -- Base TFC price: 150 EUR/CHF
  total_amount DECIMAL(12,2) NOT NULL, -- Total transaction amount
  currency VARCHAR(3) NOT NULL DEFAULT 'EUR' CHECK (currency IN ('EUR', 'CHF')),
  
  -- Bulk discount information
  base_price_per_credit DECIMAL(10,2) DEFAULT 150.00, -- Standard price before discounts
  bulk_discount_tier VARCHAR(20) CHECK (bulk_discount_tier IN ('individual', 'bulk_tier_1', 'bulk_tier_2')),
  discount_percentage DECIMAL(5,2) DEFAULT 0.00, -- 25.00 for 25% off
  discount_amount DECIMAL(10,2) DEFAULT 0.00, -- Total discount in currency
  
  -- Payment relationship
  payment_id UUID REFERENCES api.tfc_payments(id),
  
  -- Usage tracking (for 'usage' transactions)
  workflow_type VARCHAR(20) CHECK (workflow_type IN ('onboarding', 'offboarding', 'role_change', 'internal_transfer')),
  workflow_id UUID, -- Reference to specific workflow
  employee_uid VARCHAR(64), -- Anonymous employee UID
  
  -- Process-specific pricing
  emergency_surcharge BOOLEAN DEFAULT FALSE, -- Future: premium pricing for urgent processes
  bulk_process_discount BOOLEAN DEFAULT FALSE, -- Future: discount for bulk operations
  
  -- Transaction metadata
  description TEXT NOT NULL,
  internal_notes TEXT, -- Internal notes for customer service
  
  -- Audit and approval
  created_by VARCHAR(100) NOT NULL, -- System or user who created transaction
  approved_by UUID REFERENCES api.account_contacts(id), -- Who approved (for large transactions)
  approved_at TIMESTAMP WITH TIME ZONE,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT valid_usage_transaction CHECK (
    (transaction_type = 'usage' AND workflow_type IS NOT NULL AND workflow_id IS NOT NULL AND credit_amount < 0) OR
    (transaction_type != 'usage')
  ),
  CONSTRAINT valid_purchase_transaction CHECK (
    (transaction_type = 'purchase' AND payment_id IS NOT NULL AND credit_amount > 0) OR
    (transaction_type != 'purchase')
  ),
  CONSTRAINT valid_bulk_tier_pricing CHECK (
    (bulk_discount_tier = 'individual' AND discount_percentage = 0) OR
    (bulk_discount_tier = 'bulk_tier_1' AND discount_percentage = 25.00 AND price_per_credit = 112.50) OR
    (bulk_discount_tier = 'bulk_tier_2' AND discount_percentage = 30.00 AND price_per_credit = 105.00) OR
    (bulk_discount_tier IS NULL)
  )
);

-- =====================================================
-- TFC LEDGER - CLIENT BALANCES (UPDATED)
-- =====================================================

CREATE TABLE IF NOT EXISTS api.tfc_client_balances (
  -- Primary key is client_id (one record per client)
  client_id UUID PRIMARY KEY REFERENCES api.clients(id) ON DELETE CASCADE,
  
  -- TFC balance tracking
  total_purchased INTEGER NOT NULL DEFAULT 0,
  total_used INTEGER NOT NULL DEFAULT 0,
  total_refunded INTEGER NOT NULL DEFAULT 0,
  total_adjustments INTEGER NOT NULL DEFAULT 0, -- Can be positive or negative
  total_expired INTEGER NOT NULL DEFAULT 0, -- Credits that expired unused
  
  -- Calculated current balance
  current_balance INTEGER GENERATED ALWAYS AS (total_purchased + total_adjustments - total_used - total_refunded - total_expired) STORED,
  
  -- Reserved credits for in-progress workflows
  reserved_credits INTEGER NOT NULL DEFAULT 0,
  
  -- Available credits (current balance - reserved)
  available_credits INTEGER GENERATED ALWAYS AS (total_purchased + total_adjustments - total_used - total_refunded - total_expired - reserved_credits) STORED,
  
  -- Financial totals
  total_spent DECIMAL(12,2) NOT NULL DEFAULT 0.00, -- Total money spent on credits
  total_refunded_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00, -- Total money refunded
  
  -- Average pricing (weighted by purchase amounts)
  average_credit_price DECIMAL(10,2) GENERATED ALWAYS AS (
    CASE WHEN total_purchased > 0 THEN total_spent / total_purchased ELSE 150.00 END
  ) STORED,
  
  -- Alert and automation thresholds
  low_balance_threshold INTEGER DEFAULT 10,
  critical_balance_threshold INTEGER DEFAULT 5,
  auto_replenish_enabled BOOLEAN DEFAULT FALSE,
  auto_replenish_threshold INTEGER DEFAULT 5,
  auto_replenish_amount INTEGER DEFAULT 50,
  auto_replenish_payment_method VARCHAR(30),
  
  -- Preferred settings
  preferred_currency VARCHAR(3) DEFAULT 'EUR' CHECK (preferred_currency IN ('EUR', 'CHF')),
  billing_contact_id UUID REFERENCES api.account_contacts(id),
  
  -- Usage patterns and lifecycle
  first_purchase_date DATE,
  last_purchase_at TIMESTAMP WITH TIME ZONE,
  last_usage_at TIMESTAMP WITH TIME ZONE,
  last_auto_replenish_at TIMESTAMP WITH TIME ZONE,
  most_recent_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Credit expiration policy (future feature)
  credits_expire BOOLEAN DEFAULT FALSE,
  credit_expiration_months INTEGER DEFAULT 24,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT non_negative_balances CHECK (
    total_purchased >= 0 AND 
    total_used >= 0 AND 
    total_refunded >= 0 AND 
    total_expired >= 0 AND
    reserved_credits >= 0
  ),
  CONSTRAINT valid_thresholds CHECK (
    low_balance_threshold >= critical_balance_threshold AND
    critical_balance_threshold >= 0 AND
    auto_replenish_threshold >= 0 AND
    auto_replenish_amount > 0
  )
);

-- =====================================================
-- TFC USAGE TRACKING
-- =====================================================

CREATE TABLE IF NOT EXISTS api.tfc_workflow_usage (
  -- Primary identifier
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Workflow relationship
  client_id UUID NOT NULL REFERENCES api.clients(id) ON DELETE CASCADE,
  workflow_id UUID NOT NULL, -- References workflow in specific workflow table
  workflow_type VARCHAR(20) NOT NULL CHECK (workflow_type IN ('onboarding', 'offboarding', 'role_change', 'internal_transfer')),
  
  -- Employee context (anonymous)
  employee_uid VARCHAR(64) NOT NULL,
  
  -- TFC usage details
  credits_consumed INTEGER NOT NULL DEFAULT 1,
  credit_rate DECIMAL(10,2) NOT NULL DEFAULT 150.00, -- Rate at time of consumption
  total_cost DECIMAL(10,2) NOT NULL,
  currency VARCHAR(3) NOT NULL DEFAULT 'EUR',
  
  -- Pricing context
  pricing_tier VARCHAR(20) DEFAULT 'individual' CHECK (pricing_tier IN ('individual', 'bulk_tier_1', 'bulk_tier_2', 'emergency', 'promotional')),
  bulk_discount_applied DECIMAL(5,2) DEFAULT 0.00, -- Percentage discount applied
  emergency_surcharge BOOLEAN DEFAULT FALSE,
  promotional_discount_code VARCHAR(50),
  
  -- Usage timing
  reserved_at TIMESTAMP WITH TIME ZONE, -- When credit was reserved
  consumed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(), -- When credit was actually consumed
  workflow_initiated_at TIMESTAMP WITH TIME ZONE,
  workflow_completed_at TIMESTAMP WITH TIME ZONE,
  
  -- Credit transaction reference
  credit_transaction_id UUID NOT NULL REFERENCES api.tfc_credit_transactions(id),
  
  -- Workflow outcome tracking
  workflow_status VARCHAR(20), -- Current workflow status
  workflow_completion_success BOOLEAN, -- Whether workflow completed successfully
  refund_eligible BOOLEAN DEFAULT FALSE, -- Whether this usage could be refunded
  refund_processed BOOLEAN DEFAULT FALSE,
  refund_amount DECIMAL(10,2),
  
  -- Business context for analytics
  department_category VARCHAR(50),
  seniority_level VARCHAR(20),
  workflow_complexity VARCHAR(20),
  geographic_region VARCHAR(50),
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT valid_credits_consumed CHECK (credits_consumed > 0),
  CONSTRAINT valid_cost_calculation CHECK (total_cost = credits_consumed * credit_rate),
  CONSTRAINT valid_consumption_timing CHECK (
    reserved_at IS NULL OR consumed_at >= reserved_at
  ),
  CONSTRAINT valid_refund_amount CHECK (
    refund_amount IS NULL OR (refund_amount >= 0 AND refund_amount <= total_cost)
  )
);

-- =====================================================
-- INVOICE MANAGEMENT
-- =====================================================

CREATE TABLE IF NOT EXISTS api.tfc_invoices (
  -- Primary identifier
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Client relationship
  client_id UUID NOT NULL REFERENCES api.clients(id) ON DELETE CASCADE,
  
  -- Invoice details
  invoice_number VARCHAR(100) NOT NULL UNIQUE,
  invoice_date DATE NOT NULL DEFAULT CURRENT_DATE,
  due_date DATE,
  
  -- Amount and currency
  subtotal_amount DECIMAL(12,2) NOT NULL,
  tax_amount DECIMAL(12,2) DEFAULT 0.00,
  total_amount DECIMAL(12,2) NOT NULL,
  currency VARCHAR(3) NOT NULL DEFAULT 'EUR' CHECK (currency IN ('EUR', 'CHF')),
  
  -- Status and payment
  status VARCHAR(20) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'paid', 'overdue', 'cancelled', 'refunded')),
  payment_id UUID REFERENCES api.tfc_payments(id),
  paid_at TIMESTAMP WITH TIME ZONE,
  paid_amount DECIMAL(12,2),
  
  -- Invoice content
  line_items JSONB NOT NULL, -- Array of line items with description, quantity, rate
  notes TEXT,
  terms_and_conditions TEXT,
  
  -- File storage
  pdf_url TEXT,
  pdf_generated_at TIMESTAMP WITH TIME ZONE,
  
  -- Billing contact
  billing_contact_id UUID REFERENCES api.account_contacts(id),
  sent_to_email VARCHAR(255),
  sent_at TIMESTAMP WITH TIME ZONE,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT positive_amounts CHECK (subtotal_amount >= 0 AND tax_amount >= 0 AND total_amount >= 0),
  CONSTRAINT valid_payment_details CHECK (
    (status = 'paid' AND payment_id IS NOT NULL AND paid_at IS NOT NULL) OR 
    (status != 'paid')
  )
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Account contacts indexes
CREATE INDEX IF NOT EXISTS idx_account_contacts_client_id ON account_contacts(client_id);
CREATE INDEX IF NOT EXISTS idx_account_contacts_email ON account_contacts(email);
CREATE INDEX IF NOT EXISTS idx_account_contacts_type ON account_contacts(contact_type);

-- Admin access indexes
CREATE INDEX IF NOT EXISTS idx_admin_access_client_id ON admin_access(client_id);
CREATE INDEX IF NOT EXISTS idx_admin_access_contact_id ON admin_access(contact_id);
CREATE INDEX IF NOT EXISTS idx_admin_access_level ON admin_access(access_level);
CREATE INDEX IF NOT EXISTS idx_admin_access_status ON admin_access(status);

-- Payment indexes
CREATE INDEX IF NOT EXISTS idx_tfc_payments_client_id ON tfc_payments(client_id);
CREATE INDEX IF NOT EXISTS idx_tfc_payments_status ON tfc_payments(payment_status);
CREATE INDEX IF NOT EXISTS idx_tfc_payments_gateway_transaction ON tfc_payments(gateway_transaction_id);
CREATE INDEX IF NOT EXISTS idx_tfc_payments_completed_at ON tfc_payments(completed_at);

-- Credit transaction indexes
CREATE INDEX IF NOT EXISTS idx_tfc_credit_transactions_client_id ON tfc_credit_transactions(client_id);
CREATE INDEX IF NOT EXISTS idx_tfc_credit_transactions_type ON tfc_credit_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_tfc_credit_transactions_payment_id ON tfc_credit_transactions(payment_id);
CREATE INDEX IF NOT EXISTS idx_tfc_credit_transactions_workflow_id ON tfc_credit_transactions(workflow_id);
CREATE INDEX IF NOT EXISTS idx_tfc_credit_transactions_created_at ON tfc_credit_transactions(created_at);

-- Usage tracking indexes
CREATE INDEX IF NOT EXISTS idx_tfc_workflow_usage_client_id ON tfc_workflow_usage(client_id);
CREATE INDEX IF NOT EXISTS idx_tfc_workflow_usage_workflow_id ON tfc_workflow_usage(workflow_id);
CREATE INDEX IF NOT EXISTS idx_tfc_workflow_usage_type ON tfc_workflow_usage(workflow_type);
CREATE INDEX IF NOT EXISTS idx_tfc_workflow_usage_consumed_at ON tfc_workflow_usage(consumed_at);

-- Invoice indexes
CREATE INDEX IF NOT EXISTS idx_tfc_invoices_client_id ON tfc_invoices(client_id);
CREATE INDEX IF NOT EXISTS idx_tfc_invoices_number ON tfc_invoices(invoice_number);
CREATE INDEX IF NOT EXISTS idx_tfc_invoices_status ON tfc_invoices(status);
CREATE INDEX IF NOT EXISTS idx_tfc_invoices_date ON tfc_invoices(invoice_date);

-- Composite indexes for analytics
CREATE INDEX IF NOT EXISTS idx_tfc_transactions_client_type_date ON tfc_credit_transactions(client_id, transaction_type, created_at);
CREATE INDEX IF NOT EXISTS idx_tfc_usage_client_type_date ON tfc_workflow_usage(client_id, workflow_type, consumed_at);

-- Balance monitoring indexes
CREATE INDEX IF NOT EXISTS idx_tfc_balances_low_balance ON tfc_client_balances(available_credits) WHERE available_credits <= 10;
CREATE INDEX IF NOT EXISTS idx_tfc_balances_auto_replenish ON tfc_client_balances(client_id) WHERE auto_replenish_enabled = TRUE;

-- =====================================================
-- TRIGGERS FOR AUTOMATION
-- =====================================================

-- Update timestamp triggers
CREATE OR REPLACE FUNCTION update_tfc_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update triggers to all tables
DROP TRIGGER IF EXISTS trigger_account_contacts_updated_at ON account_contacts;
CREATE TRIGGER trigger_account_contacts_updated_at
  BEFORE UPDATE ON account_contacts
  FOR EACH ROW
  EXECUTE FUNCTION update_tfc_updated_at();

DROP TRIGGER IF EXISTS trigger_admin_access_updated_at ON admin_access;
CREATE TRIGGER trigger_admin_access_updated_at
  BEFORE UPDATE ON admin_access
  FOR EACH ROW
  EXECUTE FUNCTION update_tfc_updated_at();

DROP TRIGGER IF EXISTS trigger_tfc_payments_updated_at ON tfc_payments;
CREATE TRIGGER trigger_tfc_payments_updated_at
  BEFORE UPDATE ON tfc_payments
  FOR EACH ROW
  EXECUTE FUNCTION update_tfc_updated_at();

DROP TRIGGER IF EXISTS trigger_tfc_credit_transactions_updated_at ON tfc_credit_transactions;
CREATE TRIGGER trigger_tfc_credit_transactions_updated_at
  BEFORE UPDATE ON tfc_credit_transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_tfc_updated_at();

DROP TRIGGER IF EXISTS trigger_tfc_client_balances_updated_at ON tfc_client_balances;
CREATE TRIGGER trigger_tfc_client_balances_updated_at
  BEFORE UPDATE ON tfc_client_balances
  FOR EACH ROW
  EXECUTE FUNCTION update_tfc_updated_at();

DROP TRIGGER IF EXISTS trigger_tfc_workflow_usage_updated_at ON tfc_workflow_usage;
CREATE TRIGGER trigger_tfc_workflow_usage_updated_at
  BEFORE UPDATE ON tfc_workflow_usage
  FOR EACH ROW
  EXECUTE FUNCTION update_tfc_updated_at();

DROP TRIGGER IF EXISTS trigger_tfc_invoices_updated_at ON tfc_invoices;
CREATE TRIGGER trigger_tfc_invoices_updated_at
  BEFORE UPDATE ON tfc_invoices
  FOR EACH ROW
  EXECUTE FUNCTION update_tfc_updated_at();

-- Auto-update credit balances when transactions are created
CREATE OR REPLACE FUNCTION update_tfc_balance_on_transaction()
RETURNS TRIGGER AS $$
DECLARE
  balance_exists BOOLEAN;
BEGIN
  -- Check if balance record exists for this client
  SELECT EXISTS(SELECT 1 FROM tfc_client_balances WHERE client_id = NEW.client_id) INTO balance_exists;
  
  -- Create balance record if it doesn't exist
  IF NOT balance_exists THEN
    INSERT INTO tfc_client_balances (client_id, created_at)
    VALUES (NEW.client_id, NOW())
    ON CONFLICT (client_id) DO NOTHING;
  END IF;
  
  -- Update balance based on transaction type
  IF NEW.transaction_type = 'purchase' THEN
    UPDATE tfc_client_balances
    SET 
      total_purchased = total_purchased + NEW.credit_amount,
      total_spent = total_spent + NEW.total_amount,
      last_purchase_at = NOW(),
      most_recent_activity = NOW(),
      first_purchase_date = COALESCE(first_purchase_date, CURRENT_DATE)
    WHERE client_id = NEW.client_id;
    
  ELSIF NEW.transaction_type = 'usage' THEN
    UPDATE tfc_client_balances
    SET 
      total_used = total_used + ABS(NEW.credit_amount),
      last_usage_at = NOW(),
      most_recent_activity = NOW()
    WHERE client_id = NEW.client_id;
    
  ELSIF NEW.transaction_type = 'refund' THEN
    UPDATE tfc_client_balances
    SET 
      total_refunded = total_refunded + NEW.credit_amount,
      total_refunded_amount = total_refunded_amount + NEW.total_amount,
      most_recent_activity = NOW()
    WHERE client_id = NEW.client_id;
    
  ELSIF NEW.transaction_type = 'adjustment' THEN
    UPDATE tfc_client_balances
    SET 
      total_adjustments = total_adjustments + NEW.credit_amount,
      most_recent_activity = NOW()
    WHERE client_id = NEW.client_id;
    
  ELSIF NEW.transaction_type = 'bonus' THEN
    UPDATE tfc_client_balances
    SET 
      total_purchased = total_purchased + NEW.credit_amount, -- Treat bonus as free purchase
      most_recent_activity = NOW()
    WHERE client_id = NEW.client_id;
    
  ELSIF NEW.transaction_type = 'expiration' THEN
    UPDATE tfc_client_balances
    SET 
      total_expired = total_expired + ABS(NEW.credit_amount),
      most_recent_activity = NOW()
    WHERE client_id = NEW.client_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_tfc_balance_on_transaction ON tfc_credit_transactions;
CREATE TRIGGER trigger_update_tfc_balance_on_transaction
  AFTER INSERT ON tfc_credit_transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_tfc_balance_on_transaction();

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS on all TFC tables
ALTER TABLE account_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_access ENABLE ROW LEVEL SECURITY;
ALTER TABLE tfc_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE tfc_credit_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE tfc_client_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE tfc_workflow_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE tfc_invoices ENABLE ROW LEVEL SECURITY;

-- Thepia staff access policies (full access)
DROP POLICY IF EXISTS policy_account_contacts_staff_access ON account_contacts;
CREATE POLICY policy_account_contacts_staff_access ON account_contacts
  FOR ALL 
  USING (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

DROP POLICY IF EXISTS policy_admin_access_staff_access ON admin_access;
CREATE POLICY policy_admin_access_staff_access ON admin_access
  FOR ALL 
  USING (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

DROP POLICY IF EXISTS policy_tfc_payments_staff_access ON tfc_payments;
CREATE POLICY policy_tfc_payments_staff_access ON tfc_payments
  FOR ALL 
  USING (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

DROP POLICY IF EXISTS policy_tfc_credit_transactions_staff_access ON tfc_credit_transactions;
CREATE POLICY policy_tfc_credit_transactions_staff_access ON tfc_credit_transactions
  FOR ALL 
  USING (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

DROP POLICY IF EXISTS policy_tfc_client_balances_staff_access ON tfc_client_balances;
CREATE POLICY policy_tfc_client_balances_staff_access ON tfc_client_balances
  FOR ALL 
  USING (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

DROP POLICY IF EXISTS policy_tfc_workflow_usage_staff_access ON tfc_workflow_usage;
CREATE POLICY policy_tfc_workflow_usage_staff_access ON tfc_workflow_usage
  FOR ALL 
  USING (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

DROP POLICY IF EXISTS policy_tfc_invoices_staff_access ON tfc_invoices;
CREATE POLICY policy_tfc_invoices_staff_access ON tfc_invoices
  FOR ALL 
  USING (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

-- Client-specific access policies (restricted by client_id)
DROP POLICY IF EXISTS policy_account_contacts_client_access ON account_contacts;
CREATE POLICY policy_account_contacts_client_access ON account_contacts
  FOR ALL
  USING (
    client_id::text = auth.jwt()->>'client_id'
    OR EXISTS (
      SELECT 1 FROM api.clients 
      WHERE clients.id = account_contacts.client_id 
        AND clients.client_code = auth.jwt()->>'client_code'
    )
  );

DROP POLICY IF EXISTS policy_admin_access_client_access ON admin_access;
CREATE POLICY policy_admin_access_client_access ON admin_access
  FOR ALL
  USING (
    client_id::text = auth.jwt()->>'client_id'
    OR EXISTS (
      SELECT 1 FROM api.clients 
      WHERE clients.id = admin_access.client_id 
        AND clients.client_code = auth.jwt()->>'client_code'
    )
  );

DROP POLICY IF EXISTS policy_tfc_payments_client_access ON tfc_payments;
CREATE POLICY policy_tfc_payments_client_access ON tfc_payments
  FOR ALL
  USING (
    client_id::text = auth.jwt()->>'client_id'
    OR EXISTS (
      SELECT 1 FROM api.clients 
      WHERE clients.id = tfc_payments.client_id 
        AND clients.client_code = auth.jwt()->>'client_code'
    )
  );

DROP POLICY IF EXISTS policy_tfc_credit_transactions_client_access ON tfc_credit_transactions;
CREATE POLICY policy_tfc_credit_transactions_client_access ON tfc_credit_transactions
  FOR ALL
  USING (
    client_id::text = auth.jwt()->>'client_id'
    OR EXISTS (
      SELECT 1 FROM api.clients 
      WHERE clients.id = tfc_credit_transactions.client_id 
        AND clients.client_code = auth.jwt()->>'client_code'
    )
  );

DROP POLICY IF EXISTS policy_tfc_client_balances_client_access ON tfc_client_balances;
CREATE POLICY policy_tfc_client_balances_client_access ON tfc_client_balances
  FOR ALL
  USING (
    client_id::text = auth.jwt()->>'client_id'
    OR EXISTS (
      SELECT 1 FROM api.clients 
      WHERE clients.id = tfc_client_balances.client_id 
        AND clients.client_code = auth.jwt()->>'client_code'
    )
  );

DROP POLICY IF EXISTS policy_tfc_workflow_usage_client_access ON tfc_workflow_usage;
CREATE POLICY policy_tfc_workflow_usage_client_access ON tfc_workflow_usage
  FOR ALL
  USING (
    client_id::text = auth.jwt()->>'client_id'
    OR EXISTS (
      SELECT 1 FROM api.clients 
      WHERE clients.id = tfc_workflow_usage.client_id 
        AND clients.client_code = auth.jwt()->>'client_code'
    )
  );

DROP POLICY IF EXISTS policy_tfc_invoices_client_access ON tfc_invoices;
CREATE POLICY policy_tfc_invoices_client_access ON tfc_invoices
  FOR ALL
  USING (
    client_id::text = auth.jwt()->>'client_id'
    OR EXISTS (
      SELECT 1 FROM api.clients 
      WHERE clients.id = tfc_invoices.client_id 
        AND clients.client_code = auth.jwt()->>'client_code'
    )
  );

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to purchase TFC credits with bulk discounts
CREATE OR REPLACE FUNCTION purchase_tfc_credits(
  p_client_id UUID,
  p_credit_amount INTEGER,
  p_payment_method VARCHAR(30),
  p_currency VARCHAR(3) DEFAULT 'EUR',
  p_payment_reference VARCHAR(255) DEFAULT NULL,
  p_contact_id UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  base_price DECIMAL(10,2) := 150.00;
  bulk_tier VARCHAR(20) := 'individual';
  discount_percentage DECIMAL(5,2) := 0.00;
  final_price DECIMAL(10,2);
  discount_amount DECIMAL(10,2);
  total_amount DECIMAL(12,2);
  payment_id UUID;
  transaction_id UUID;
  result JSONB;
BEGIN
  -- Validate currency
  IF p_currency NOT IN ('EUR', 'CHF') THEN
    RETURN jsonb_build_object('error', 'Invalid currency. Must be EUR or CHF.');
  END IF;
  
  -- Determine bulk discount tier
  IF p_credit_amount >= 2500 THEN
    bulk_tier := 'bulk_tier_2';
    discount_percentage := 30.00; -- 30% off
    final_price := 105.00;
  ELSIF p_credit_amount >= 500 THEN
    bulk_tier := 'bulk_tier_1';
    discount_percentage := 25.00; -- 25% off
    final_price := 112.50;
  ELSE
    bulk_tier := 'individual';
    discount_percentage := 0.00;
    final_price := base_price;
  END IF;
  
  discount_amount := (base_price - final_price) * p_credit_amount;
  total_amount := final_price * p_credit_amount;
  
  -- Create payment record
  INSERT INTO tfc_payments (
    client_id,
    contact_id,
    payment_amount,
    currency,
    payment_method,
    payment_status,
    reference_number,
    payment_description
  ) VALUES (
    p_client_id,
    p_contact_id,
    total_amount,
    p_currency,
    p_payment_method,
    'pending',
    p_payment_reference,
    'TFC Credit Purchase: ' || p_credit_amount || ' credits'
  ) RETURNING id INTO payment_id;
  
  -- Create credit transaction
  INSERT INTO tfc_credit_transactions (
    client_id,
    transaction_type,
    credit_amount,
    price_per_credit,
    total_amount,
    currency,
    base_price_per_credit,
    bulk_discount_tier,
    discount_percentage,
    discount_amount,
    payment_id,
    description,
    created_by
  ) VALUES (
    p_client_id,
    'purchase',
    p_credit_amount,
    final_price,
    total_amount,
    p_currency,
    base_price,
    bulk_tier,
    discount_percentage,
    discount_amount,
    payment_id,
    'TFC Credit Purchase: ' || p_credit_amount || ' credits with ' || 
    CASE WHEN discount_percentage > 0 THEN discount_percentage::text || '% bulk discount' ELSE 'standard pricing' END,
    'purchase_system'
  ) RETURNING id INTO transaction_id;
  
  -- Build result
  result := jsonb_build_object(
    'success', true,
    'payment_id', payment_id,
    'transaction_id', transaction_id,
    'purchase_details', jsonb_build_object(
      'credits_purchased', p_credit_amount,
      'bulk_tier', bulk_tier,
      'base_price_per_credit', base_price,
      'final_price_per_credit', final_price,
      'discount_percentage', discount_percentage,
      'total_discount', discount_amount,
      'total_amount', total_amount,
      'currency', p_currency
    )
  );
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check TFC balance and alerts
CREATE OR REPLACE FUNCTION check_tfc_balance_alerts(p_client_id UUID)
RETURNS JSONB AS $$
DECLARE
  balance_info RECORD;
  alerts JSONB := '[]'::JSONB;
BEGIN
  SELECT * INTO balance_info
  FROM tfc_client_balances
  WHERE client_id = p_client_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Client not found');
  END IF;
  
  -- Check for critical balance
  IF balance_info.available_credits <= balance_info.critical_balance_threshold THEN
    alerts := alerts || jsonb_build_array(
      jsonb_build_object(
        'type', 'critical_balance',
        'severity', 'high',
        'message', 'Critical: Only ' || balance_info.available_credits || ' TFC remaining',
        'available_credits', balance_info.available_credits,
        'threshold', balance_info.critical_balance_threshold,
        'recommended_action', 'Purchase credits immediately to continue workflows'
      )
    );
  ELSIF balance_info.available_credits <= balance_info.low_balance_threshold THEN
    alerts := alerts || jsonb_build_array(
      jsonb_build_object(
        'type', 'low_balance',
        'severity', 'medium',
        'message', 'Low balance: ' || balance_info.available_credits || ' TFC remaining',
        'available_credits', balance_info.available_credits,
        'threshold', balance_info.low_balance_threshold,
        'recommended_action', 'Consider purchasing more credits'
      )
    );
  END IF;
  
  -- Check for auto-replenish trigger
  IF balance_info.auto_replenish_enabled AND 
     balance_info.available_credits <= balance_info.auto_replenish_threshold THEN
    alerts := alerts || jsonb_build_array(
      jsonb_build_object(
        'type', 'auto_replenish_trigger',
        'severity', 'info',
        'message', 'Auto-replenish triggered for ' || balance_info.auto_replenish_amount || ' TFC',
        'replenish_amount', balance_info.auto_replenish_amount,
        'payment_method', balance_info.auto_replenish_payment_method
      )
    );
  END IF;
  
  RETURN jsonb_build_object(
    'client_id', p_client_id,
    'balance_summary', jsonb_build_object(
      'available_credits', balance_info.available_credits,
      'current_balance', balance_info.current_balance,
      'reserved_credits', balance_info.reserved_credits,
      'total_purchased', balance_info.total_purchased,
      'total_used', balance_info.total_used,
      'average_credit_price', balance_info.average_credit_price,
      'preferred_currency', balance_info.preferred_currency
    ),
    'alerts', alerts,
    'balance_status', CASE 
      WHEN balance_info.available_credits <= balance_info.critical_balance_threshold THEN 'critical'
      WHEN balance_info.available_credits <= balance_info.low_balance_threshold THEN 'low'
      ELSE 'healthy'
    END
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get TFC usage analytics
CREATE OR REPLACE FUNCTION get_tfc_usage_analytics(
  p_client_id UUID,
  p_start_date DATE DEFAULT NULL,
  p_end_date DATE DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  start_date DATE := COALESCE(p_start_date, CURRENT_DATE - INTERVAL '30 days');
  end_date DATE := COALESCE(p_end_date, CURRENT_DATE);
  analytics JSONB;
BEGIN
  WITH usage_stats AS (
    SELECT 
      workflow_type,
      COUNT(*) as workflow_count,
      SUM(credits_consumed) as total_credits,
      SUM(total_cost) as total_cost,
      AVG(credit_rate) as avg_rate,
      COUNT(*) FILTER (WHERE emergency_surcharge = TRUE) as emergency_count,
      COUNT(*) FILTER (WHERE bulk_discount_applied > 0) as bulk_discount_count,
      COUNT(*) FILTER (WHERE pricing_tier = 'bulk_tier_1') as tier1_count,
      COUNT(*) FILTER (WHERE pricing_tier = 'bulk_tier_2') as tier2_count
    FROM tfc_workflow_usage
    WHERE client_id = p_client_id
      AND consumed_at::date BETWEEN start_date AND end_date
    GROUP BY workflow_type
  ),
  monthly_trends AS (
    SELECT 
      DATE_TRUNC('month', consumed_at) as month,
      COUNT(*) as workflows,
      SUM(credits_consumed) as credits,
      SUM(total_cost) as cost,
      AVG(credit_rate) as avg_rate
    FROM tfc_workflow_usage
    WHERE client_id = p_client_id
      AND consumed_at::date BETWEEN start_date AND end_date
    GROUP BY DATE_TRUNC('month', consumed_at)
    ORDER BY month
  ),
  department_breakdown AS (
    SELECT 
      department_category,
      COUNT(*) as workflows,
      SUM(credits_consumed) as credits,
      SUM(total_cost) as cost
    FROM tfc_workflow_usage
    WHERE client_id = p_client_id
      AND consumed_at::date BETWEEN start_date AND end_date
      AND department_category IS NOT NULL
    GROUP BY department_category
    ORDER BY cost DESC
  )
  SELECT jsonb_build_object(
    'period', jsonb_build_object(
      'start_date', start_date,
      'end_date', end_date,
      'days', end_date - start_date + 1
    ),
    'summary', jsonb_build_object(
      'total_workflows', COALESCE(SUM(workflow_count), 0),
      'total_credits_consumed', COALESCE(SUM(total_credits), 0),
      'total_cost', COALESCE(SUM(total_cost), 0),
      'average_cost_per_workflow', COALESCE(SUM(total_cost) / NULLIF(SUM(workflow_count), 0), 0),
      'average_credit_rate', COALESCE(AVG(avg_rate), 150.00)
    ),
    'by_workflow_type', jsonb_agg(to_jsonb(usage_stats.*)) FILTER (WHERE usage_stats.workflow_type IS NOT NULL),
    'monthly_trends', (
      SELECT jsonb_agg(to_jsonb(monthly_trends.*))
      FROM monthly_trends
    ),
    'department_breakdown', (
      SELECT jsonb_agg(to_jsonb(department_breakdown.*))
      FROM department_breakdown
    ),
    'bulk_discount_savings', jsonb_build_object(
      'tier1_workflows', COALESCE(SUM(tier1_count), 0),
      'tier2_workflows', COALESCE(SUM(tier2_count), 0),
      'estimated_savings', COALESCE(
        SUM(tier1_count) * (150.00 - 112.50) + SUM(tier2_count) * (150.00 - 105.00), 
        0
      )
    )
  ) INTO analytics
  FROM usage_stats;
  
  RETURN COALESCE(analytics, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON TABLE account_contacts IS 'Account contact persons with roles, permissions, and communication preferences';
COMMENT ON TABLE admin_access IS 'Admin access levels and permissions for client account management';
COMMENT ON TABLE tfc_payments IS 'Payment tracking for TFC credit purchases with gateway integration';
COMMENT ON TABLE tfc_credit_transactions IS 'Complete TFC transaction ledger with 150 EUR/CHF base pricing and bulk discounts';
COMMENT ON TABLE tfc_client_balances IS 'Real-time TFC balance tracking with automatic calculations and alert thresholds';
COMMENT ON TABLE tfc_workflow_usage IS 'Detailed TFC usage tracking for each workflow with pricing context and analytics';
COMMENT ON TABLE tfc_invoices IS 'Invoice management for TFC purchases and billing';

COMMENT ON COLUMN tfc_credit_transactions.price_per_credit IS 'Actual price paid per TFC: 150 EUR/CHF base, 112.50 (25% off), 105 (30% off)';
COMMENT ON COLUMN tfc_credit_transactions.bulk_discount_tier IS 'individual (0%), bulk_tier_1 (25% off 500+), bulk_tier_2 (30% off 2500+)';
COMMENT ON COLUMN tfc_client_balances.available_credits IS 'Computed: current_balance - reserved_credits';
COMMENT ON COLUMN tfc_workflow_usage.credit_rate IS 'TFC rate charged for this specific workflow at time of consumption';
COMMENT ON COLUMN account_contacts.contact_type IS 'primary, billing, technical, admin, emergency contact roles';
COMMENT ON COLUMN admin_access.access_level IS 'owner, admin, manager, viewer, billing_only access levels';