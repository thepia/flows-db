-- Enhanced Demo Schema Implementation
-- This file implements the comprehensive demo data structure outlined in SCHEMA_ENHANCEMENTS.md

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- 1. Enhanced Client Management
-- Add columns to existing clients table
ALTER TABLE api.clients ADD COLUMN IF NOT EXISTS industry VARCHAR(100);
ALTER TABLE api.clients ADD COLUMN IF NOT EXISTS founded_year INTEGER;
ALTER TABLE api.clients ADD COLUMN IF NOT EXISTS headquarters_city VARCHAR(100);
ALTER TABLE api.clients ADD COLUMN IF NOT EXISTS headquarters_country VARCHAR(50);
ALTER TABLE api.clients ADD COLUMN IF NOT EXISTS headquarters_timezone VARCHAR(50);
ALTER TABLE api.clients ADD COLUMN IF NOT EXISTS employee_count INTEGER;
ALTER TABLE api.clients ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE api.clients ADD COLUMN IF NOT EXISTS culture_keywords TEXT[];
ALTER TABLE api.clients ADD COLUMN IF NOT EXISTS business_model TEXT;
ALTER TABLE api.clients ADD COLUMN IF NOT EXISTS demo_type VARCHAR(50) DEFAULT 'standard';
ALTER TABLE api.clients ADD COLUMN IF NOT EXISTS demo_complexity VARCHAR(20) DEFAULT 'medium';
ALTER TABLE api.clients ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW();
ALTER TABLE api.clients ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

-- Add trigger for clients updated_at
DROP TRIGGER IF EXISTS update_clients_updated_at ON api.clients;
CREATE TRIGGER update_clients_updated_at BEFORE UPDATE ON api.clients
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Client Offices table
CREATE TABLE IF NOT EXISTS api.client_offices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES api.clients(id) ON DELETE CASCADE,
  office_name VARCHAR(100) NOT NULL,
  city VARCHAR(100) NOT NULL,
  country VARCHAR(50) NOT NULL,
  timezone VARCHAR(50) NOT NULL,
  address TEXT,
  employee_count INTEGER DEFAULT 0,
  office_type VARCHAR(50) DEFAULT 'branch',
  is_active BOOLEAN DEFAULT true,
  opened_date DATE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

DROP TRIGGER IF EXISTS update_client_offices_updated_at ON api.client_offices;
CREATE TRIGGER update_client_offices_updated_at BEFORE UPDATE ON api.client_offices
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Indexes for client_offices
CREATE INDEX IF NOT EXISTS idx_client_offices_client_id ON api.client_offices(client_id);
CREATE INDEX IF NOT EXISTS idx_client_offices_active ON api.client_offices(is_active) WHERE is_active = true;

-- 2. Enhanced Employee Management
-- Add comprehensive demographic columns to employees
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS office_id UUID REFERENCES api.client_offices(id);
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS employee_number VARCHAR(50);
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS title VARCHAR(100);
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS middle_name VARCHAR(100);
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS preferred_name VARCHAR(100);
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS date_of_birth DATE;
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS nationality VARCHAR(50);
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS languages_spoken TEXT[];
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS gender VARCHAR(20);
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS ethnicity VARCHAR(50);
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS education_level VARCHAR(50);
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS university VARCHAR(200);
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS degree_field VARCHAR(100);
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS years_of_experience INTEGER;
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS previous_company VARCHAR(200);
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS emergency_contact_name VARCHAR(200);
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS emergency_contact_phone VARCHAR(50);
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS emergency_contact_relationship VARCHAR(50);
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS work_authorization_status VARCHAR(50);
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS visa_type VARCHAR(50);
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS visa_expiry_date DATE;
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS linkedin_profile VARCHAR(500);
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS skills TEXT[];
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS certifications TEXT[];
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS security_clearance_level VARCHAR(50);
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS is_remote_eligible BOOLEAN DEFAULT false;
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS remote_work_percentage INTEGER DEFAULT 0;
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS cost_center VARCHAR(50);
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS reporting_manager_id UUID REFERENCES api.employees(id);
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS hire_date DATE;
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS probation_end_date DATE;
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS contract_type VARCHAR(50) DEFAULT 'permanent';
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS contract_end_date DATE;
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS salary_currency VARCHAR(3);
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS salary_amount DECIMAL(12,2);
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS salary_frequency VARCHAR(20) DEFAULT 'annual';
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS benefits_eligible BOOLEAN DEFAULT true;
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS stock_options_eligible BOOLEAN DEFAULT false;
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS notice_period_days INTEGER DEFAULT 30;
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW();
ALTER TABLE api.employees ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

-- Add trigger for employees updated_at
DROP TRIGGER IF EXISTS update_employees_updated_at ON api.employees;
CREATE TRIGGER update_employees_updated_at BEFORE UPDATE ON api.employees
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Performance indexes for employees
CREATE INDEX IF NOT EXISTS idx_employees_office_id ON api.employees(office_id);
CREATE INDEX IF NOT EXISTS idx_employees_manager_id ON api.employees(reporting_manager_id);
CREATE INDEX IF NOT EXISTS idx_employees_hire_date ON api.employees(hire_date);
CREATE INDEX IF NOT EXISTS idx_employees_status_location ON api.employees(status, office_id);

-- Employee Process History table
CREATE TABLE IF NOT EXISTS api.employee_process_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID REFERENCES api.employees(id) ON DELETE CASCADE,
  process_type VARCHAR(50) NOT NULL,
  process_status VARCHAR(50) NOT NULL,
  start_date DATE NOT NULL,
  expected_completion_date DATE,
  actual_completion_date DATE,
  complexity_level VARCHAR(20) DEFAULT 'standard',
  assigned_hr_contact_id UUID REFERENCES api.employees(id),
  process_notes TEXT,
  completion_percentage INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

DROP TRIGGER IF EXISTS update_employee_process_history_updated_at ON api.employee_process_history;
CREATE TRIGGER update_employee_process_history_updated_at BEFORE UPDATE ON api.employee_process_history
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX IF NOT EXISTS idx_employee_process_history_employee ON api.employee_process_history(employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_process_history_status ON api.employee_process_history(process_status);
CREATE INDEX IF NOT EXISTS idx_employee_process_history_active ON api.employee_process_history(process_status, start_date);

-- 3. Enhanced Document Management
-- Document Templates table
CREATE TABLE IF NOT EXISTS api.document_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES api.clients(id) ON DELETE CASCADE,
  template_name VARCHAR(200) NOT NULL,
  template_category VARCHAR(100) NOT NULL,
  template_subcategory VARCHAR(100),
  document_type VARCHAR(100) NOT NULL,
  applicable_regions TEXT[],
  applicable_roles TEXT[],
  complexity_level VARCHAR(20) DEFAULT 'standard',
  is_mandatory BOOLEAN DEFAULT false,
  requires_signature BOOLEAN DEFAULT false,
  requires_witness BOOLEAN DEFAULT false,
  requires_notarization BOOLEAN DEFAULT false,
  template_content TEXT,
  instructions TEXT,
  estimated_completion_minutes INTEGER,
  legal_review_required BOOLEAN DEFAULT false,
  version_number VARCHAR(20) DEFAULT '1.0',
  is_active BOOLEAN DEFAULT true,
  effective_date DATE DEFAULT CURRENT_DATE,
  expiry_date DATE,
  created_by UUID REFERENCES api.employees(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

DROP TRIGGER IF EXISTS update_document_templates_updated_at ON api.document_templates;
CREATE TRIGGER update_document_templates_updated_at BEFORE UPDATE ON api.document_templates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX IF NOT EXISTS idx_document_templates_client ON api.document_templates(client_id);
CREATE INDEX IF NOT EXISTS idx_document_templates_category ON api.document_templates(template_category, is_active);
CREATE INDEX IF NOT EXISTS idx_document_templates_mandatory ON api.document_templates(is_mandatory) WHERE is_mandatory = true;

-- Enhance existing documents table
ALTER TABLE api.documents ADD COLUMN IF NOT EXISTS template_id UUID REFERENCES api.document_templates(id);
ALTER TABLE api.documents ADD COLUMN IF NOT EXISTS process_history_id UUID REFERENCES api.employee_process_history(id);
ALTER TABLE api.documents ADD COLUMN IF NOT EXISTS document_category VARCHAR(100);
ALTER TABLE api.documents ADD COLUMN IF NOT EXISTS document_subcategory VARCHAR(100);
ALTER TABLE api.documents ADD COLUMN IF NOT EXISTS priority_level VARCHAR(20) DEFAULT 'normal';
ALTER TABLE api.documents ADD COLUMN IF NOT EXISTS due_date DATE;
ALTER TABLE api.documents ADD COLUMN IF NOT EXISTS assigned_to_id UUID REFERENCES api.employees(id);
ALTER TABLE api.documents ADD COLUMN IF NOT EXISTS completed_by_id UUID REFERENCES api.employees(id);
ALTER TABLE api.documents ADD COLUMN IF NOT EXISTS completion_date TIMESTAMP;
ALTER TABLE api.documents ADD COLUMN IF NOT EXISTS requires_review BOOLEAN DEFAULT false;
ALTER TABLE api.documents ADD COLUMN IF NOT EXISTS reviewed_by_id UUID REFERENCES api.employees(id);
ALTER TABLE api.documents ADD COLUMN IF NOT EXISTS review_date TIMESTAMP;
ALTER TABLE api.documents ADD COLUMN IF NOT EXISTS review_notes TEXT;
ALTER TABLE api.documents ADD COLUMN IF NOT EXISTS file_path VARCHAR(500);
ALTER TABLE api.documents ADD COLUMN IF NOT EXISTS file_size_bytes BIGINT;
ALTER TABLE api.documents ADD COLUMN IF NOT EXISTS file_type VARCHAR(50);
ALTER TABLE api.documents ADD COLUMN IF NOT EXISTS digital_signature_hash VARCHAR(255);
ALTER TABLE api.documents ADD COLUMN IF NOT EXISTS is_confidential BOOLEAN DEFAULT false;
ALTER TABLE api.documents ADD COLUMN IF NOT EXISTS retention_period_years INTEGER;
ALTER TABLE api.documents ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW();
ALTER TABLE api.documents ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

DROP TRIGGER IF EXISTS update_documents_updated_at ON api.documents;
CREATE TRIGGER update_documents_updated_at BEFORE UPDATE ON api.documents
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX IF NOT EXISTS idx_documents_template ON api.documents(template_id);
CREATE INDEX IF NOT EXISTS idx_documents_process ON api.documents(process_history_id);
CREATE INDEX IF NOT EXISTS idx_documents_assigned ON api.documents(assigned_to_id, status);
CREATE INDEX IF NOT EXISTS idx_documents_due_date ON api.documents(due_date) WHERE due_date IS NOT NULL;

-- 4. Enhanced Task Management
-- Task Templates table
CREATE TABLE IF NOT EXISTS api.task_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES api.clients(id) ON DELETE CASCADE,
  template_name VARCHAR(200) NOT NULL,
  template_description TEXT,
  task_category VARCHAR(100) NOT NULL,
  process_type VARCHAR(50) NOT NULL,
  applicable_roles TEXT[],
  applicable_levels TEXT[],
  estimated_duration_hours DECIMAL(5,2),
  is_mandatory BOOLEAN DEFAULT true,
  sequence_order INTEGER,
  dependencies TEXT[],
  instructions TEXT,
  success_criteria TEXT,
  resources_needed TEXT[],
  assigned_role VARCHAR(100),
  automation_possible BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES api.employees(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

DROP TRIGGER IF EXISTS update_task_templates_updated_at ON api.task_templates;
CREATE TRIGGER update_task_templates_updated_at BEFORE UPDATE ON api.task_templates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX IF NOT EXISTS idx_task_templates_client ON api.task_templates(client_id);
CREATE INDEX IF NOT EXISTS idx_task_templates_category ON api.task_templates(task_category, process_type);
CREATE INDEX IF NOT EXISTS idx_task_templates_sequence ON api.task_templates(sequence_order);

-- Workflow Templates table
CREATE TABLE IF NOT EXISTS api.workflow_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES api.clients(id) ON DELETE CASCADE,
  workflow_name VARCHAR(200) NOT NULL,
  workflow_description TEXT,
  process_type VARCHAR(50) NOT NULL,
  complexity_level VARCHAR(20) DEFAULT 'standard',
  applicable_roles TEXT[],
  applicable_levels TEXT[],
  estimated_total_days INTEGER,
  is_default BOOLEAN DEFAULT false,
  task_template_ids UUID[],
  document_template_ids UUID[],
  milestone_definitions JSONB,
  escalation_rules JSONB,
  approval_requirements JSONB,
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES api.employees(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

DROP TRIGGER IF EXISTS update_workflow_templates_updated_at ON api.workflow_templates;
CREATE TRIGGER update_workflow_templates_updated_at BEFORE UPDATE ON api.workflow_templates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX IF NOT EXISTS idx_workflow_templates_client ON api.workflow_templates(client_id);
CREATE INDEX IF NOT EXISTS idx_workflow_templates_process ON api.workflow_templates(process_type, complexity_level);
CREATE INDEX IF NOT EXISTS idx_workflow_templates_default ON api.workflow_templates(is_default) WHERE is_default = true;

-- Enhance existing tasks table
ALTER TABLE api.tasks ADD COLUMN IF NOT EXISTS template_id UUID REFERENCES api.task_templates(id);
ALTER TABLE api.tasks ADD COLUMN IF NOT EXISTS process_history_id UUID REFERENCES api.employee_process_history(id);
ALTER TABLE api.tasks ADD COLUMN IF NOT EXISTS workflow_template_id UUID REFERENCES api.workflow_templates(id);
ALTER TABLE api.tasks ADD COLUMN IF NOT EXISTS parent_task_id UUID REFERENCES api.tasks(id);
ALTER TABLE api.tasks ADD COLUMN IF NOT EXISTS sequence_order INTEGER;
ALTER TABLE api.tasks ADD COLUMN IF NOT EXISTS estimated_hours DECIMAL(5,2);
ALTER TABLE api.tasks ADD COLUMN IF NOT EXISTS actual_hours DECIMAL(5,2);
ALTER TABLE api.tasks ADD COLUMN IF NOT EXISTS depends_on_task_ids UUID[];
ALTER TABLE api.tasks ADD COLUMN IF NOT EXISTS blocking_task_ids UUID[];
ALTER TABLE api.tasks ADD COLUMN IF NOT EXISTS milestone_name VARCHAR(100);
ALTER TABLE api.tasks ADD COLUMN IF NOT EXISTS automation_status VARCHAR(50) DEFAULT 'manual';
ALTER TABLE api.tasks ADD COLUMN IF NOT EXISTS escalation_level INTEGER DEFAULT 0;
ALTER TABLE api.tasks ADD COLUMN IF NOT EXISTS escalated_to_id UUID REFERENCES api.employees(id);
ALTER TABLE api.tasks ADD COLUMN IF NOT EXISTS escalation_date TIMESTAMP;
ALTER TABLE api.tasks ADD COLUMN IF NOT EXISTS resources_needed TEXT[];
ALTER TABLE api.tasks ADD COLUMN IF NOT EXISTS completion_notes TEXT;
ALTER TABLE api.tasks ADD COLUMN IF NOT EXISTS quality_score INTEGER;
ALTER TABLE api.tasks ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW();
ALTER TABLE api.tasks ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

DROP TRIGGER IF EXISTS update_tasks_updated_at ON api.tasks;
CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON api.tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX IF NOT EXISTS idx_tasks_template ON api.tasks(template_id);
CREATE INDEX IF NOT EXISTS idx_tasks_process ON api.tasks(process_history_id);
CREATE INDEX IF NOT EXISTS idx_tasks_workflow ON api.tasks(workflow_template_id);
CREATE INDEX IF NOT EXISTS idx_tasks_dependencies ON api.tasks USING GIN(depends_on_task_ids);
CREATE INDEX IF NOT EXISTS idx_tasks_milestone ON api.tasks(milestone_name) WHERE milestone_name IS NOT NULL;

-- 5. Performance & Analytics Tables
-- Process Metrics table
CREATE TABLE IF NOT EXISTS api.process_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES api.clients(id) ON DELETE CASCADE,
  process_history_id UUID REFERENCES api.employee_process_history(id) ON DELETE CASCADE,
  metric_date DATE NOT NULL,
  total_tasks INTEGER DEFAULT 0,
  completed_tasks INTEGER DEFAULT 0,
  overdue_tasks INTEGER DEFAULT 0,
  total_documents INTEGER DEFAULT 0,
  completed_documents INTEGER DEFAULT 0,
  pending_review_documents INTEGER DEFAULT 0,
  average_task_completion_hours DECIMAL(8,2),
  employee_satisfaction_score INTEGER,
  hr_efficiency_score INTEGER,
  process_complexity_actual VARCHAR(20),
  issues_encountered INTEGER DEFAULT 0,
  escalations_required INTEGER DEFAULT 0,
  cost_estimate DECIMAL(10,2),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_process_metrics_client_date ON api.process_metrics(client_id, metric_date);
CREATE INDEX IF NOT EXISTS idx_process_metrics_process ON api.process_metrics(process_history_id);

-- System Analytics table
CREATE TABLE IF NOT EXISTS api.system_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES api.clients(id) ON DELETE CASCADE,
  analytics_date DATE NOT NULL,
  active_processes INTEGER DEFAULT 0,
  completed_processes_mtd INTEGER DEFAULT 0,
  average_onboarding_days DECIMAL(5,2),
  average_offboarding_days DECIMAL(5,2),
  document_template_usage JSONB,
  task_template_performance JSONB,
  user_adoption_metrics JSONB,
  system_performance_metrics JSONB,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_system_analytics_client_date ON api.system_analytics(client_id, analytics_date);

-- 6. Useful Views
-- Employee Summary View
CREATE OR REPLACE VIEW api.employee_summary AS
SELECT 
  e.*,
  o.office_name,
  o.city as office_city,
  o.country as office_country,
  m.first_name as manager_first_name,
  m.last_name as manager_last_name,
  ph.process_type as current_process_type,
  ph.process_status as current_process_status,
  ph.completion_percentage
FROM api.employees e
LEFT JOIN api.client_offices o ON e.office_id = o.id
LEFT JOIN api.employees m ON e.reporting_manager_id = m.id
LEFT JOIN api.employee_process_history ph ON e.id = ph.employee_id 
  AND ph.process_status = 'active';

-- Process Dashboard View
CREATE OR REPLACE VIEW api.process_dashboard AS
SELECT 
  c.id as client_id,
  c.legal_name as client_name,
  COUNT(ph.*) as total_active_processes,
  COUNT(ph.*) FILTER (WHERE ph.process_type = 'onboarding') as active_onboarding,
  COUNT(ph.*) FILTER (WHERE ph.process_type = 'offboarding') as active_offboarding,
  AVG(ph.completion_percentage) as avg_completion,
  COUNT(t.*) FILTER (WHERE t.status = 'pending') as pending_tasks,
  COUNT(d.*) FILTER (WHERE d.status = 'pending') as pending_documents
FROM api.clients c
LEFT JOIN api.employees emp ON emp.client_id = c.id
LEFT JOIN api.employee_process_history ph ON emp.id = ph.employee_id AND ph.process_status = 'active'
LEFT JOIN api.tasks t ON ph.id = t.process_history_id AND t.status = 'pending'
LEFT JOIN api.documents d ON ph.id = d.process_history_id AND d.status = 'pending'
GROUP BY c.id, c.legal_name;