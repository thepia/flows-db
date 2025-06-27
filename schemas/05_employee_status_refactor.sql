-- =====================================================
-- EMPLOYEE STATUS REFACTOR - Proper Status Separation
-- =====================================================
-- 
-- Purpose: Separate overall employee status from process-specific status
-- Rationale: 
--   - Overall Status: Active, Previous, Other (employment relationship)
--   - Process Status: Tracked in employee_enrollments (onboarding/offboarding specific)
-- 
-- Changes:
--   1. Update employee status constraint to proper overall statuses
--   2. Remove process-specific statuses from main employee table
--   3. Rely on employee_enrollments for process tracking

-- Set schema context
SET search_path TO api, public;

-- =====================================================
-- UPDATE EMPLOYEE STATUS CONSTRAINT
-- =====================================================

-- First, update any existing process-specific statuses to proper overall statuses
UPDATE api.employees 
SET status = CASE 
  WHEN status = 'active' THEN 'active'
  WHEN status = 'offboarded' THEN 'previous'
  WHEN status IN ('invited', 'pending', 'offboarding_initiated') THEN 'other'
  ELSE 'active'
END;

-- Drop the old constraint
ALTER TABLE api.employees DROP CONSTRAINT IF EXISTS employees_status_check;

-- Add the new constraint with proper overall statuses
ALTER TABLE api.employees 
ADD CONSTRAINT employees_status_check 
CHECK (status IN ('active', 'previous', 'other'));

-- =====================================================
-- ADD PROCESS STATUS FIELDS TO ENROLLMENTS
-- =====================================================

-- Add explicit onboarding status field
ALTER TABLE api.employee_enrollments 
ADD COLUMN IF NOT EXISTS onboarding_status VARCHAR(50) DEFAULT 'not_started' 
CHECK (onboarding_status IN ('not_started', 'invited', 'in_progress', 'completed', 'on_hold'));

-- Add explicit offboarding status field  
ALTER TABLE api.employee_enrollments
ADD COLUMN IF NOT EXISTS offboarding_status VARCHAR(50) DEFAULT 'not_started'
CHECK (offboarding_status IN ('not_started', 'initiated', 'in_progress', 'completed', 'cancelled'));

-- Update existing records based on boolean flags
UPDATE api.employee_enrollments 
SET onboarding_status = CASE 
  WHEN onboarding_completed = true THEN 'completed'
  WHEN onboarding_completed = false THEN 'in_progress'
  ELSE 'not_started'
END;

UPDATE api.employee_enrollments
SET offboarding_status = CASE 
  WHEN offboarding_completed = true THEN 'completed'
  WHEN offboarding_initiated = true AND offboarding_completed = false THEN 'in_progress'
  WHEN offboarding_initiated = true THEN 'initiated'
  ELSE 'not_started'
END;

-- =====================================================
-- CREATE VIEWS FOR EASIER QUERYING
-- =====================================================

-- View that combines employee with their current process status
CREATE OR REPLACE VIEW api.employee_with_status AS
SELECT 
  e.*,
  en.onboarding_status,
  en.offboarding_status,
  en.onboarding_completed,
  en.offboarding_completed,
  en.completion_percentage,
  CASE 
    WHEN e.status = 'active' AND en.onboarding_status IN ('not_started', 'invited') THEN 'New Hire (Pending Onboarding)'
    WHEN e.status = 'active' AND en.onboarding_status = 'in_progress' THEN 'Active (Onboarding)'
    WHEN e.status = 'active' AND en.onboarding_status = 'completed' THEN 'Active'
    WHEN e.status = 'active' AND en.offboarding_status IN ('initiated', 'in_progress') THEN 'Active (Offboarding)'
    WHEN e.status = 'previous' THEN 'Previous Employee'
    WHEN e.status = 'other' THEN 'Other Status'
    ELSE 'Unknown'
  END as display_status
FROM api.employees e
LEFT JOIN api.employee_enrollments en ON e.id = en.employee_id;

-- =====================================================
-- UPDATE COMMENTS
-- =====================================================

COMMENT ON COLUMN api.employees.status IS 'Overall employment status: active (current employee), previous (former employee), other (special cases)';
COMMENT ON COLUMN api.employee_enrollments.onboarding_status IS 'Current onboarding process status';
COMMENT ON COLUMN api.employee_enrollments.offboarding_status IS 'Current offboarding process status';
COMMENT ON VIEW api.employee_with_status IS 'Combined view showing employee info with process status for easy querying';

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Index for common status queries
CREATE INDEX IF NOT EXISTS idx_employees_status ON api.employees(status);
CREATE INDEX IF NOT EXISTS idx_employee_enrollments_onboarding_status ON api.employee_enrollments(onboarding_status);
CREATE INDEX IF NOT EXISTS idx_employee_enrollments_offboarding_status ON api.employee_enrollments(offboarding_status);

-- Composite index for active employees with process status
CREATE INDEX IF NOT EXISTS idx_employees_active_with_process ON api.employees(status, id) WHERE status = 'active';