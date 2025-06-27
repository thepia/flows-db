-- =====================================================
-- ADD FUTURE STATUS TO EMPLOYEE STATUS OPTIONS
-- =====================================================
-- 
-- Purpose: Add "future" as a valid employee status for employees who haven't started yet
-- Extends the employee status constraint to include: active, previous, future, other

-- Set schema context
SET search_path TO api, public;

-- =====================================================
-- UPDATE EMPLOYEE STATUS CONSTRAINT
-- =====================================================

-- Drop the existing constraint
ALTER TABLE api.employees DROP CONSTRAINT IF EXISTS employees_status_check;

-- Add the updated constraint with "future" status
ALTER TABLE api.employees 
ADD CONSTRAINT employees_status_check 
CHECK (status IN ('active', 'previous', 'future', 'other'));

-- =====================================================
-- UPDATE COMMENTS
-- =====================================================

COMMENT ON COLUMN api.employees.status IS 'Overall employment status: active (current employee), previous (former employee), future (not yet started), other (special cases)';

-- =====================================================
-- NOTES
-- =====================================================

-- The "future" status is intended for employees who:
-- - Have been hired but haven't started yet
-- - Are in pre-boarding phase
-- - Have a future start date
-- 
-- This status helps distinguish between:
-- - active: Currently working
-- - previous: No longer with company  
-- - future: Will start in the future
-- - other: Special cases (leave, suspended, etc.)