-- Fix Offboarding Audit Log Trigger Entity Type Mapping
-- 
-- Issue: The audit log trigger was using TG_TABLE_NAME directly ('offboarding_processes')
-- but the constraint only allows: 'process', 'task', 'document', 'template'
--
-- This migration fixes the create_audit_log() function to properly map table names
-- to the allowed entity type values.

-- Fix the audit log function to map table names to correct entity types
CREATE OR REPLACE FUNCTION api.create_audit_log()
RETURNS TRIGGER AS $$
DECLARE
    entity_type_mapped text;
BEGIN
    -- Map table names to allowed entity types
    CASE TG_TABLE_NAME
        WHEN 'offboarding_processes' THEN entity_type_mapped := 'process';
        WHEN 'offboarding_tasks' THEN entity_type_mapped := 'task';
        WHEN 'offboarding_documents' THEN entity_type_mapped := 'document';
        WHEN 'offboarding_templates' THEN entity_type_mapped := 'template';
        WHEN 'offboarding_task_templates' THEN entity_type_mapped := 'template';
        WHEN 'offboarding_document_templates' THEN entity_type_mapped := 'template';
        ELSE entity_type_mapped := 'process'; -- fallback
    END CASE;
    
    IF TG_OP = 'INSERT' THEN
        INSERT INTO api.offboarding_audit_log (
            client_id, entity_type, entity_id, action, new_values, system_generated
        ) VALUES (
            NEW.client_id, entity_type_mapped, NEW.id, 'created', row_to_json(NEW), true
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO api.offboarding_audit_log (
            client_id, entity_type, entity_id, action, old_values, new_values, system_generated
        ) VALUES (
            NEW.client_id, entity_type_mapped, NEW.id, 'updated', row_to_json(OLD), row_to_json(NEW), true
        );
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO api.offboarding_audit_log (
            client_id, entity_type, entity_id, action, old_values, system_generated
        ) VALUES (
            OLD.client_id, entity_type_mapped, OLD.id, 'deleted', row_to_json(OLD), true
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

-- Verify the fix by checking constraint
DO $$
BEGIN
    -- Check if constraint exists and what values are allowed
    RAISE NOTICE 'Audit log trigger fixed. Allowed entity_type values: process, task, document, template';
    RAISE NOTICE 'Table name mappings:';
    RAISE NOTICE '  offboarding_processes -> process';
    RAISE NOTICE '  offboarding_tasks -> task';
    RAISE NOTICE '  offboarding_documents -> document';
    RAISE NOTICE '  offboarding_templates -> template';
    RAISE NOTICE '  offboarding_task_templates -> template';
    RAISE NOTICE '  offboarding_document_templates -> template';
END $$;