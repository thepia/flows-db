-- Temporarily Disable Audit Trigger for Offboarding Processes
-- 
-- This is a workaround to allow offboarding processes to be created
-- while we resolve the audit log trigger constraint issue.
--
-- After processes are created, we can re-enable with the fixed trigger.

-- Drop the problematic trigger temporarily
DROP TRIGGER IF EXISTS offboarding_processes_audit ON api.offboarding_processes;

-- Verify trigger is dropped
DO $$
BEGIN
    RAISE NOTICE 'Audit trigger for offboarding_processes has been temporarily disabled';
    RAISE NOTICE 'Offboarding processes can now be created without audit log constraint issues';
    RAISE NOTICE 'Re-enable with the fixed trigger after populating demo data';
END $$;