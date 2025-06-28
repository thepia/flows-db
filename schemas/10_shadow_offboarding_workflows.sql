-- =====================================================
-- SHADOW OFFBOARDING WORKFLOWS - External Monitoring Model
-- =====================================================
-- 
-- Purpose: External knowledge transfer and communication coordination for offboarding
-- Context: Shadow Organization model - external monitoring, no internal system access
-- Privacy: Employee-controlled data sharing, 90-day auto-deletion, no PII storage
-- Dependencies: clients, client_applications tables

-- Set schema context
SET search_path TO api, public;

-- =====================================================
-- OFFBOARDING WORKFLOWS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS api.offboarding_workflows (
  -- Primary identifier
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Client and application relationship
  client_id UUID NOT NULL REFERENCES api.clients(id) ON DELETE CASCADE,
  app_id UUID REFERENCES api.client_applications(id) ON DELETE CASCADE,
  
  -- Employee identification (anonymous UID only, no PII)
  employee_uid VARCHAR(64) NOT NULL, -- Anonymous UID from Shadow platform
  workflow_type VARCHAR(30) DEFAULT 'offboarding' CHECK (workflow_type IN ('offboarding', 'internal_transfer', 'role_change', 'retirement')),
  
  -- Workflow status and lifecycle
  status VARCHAR(20) DEFAULT 'initiated' CHECK (status IN ('initiated', 'knowledge_transfer', 'coordination', 'verification', 'completed', 'cancelled')),
  priority VARCHAR(20) DEFAULT 'standard' CHECK (priority IN ('low', 'standard', 'high', 'urgent')),
  
  -- Timeline tracking
  initiated_date DATE NOT NULL DEFAULT CURRENT_DATE,
  expected_last_day DATE, -- Employee's expected final day
  knowledge_transfer_deadline DATE, -- Deadline for knowledge transfer completion
  final_completion_deadline DATE, -- All offboarding tasks must be complete by this date
  actual_completion_date DATE,
  
  -- External coordination status
  exit_interview_scheduled BOOLEAN DEFAULT FALSE,
  exit_interview_completed BOOLEAN DEFAULT FALSE,
  knowledge_transfer_completed BOOLEAN DEFAULT FALSE,
  documentation_submitted BOOLEAN DEFAULT FALSE,
  handover_verified BOOLEAN DEFAULT FALSE,
  compliance_verified BOOLEAN DEFAULT FALSE,
  
  -- Credit system integration (175 EUR per offboarding workflow)
  credit_consumed BOOLEAN DEFAULT FALSE,
  credit_transaction_id UUID, -- Reference to credit transaction
  credit_amount DECIMAL(10,2) DEFAULT 175.00,
  
  -- Employee context (categories only, no PII)
  department_category VARCHAR(50), -- Generic categories: 'technical', 'sales', 'operations', 'leadership', 'support'
  seniority_level VARCHAR(20) CHECK (seniority_level IN ('junior', 'mid_level', 'senior', 'principal', 'leadership', 'executive')),
  role_type VARCHAR(30), -- Generic role types: 'individual_contributor', 'team_lead', 'manager', 'director', 'specialist'
  
  -- Workflow complexity assessment
  workflow_complexity VARCHAR(20) DEFAULT 'standard' CHECK (workflow_complexity IN ('simple', 'standard', 'complex', 'executive')),
  estimated_knowledge_transfer_hours INTEGER DEFAULT 8, -- Estimated hours needed for knowledge transfer
  number_of_direct_reports INTEGER DEFAULT 0,
  number_of_key_relationships INTEGER DEFAULT 0, -- Client/vendor relationships to transfer
  
  -- Process coordination
  assigned_coordinator VARCHAR(100), -- HR or process coordinator (role, not name)
  requires_legal_review BOOLEAN DEFAULT FALSE,
  requires_security_clearance_review BOOLEAN DEFAULT FALSE,
  requires_client_notification BOOLEAN DEFAULT FALSE,
  
  -- External system coordination flags (for employer's internal systems)
  employer_asset_return_required BOOLEAN DEFAULT TRUE,
  employer_system_access_review_required BOOLEAN DEFAULT TRUE,
  employer_payroll_coordination_required BOOLEAN DEFAULT TRUE,
  
  -- Knowledge transfer categorization
  has_critical_system_knowledge BOOLEAN DEFAULT FALSE,
  has_client_relationships BOOLEAN DEFAULT FALSE,
  has_vendor_relationships BOOLEAN DEFAULT FALSE,
  has_specialized_processes BOOLEAN DEFAULT FALSE,
  has_team_leadership_responsibilities BOOLEAN DEFAULT FALSE,
  
  -- Communication and documentation
  preferred_communication_method VARCHAR(30) DEFAULT 'platform_messaging',
  documentation_language VARCHAR(10) DEFAULT 'en',
  requires_translation BOOLEAN DEFAULT FALSE,
  
  -- Timestamps and audit
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by VARCHAR(100) NOT NULL, -- Role or system that initiated
  
  -- Auto-deletion compliance (Shadow platform requirement)
  deletion_scheduled_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '90 days'),
  deletion_warning_sent BOOLEAN DEFAULT FALSE,
  
  -- Constraints
  CONSTRAINT valid_deadlines CHECK (
    expected_last_day IS NULL OR expected_last_day >= initiated_date
  ),
  CONSTRAINT valid_knowledge_transfer_deadline CHECK (
    knowledge_transfer_deadline IS NULL OR 
    (expected_last_day IS NULL OR knowledge_transfer_deadline <= expected_last_day)
  ),
  CONSTRAINT valid_final_deadline CHECK (
    final_completion_deadline IS NULL OR 
    (expected_last_day IS NULL OR final_completion_deadline >= expected_last_day)
  )
);

-- =====================================================
-- KNOWLEDGE TRANSFER ITEMS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS api.knowledge_transfer_items (
  -- Primary identifier
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Workflow relationship
  offboarding_workflow_id UUID NOT NULL REFERENCES api.offboarding_workflows(id) ON DELETE CASCADE,
  
  -- Knowledge categorization
  knowledge_type VARCHAR(30) NOT NULL CHECK (knowledge_type IN (
    'process_documentation', 
    'client_relationships', 
    'vendor_relationships',
    'project_handover', 
    'system_knowledge', 
    'tribal_knowledge',
    'team_procedures',
    'compliance_knowledge',
    'training_materials',
    'institutional_memory'
  )),
  
  -- Knowledge details (employee-provided, no PII)
  title VARCHAR(255) NOT NULL,
  description TEXT,
  business_impact VARCHAR(20) DEFAULT 'medium' CHECK (business_impact IN ('low', 'medium', 'high', 'critical')),
  urgency VARCHAR(20) DEFAULT 'standard' CHECK (urgency IN ('low', 'standard', 'high', 'immediate')),
  
  -- Transfer coordination
  successor_role VARCHAR(100), -- Role/title, not person name
  successor_identified BOOLEAN DEFAULT FALSE,
  backup_successor_identified BOOLEAN DEFAULT FALSE,
  
  -- Documentation and transfer progress
  documentation_status VARCHAR(20) DEFAULT 'pending' CHECK (documentation_status IN ('pending', 'in_progress', 'completed', 'not_required')),
  handover_session_required BOOLEAN DEFAULT TRUE,
  handover_session_scheduled BOOLEAN DEFAULT FALSE,
  handover_session_completed BOOLEAN DEFAULT FALSE,
  
  -- Verification and quality assurance
  documentation_reviewed BOOLEAN DEFAULT FALSE,
  successor_confirmation_received BOOLEAN DEFAULT FALSE,
  knowledge_verified BOOLEAN DEFAULT FALSE,
  
  -- Timeline tracking
  target_completion_date DATE,
  actual_completion_date DATE,
  estimated_hours DECIMAL(4,1) DEFAULT 2.0, -- Estimated hours for this knowledge transfer
  actual_hours DECIMAL(4,1), -- Actual time spent on transfer
  
  -- External coordination
  requires_client_introduction BOOLEAN DEFAULT FALSE,
  requires_vendor_introduction BOOLEAN DEFAULT FALSE,
  requires_system_access_coordination BOOLEAN DEFAULT FALSE,
  requires_legal_review BOOLEAN DEFAULT FALSE,
  
  -- Quality metrics
  complexity_score INTEGER CHECK (complexity_score BETWEEN 1 AND 10),
  knowledge_uniqueness_score INTEGER CHECK (knowledge_uniqueness_score BETWEEN 1 AND 10),
  business_continuity_risk VARCHAR(20) CHECK (business_continuity_risk IN ('minimal', 'low', 'medium', 'high', 'severe')),
  
  -- Documentation attachments (references only, actual files in Shadow platform)
  has_written_documentation BOOLEAN DEFAULT FALSE,
  has_process_diagrams BOOLEAN DEFAULT FALSE,
  has_video_walkthroughs BOOLEAN DEFAULT FALSE,
  has_contact_lists BOOLEAN DEFAULT FALSE,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- OFFBOARDING COMPLIANCE CHECKS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS api.offboarding_compliance_checks (
  -- Primary identifier
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Workflow relationship
  offboarding_workflow_id UUID NOT NULL REFERENCES api.offboarding_workflows(id) ON DELETE CASCADE,
  
  -- Compliance category and details
  compliance_type VARCHAR(30) NOT NULL CHECK (compliance_type IN (
    'exit_interview',
    'knowledge_transfer_verification',
    'documentation_handover',
    'project_transition_confirmation',
    'client_notification_completion',
    'vendor_notification_completion',
    'team_transition_briefing',
    'security_clearance_review',
    'legal_document_completion',
    'hr_policy_compliance',
    'equipment_return_coordination', -- Note: coordination only, not direct management
    'system_access_review_coordination', -- Note: coordination only, not direct management
    'payroll_coordination_verification' -- Note: coordination only, not direct management
  )),
  
  -- Compliance status and tracking
  required BOOLEAN DEFAULT TRUE,
  criticality VARCHAR(20) DEFAULT 'standard' CHECK (criticality IN ('optional', 'standard', 'important', 'critical')),
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'not_applicable', 'waived')),
  
  -- Responsibility and coordination
  responsible_party VARCHAR(100), -- Role/department responsible for completion
  coordinator_assigned VARCHAR(100), -- Shadow platform coordinator role
  requires_external_coordination BOOLEAN DEFAULT FALSE, -- Requires employer's internal systems
  
  -- Verification and documentation
  completion_evidence TEXT, -- Description of how compliance was verified
  verified_by VARCHAR(100), -- Role of person who verified completion
  verification_date DATE,
  waiver_reason TEXT, -- If compliance check was waived
  waiver_approved_by VARCHAR(100), -- Role of person who approved waiver
  
  -- Timeline management
  due_date DATE,
  reminder_sent BOOLEAN DEFAULT FALSE,
  escalation_triggered BOOLEAN DEFAULT FALSE,
  completed_date DATE,
  
  -- Risk assessment
  non_compliance_risk VARCHAR(20) CHECK (non_compliance_risk IN ('minimal', 'low', 'medium', 'high', 'severe')),
  business_impact_if_missed TEXT,
  legal_impact_if_missed TEXT,
  
  -- External dependencies
  depends_on_employer_systems BOOLEAN DEFAULT FALSE,
  depends_on_third_party BOOLEAN DEFAULT FALSE,
  dependency_description TEXT,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- OFFBOARDING COMMUNICATIONS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS api.offboarding_communications (
  -- Primary identifier
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Workflow relationship
  offboarding_workflow_id UUID NOT NULL REFERENCES api.offboarding_workflows(id) ON DELETE CASCADE,
  
  -- Communication type and purpose
  communication_type VARCHAR(30) NOT NULL CHECK (communication_type IN (
    'exit_interview',
    'knowledge_handover_meeting',
    'client_notification_call',
    'vendor_notification_call',
    'team_announcement_meeting',
    'project_transition_session',
    'documentation_review_session',
    'compliance_verification_meeting',
    'final_wrap_up_call'
  )),
  
  -- Scheduling information (privacy-conscious)
  scheduled_date DATE,
  scheduled_time TIME,
  duration_minutes INTEGER DEFAULT 60,
  timezone VARCHAR(50) DEFAULT 'UTC',
  
  -- Meeting coordination
  meeting_platform VARCHAR(50), -- 'zoom', 'teams', 'meet', 'phone', 'in_person'
  meeting_link_provided BOOLEAN DEFAULT FALSE,
  calendar_invites_sent BOOLEAN DEFAULT FALSE,
  
  -- Participants (roles only, no personal names)
  participant_roles JSONB DEFAULT '[]', -- ['departing_employee', 'manager', 'hr_representative', 'successor', 'coordinator']
  facilitator_role VARCHAR(50),
  required_participants INTEGER DEFAULT 1,
  confirmed_participants INTEGER DEFAULT 0,
  
  -- Communication status
  status VARCHAR(20) DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'confirmed', 'in_progress', 'completed', 'cancelled', 'rescheduled')),
  rescheduled_from_date DATE,
  rescheduled_reason TEXT,
  cancellation_reason TEXT,
  
  -- Preparation and documentation
  agenda_provided BOOLEAN DEFAULT FALSE,
  preparation_materials_sent BOOLEAN DEFAULT FALSE,
  pre_meeting_requirements_met BOOLEAN DEFAULT FALSE,
  
  -- Meeting outcomes
  notes_captured BOOLEAN DEFAULT FALSE,
  action_items_assigned BOOLEAN DEFAULT FALSE,
  follow_up_required BOOLEAN DEFAULT FALSE,
  follow_up_scheduled BOOLEAN DEFAULT FALSE,
  
  -- Quality and effectiveness
  objectives_met BOOLEAN DEFAULT FALSE,
  participant_satisfaction_score INTEGER CHECK (participant_satisfaction_score BETWEEN 1 AND 10),
  meeting_effectiveness_score INTEGER CHECK (meeting_effectiveness_score BETWEEN 1 AND 10),
  
  -- External coordination needs
  requires_client_participation BOOLEAN DEFAULT FALSE,
  requires_vendor_participation BOOLEAN DEFAULT FALSE,
  requires_legal_presence BOOLEAN DEFAULT FALSE,
  requires_security_clearance BOOLEAN DEFAULT FALSE,
  
  -- Documentation and follow-up
  summary_document_created BOOLEAN DEFAULT FALSE,
  action_items_tracked BOOLEAN DEFAULT FALSE,
  decisions_documented BOOLEAN DEFAULT FALSE,
  next_steps_clarified BOOLEAN DEFAULT FALSE,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Offboarding workflows indexes
CREATE INDEX IF NOT EXISTS idx_offboarding_workflows_client_id ON offboarding_workflows(client_id);
CREATE INDEX IF NOT EXISTS idx_offboarding_workflows_status ON offboarding_workflows(status);
CREATE INDEX IF NOT EXISTS idx_offboarding_workflows_employee_uid ON offboarding_workflows(employee_uid);
CREATE INDEX IF NOT EXISTS idx_offboarding_workflows_initiated_date ON offboarding_workflows(initiated_date);
CREATE INDEX IF NOT EXISTS idx_offboarding_workflows_deletion_scheduled ON offboarding_workflows(deletion_scheduled_at);

-- Knowledge transfer items indexes
CREATE INDEX IF NOT EXISTS idx_knowledge_transfer_workflow_id ON knowledge_transfer_items(offboarding_workflow_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_transfer_type ON knowledge_transfer_items(knowledge_type);
CREATE INDEX IF NOT EXISTS idx_knowledge_transfer_business_impact ON knowledge_transfer_items(business_impact);
CREATE INDEX IF NOT EXISTS idx_knowledge_transfer_completion ON knowledge_transfer_items(actual_completion_date);

-- Compliance checks indexes
CREATE INDEX IF NOT EXISTS idx_compliance_checks_workflow_id ON offboarding_compliance_checks(offboarding_workflow_id);
CREATE INDEX IF NOT EXISTS idx_compliance_checks_type ON offboarding_compliance_checks(compliance_type);
CREATE INDEX IF NOT EXISTS idx_compliance_checks_status ON offboarding_compliance_checks(status);
CREATE INDEX IF NOT EXISTS idx_compliance_checks_due_date ON offboarding_compliance_checks(due_date);

-- Communications indexes
CREATE INDEX IF NOT EXISTS idx_communications_workflow_id ON offboarding_communications(offboarding_workflow_id);
CREATE INDEX IF NOT EXISTS idx_communications_type ON offboarding_communications(communication_type);
CREATE INDEX IF NOT EXISTS idx_communications_scheduled_date ON offboarding_communications(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_communications_status ON offboarding_communications(status);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_offboarding_status_priority ON offboarding_workflows(status, priority);
CREATE INDEX IF NOT EXISTS idx_knowledge_transfer_status_deadline ON knowledge_transfer_items(documentation_status, target_completion_date);
CREATE INDEX IF NOT EXISTS idx_compliance_status_criticality ON offboarding_compliance_checks(status, criticality);

-- =====================================================
-- TRIGGERS FOR AUTOMATION
-- =====================================================

-- Update timestamp trigger
CREATE OR REPLACE FUNCTION update_offboarding_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables
DROP TRIGGER IF EXISTS trigger_offboarding_workflows_updated_at ON offboarding_workflows;
CREATE TRIGGER trigger_offboarding_workflows_updated_at
  BEFORE UPDATE ON offboarding_workflows
  FOR EACH ROW
  EXECUTE FUNCTION update_offboarding_updated_at();

DROP TRIGGER IF EXISTS trigger_knowledge_transfer_updated_at ON knowledge_transfer_items;
CREATE TRIGGER trigger_knowledge_transfer_updated_at
  BEFORE UPDATE ON knowledge_transfer_items
  FOR EACH ROW
  EXECUTE FUNCTION update_offboarding_updated_at();

DROP TRIGGER IF EXISTS trigger_compliance_checks_updated_at ON offboarding_compliance_checks;
CREATE TRIGGER trigger_compliance_checks_updated_at
  BEFORE UPDATE ON offboarding_compliance_checks
  FOR EACH ROW
  EXECUTE FUNCTION update_offboarding_updated_at();

DROP TRIGGER IF EXISTS trigger_communications_updated_at ON offboarding_communications;
CREATE TRIGGER trigger_communications_updated_at
  BEFORE UPDATE ON offboarding_communications
  FOR EACH ROW
  EXECUTE FUNCTION update_offboarding_updated_at();

-- Auto-consume credit when workflow is initiated
CREATE OR REPLACE FUNCTION consume_offboarding_credit()
RETURNS TRIGGER AS $$
BEGIN
  -- Only consume credit once when status changes from any state to an active state
  IF NEW.status IN ('knowledge_transfer', 'coordination', 'verification') AND 
     OLD.status = 'initiated' AND 
     NEW.credit_consumed = FALSE THEN
    
    -- Mark credit as consumed
    NEW.credit_consumed = TRUE;
    
    -- Note: Actual credit transaction would be handled by application layer
    -- This trigger just marks the consumption point
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_consume_offboarding_credit ON offboarding_workflows;
CREATE TRIGGER trigger_consume_offboarding_credit
  BEFORE UPDATE ON offboarding_workflows
  FOR EACH ROW
  EXECUTE FUNCTION consume_offboarding_credit();

-- Auto-update workflow completion status based on knowledge transfer and compliance
CREATE OR REPLACE FUNCTION update_workflow_completion_status()
RETURNS TRIGGER AS $$
DECLARE
  workflow_id UUID;
  pending_knowledge_items INTEGER;
  pending_compliance_items INTEGER;
BEGIN
  -- Get the workflow ID
  workflow_id := COALESCE(NEW.offboarding_workflow_id, OLD.offboarding_workflow_id);
  
  -- Count pending items
  SELECT COUNT(*) INTO pending_knowledge_items
  FROM knowledge_transfer_items
  WHERE offboarding_workflow_id = workflow_id 
    AND knowledge_verified = FALSE;
    
  SELECT COUNT(*) INTO pending_compliance_items
  FROM offboarding_compliance_checks
  WHERE offboarding_workflow_id = workflow_id 
    AND status NOT IN ('completed', 'not_applicable', 'waived')
    AND required = TRUE;
  
  -- Update workflow status if all items are complete
  IF pending_knowledge_items = 0 AND pending_compliance_items = 0 THEN
    UPDATE offboarding_workflows
    SET 
      status = 'completed',
      actual_completion_date = CURRENT_DATE,
      knowledge_transfer_completed = TRUE,
      compliance_verified = TRUE
    WHERE id = workflow_id
      AND status != 'completed';
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Apply completion trigger to knowledge transfer and compliance tables
DROP TRIGGER IF EXISTS trigger_update_workflow_completion_knowledge ON knowledge_transfer_items;
CREATE TRIGGER trigger_update_workflow_completion_knowledge
  AFTER INSERT OR UPDATE OR DELETE ON knowledge_transfer_items
  FOR EACH ROW
  EXECUTE FUNCTION update_workflow_completion_status();

DROP TRIGGER IF EXISTS trigger_update_workflow_completion_compliance ON offboarding_compliance_checks;
CREATE TRIGGER trigger_update_workflow_completion_compliance
  AFTER INSERT OR UPDATE OR DELETE ON offboarding_compliance_checks
  FOR EACH ROW
  EXECUTE FUNCTION update_workflow_completion_status();

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE offboarding_workflows ENABLE ROW LEVEL SECURITY;
ALTER TABLE knowledge_transfer_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE offboarding_compliance_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE offboarding_communications ENABLE ROW LEVEL SECURITY;

-- Staff access policies (Thepia team can access all data)
DROP POLICY IF EXISTS policy_offboarding_workflows_staff_access ON offboarding_workflows;
CREATE POLICY policy_offboarding_workflows_staff_access ON offboarding_workflows
  FOR ALL 
  USING (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

DROP POLICY IF EXISTS policy_knowledge_transfer_staff_access ON knowledge_transfer_items;
CREATE POLICY policy_knowledge_transfer_staff_access ON knowledge_transfer_items
  FOR ALL 
  USING (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

DROP POLICY IF EXISTS policy_compliance_checks_staff_access ON offboarding_compliance_checks;
CREATE POLICY policy_compliance_checks_staff_access ON offboarding_compliance_checks
  FOR ALL 
  USING (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

DROP POLICY IF EXISTS policy_communications_staff_access ON offboarding_communications;
CREATE POLICY policy_communications_staff_access ON offboarding_communications
  FOR ALL 
  USING (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

-- Client-specific access policies
DROP POLICY IF EXISTS policy_offboarding_workflows_client_access ON offboarding_workflows;
CREATE POLICY policy_offboarding_workflows_client_access ON offboarding_workflows
  FOR ALL
  USING (
    client_id::text = auth.jwt()->>'client_id'
    OR EXISTS (
      SELECT 1 FROM api.clients 
      WHERE clients.id = offboarding_workflows.client_id 
        AND clients.client_code = auth.jwt()->>'client_code'
    )
  );

-- Cascade client access to related tables
DROP POLICY IF EXISTS policy_knowledge_transfer_client_access ON knowledge_transfer_items;
CREATE POLICY policy_knowledge_transfer_client_access ON knowledge_transfer_items
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM api.offboarding_workflows ow
      WHERE ow.id = knowledge_transfer_items.offboarding_workflow_id
        AND (
          ow.client_id::text = auth.jwt()->>'client_id'
          OR EXISTS (
            SELECT 1 FROM api.clients c
            WHERE c.id = ow.client_id 
              AND c.client_code = auth.jwt()->>'client_code'
          )
        )
    )
  );

DROP POLICY IF EXISTS policy_compliance_checks_client_access ON offboarding_compliance_checks;
CREATE POLICY policy_compliance_checks_client_access ON offboarding_compliance_checks
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM api.offboarding_workflows ow
      WHERE ow.id = offboarding_compliance_checks.offboarding_workflow_id
        AND (
          ow.client_id::text = auth.jwt()->>'client_id'
          OR EXISTS (
            SELECT 1 FROM api.clients c
            WHERE c.id = ow.client_id 
              AND c.client_code = auth.jwt()->>'client_code'
          )
        )
    )
  );

DROP POLICY IF EXISTS policy_communications_client_access ON offboarding_communications;
CREATE POLICY policy_communications_client_access ON offboarding_communications
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM api.offboarding_workflows ow
      WHERE ow.id = offboarding_communications.offboarding_workflow_id
        AND (
          ow.client_id::text = auth.jwt()->>'client_id'
          OR EXISTS (
            SELECT 1 FROM api.clients c
            WHERE c.id = ow.client_id 
              AND c.client_code = auth.jwt()->>'client_code'
          )
        )
    )
  );

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to initiate a new offboarding workflow
CREATE OR REPLACE FUNCTION initiate_offboarding_workflow(
  p_client_id UUID,
  p_employee_uid VARCHAR(64),
  p_expected_last_day DATE DEFAULT NULL,
  p_department_category VARCHAR(50) DEFAULT NULL,
  p_seniority_level VARCHAR(20) DEFAULT 'mid_level',
  p_workflow_complexity VARCHAR(20) DEFAULT 'standard'
)
RETURNS UUID AS $$
DECLARE
  workflow_id UUID;
  knowledge_transfer_deadline DATE;
  final_deadline DATE;
BEGIN
  -- Calculate deadlines based on expected last day
  IF p_expected_last_day IS NOT NULL THEN
    knowledge_transfer_deadline := p_expected_last_day - INTERVAL '5 days';
    final_deadline := p_expected_last_day + INTERVAL '30 days';
  ELSE
    knowledge_transfer_deadline := CURRENT_DATE + INTERVAL '14 days';
    final_deadline := CURRENT_DATE + INTERVAL '45 days';
  END IF;
  
  -- Create the workflow
  INSERT INTO offboarding_workflows (
    client_id,
    employee_uid,
    expected_last_day,
    knowledge_transfer_deadline,
    final_completion_deadline,
    department_category,
    seniority_level,
    workflow_complexity,
    created_by
  ) VALUES (
    p_client_id,
    p_employee_uid,
    p_expected_last_day,
    knowledge_transfer_deadline,
    final_deadline,
    p_department_category,
    p_seniority_level,
    p_workflow_complexity,
    'system_initiation'
  ) RETURNING id INTO workflow_id;
  
  -- Create default compliance checks based on workflow complexity
  PERFORM create_default_compliance_checks(workflow_id, p_workflow_complexity);
  
  RETURN workflow_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create default compliance checks based on workflow complexity
CREATE OR REPLACE FUNCTION create_default_compliance_checks(
  p_workflow_id UUID,
  p_complexity VARCHAR(20)
)
RETURNS VOID AS $$
BEGIN
  -- Standard compliance checks for all workflows
  INSERT INTO offboarding_compliance_checks (
    offboarding_workflow_id,
    compliance_type,
    criticality,
    responsible_party,
    due_date
  ) VALUES 
  (p_workflow_id, 'exit_interview', 'important', 'hr_department', (SELECT expected_last_day FROM offboarding_workflows WHERE id = p_workflow_id)),
  (p_workflow_id, 'knowledge_transfer_verification', 'critical', 'manager', (SELECT knowledge_transfer_deadline FROM offboarding_workflows WHERE id = p_workflow_id)),
  (p_workflow_id, 'documentation_handover', 'important', 'departing_employee', (SELECT knowledge_transfer_deadline FROM offboarding_workflows WHERE id = p_workflow_id));
  
  -- Additional checks for complex workflows
  IF p_complexity IN ('complex', 'executive') THEN
    INSERT INTO offboarding_compliance_checks (
      offboarding_workflow_id,
      compliance_type,
      criticality,
      responsible_party,
      due_date
    ) VALUES 
    (p_workflow_id, 'client_notification_completion', 'critical', 'account_manager', (SELECT expected_last_day - INTERVAL '7 days' FROM offboarding_workflows WHERE id = p_workflow_id)),
    (p_workflow_id, 'team_transition_briefing', 'important', 'manager', (SELECT expected_last_day - INTERVAL '3 days' FROM offboarding_workflows WHERE id = p_workflow_id)),
    (p_workflow_id, 'legal_document_completion', 'important', 'legal_department', (SELECT final_completion_deadline FROM offboarding_workflows WHERE id = p_workflow_id));
  END IF;
  
  -- Executive-level additional checks
  IF p_complexity = 'executive' THEN
    INSERT INTO offboarding_compliance_checks (
      offboarding_workflow_id,
      compliance_type,
      criticality,
      responsible_party,
      due_date
    ) VALUES 
    (p_workflow_id, 'security_clearance_review', 'critical', 'security_department', (SELECT expected_last_day FROM offboarding_workflows WHERE id = p_workflow_id)),
    (p_workflow_id, 'vendor_notification_completion', 'important', 'procurement_department', (SELECT expected_last_day - INTERVAL '14 days' FROM offboarding_workflows WHERE id = p_workflow_id));
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get offboarding workflow with progress summary
CREATE OR REPLACE FUNCTION get_offboarding_workflow_summary(p_workflow_id UUID)
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'workflow', to_jsonb(ow.*),
    'knowledge_transfer_items', COALESCE(kt.items, '[]'::jsonb),
    'compliance_checks', COALESCE(cc.checks, '[]'::jsonb),
    'communications', COALESCE(comm.communications, '[]'::jsonb),
    'progress', jsonb_build_object(
      'total_knowledge_items', COALESCE(kt.total_count, 0),
      'completed_knowledge_items', COALESCE(kt.completed_count, 0),
      'total_compliance_checks', COALESCE(cc.total_count, 0),
      'completed_compliance_checks', COALESCE(cc.completed_count, 0),
      'completion_percentage', CASE 
        WHEN COALESCE(kt.total_count, 0) + COALESCE(cc.total_count, 0) = 0 THEN 0
        ELSE ROUND(
          ((COALESCE(kt.completed_count, 0) + COALESCE(cc.completed_count, 0))::DECIMAL / 
           (COALESCE(kt.total_count, 0) + COALESCE(cc.total_count, 0))) * 100, 1
        )
      END
    )
  ) INTO result
  FROM offboarding_workflows ow
  LEFT JOIN (
    SELECT 
      offboarding_workflow_id,
      jsonb_agg(to_jsonb(kt.*)) as items,
      COUNT(*) as total_count,
      COUNT(*) FILTER (WHERE knowledge_verified = TRUE) as completed_count
    FROM knowledge_transfer_items kt
    WHERE offboarding_workflow_id = p_workflow_id
    GROUP BY offboarding_workflow_id
  ) kt ON kt.offboarding_workflow_id = ow.id
  LEFT JOIN (
    SELECT 
      offboarding_workflow_id,
      jsonb_agg(to_jsonb(occ.*)) as checks,
      COUNT(*) as total_count,
      COUNT(*) FILTER (WHERE status = 'completed') as completed_count
    FROM offboarding_compliance_checks occ
    WHERE offboarding_workflow_id = p_workflow_id
    GROUP BY offboarding_workflow_id
  ) cc ON cc.offboarding_workflow_id = ow.id
  LEFT JOIN (
    SELECT 
      offboarding_workflow_id,
      jsonb_agg(to_jsonb(oc.*)) as communications
    FROM offboarding_communications oc
    WHERE offboarding_workflow_id = p_workflow_id
    GROUP BY offboarding_workflow_id
  ) comm ON comm.offboarding_workflow_id = ow.id
  WHERE ow.id = p_workflow_id;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON TABLE offboarding_workflows IS 'External offboarding workflow coordination using Shadow platform model - employee-controlled knowledge transfer and communication facilitation';
COMMENT ON TABLE knowledge_transfer_items IS 'Individual knowledge transfer items with external coordination and employee control';
COMMENT ON TABLE offboarding_compliance_checks IS 'External compliance coordination and verification tracking';
COMMENT ON TABLE offboarding_communications IS 'Communication coordination and scheduling for offboarding stakeholders';

COMMENT ON COLUMN offboarding_workflows.employee_uid IS 'Anonymous UID from Shadow platform - no PII stored';
COMMENT ON COLUMN offboarding_workflows.credit_consumed IS 'Track when 175 EUR credit is consumed for this workflow';
COMMENT ON COLUMN offboarding_workflows.deletion_scheduled_at IS 'Auto-deletion after 90 days per Shadow platform privacy policy';
COMMENT ON COLUMN knowledge_transfer_items.business_impact IS 'Business impact assessment for prioritizing knowledge transfer';
COMMENT ON COLUMN offboarding_compliance_checks.requires_external_coordination IS 'Indicates if this check requires coordination with employer internal systems';
COMMENT ON COLUMN offboarding_communications.participant_roles IS 'JSON array of participant roles (no personal names)';