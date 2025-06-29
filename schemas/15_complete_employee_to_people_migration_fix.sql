-- =====================================================
-- COMPLETE EMPLOYEE TO PEOPLE MIGRATION FIX
-- =====================================================
-- 
-- Purpose: Complete the incomplete migration from employees to people
-- This fixes the remaining issues:
--   1. Rename employee_id columns to person_id in documents and tasks tables
--   2. Update foreign key constraints to reference people table
--   3. Update functions and triggers to use person_id
--   4. Update RLS policies for documents and tasks tables
--   5. Fix any remaining references

-- Set schema context
SET search_path TO api, public;

-- =====================================================
-- STEP 1: ALTER DOCUMENTS TABLE
-- =====================================================

-- Drop existing foreign key constraint
ALTER TABLE api.documents 
DROP CONSTRAINT IF EXISTS documents_employee_id_fkey;

-- Rename employee_id column to person_id
ALTER TABLE api.documents 
RENAME COLUMN employee_id TO person_id;

-- Add new foreign key constraint to people table
ALTER TABLE api.documents 
ADD CONSTRAINT documents_person_id_fkey 
FOREIGN KEY (person_id) REFERENCES api.people(id) ON DELETE CASCADE;

-- Update index name for consistency
DROP INDEX IF EXISTS api.idx_documents_employee_id;
CREATE INDEX IF NOT EXISTS idx_documents_person_id ON api.documents(person_id);

-- =====================================================
-- STEP 2: ALTER TASKS TABLE
-- =====================================================

-- Drop existing foreign key constraint
ALTER TABLE api.tasks 
DROP CONSTRAINT IF EXISTS tasks_employee_id_fkey;

-- Rename employee_id column to person_id
ALTER TABLE api.tasks 
RENAME COLUMN employee_id TO person_id;

-- Add new foreign key constraint to people table
ALTER TABLE api.tasks 
ADD CONSTRAINT tasks_person_id_fkey 
FOREIGN KEY (person_id) REFERENCES api.people(id) ON DELETE CASCADE;

-- Update index name for consistency
DROP INDEX IF EXISTS api.idx_tasks_employee_id;
CREATE INDEX IF NOT EXISTS idx_tasks_person_id ON api.tasks(person_id);

-- =====================================================
-- STEP 3: UPDATE FUNCTIONS
-- =====================================================

-- Update completion percentage function to use person_id
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
  WHERE person_id = COALESCE(NEW.person_id, OLD.person_id);
  
  SELECT COUNT(*) INTO completed_tasks
  FROM api.tasks
  WHERE person_id = COALESCE(NEW.person_id, OLD.person_id)
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
  WHERE person_id = COALESCE(NEW.person_id, OLD.person_id);
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Update get_person_with_enrollment function (this was already updated in migration 13)
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
      person_id,
      jsonb_agg(to_jsonb(d.*)) as documents
    FROM api.documents d
    GROUP BY person_id
  ) docs ON docs.person_id = p.id
  LEFT JOIN (
    SELECT 
      person_id,
      jsonb_agg(to_jsonb(t.*)) as tasks
    FROM api.tasks t
    GROUP BY person_id
  ) tasks ON tasks.person_id = p.id
  WHERE p.id = p_person_id;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 4: UPDATE VIEWS
-- =====================================================

-- Drop old employee views that might still exist
DROP VIEW IF EXISTS api.employee_dashboard;
DROP VIEW IF EXISTS api.employee_with_status;

-- Ensure people dashboard view exists and is correct
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

-- Ensure people_with_status view exists and is correct
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
-- STEP 5: UPDATE ROW LEVEL SECURITY POLICIES
-- =====================================================

-- Ensure RLS is enabled on documents and tasks tables
ALTER TABLE api.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.tasks ENABLE ROW LEVEL SECURITY;

-- Drop old policies if they exist
DROP POLICY IF EXISTS policy_documents_staff_access ON api.documents;
DROP POLICY IF EXISTS policy_documents_client_access ON api.documents;
DROP POLICY IF EXISTS policy_documents_anon_access ON api.documents;

DROP POLICY IF EXISTS policy_tasks_staff_access ON api.tasks;
DROP POLICY IF EXISTS policy_tasks_client_access ON api.tasks;
DROP POLICY IF EXISTS policy_tasks_anon_access ON api.tasks;

-- Create RLS policies for documents table
CREATE POLICY policy_documents_anon_access ON api.documents
  FOR ALL 
  USING (true);

CREATE POLICY policy_documents_staff_access ON api.documents
  FOR ALL 
  USING (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
    OR auth.jwt()->>'role' = 'anon'
  );

CREATE POLICY policy_documents_client_access ON api.documents
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM api.people 
      WHERE people.id = documents.person_id 
        AND (
          people.client_id::text = auth.jwt()->>'client_id'
          OR EXISTS (
            SELECT 1 FROM api.clients 
            WHERE clients.id = people.client_id 
              AND clients.client_code = auth.jwt()->>'client_code'
          )
        )
    )
    OR auth.jwt()->>'role' = 'anon'
  );

-- Create RLS policies for tasks table
CREATE POLICY policy_tasks_anon_access ON api.tasks
  FOR ALL 
  USING (true);

CREATE POLICY policy_tasks_staff_access ON api.tasks
  FOR ALL 
  USING (
    auth.jwt()->>'role' = 'thepia_staff'
    OR auth.jwt()->>'role' = 'service_role'
    OR auth.jwt()->>'role' = 'anon'
  );

CREATE POLICY policy_tasks_client_access ON api.tasks
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM api.people 
      WHERE people.id = tasks.person_id 
        AND (
          people.client_id::text = auth.jwt()->>'client_id'
          OR EXISTS (
            SELECT 1 FROM api.clients 
            WHERE clients.id = people.client_id 
              AND clients.client_code = auth.jwt()->>'client_code'
          )
        )
    )
    OR auth.jwt()->>'role' = 'anon'
  );

-- =====================================================
-- STEP 6: RECREATE TRIGGERS  
-- =====================================================

-- Drop existing triggers on tasks table that reference old function
DROP TRIGGER IF EXISTS trigger_update_completion_percentage ON api.tasks;

-- Recreate the trigger with updated function
CREATE TRIGGER trigger_update_completion_percentage
  AFTER INSERT OR UPDATE OR DELETE ON api.tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_completion_percentage();

-- Ensure updated_at triggers exist for documents and tasks
CREATE OR REPLACE FUNCTION update_updated_at_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_documents_updated_at ON api.documents;
CREATE TRIGGER trigger_documents_updated_at
  BEFORE UPDATE ON api.documents
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_timestamp();

DROP TRIGGER IF EXISTS trigger_tasks_updated_at ON api.tasks;
CREATE TRIGGER trigger_tasks_updated_at
  BEFORE UPDATE ON api.tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_timestamp();

-- =====================================================
-- STEP 7: ADD COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON COLUMN api.documents.person_id IS 'Reference to person this document belongs to';
COMMENT ON COLUMN api.tasks.person_id IS 'Reference to person this task is assigned to';

COMMENT ON POLICY policy_documents_anon_access ON api.documents IS 'Allow anonymous access for demo purposes';
COMMENT ON POLICY policy_documents_staff_access ON api.documents IS 'Full access for Thepia staff and service roles';  
COMMENT ON POLICY policy_documents_client_access ON api.documents IS 'Client-specific access to their people documents';

COMMENT ON POLICY policy_tasks_anon_access ON api.tasks IS 'Allow anonymous access for demo purposes';
COMMENT ON POLICY policy_tasks_staff_access ON api.tasks IS 'Full access for Thepia staff and service roles';
COMMENT ON POLICY policy_tasks_client_access ON api.tasks IS 'Client-specific access to their people tasks';

-- =====================================================
-- VALIDATION QUERIES
-- =====================================================

-- These queries can be run to validate the migration worked correctly:
-- 
-- Check column names:
-- SELECT column_name FROM information_schema.columns 
-- WHERE table_schema = 'api' AND table_name = 'documents';
--
-- SELECT column_name FROM information_schema.columns 
-- WHERE table_schema = 'api' AND table_name = 'tasks';
--
-- Check foreign key constraints:
-- SELECT constraint_name, table_name, column_name, foreign_table_name, foreign_column_name
-- FROM information_schema.key_column_usage kcu
-- JOIN information_schema.table_constraints tc ON kcu.constraint_name = tc.constraint_name
-- WHERE tc.constraint_type = 'FOREIGN KEY' 
-- AND kcu.table_schema = 'api' 
-- AND kcu.table_name IN ('documents', 'tasks');

-- =====================================================
-- NOTES
-- =====================================================

-- Migration Fix Complete!
-- 
-- Changes Made:
-- 1. Renamed employee_id columns to person_id in documents and tasks tables
-- 2. Updated foreign key constraints to reference people table instead of employees
-- 3. Updated all functions to use person_id instead of employee_id
-- 4. Updated views to use correct table relationships
-- 5. Created proper RLS policies for documents and tasks tables
-- 6. Recreated triggers with updated function references
-- 7. Updated indexes to reflect new column names
-- 
-- This completes the employee-to-people migration that was started in migration 13
-- but was incomplete for the documents and tasks tables.