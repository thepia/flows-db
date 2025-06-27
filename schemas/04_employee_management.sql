-- =====================================================
-- EMPLOYEE MANAGEMENT TABLES - Demo Data Support
-- =====================================================
-- 
-- Purpose: Extended tables to support rich demo data
-- Context: Employee lifecycle tracking beyond basic invitations
-- Dependencies: clients, client_applications tables

-- Set schema context
SET search_path TO api, public;

-- =====================================================
-- EMPLOYEES TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS api.employees (
  -- Primary identifier
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Client relationship
  client_id UUID NOT NULL REFERENCES api.clients(id) ON DELETE CASCADE,
  
  -- Employee identification (using demo IDs for consistency)
  employee_code VARCHAR(50) UNIQUE NOT NULL,
  
  -- Personal information (minimal - most PII in encrypted invitations)
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  company_email VARCHAR(255) UNIQUE NOT NULL,
  
  -- Work information
  department VARCHAR(100) NOT NULL,
  position VARCHAR(150) NOT NULL,
  location VARCHAR(150) NOT NULL,
  manager VARCHAR(150),
  
  -- Employment details
  start_date DATE,
  end_date DATE,
  employment_type VARCHAR(50) DEFAULT 'full_time' CHECK (employment_type IN ('full_time', 'part_time', 'contractor', 'intern')),
  work_location VARCHAR(50) DEFAULT 'office' CHECK (work_location IN ('office', 'remote', 'hybrid')),
  
  -- Status tracking
  status VARCHAR(50) DEFAULT 'invited' CHECK (status IN ('invited', 'pending', 'active', 'offboarding_initiated', 'offboarded')),
  security_clearance VARCHAR(20) DEFAULT 'low' CHECK (security_clearance IN ('low', 'medium', 'high')),
  
  -- Metadata
  skills JSONB DEFAULT '[]',
  languages JSONB DEFAULT '[]',
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_activity TIMESTAMP WITH TIME ZONE,
  
  -- Constraints
  CONSTRAINT valid_employee_code CHECK (employee_code ~ '^[a-z0-9-]+$'),
  CONSTRAINT valid_company_email CHECK (company_email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- =====================================================
-- EMPLOYEE ENROLLMENTS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS api.employee_enrollments (
  -- Primary identifier
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Employee relationship
  employee_id UUID NOT NULL REFERENCES api.employees(id) ON DELETE CASCADE,
  
  -- Onboarding tracking
  onboarding_completed BOOLEAN DEFAULT FALSE,
  completion_date TIMESTAMP WITH TIME ZONE,
  completion_percentage INTEGER DEFAULT 0 CHECK (completion_percentage >= 0 AND completion_percentage <= 100),
  
  -- Mentoring
  mentor VARCHAR(150),
  buddy_program BOOLEAN DEFAULT FALSE,
  
  -- Offboarding tracking
  offboarding_initiated BOOLEAN DEFAULT FALSE,
  offboarding_completed BOOLEAN DEFAULT FALSE,
  offboarding_reason VARCHAR(100),
  offboarding_initiated_date TIMESTAMP WITH TIME ZONE,
  offboarding_completion_date TIMESTAMP WITH TIME ZONE,
  new_position TEXT,
  exit_interview_completed BOOLEAN DEFAULT FALSE,
  knowledge_transfer_completed BOOLEAN DEFAULT FALSE,
  equipment_returned BOOLEAN DEFAULT FALSE,
  access_revoked BOOLEAN DEFAULT FALSE,
  final_payroll BOOLEAN DEFAULT FALSE,
  
  -- Activity tracking
  last_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- DOCUMENTS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS api.documents (
  -- Primary identifier
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Employee relationship
  employee_id UUID NOT NULL REFERENCES api.employees(id) ON DELETE CASCADE,
  
  -- Document details
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50) NOT NULL CHECK (type IN ('contract', 'id_verification', 'tax_form', 'handbook', 'gdpr_consent', 'financial_disclosure', 'resignation_letter', 'knowledge_transfer', 'equipment_return', 'termination_notice', 'other')),
  
  -- Status tracking
  status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'uploaded', 'verified', 'rejected')),
  
  -- Review information
  uploaded_at TIMESTAMP WITH TIME ZONE,
  reviewed_at TIMESTAMP WITH TIME ZONE,
  reviewed_by VARCHAR(150),
  comments TEXT,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- TASKS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS api.tasks (
  -- Primary identifier
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Employee relationship
  employee_id UUID NOT NULL REFERENCES api.employees(id) ON DELETE CASCADE,
  
  -- Task details
  title VARCHAR(255) NOT NULL,
  description TEXT,
  category VARCHAR(50) NOT NULL CHECK (category IN ('onboarding', 'training', 'compliance', 'equipment', 'networking', 'knowledge_transfer', 'security', 'other')),
  
  -- Status and priority
  status VARCHAR(50) DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'completed', 'overdue')),
  priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
  
  -- Assignment and scheduling
  assigned_by VARCHAR(150) NOT NULL,
  assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  due_date TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- INDEXES
-- =====================================================

-- Employees indexes
CREATE INDEX IF NOT EXISTS idx_employees_client_id ON employees(client_id);
CREATE INDEX IF NOT EXISTS idx_employees_employee_code ON employees(employee_code);
CREATE INDEX IF NOT EXISTS idx_employees_status ON employees(status);
CREATE INDEX IF NOT EXISTS idx_employees_department ON employees(department);
CREATE INDEX IF NOT EXISTS idx_employees_company_email ON employees(company_email);

-- Employee enrollments indexes
CREATE INDEX IF NOT EXISTS idx_employee_enrollments_employee_id ON employee_enrollments(employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_enrollments_onboarding_completed ON employee_enrollments(onboarding_completed);
CREATE INDEX IF NOT EXISTS idx_employee_enrollments_offboarding_initiated ON employee_enrollments(offboarding_initiated);

-- Documents indexes
CREATE INDEX IF NOT EXISTS idx_documents_employee_id ON documents(employee_id);
CREATE INDEX IF NOT EXISTS idx_documents_type ON documents(type);
CREATE INDEX IF NOT EXISTS idx_documents_status ON documents(status);

-- Tasks indexes
CREATE INDEX IF NOT EXISTS idx_tasks_employee_id ON tasks(employee_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_category ON tasks(category);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Update timestamp triggers
CREATE OR REPLACE FUNCTION update_employee_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_employees_updated_at ON employees;
CREATE TRIGGER trigger_employees_updated_at
  BEFORE UPDATE ON employees
  FOR EACH ROW
  EXECUTE FUNCTION update_employee_updated_at();

DROP TRIGGER IF EXISTS trigger_employee_enrollments_updated_at ON employee_enrollments;
CREATE TRIGGER trigger_employee_enrollments_updated_at
  BEFORE UPDATE ON employee_enrollments
  FOR EACH ROW
  EXECUTE FUNCTION update_employee_updated_at();

DROP TRIGGER IF EXISTS trigger_documents_updated_at ON documents;
CREATE TRIGGER trigger_documents_updated_at
  BEFORE UPDATE ON documents
  FOR EACH ROW
  EXECUTE FUNCTION update_employee_updated_at();

DROP TRIGGER IF EXISTS trigger_tasks_updated_at ON tasks;
CREATE TRIGGER trigger_tasks_updated_at
  BEFORE UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_employee_updated_at();

-- Auto-update completion percentage based on tasks
CREATE OR REPLACE FUNCTION update_completion_percentage()
RETURNS TRIGGER AS $$
DECLARE
  total_tasks INTEGER;
  completed_tasks INTEGER;
  new_percentage INTEGER;
BEGIN
  -- Count total and completed tasks for the employee
  SELECT COUNT(*) INTO total_tasks
  FROM tasks
  WHERE employee_id = COALESCE(NEW.employee_id, OLD.employee_id);
  
  SELECT COUNT(*) INTO completed_tasks
  FROM tasks
  WHERE employee_id = COALESCE(NEW.employee_id, OLD.employee_id)
    AND status = 'completed';
  
  -- Calculate percentage
  IF total_tasks > 0 THEN
    new_percentage := ROUND((completed_tasks::DECIMAL / total_tasks) * 100);
  ELSE
    new_percentage := 0;
  END IF;
  
  -- Update enrollment record
  UPDATE employee_enrollments
  SET 
    completion_percentage = new_percentage,
    onboarding_completed = (new_percentage >= 95),
    completion_date = CASE 
      WHEN new_percentage >= 95 AND onboarding_completed = FALSE THEN NOW()
      ELSE completion_date
    END,
    last_activity = NOW(),
    updated_at = NOW()
  WHERE employee_id = COALESCE(NEW.employee_id, OLD.employee_id);
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_completion_percentage ON tasks;
CREATE TRIGGER trigger_update_completion_percentage
  AFTER INSERT OR UPDATE OR DELETE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_completion_percentage();

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Staff access policies
DROP POLICY IF EXISTS policy_employees_staff_access ON employees;
CREATE POLICY policy_employees_staff_access ON employees
  FOR ALL 
  USING (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

DROP POLICY IF EXISTS policy_employee_enrollments_staff_access ON employee_enrollments;
CREATE POLICY policy_employee_enrollments_staff_access ON employee_enrollments
  FOR ALL 
  USING (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

DROP POLICY IF EXISTS policy_documents_staff_access ON documents;
CREATE POLICY policy_documents_staff_access ON documents
  FOR ALL 
  USING (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

DROP POLICY IF EXISTS policy_tasks_staff_access ON tasks;
CREATE POLICY policy_tasks_staff_access ON tasks
  FOR ALL 
  USING (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

-- Client-specific access policies
DROP POLICY IF EXISTS policy_employees_client_access ON employees;
CREATE POLICY policy_employees_client_access ON employees
  FOR ALL
  USING (
    client_id::text = auth.jwt()->>'client_id'
    OR EXISTS (
      SELECT 1 FROM api.clients 
      WHERE clients.id = employees.client_id 
        AND clients.client_code = auth.jwt()->>'client_code'
    )
  );

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to get employee with enrollment data
CREATE OR REPLACE FUNCTION get_employee_with_enrollment(p_employee_id UUID)
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'employee', to_jsonb(e.*),
    'enrollment', to_jsonb(en.*),
    'documents', COALESCE(docs.documents, '[]'::jsonb),
    'tasks', COALESCE(tasks.tasks, '[]'::jsonb)
  ) INTO result
  FROM employees e
  LEFT JOIN employee_enrollments en ON en.employee_id = e.id
  LEFT JOIN (
    SELECT 
      employee_id,
      jsonb_agg(to_jsonb(d.*)) as documents
    FROM documents d
    GROUP BY employee_id
  ) docs ON docs.employee_id = e.id
  LEFT JOIN (
    SELECT 
      employee_id,
      jsonb_agg(to_jsonb(t.*)) as tasks
    FROM tasks t
    GROUP BY employee_id
  ) tasks ON tasks.employee_id = e.id
  WHERE e.id = p_employee_id;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- VIEWS
-- =====================================================

-- Employee dashboard view
CREATE OR REPLACE VIEW employee_dashboard AS
SELECT 
  e.id,
  e.employee_code,
  e.first_name,
  e.last_name,
  e.company_email,
  e.department,
  e.position,
  e.location,
  e.status,
  e.start_date,
  en.onboarding_completed,
  en.completion_percentage,
  en.last_activity,
  c.client_code,
  c.legal_name as client_name
FROM employees e
LEFT JOIN employee_enrollments en ON en.employee_id = e.id
JOIN clients c ON c.id = e.client_id
WHERE e.status != 'offboarded' OR e.updated_at > NOW() - INTERVAL '30 days'
ORDER BY e.created_at DESC;

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE employees IS 'Employee master data for demo scenarios';
COMMENT ON TABLE employee_enrollments IS 'Employee onboarding and offboarding progress tracking';
COMMENT ON TABLE documents IS 'Document upload and verification tracking';
COMMENT ON TABLE tasks IS 'Task assignment and completion tracking';

COMMENT ON COLUMN employees.employee_code IS 'Unique employee identifier for demo consistency';
COMMENT ON COLUMN employee_enrollments.completion_percentage IS 'Calculated from completed tasks percentage';
COMMENT ON COLUMN documents.type IS 'Document category for workflow routing';
COMMENT ON COLUMN tasks.category IS 'Task category for organization and reporting';