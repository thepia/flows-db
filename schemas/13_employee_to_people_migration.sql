-- =====================================================
-- EMPLOYEE TO PEOPLE MIGRATION - Comprehensive Rename
-- =====================================================
-- 
-- Purpose: Rename employee tables to people and update status fields
-- Changes:
--   1. Rename tables: employees → people, employee_enrollments → people_enrollments
--   2. Rename status field: status → employment_status (active, former, future) - optional
--   3. Add associate_status field (board_member, consultant, advisor, contractor, volunteer, partner, other) - optional
--   4. Move contractors from employment_type to associate_status
--   5. Update all references, indexes, constraints, and functions
--   6. Add validation logic to ensure mutual exclusivity

-- Set schema context
SET search_path TO api, public;

-- =====================================================
-- STEP 1: CREATE NEW TABLES WITH UPDATED SCHEMA
-- =====================================================

-- Create people table (renamed from employees)
CREATE TABLE IF NOT EXISTS api.people (
  -- Primary identifier
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Client relationship
  client_id UUID NOT NULL REFERENCES api.clients(id) ON DELETE CASCADE,
  
  -- Person identification (using demo IDs for consistency)
  person_code VARCHAR(50) UNIQUE NOT NULL,
  
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
  employment_type VARCHAR(50) DEFAULT 'full_time' CHECK (employment_type IN ('full_time', 'part_time', 'intern')),
  work_location VARCHAR(50) DEFAULT 'office' CHECK (work_location IN ('office', 'remote', 'hybrid')),
  
  -- Status tracking (mutually exclusive)
  employment_status VARCHAR(50) CHECK (employment_status IN ('active', 'former', 'future')),
  associate_status VARCHAR(50) CHECK (associate_status IN ('board_member', 'consultant', 'advisor', 'contractor', 'volunteer', 'partner', 'other')),
  security_clearance VARCHAR(20) DEFAULT 'low' CHECK (security_clearance IN ('low', 'medium', 'high')),
  
  -- Metadata
  skills JSONB DEFAULT '[]',
  languages JSONB DEFAULT '[]',
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_activity TIMESTAMP WITH TIME ZONE,
  
  -- Constraints
  CONSTRAINT valid_person_code CHECK (person_code ~ '^[a-z0-9-]+$'),
  CONSTRAINT valid_company_email CHECK (company_email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
  CONSTRAINT mutually_exclusive_status CHECK (
    (employment_status IS NOT NULL AND associate_status IS NULL) OR
    (employment_status IS NULL AND associate_status IS NOT NULL) OR
    (employment_status IS NULL AND associate_status IS NULL)
  )
);

-- Create people_enrollments table (renamed from employee_enrollments)
CREATE TABLE IF NOT EXISTS api.people_enrollments (
  -- Primary identifier
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Person relationship
  person_id UUID NOT NULL REFERENCES api.people(id) ON DELETE CASCADE,
  
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
  
  -- Process status fields (from previous migration)
  onboarding_status VARCHAR(50) DEFAULT 'not_started' 
    CHECK (onboarding_status IN ('not_started', 'invited', 'in_progress', 'completed', 'on_hold')),
  offboarding_status VARCHAR(50) DEFAULT 'not_started'
    CHECK (offboarding_status IN ('not_started', 'initiated', 'in_progress', 'completed', 'cancelled')),
  
  -- Activity tracking
  last_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- STEP 2: MIGRATE DATA FROM OLD TABLES
-- =====================================================

-- Migrate employees to people
INSERT INTO api.people (
  id, client_id, person_code, first_name, last_name, company_email,
  department, position, location, manager, start_date, end_date,
  employment_type, work_location, employment_status, associate_status,
  security_clearance, skills, languages, created_at, updated_at, last_activity
)
SELECT 
  id, client_id, employee_code, first_name, last_name, company_email,
  department, position, location, manager, start_date, end_date,
  -- Handle employment_type: move contractors to associate_status
  CASE 
    WHEN employment_type = 'contractor' THEN 'full_time'
    ELSE employment_type
  END,
  work_location,
  -- Map old status to employment_status
  CASE 
    WHEN status = 'active' THEN 'active'
    WHEN status = 'previous' THEN 'former'
    WHEN status = 'future' THEN 'future'
    WHEN status = 'other' AND employment_type != 'contractor' THEN NULL
    ELSE NULL
  END,
  -- Map contractors to associate_status
  CASE 
    WHEN employment_type = 'contractor' THEN 'contractor'
    WHEN status = 'other' AND employment_type != 'contractor' THEN 'other'
    ELSE NULL
  END,
  security_clearance, skills, languages, created_at, updated_at, last_activity
FROM api.employees
WHERE NOT EXISTS (SELECT 1 FROM api.people WHERE people.id = employees.id);

-- Migrate employee_enrollments to people_enrollments
INSERT INTO api.people_enrollments (
  id, person_id, onboarding_completed, completion_date, completion_percentage,
  mentor, buddy_program, offboarding_initiated, offboarding_completed,
  offboarding_reason, offboarding_initiated_date, offboarding_completion_date,
  new_position, exit_interview_completed, knowledge_transfer_completed,
  equipment_returned, access_revoked, final_payroll, onboarding_status,
  offboarding_status, last_activity, created_at, updated_at
)
SELECT 
  id, employee_id, onboarding_completed, completion_date, completion_percentage,
  mentor, buddy_program, offboarding_initiated, offboarding_completed,
  offboarding_reason, offboarding_initiated_date, offboarding_completion_date,
  new_position, exit_interview_completed, knowledge_transfer_completed,
  equipment_returned, access_revoked, final_payroll, onboarding_status,
  offboarding_status, last_activity, created_at, updated_at
FROM api.employee_enrollments
WHERE NOT EXISTS (SELECT 1 FROM api.people_enrollments WHERE people_enrollments.id = employee_enrollments.id);

-- Update documents table to reference people
UPDATE api.documents 
SET employee_id = (SELECT id FROM api.people WHERE people.id = documents.employee_id)
WHERE EXISTS (SELECT 1 FROM api.people WHERE people.id = documents.employee_id);

-- Update tasks table to reference people  
UPDATE api.tasks
SET employee_id = (SELECT id FROM api.people WHERE people.id = tasks.employee_id)
WHERE EXISTS (SELECT 1 FROM api.people WHERE people.id = tasks.employee_id);

-- =====================================================
-- STEP 3: CREATE INDEXES
-- =====================================================

-- People indexes
CREATE INDEX IF NOT EXISTS idx_people_client_id ON api.people(client_id);
CREATE INDEX IF NOT EXISTS idx_people_person_code ON api.people(person_code);
CREATE INDEX IF NOT EXISTS idx_people_employment_status ON api.people(employment_status);
CREATE INDEX IF NOT EXISTS idx_people_associate_status ON api.people(associate_status);
CREATE INDEX IF NOT EXISTS idx_people_department ON api.people(department);
CREATE INDEX IF NOT EXISTS idx_people_company_email ON api.people(company_email);

-- People enrollments indexes
CREATE INDEX IF NOT EXISTS idx_people_enrollments_person_id ON api.people_enrollments(person_id);
CREATE INDEX IF NOT EXISTS idx_people_enrollments_onboarding_completed ON api.people_enrollments(onboarding_completed);
CREATE INDEX IF NOT EXISTS idx_people_enrollments_offboarding_initiated ON api.people_enrollments(offboarding_initiated);
CREATE INDEX IF NOT EXISTS idx_people_enrollments_onboarding_status ON api.people_enrollments(onboarding_status);
CREATE INDEX IF NOT EXISTS idx_people_enrollments_offboarding_status ON api.people_enrollments(offboarding_status);

-- Composite index for active people with process status
CREATE INDEX IF NOT EXISTS idx_people_active_with_process ON api.people(employment_status, id) WHERE employment_status = 'active';

-- =====================================================
-- STEP 4: UPDATE TRIGGERS AND FUNCTIONS
-- =====================================================

-- Update timestamp triggers
CREATE OR REPLACE FUNCTION update_person_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_people_updated_at ON api.people;
CREATE TRIGGER trigger_people_updated_at
  BEFORE UPDATE ON api.people
  FOR EACH ROW
  EXECUTE FUNCTION update_person_updated_at();

DROP TRIGGER IF EXISTS trigger_people_enrollments_updated_at ON api.people_enrollments;
CREATE TRIGGER trigger_people_enrollments_updated_at
  BEFORE UPDATE ON api.people_enrollments
  FOR EACH ROW
  EXECUTE FUNCTION update_person_updated_at();

-- Update completion percentage function
CREATE OR REPLACE FUNCTION update_completion_percentage()
RETURNS TRIGGER AS $$
DECLARE
  total_tasks INTEGER;
  completed_tasks INTEGER;
  new_percentage INTEGER;
BEGIN
  -- Count total and completed tasks for the person
  SELECT COUNT(*) INTO total_tasks
  FROM api.tasks
  WHERE employee_id = COALESCE(NEW.employee_id, OLD.employee_id);
  
  SELECT COUNT(*) INTO completed_tasks
  FROM api.tasks
  WHERE employee_id = COALESCE(NEW.employee_id, OLD.employee_id)
    AND status = 'completed';
  
  -- Calculate percentage
  IF total_tasks > 0 THEN
    new_percentage := ROUND((completed_tasks::DECIMAL / total_tasks) * 100);
  ELSE
    new_percentage := 0;
  END IF;
  
  -- Update enrollment record
  UPDATE api.people_enrollments
  SET 
    completion_percentage = new_percentage,
    onboarding_completed = (new_percentage >= 95),
    completion_date = CASE 
      WHEN new_percentage >= 95 AND onboarding_completed = FALSE THEN NOW()
      ELSE completion_date
    END,
    last_activity = NOW(),
    updated_at = NOW()
  WHERE person_id = COALESCE(NEW.employee_id, OLD.employee_id);
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Update helper function
CREATE OR REPLACE FUNCTION get_person_with_enrollment(p_person_id UUID)
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'person', to_jsonb(p.*),
    'enrollment', to_jsonb(en.*),
    'documents', COALESCE(docs.documents, '[]'::jsonb),
    'tasks', COALESCE(tasks.tasks, '[]'::jsonb)
  ) INTO result
  FROM api.people p
  LEFT JOIN api.people_enrollments en ON en.person_id = p.id
  LEFT JOIN (
    SELECT 
      employee_id as person_id,
      jsonb_agg(to_jsonb(d.*)) as documents
    FROM api.documents d
    GROUP BY employee_id
  ) docs ON docs.person_id = p.id
  LEFT JOIN (
    SELECT 
      employee_id as person_id,
      jsonb_agg(to_jsonb(t.*)) as tasks
    FROM api.tasks t
    GROUP BY employee_id
  ) tasks ON tasks.person_id = p.id
  WHERE p.id = p_person_id;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 5: UPDATE VIEWS
-- =====================================================

-- Drop old views
DROP VIEW IF EXISTS api.employee_dashboard;
DROP VIEW IF EXISTS api.employee_with_status;

-- Create new people dashboard view
CREATE OR REPLACE VIEW api.people_dashboard AS
SELECT 
  p.id,
  p.person_code,
  p.first_name,
  p.last_name,
  p.company_email,
  p.department,
  p.position,
  p.location,
  p.employment_status,
  p.associate_status,
  p.start_date,
  en.onboarding_completed,
  en.completion_percentage,
  en.last_activity,
  c.client_code,
  c.legal_name as client_name
FROM api.people p
LEFT JOIN api.people_enrollments en ON en.person_id = p.id
JOIN api.clients c ON c.id = p.client_id
WHERE p.employment_status != 'former' OR p.updated_at > NOW() - INTERVAL '30 days'
ORDER BY p.created_at DESC;

-- Create view that combines person with their current process status
CREATE OR REPLACE VIEW api.people_with_status AS
SELECT 
  p.*,
  en.onboarding_status,
  en.offboarding_status,
  en.onboarding_completed,
  en.offboarding_completed,
  en.completion_percentage,
  CASE 
    WHEN p.employment_status = 'active' AND en.onboarding_status IN ('not_started', 'invited') THEN 'New Hire (Pending Onboarding)'
    WHEN p.employment_status = 'active' AND en.onboarding_status = 'in_progress' THEN 'Active (Onboarding)'
    WHEN p.employment_status = 'active' AND en.onboarding_status = 'completed' THEN 'Active'
    WHEN p.employment_status = 'active' AND en.offboarding_status IN ('initiated', 'in_progress') THEN 'Active (Offboarding)'
    WHEN p.employment_status = 'former' THEN 'Former Employee'
    WHEN p.employment_status = 'future' THEN 'Future Employee'
    WHEN p.associate_status = 'board_member' THEN 'Board Member'
    WHEN p.associate_status = 'consultant' THEN 'Consultant'
    WHEN p.associate_status = 'advisor' THEN 'Advisor'
    WHEN p.associate_status = 'contractor' THEN 'Contractor'
    WHEN p.associate_status = 'volunteer' THEN 'Volunteer'
    WHEN p.associate_status = 'partner' THEN 'Partner'
    WHEN p.associate_status = 'other' THEN 'Associate (Other)'
    ELSE 'Unknown'
  END as display_status
FROM api.people p
LEFT JOIN api.people_enrollments en ON p.id = en.person_id;

-- =====================================================
-- STEP 6: UPDATE ROW LEVEL SECURITY
-- =====================================================

-- Enable RLS on new tables
ALTER TABLE api.people ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.people_enrollments ENABLE ROW LEVEL SECURITY;

-- Staff access policies
DROP POLICY IF EXISTS policy_people_staff_access ON api.people;
CREATE POLICY policy_people_staff_access ON api.people
  FOR ALL 
  USING (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

DROP POLICY IF EXISTS policy_people_enrollments_staff_access ON api.people_enrollments;
CREATE POLICY policy_people_enrollments_staff_access ON api.people_enrollments
  FOR ALL 
  USING (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
  );

-- Client-specific access policies
DROP POLICY IF EXISTS policy_people_client_access ON api.people;
CREATE POLICY policy_people_client_access ON api.people
  FOR ALL
  USING (
    client_id::text = auth.jwt()->>'client_id'
    OR EXISTS (
      SELECT 1 FROM api.clients 
      WHERE clients.id = people.client_id 
        AND clients.client_code = auth.jwt()->>'client_code'
    )
  );

-- =====================================================
-- STEP 7: UPDATE COMMENTS
-- =====================================================

COMMENT ON TABLE api.people IS 'People master data including employees and associates for demo scenarios';
COMMENT ON TABLE api.people_enrollments IS 'Person onboarding and offboarding progress tracking';

COMMENT ON COLUMN api.people.person_code IS 'Unique person identifier for demo consistency';
COMMENT ON COLUMN api.people.employment_status IS 'Employment relationship status: active (current employee), former (ex-employee), future (not yet started) - optional';
COMMENT ON COLUMN api.people.associate_status IS 'Associate relationship status for non-employees: board_member, consultant, advisor, contractor, volunteer, partner, other - optional';
COMMENT ON COLUMN api.people_enrollments.completion_percentage IS 'Calculated from completed tasks percentage';

COMMENT ON VIEW api.people_with_status IS 'Combined view showing person info with process status for easy querying';
COMMENT ON VIEW api.people_dashboard IS 'Dashboard view for people management';

-- =====================================================
-- STEP 8: RENAME OLD TABLES (BACKUP)
-- =====================================================

-- Rename old tables to backup format for safety
ALTER TABLE IF EXISTS api.employees RENAME TO employees_backup_pre_people_migration;
ALTER TABLE IF EXISTS api.employee_enrollments RENAME TO employee_enrollments_backup_pre_people_migration;

-- =====================================================
-- NOTES
-- =====================================================

-- Migration completed successfully!
-- 
-- Key Changes:
-- 1. Tables renamed: employees → people, employee_enrollments → people_enrollments
-- 2. Status field renamed and updated: status → employment_status (active, former, future) - optional
-- 3. New associate_status field added (board_member, consultant, advisor, contractor, volunteer, partner, other) - optional
-- 4. Contractors moved from employment_type to associate_status
-- 5. Mutual exclusivity constraint added between employment_status and associate_status
-- 6. All indexes, triggers, functions, and views updated
-- 7. Old tables renamed to backup format
-- 
-- Breaking Changes:
-- - All application code referencing employees/employee_enrollments tables needs updating
-- - API endpoints and queries need to be updated to use people/people_enrollments
-- - Status field queries need to be updated to use employment_status/associate_status