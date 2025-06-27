-- =====================================================
-- APP-SPECIFIC METRICS SUPPORT - Task-Application Association
-- =====================================================
-- 
-- Purpose: Enable proper KPI tracking for onboarding and offboarding
-- Requirements:
--   1. Associate tasks with specific applications (onboarding vs offboarding)
--   2. Track employee enrollment in specific application processes
--   3. Support meaningful business metrics calculation
--
-- Business Context:
--   - Onboarding and offboarding are separate applications
--   - Clients may have access to one or both applications
--   - Metrics must reflect actual process state, not just invitation counts

-- Set schema context
SET search_path TO api, public;

-- =====================================================
-- UPDATE TASKS TABLE - Add Application Association
-- =====================================================

-- Add app_id to associate tasks with specific applications
ALTER TABLE api.tasks 
ADD COLUMN IF NOT EXISTS app_id UUID REFERENCES api.client_applications(id) ON DELETE CASCADE;

-- Add constraint to ensure task belongs to same client as the application
ALTER TABLE api.tasks 
ADD CONSTRAINT tasks_app_client_match 
CHECK (
  app_id IS NULL OR 
  EXISTS (
    SELECT 1 FROM api.client_applications ca 
    JOIN api.employees e ON e.client_id = ca.client_id 
    WHERE ca.id = app_id AND e.id = employee_id
  )
);

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_tasks_app_id ON api.tasks(app_id);
CREATE INDEX IF NOT EXISTS idx_tasks_employee_app ON api.tasks(employee_id, app_id);

-- =====================================================
-- EMPLOYEE APPLICATION ENROLLMENTS - Process Tracking
-- =====================================================

-- Track employee enrollment in specific application processes
CREATE TABLE IF NOT EXISTS api.employee_app_enrollments (
  -- Primary identifier
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Relationships
  employee_id UUID NOT NULL REFERENCES api.employees(id) ON DELETE CASCADE,
  app_id UUID NOT NULL REFERENCES api.client_applications(id) ON DELETE CASCADE,
  
  -- Process tracking timestamps
  invitation_sent_at TIMESTAMP WITH TIME ZONE,
  invitation_accepted_at TIMESTAMP WITH TIME ZONE,
  process_started_at TIMESTAMP WITH TIME ZONE,
  process_completed_at TIMESTAMP WITH TIME ZONE,
  
  -- Status tracking
  status VARCHAR(50) DEFAULT 'invited' CHECK (status IN (
    'invited',      -- Invitation sent
    'accepted',     -- Invitation accepted by employee
    'in_progress',  -- Tasks assigned and employee working
    'completed',    -- All tasks completed
    'cancelled'     -- Process cancelled/terminated
  )),
  
  -- Association dates (denormalized for performance)
  association_start_date DATE,
  association_end_date DATE,
  
  -- Completion tracking
  total_tasks INTEGER DEFAULT 0,
  completed_tasks INTEGER DEFAULT 0,
  completion_percentage INTEGER GENERATED ALWAYS AS (
    CASE 
      WHEN total_tasks = 0 THEN 0
      ELSE (completed_tasks * 100) / total_tasks
    END
  ) STORED,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  UNIQUE(employee_id, app_id),
  CHECK (completed_tasks <= total_tasks),
  CHECK (completion_percentage >= 0 AND completion_percentage <= 100)
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Primary lookup indexes
CREATE INDEX IF NOT EXISTS idx_employee_app_enrollments_employee ON api.employee_app_enrollments(employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_app_enrollments_app ON api.employee_app_enrollments(app_id);
CREATE INDEX IF NOT EXISTS idx_employee_app_enrollments_status ON api.employee_app_enrollments(status);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_employee_app_enrollments_app_status ON api.employee_app_enrollments(app_id, status);
CREATE INDEX IF NOT EXISTS idx_employee_app_enrollments_active ON api.employee_app_enrollments(app_id, status, association_end_date) 
WHERE status = 'in_progress';

-- Association date indexes for offboarding metrics
CREATE INDEX IF NOT EXISTS idx_employee_app_enrollments_end_date ON api.employee_app_enrollments(association_end_date) 
WHERE status = 'in_progress' AND association_end_date IS NOT NULL;

-- =====================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- =====================================================

-- Function to update enrollment task counts
CREATE OR REPLACE FUNCTION update_enrollment_task_counts()
RETURNS TRIGGER AS $$
BEGIN
  -- Update total and completed task counts for the enrollment
  UPDATE api.employee_app_enrollments 
  SET 
    total_tasks = (
      SELECT COUNT(*) 
      FROM api.tasks 
      WHERE employee_id = COALESCE(NEW.employee_id, OLD.employee_id)
        AND app_id = COALESCE(NEW.app_id, OLD.app_id)
    ),
    completed_tasks = (
      SELECT COUNT(*) 
      FROM api.tasks 
      WHERE employee_id = COALESCE(NEW.employee_id, OLD.employee_id)
        AND app_id = COALESCE(NEW.app_id, OLD.app_id)
        AND status = 'completed'
    ),
    updated_at = NOW()
  WHERE employee_id = COALESCE(NEW.employee_id, OLD.employee_id)
    AND app_id = COALESCE(NEW.app_id, OLD.app_id);
    
  -- Update process_completed_at when all tasks are done
  UPDATE api.employee_app_enrollments
  SET 
    process_completed_at = CASE 
      WHEN completion_percentage = 100 AND process_completed_at IS NULL THEN NOW()
      WHEN completion_percentage < 100 THEN NULL
      ELSE process_completed_at
    END,
    status = CASE
      WHEN completion_percentage = 100 THEN 'completed'
      WHEN completion_percentage > 0 AND status = 'accepted' THEN 'in_progress'
      ELSE status
    END
  WHERE employee_id = COALESCE(NEW.employee_id, OLD.employee_id)
    AND app_id = COALESCE(NEW.app_id, OLD.app_id);
    
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Trigger on task changes
DROP TRIGGER IF EXISTS trigger_update_enrollment_counts ON api.tasks;
CREATE TRIGGER trigger_update_enrollment_counts
  AFTER INSERT OR UPDATE OR DELETE ON api.tasks
  FOR EACH ROW
  WHEN (NEW.app_id IS NOT NULL OR OLD.app_id IS NOT NULL)
  EXECUTE FUNCTION update_enrollment_task_counts();

-- =====================================================
-- VIEWS FOR EASY QUERYING
-- =====================================================

-- Active onboarding employees view
CREATE OR REPLACE VIEW api.active_onboarding AS
SELECT 
  e.id as employee_id,
  e.first_name,
  e.last_name,
  e.company_email,
  eae.status,
  eae.completion_percentage,
  eae.total_tasks,
  eae.completed_tasks,
  eae.process_started_at,
  eae.created_at as enrollment_created_at
FROM api.employees e
JOIN api.employee_app_enrollments eae ON e.id = eae.employee_id
JOIN api.client_applications ca ON eae.app_id = ca.id
WHERE ca.app_code = 'onboarding'
  AND eae.status = 'in_progress'
  AND eae.total_tasks > 0
  AND eae.completed_tasks < eae.total_tasks;

-- Active offboarding employees view  
CREATE OR REPLACE VIEW api.active_offboarding AS
SELECT 
  e.id as employee_id,
  e.first_name,
  e.last_name,
  e.company_email,
  eae.status,
  eae.completion_percentage,
  eae.total_tasks,
  eae.completed_tasks,
  eae.association_end_date,
  eae.association_end_date - CURRENT_DATE as days_until_end,
  eae.process_started_at,
  eae.created_at as enrollment_created_at
FROM api.employees e
JOIN api.employee_app_enrollments eae ON e.id = eae.employee_id
JOIN api.client_applications ca ON eae.app_id = ca.id
WHERE ca.app_code = 'offboarding'
  AND eae.status = 'in_progress'
  AND eae.total_tasks > 0
  AND eae.completed_tasks < eae.total_tasks
  AND (eae.association_end_date IS NULL OR eae.association_end_date > CURRENT_DATE);

-- =====================================================
-- DATA MIGRATION - Populate Existing Data
-- =====================================================

-- Update existing tasks to associate with applications based on task category
-- This is a best-effort migration - may need manual review
UPDATE api.tasks 
SET app_id = (
  SELECT ca.id 
  FROM api.client_applications ca
  JOIN api.employees e ON e.client_id = ca.client_id
  WHERE e.id = tasks.employee_id
    AND ca.app_code = CASE 
      WHEN tasks.category IN ('onboarding', 'training', 'setup') THEN 'onboarding'
      WHEN tasks.category IN ('offboarding', 'equipment', 'exit') THEN 'offboarding'
      ELSE 'onboarding' -- Default to onboarding for ambiguous tasks
    END
  LIMIT 1
)
WHERE app_id IS NULL;

-- Create enrollments for employees with tasks
INSERT INTO api.employee_app_enrollments (
  employee_id, 
  app_id, 
  status,
  process_started_at,
  association_start_date,
  association_end_date
)
SELECT DISTINCT
  t.employee_id,
  t.app_id,
  CASE 
    WHEN COUNT(CASE WHEN t.status = 'completed' THEN 1 END) = COUNT(*) THEN 'completed'
    WHEN COUNT(CASE WHEN t.status IN ('in_progress', 'completed') THEN 1 END) > 0 THEN 'in_progress'
    ELSE 'accepted'
  END as status,
  MIN(t.assigned_at) as process_started_at,
  e.start_date as association_start_date,
  e.end_date as association_end_date
FROM api.tasks t
JOIN api.employees e ON t.employee_id = e.id
WHERE t.app_id IS NOT NULL
GROUP BY t.employee_id, t.app_id, e.start_date, e.end_date
ON CONFLICT (employee_id, app_id) DO NOTHING;

-- =====================================================
-- FUNCTIONS FOR METRIC CALCULATION
-- =====================================================

-- Function to get onboarding count for a client
CREATE OR REPLACE FUNCTION get_client_onboarding_count(client_uuid UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)
    FROM api.active_onboarding ao
    JOIN api.employees e ON ao.employee_id = e.id
    WHERE e.client_id = client_uuid
  );
END;
$$ LANGUAGE plpgsql;

-- Function to get offboarding count for a client
CREATE OR REPLACE FUNCTION get_client_offboarding_count(client_uuid UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)
    FROM api.active_offboarding ao
    JOIN api.employees e ON ao.employee_id = e.id
    WHERE e.client_id = client_uuid
  );
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON TABLE api.employee_app_enrollments IS 'Tracks employee enrollment in specific application processes (onboarding/offboarding)';
COMMENT ON COLUMN api.tasks.app_id IS 'Associates task with specific application (onboarding or offboarding)';
COMMENT ON VIEW api.active_onboarding IS 'Employees currently in active onboarding process with incomplete tasks';
COMMENT ON VIEW api.active_offboarding IS 'Employees currently in active offboarding process with incomplete tasks and future end dates';
COMMENT ON FUNCTION get_client_onboarding_count IS 'Returns count of employees in active onboarding for specified client';
COMMENT ON FUNCTION get_client_offboarding_count IS 'Returns count of employees in active offboarding for specified client';