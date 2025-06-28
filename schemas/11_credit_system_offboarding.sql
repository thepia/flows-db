-- =====================================================
-- CREDIT SYSTEM FOR OFFBOARDING WORKFLOWS
-- =====================================================
-- 
-- Purpose: 175 EUR consumable credit system for offboarding workflow initiation
-- Context: Shadow Organization external monitoring model
-- Business Model: Credit consumed when workflow becomes active, not on completion
-- Dependencies: clients, offboarding_workflows tables

-- Set schema context
SET search_path TO api, public;

-- =====================================================
-- CREDIT TRANSACTIONS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS api.credit_transactions (
  -- Primary identifier
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Client relationship
  client_id UUID NOT NULL REFERENCES api.clients(id) ON DELETE CASCADE,
  
  -- Transaction details
  transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('purchase', 'usage', 'refund', 'adjustment', 'bonus')),
  
  -- Credit and pricing information
  credit_amount INTEGER NOT NULL, -- Number of credits (positive for purchase/bonus, negative for usage)
  price_per_credit DECIMAL(10,2) NOT NULL DEFAULT 175.00, -- EUR per credit
  total_amount DECIMAL(12,2) NOT NULL, -- Total transaction amount in EUR
  currency VARCHAR(3) NOT NULL DEFAULT 'EUR',
  
  -- Usage tracking (for 'usage' transactions)
  workflow_type VARCHAR(20) CHECK (workflow_type IN ('onboarding', 'offboarding', 'role_change', 'internal_transfer')),
  workflow_id UUID, -- Reference to specific workflow (offboarding_workflows.id)
  employee_uid VARCHAR(64), -- Anonymous employee UID for audit trail
  
  -- Purchase tracking (for 'purchase' transactions)
  payment_method VARCHAR(30) CHECK (payment_method IN ('credit_card', 'bank_transfer', 'invoice', 'purchase_order', 'stripe', 'paypal')),
  payment_reference VARCHAR(255), -- Payment gateway transaction ID
  invoice_number VARCHAR(100),
  
  -- Bulk pricing and discounts
  base_price_per_credit DECIMAL(10,2) DEFAULT 175.00, -- Standard price before discounts
  discount_percentage DECIMAL(5,2) DEFAULT 0.00, -- Discount applied (e.g., 10.00 for 10%)
  discount_reason VARCHAR(100), -- 'bulk_purchase', 'loyalty_discount', 'promotional', 'emergency_premium'
  
  -- Special pricing for different workflow types
  emergency_offboarding BOOLEAN DEFAULT FALSE, -- 350 EUR for urgent departures
  bulk_restructuring BOOLEAN DEFAULT FALSE, -- 125 EUR for bulk offboardings
  
  -- Transaction metadata
  description TEXT,
  internal_notes TEXT, -- Internal notes for customer service
  
  -- Audit and compliance
  created_by VARCHAR(100) NOT NULL, -- Role/system that created transaction
  approved_by VARCHAR(100), -- For high-value transactions requiring approval
  approved_at TIMESTAMP WITH TIME ZONE,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT valid_usage_transaction CHECK (
    (transaction_type = 'usage' AND workflow_type IS NOT NULL AND workflow_id IS NOT NULL) OR
    (transaction_type != 'usage')
  ),
  CONSTRAINT valid_purchase_transaction CHECK (
    (transaction_type = 'purchase' AND payment_method IS NOT NULL) OR
    (transaction_type != 'purchase')
  ),
  CONSTRAINT valid_credit_amount CHECK (
    (transaction_type IN ('purchase', 'bonus', 'refund') AND credit_amount > 0) OR
    (transaction_type IN ('usage', 'adjustment') AND credit_amount < 0) OR
    (transaction_type = 'adjustment') -- Adjustments can be positive or negative
  ),
  CONSTRAINT valid_emergency_pricing CHECK (
    (emergency_offboarding = FALSE) OR 
    (emergency_offboarding = TRUE AND price_per_credit = 350.00)
  ),
  CONSTRAINT valid_bulk_pricing CHECK (
    (bulk_restructuring = FALSE) OR 
    (bulk_restructuring = TRUE AND price_per_credit = 125.00)
  )
);

-- =====================================================
-- CLIENT CREDIT BALANCES TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS api.client_credit_balances (
  -- Primary key is client_id (one record per client)
  client_id UUID PRIMARY KEY REFERENCES api.clients(id) ON DELETE CASCADE,
  
  -- Credit balance tracking
  total_purchased INTEGER NOT NULL DEFAULT 0,
  total_used INTEGER NOT NULL DEFAULT 0,
  total_refunded INTEGER NOT NULL DEFAULT 0,
  total_adjustments INTEGER NOT NULL DEFAULT 0, -- Can be positive or negative
  
  -- Calculated balance (total purchased + adjustments - used - refunded)
  current_balance INTEGER GENERATED ALWAYS AS (total_purchased + total_adjustments - total_used - total_refunded) STORED,
  
  -- Reserved credits for in-progress workflows
  reserved_credits INTEGER NOT NULL DEFAULT 0,
  
  -- Available credits (current balance - reserved)
  available_credits INTEGER GENERATED ALWAYS AS (total_purchased + total_adjustments - total_used - total_refunded - reserved_credits) STORED,
  
  -- Alert and automation thresholds
  low_balance_threshold INTEGER DEFAULT 10,
  critical_balance_threshold INTEGER DEFAULT 5,
  auto_replenish_enabled BOOLEAN DEFAULT FALSE,
  auto_replenish_threshold INTEGER DEFAULT 5,
  auto_replenish_amount INTEGER DEFAULT 50,
  
  -- Purchase history
  total_spent DECIMAL(12,2) NOT NULL DEFAULT 0.00, -- Total amount spent on credits
  average_credit_price DECIMAL(10,2) GENERATED ALWAYS AS (
    CASE WHEN total_purchased > 0 THEN total_spent / total_purchased ELSE 175.00 END
  ) STORED,
  
  -- Usage patterns
  last_purchase_at TIMESTAMP WITH TIME ZONE,
  last_usage_at TIMESTAMP WITH TIME ZONE,
  last_auto_replenish_at TIMESTAMP WITH TIME ZONE,
  
  -- Lifecycle tracking
  first_purchase_date DATE,
  most_recent_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT non_negative_purchased CHECK (total_purchased >= 0),
  CONSTRAINT non_negative_used CHECK (total_used >= 0),
  CONSTRAINT non_negative_refunded CHECK (total_refunded >= 0),
  CONSTRAINT non_negative_reserved CHECK (reserved_credits >= 0),
  CONSTRAINT valid_thresholds CHECK (
    low_balance_threshold >= critical_balance_threshold AND
    critical_balance_threshold >= 0 AND
    auto_replenish_threshold >= 0 AND
    auto_replenish_amount > 0
  )
);

-- =====================================================
-- WORKFLOW CREDIT USAGE TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS api.workflow_credit_usage (
  -- Primary identifier
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Workflow relationship
  client_id UUID NOT NULL REFERENCES api.clients(id) ON DELETE CASCADE,
  workflow_id UUID NOT NULL, -- References offboarding_workflows.id or future onboarding_workflows.id
  workflow_type VARCHAR(20) NOT NULL CHECK (workflow_type IN ('onboarding', 'offboarding', 'role_change', 'internal_transfer')),
  
  -- Employee context (anonymous)
  employee_uid VARCHAR(64) NOT NULL,
  
  -- Credit usage details
  credits_consumed INTEGER NOT NULL DEFAULT 1,
  credit_rate DECIMAL(10,2) NOT NULL DEFAULT 175.00, -- Rate at time of consumption
  total_cost DECIMAL(10,2) NOT NULL,
  
  -- Pricing context
  pricing_tier VARCHAR(20) DEFAULT 'standard' CHECK (pricing_tier IN ('standard', 'emergency', 'bulk', 'promotional')),
  emergency_surcharge BOOLEAN DEFAULT FALSE,
  bulk_discount BOOLEAN DEFAULT FALSE,
  promotional_discount_applied VARCHAR(50),
  
  -- Usage tracking
  reserved_at TIMESTAMP WITH TIME ZONE, -- When credit was reserved
  consumed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(), -- When credit was actually consumed
  workflow_initiated_at TIMESTAMP WITH TIME ZONE,
  workflow_completed_at TIMESTAMP WITH TIME ZONE,
  
  -- Credit transaction reference
  credit_transaction_id UUID NOT NULL REFERENCES api.credit_transactions(id),
  
  -- Workflow outcome tracking
  workflow_status VARCHAR(20), -- Current workflow status
  workflow_completion_success BOOLEAN, -- Whether workflow completed successfully
  refund_eligible BOOLEAN DEFAULT FALSE, -- Whether this usage could be refunded
  refund_processed BOOLEAN DEFAULT FALSE,
  
  -- Business context
  department_category VARCHAR(50),
  seniority_level VARCHAR(20),
  workflow_complexity VARCHAR(20),
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT valid_credits_consumed CHECK (credits_consumed > 0),
  CONSTRAINT valid_cost_calculation CHECK (total_cost = credits_consumed * credit_rate),
  CONSTRAINT valid_consumption_timing CHECK (
    reserved_at IS NULL OR consumed_at >= reserved_at
  )
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Credit transactions indexes
CREATE INDEX IF NOT EXISTS idx_credit_transactions_client_id ON credit_transactions(client_id);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_type ON credit_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_workflow_id ON credit_transactions(workflow_id);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_created_at ON credit_transactions(created_at);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_payment_reference ON credit_transactions(payment_reference);

-- Credit balances indexes (for monitoring and alerts)
CREATE INDEX IF NOT EXISTS idx_credit_balances_available_credits ON client_credit_balances(available_credits);
CREATE INDEX IF NOT EXISTS idx_credit_balances_low_balance ON client_credit_balances(available_credits) WHERE available_credits <= 10;
CREATE INDEX IF NOT EXISTS idx_credit_balances_auto_replenish ON client_credit_balances(client_id) WHERE auto_replenish_enabled = TRUE;

-- Workflow credit usage indexes
CREATE INDEX IF NOT EXISTS idx_workflow_credit_usage_client_id ON workflow_credit_usage(client_id);
CREATE INDEX IF NOT EXISTS idx_workflow_credit_usage_workflow_id ON workflow_credit_usage(workflow_id);
CREATE INDEX IF NOT EXISTS idx_workflow_credit_usage_workflow_type ON workflow_credit_usage(workflow_type);
CREATE INDEX IF NOT EXISTS idx_workflow_credit_usage_consumed_at ON workflow_credit_usage(consumed_at);

-- Composite indexes for analytics
CREATE INDEX IF NOT EXISTS idx_credit_transactions_client_type_date ON credit_transactions(client_id, transaction_type, created_at);
CREATE INDEX IF NOT EXISTS idx_workflow_usage_client_type_date ON workflow_credit_usage(client_id, workflow_type, consumed_at);

-- =====================================================
-- TRIGGERS FOR AUTOMATION
-- =====================================================

-- Update timestamp triggers
CREATE OR REPLACE FUNCTION update_credit_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_credit_transactions_updated_at ON credit_transactions;
CREATE TRIGGER trigger_credit_transactions_updated_at
  BEFORE UPDATE ON credit_transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_credit_updated_at();

DROP TRIGGER IF EXISTS trigger_credit_balances_updated_at ON client_credit_balances;
CREATE TRIGGER trigger_credit_balances_updated_at
  BEFORE UPDATE ON client_credit_balances
  FOR EACH ROW
  EXECUTE FUNCTION update_credit_updated_at();

DROP TRIGGER IF EXISTS trigger_workflow_credit_usage_updated_at ON workflow_credit_usage;
CREATE TRIGGER trigger_workflow_credit_usage_updated_at
  BEFORE UPDATE ON workflow_credit_usage
  FOR EACH ROW
  EXECUTE FUNCTION update_credit_updated_at();

-- Auto-update credit balances when transactions are created
CREATE OR REPLACE FUNCTION update_credit_balance_on_transaction()
RETURNS TRIGGER AS $$
DECLARE
  balance_exists BOOLEAN;
BEGIN
  -- Check if balance record exists for this client
  SELECT EXISTS(SELECT 1 FROM client_credit_balances WHERE client_id = NEW.client_id) INTO balance_exists;
  
  -- Create balance record if it doesn't exist
  IF NOT balance_exists THEN
    INSERT INTO client_credit_balances (client_id, created_at)
    VALUES (NEW.client_id, NOW())
    ON CONFLICT (client_id) DO NOTHING;
  END IF;
  
  -- Update balance based on transaction type
  IF NEW.transaction_type = 'purchase' THEN
    UPDATE client_credit_balances
    SET 
      total_purchased = total_purchased + NEW.credit_amount,
      total_spent = total_spent + NEW.total_amount,
      last_purchase_at = NOW(),
      most_recent_activity = NOW(),
      first_purchase_date = COALESCE(first_purchase_date, CURRENT_DATE)
    WHERE client_id = NEW.client_id;
    
  ELSIF NEW.transaction_type = 'usage' THEN
    UPDATE client_credit_balances
    SET 
      total_used = total_used + ABS(NEW.credit_amount),
      last_usage_at = NOW(),
      most_recent_activity = NOW()
    WHERE client_id = NEW.client_id;
    
  ELSIF NEW.transaction_type = 'refund' THEN
    UPDATE client_credit_balances
    SET 
      total_refunded = total_refunded + NEW.credit_amount,
      most_recent_activity = NOW()
    WHERE client_id = NEW.client_id;
    
  ELSIF NEW.transaction_type = 'adjustment' THEN
    UPDATE client_credit_balances
    SET 
      total_adjustments = total_adjustments + NEW.credit_amount,
      most_recent_activity = NOW()
    WHERE client_id = NEW.client_id;
    
  ELSIF NEW.transaction_type = 'bonus' THEN
    UPDATE client_credit_balances
    SET 
      total_purchased = total_purchased + NEW.credit_amount, -- Treat bonus as free purchase
      most_recent_activity = NOW()
    WHERE client_id = NEW.client_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_credit_balance_on_transaction ON credit_transactions;
CREATE TRIGGER trigger_update_credit_balance_on_transaction
  AFTER INSERT ON credit_transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_credit_balance_on_transaction();

-- Reserve credits when offboarding workflow becomes active
CREATE OR REPLACE FUNCTION reserve_credits_for_workflow()
RETURNS TRIGGER AS $$
DECLARE
  credits_needed INTEGER := 1;
  current_available INTEGER;
  credit_rate DECIMAL(10,2) := 175.00;
BEGIN
  -- Only process when workflow status changes to an active state
  IF NEW.status IN ('knowledge_transfer', 'coordination', 'verification') AND 
     OLD.status = 'initiated' AND 
     NEW.credit_consumed = FALSE THEN
    
    -- Determine credit rate based on workflow characteristics
    IF NEW.priority = 'urgent' THEN
      credit_rate := 350.00; -- Emergency offboarding rate
    ELSIF NEW.workflow_complexity = 'simple' OR 
          (SELECT COUNT(*) FROM offboarding_workflows 
           WHERE client_id = NEW.client_id 
             AND status IN ('knowledge_transfer', 'coordination', 'verification')
             AND created_at::date = CURRENT_DATE) >= 5 THEN
      credit_rate := 125.00; -- Bulk offboarding rate
    END IF;
    
    -- Check available credits
    SELECT available_credits INTO current_available
    FROM client_credit_balances
    WHERE client_id = NEW.client_id;
    
    -- Prevent workflow progression if insufficient credits
    IF current_available < credits_needed THEN
      RAISE EXCEPTION 'Insufficient credits: % available, % required', current_available, credits_needed;
    END IF;
    
    -- Reserve the credits
    UPDATE client_credit_balances
    SET reserved_credits = reserved_credits + credits_needed
    WHERE client_id = NEW.client_id;
    
    -- Create usage transaction
    INSERT INTO credit_transactions (
      client_id,
      transaction_type,
      credit_amount,
      price_per_credit,
      total_amount,
      workflow_type,
      workflow_id,
      employee_uid,
      emergency_offboarding,
      bulk_restructuring,
      description,
      created_by
    ) VALUES (
      NEW.client_id,
      'usage',
      -credits_needed, -- Negative for usage
      credit_rate,
      credit_rate * credits_needed,
      'offboarding',
      NEW.id,
      NEW.employee_uid,
      (credit_rate = 350.00),
      (credit_rate = 125.00),
      'Credit consumed for offboarding workflow: ' || NEW.employee_uid,
      'workflow_system'
    );
    
    -- Create workflow usage record
    INSERT INTO workflow_credit_usage (
      client_id,
      workflow_id,
      workflow_type,
      employee_uid,
      credits_consumed,
      credit_rate,
      total_cost,
      pricing_tier,
      emergency_surcharge,
      bulk_discount,
      workflow_initiated_at,
      credit_transaction_id,
      department_category,
      seniority_level,
      workflow_complexity
    ) VALUES (
      NEW.client_id,
      NEW.id,
      'offboarding',
      NEW.employee_uid,
      credits_needed,
      credit_rate,
      credit_rate * credits_needed,
      CASE 
        WHEN credit_rate = 350.00 THEN 'emergency'
        WHEN credit_rate = 125.00 THEN 'bulk'
        ELSE 'standard'
      END,
      (credit_rate = 350.00),
      (credit_rate = 125.00),
      NOW(),
      currval('credit_transactions_id_seq'),
      NEW.department_category,
      NEW.seniority_level,
      NEW.workflow_complexity
    );
    
    -- Mark credit as consumed in workflow
    NEW.credit_consumed = TRUE;
    NEW.credit_transaction_id = currval('credit_transactions_id_seq');
    NEW.credit_amount = credit_rate;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to offboarding workflows table (will be created by previous schema)
-- This trigger is defined here but will be applied after offboarding_workflows table exists

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS on all credit tables
ALTER TABLE credit_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_credit_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE workflow_credit_usage ENABLE ROW LEVEL SECURITY;

-- Staff access policies
DROP POLICY IF EXISTS policy_credit_transactions_staff_access ON credit_transactions;
CREATE POLICY policy_credit_transactions_staff_access ON credit_transactions
  FOR ALL 
  USING (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

DROP POLICY IF EXISTS policy_credit_balances_staff_access ON client_credit_balances;
CREATE POLICY policy_credit_balances_staff_access ON client_credit_balances
  FOR ALL 
  USING (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

DROP POLICY IF EXISTS policy_workflow_credit_usage_staff_access ON workflow_credit_usage;
CREATE POLICY policy_workflow_credit_usage_staff_access ON workflow_credit_usage
  FOR ALL 
  USING (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

-- Client-specific access policies
DROP POLICY IF EXISTS policy_credit_transactions_client_access ON credit_transactions;
CREATE POLICY policy_credit_transactions_client_access ON credit_transactions
  FOR ALL
  USING (
    client_id::text = auth.jwt()->>'client_id'
    OR EXISTS (
      SELECT 1 FROM api.clients 
      WHERE clients.id = credit_transactions.client_id 
        AND clients.client_code = auth.jwt()->>'client_code'
    )
  );

DROP POLICY IF EXISTS policy_credit_balances_client_access ON client_credit_balances;
CREATE POLICY policy_credit_balances_client_access ON client_credit_balances
  FOR ALL
  USING (
    client_id::text = auth.jwt()->>'client_id'
    OR EXISTS (
      SELECT 1 FROM api.clients 
      WHERE clients.id = client_credit_balances.client_id 
        AND clients.client_code = auth.jwt()->>'client_code'
    )
  );

DROP POLICY IF EXISTS policy_workflow_credit_usage_client_access ON workflow_credit_usage;
CREATE POLICY policy_workflow_credit_usage_client_access ON workflow_credit_usage
  FOR ALL
  USING (
    client_id::text = auth.jwt()->>'client_id'
    OR EXISTS (
      SELECT 1 FROM api.clients 
      WHERE clients.id = workflow_credit_usage.client_id 
        AND clients.client_code = auth.jwt()->>'client_code'
    )
  );

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to purchase credits
CREATE OR REPLACE FUNCTION purchase_credits(
  p_client_id UUID,
  p_credit_amount INTEGER,
  p_payment_method VARCHAR(30),
  p_payment_reference VARCHAR(255) DEFAULT NULL,
  p_bulk_discount BOOLEAN DEFAULT FALSE
)
RETURNS UUID AS $$
DECLARE
  transaction_id UUID;
  base_price DECIMAL(10,2) := 175.00;
  discount_rate DECIMAL(5,2) := 0.00;
  final_price DECIMAL(10,2);
  total_amount DECIMAL(12,2);
BEGIN
  -- Calculate bulk discount
  IF p_bulk_discount OR p_credit_amount >= 100 THEN
    discount_rate := CASE 
      WHEN p_credit_amount >= 1000 THEN 20.00 -- 20% discount for 1000+
      WHEN p_credit_amount >= 500 THEN 15.00  -- 15% discount for 500+
      WHEN p_credit_amount >= 100 THEN 10.00  -- 10% discount for 100+
      WHEN p_credit_amount >= 50 THEN 5.00    -- 5% discount for 50+
      ELSE 0.00
    END;
  END IF;
  
  final_price := base_price * (1 - discount_rate / 100);
  total_amount := final_price * p_credit_amount;
  
  -- Create purchase transaction
  INSERT INTO credit_transactions (
    client_id,
    transaction_type,
    credit_amount,
    price_per_credit,
    total_amount,
    payment_method,
    payment_reference,
    base_price_per_credit,
    discount_percentage,
    discount_reason,
    description,
    created_by
  ) VALUES (
    p_client_id,
    'purchase',
    p_credit_amount,
    final_price,
    total_amount,
    p_payment_method,
    p_payment_reference,
    base_price,
    discount_rate,
    CASE WHEN discount_rate > 0 THEN 'bulk_purchase' ELSE NULL END,
    'Credit purchase: ' || p_credit_amount || ' credits',
    'purchase_system'
  ) RETURNING id INTO transaction_id;
  
  RETURN transaction_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check credit balance and trigger alerts
CREATE OR REPLACE FUNCTION check_credit_balance_alerts(p_client_id UUID)
RETURNS JSONB AS $$
DECLARE
  balance_info RECORD;
  alerts JSONB := '[]'::JSONB;
BEGIN
  SELECT * INTO balance_info
  FROM client_credit_balances
  WHERE client_id = p_client_id;
  
  IF NOT FOUND THEN
    RETURN '{"error": "Client not found"}'::JSONB;
  END IF;
  
  -- Check for low balance
  IF balance_info.available_credits <= balance_info.critical_balance_threshold THEN
    alerts := alerts || jsonb_build_array(
      jsonb_build_object(
        'type', 'critical_balance',
        'message', 'Critical: Only ' || balance_info.available_credits || ' credits remaining',
        'available_credits', balance_info.available_credits,
        'threshold', balance_info.critical_balance_threshold
      )
    );
  ELSIF balance_info.available_credits <= balance_info.low_balance_threshold THEN
    alerts := alerts || jsonb_build_array(
      jsonb_build_object(
        'type', 'low_balance',
        'message', 'Low balance: ' || balance_info.available_credits || ' credits remaining',
        'available_credits', balance_info.available_credits,
        'threshold', balance_info.low_balance_threshold
      )
    );
  END IF;
  
  -- Check for auto-replenish trigger
  IF balance_info.auto_replenish_enabled AND 
     balance_info.available_credits <= balance_info.auto_replenish_threshold THEN
    alerts := alerts || jsonb_build_array(
      jsonb_build_object(
        'type', 'auto_replenish_trigger',
        'message', 'Auto-replenish triggered for ' || balance_info.auto_replenish_amount || ' credits',
        'replenish_amount', balance_info.auto_replenish_amount
      )
    );
  END IF;
  
  RETURN jsonb_build_object(
    'client_id', p_client_id,
    'available_credits', balance_info.available_credits,
    'alerts', alerts,
    'balance_status', CASE 
      WHEN balance_info.available_credits <= balance_info.critical_balance_threshold THEN 'critical'
      WHEN balance_info.available_credits <= balance_info.low_balance_threshold THEN 'low'
      ELSE 'healthy'
    END
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get credit usage analytics
CREATE OR REPLACE FUNCTION get_credit_usage_analytics(
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
      COUNT(*) FILTER (WHERE bulk_discount = TRUE) as bulk_count
    FROM workflow_credit_usage
    WHERE client_id = p_client_id
      AND consumed_at::date BETWEEN start_date AND end_date
    GROUP BY workflow_type
  ),
  monthly_trends AS (
    SELECT 
      DATE_TRUNC('month', consumed_at) as month,
      COUNT(*) as workflows,
      SUM(credits_consumed) as credits,
      SUM(total_cost) as cost
    FROM workflow_credit_usage
    WHERE client_id = p_client_id
      AND consumed_at::date BETWEEN start_date AND end_date
    GROUP BY DATE_TRUNC('month', consumed_at)
    ORDER BY month
  )
  SELECT jsonb_build_object(
    'period', jsonb_build_object(
      'start_date', start_date,
      'end_date', end_date
    ),
    'summary', jsonb_build_object(
      'total_workflows', COALESCE(SUM(workflow_count), 0),
      'total_credits_consumed', COALESCE(SUM(total_credits), 0),
      'total_cost', COALESCE(SUM(total_cost), 0),
      'average_cost_per_workflow', COALESCE(SUM(total_cost) / NULLIF(SUM(workflow_count), 0), 0)
    ),
    'by_workflow_type', jsonb_agg(to_jsonb(usage_stats.*)),
    'monthly_trends', (
      SELECT jsonb_agg(to_jsonb(monthly_trends.*))
      FROM monthly_trends
    )
  ) INTO analytics
  FROM usage_stats;
  
  RETURN analytics;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON TABLE credit_transactions IS 'Complete transaction history for credit purchases, usage, refunds, and adjustments with 175 EUR base pricing';
COMMENT ON TABLE client_credit_balances IS 'Real-time credit balance tracking with automatic calculations and alert thresholds';
COMMENT ON TABLE workflow_credit_usage IS 'Detailed usage tracking for each workflow with pricing context and business metrics';

COMMENT ON COLUMN credit_transactions.price_per_credit IS 'Actual price paid per credit (175 EUR standard, 350 EUR emergency, 125 EUR bulk)';
COMMENT ON COLUMN credit_transactions.emergency_offboarding IS 'TRUE for urgent offboarding workflows charged at 350 EUR premium rate';
COMMENT ON COLUMN credit_transactions.bulk_restructuring IS 'TRUE for bulk offboarding scenarios charged at 125 EUR discounted rate';
COMMENT ON COLUMN client_credit_balances.available_credits IS 'Computed column: current_balance - reserved_credits';
COMMENT ON COLUMN workflow_credit_usage.credit_rate IS 'Rate charged for this specific workflow at time of consumption';
COMMENT ON COLUMN workflow_credit_usage.refund_eligible IS 'Whether this usage could potentially be refunded based on workflow outcome';