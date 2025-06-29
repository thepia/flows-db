-- =====================================================
-- ESSENTIAL EMPLOYEE TO PEOPLE MIGRATION FIX
-- =====================================================
-- 
-- This is a simplified version containing only the critical DDL statements
-- Copy and paste this directly into Supabase SQL Editor

-- Set schema context
SET search_path TO api, public;

-- =====================================================
-- STEP 1: ALTER DOCUMENTS TABLE
-- =====================================================

-- Drop existing foreign key constraint
ALTER TABLE api.documents DROP CONSTRAINT IF EXISTS documents_employee_id_fkey;

-- Rename employee_id column to person_id
ALTER TABLE api.documents RENAME COLUMN employee_id TO person_id;

-- Add new foreign key constraint to people table
ALTER TABLE api.documents ADD CONSTRAINT documents_person_id_fkey 
FOREIGN KEY (person_id) REFERENCES api.people(id) ON DELETE CASCADE;

-- Update index
DROP INDEX IF EXISTS api.idx_documents_employee_id;
CREATE INDEX IF NOT EXISTS idx_documents_person_id ON api.documents(person_id);

-- =====================================================
-- STEP 2: ALTER TASKS TABLE
-- =====================================================

-- Drop existing foreign key constraint
ALTER TABLE api.tasks DROP CONSTRAINT IF EXISTS tasks_employee_id_fkey;

-- Rename employee_id column to person_id
ALTER TABLE api.tasks RENAME COLUMN employee_id TO person_id;

-- Add new foreign key constraint to people table
ALTER TABLE api.tasks ADD CONSTRAINT tasks_person_id_fkey 
FOREIGN KEY (person_id) REFERENCES api.people(id) ON DELETE CASCADE;

-- Update index
DROP INDEX IF EXISTS api.idx_tasks_employee_id;
CREATE INDEX IF NOT EXISTS idx_tasks_person_id ON api.tasks(person_id);

-- =====================================================
-- STEP 3: ENABLE RLS AND CREATE POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE api.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.tasks ENABLE ROW LEVEL SECURITY;

-- Documents policies
DROP POLICY IF EXISTS policy_documents_anon_access ON api.documents;
CREATE POLICY policy_documents_anon_access ON api.documents FOR ALL USING (true);

DROP POLICY IF EXISTS policy_documents_staff_access ON api.documents;
CREATE POLICY policy_documents_staff_access ON api.documents
FOR ALL USING (
  auth.jwt()->>'role' = 'thepia_staff'
  OR auth.jwt()->>'role' = 'service_role'
  OR auth.jwt()->>'role' = 'anon'
);

-- Tasks policies
DROP POLICY IF EXISTS policy_tasks_anon_access ON api.tasks;
CREATE POLICY policy_tasks_anon_access ON api.tasks FOR ALL USING (true);

DROP POLICY IF EXISTS policy_tasks_staff_access ON api.tasks;
CREATE POLICY policy_tasks_staff_access ON api.tasks
FOR ALL USING (
  auth.jwt()->>'role' = 'thepia_staff'
  OR auth.jwt()->>'role' = 'service_role'
  OR auth.jwt()->>'role' = 'anon'
);

-- =====================================================
-- STEP 4: UPDATE CRITICAL FUNCTION
-- =====================================================

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

-- Recreate trigger
DROP TRIGGER IF EXISTS trigger_update_completion_percentage ON api.tasks;
CREATE TRIGGER trigger_update_completion_percentage
  AFTER INSERT OR UPDATE OR DELETE ON api.tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_completion_percentage();

-- =====================================================
-- VALIDATION QUERIES (run these to verify success)
-- =====================================================

-- Check column names (should see person_id, not employee_id)
-- SELECT column_name FROM information_schema.columns 
-- WHERE table_schema = 'api' AND table_name = 'documents';

-- SELECT column_name FROM information_schema.columns 
-- WHERE table_schema = 'api' AND table_name = 'tasks';