-- Cleanup and recreate task-oriented offboarding tables
-- Run this to fix policy conflicts and table inconsistencies

-- Drop all task-oriented offboarding objects in dependency order
DROP VIEW IF EXISTS api.offboarding_process_summary CASCADE;

DROP TRIGGER IF EXISTS offboarding_documents_audit ON api.offboarding_documents CASCADE;
DROP TRIGGER IF EXISTS offboarding_tasks_audit ON api.offboarding_tasks CASCADE;
DROP TRIGGER IF EXISTS offboarding_processes_audit ON api.offboarding_processes CASCADE;

DROP TRIGGER IF EXISTS update_offboarding_documents_updated_at ON api.offboarding_documents CASCADE;
DROP TRIGGER IF EXISTS update_offboarding_tasks_updated_at ON api.offboarding_tasks CASCADE;
DROP TRIGGER IF EXISTS update_offboarding_processes_updated_at ON api.offboarding_processes CASCADE;
DROP TRIGGER IF EXISTS update_offboarding_document_templates_updated_at ON api.offboarding_document_templates CASCADE;
DROP TRIGGER IF EXISTS update_offboarding_task_templates_updated_at ON api.offboarding_task_templates CASCADE;
DROP TRIGGER IF EXISTS update_offboarding_templates_updated_at ON api.offboarding_templates CASCADE;

DROP FUNCTION IF EXISTS create_audit_log() CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

DROP TABLE IF EXISTS api.offboarding_audit_log CASCADE;
DROP TABLE IF EXISTS api.offboarding_documents CASCADE;
DROP TABLE IF EXISTS api.offboarding_tasks CASCADE;
DROP TABLE IF EXISTS api.offboarding_processes CASCADE;
DROP TABLE IF EXISTS api.offboarding_document_templates CASCADE;
DROP TABLE IF EXISTS api.offboarding_task_templates CASCADE;
DROP TABLE IF EXISTS api.offboarding_templates CASCADE;

-- Now recreate everything from scratch by running the content of 12_task_oriented_offboarding.sql
-- (You'll need to copy and paste the content of that file after this cleanup)