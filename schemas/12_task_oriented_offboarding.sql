-- 12_task_oriented_offboarding.sql
-- Task-oriented offboarding system with templates and process management

-- Offboarding process templates (company-wide and department-specific)
CREATE TABLE IF NOT EXISTS api.offboarding_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES api.clients(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    
    -- Template scope and applicability
    template_type TEXT NOT NULL CHECK (template_type IN ('company_wide', 'department_specific', 'role_specific', 'custom')),
    department TEXT, -- NULL for company-wide templates
    role_category TEXT, -- engineering, sales, operations, leadership, support, etc.
    seniority_level TEXT CHECK (seniority_level IN ('junior', 'mid_level', 'senior', 'principal', 'leadership', 'executive')),
    
    -- Template metadata
    estimated_duration_days INTEGER DEFAULT 14,
    complexity_score INTEGER DEFAULT 1 CHECK (complexity_score BETWEEN 1 AND 5),
    is_active BOOLEAN DEFAULT true,
    is_default BOOLEAN DEFAULT false, -- One default per department/role combo
    
    -- Template configuration
    requires_manager_approval BOOLEAN DEFAULT true,
    requires_hr_approval BOOLEAN DEFAULT true,
    requires_security_review BOOLEAN DEFAULT false,
    auto_assign_tasks BOOLEAN DEFAULT true,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by TEXT, -- Employee UID who created template
    
    UNIQUE(client_id, name)
);

-- Task templates within offboarding processes
CREATE TABLE IF NOT EXISTS api.offboarding_task_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES api.clients(id) ON DELETE CASCADE,
    template_id UUID NOT NULL REFERENCES api.offboarding_templates(id) ON DELETE CASCADE,
    
    -- Task details
    name TEXT NOT NULL,
    description TEXT,
    instructions TEXT, -- Detailed instructions for completing the task
    
    -- Task classification
    category TEXT NOT NULL CHECK (category IN (
        'documentation', 'knowledge_transfer', 'access_revocation', 
        'equipment_return', 'compliance', 'communication', 
        'transition_planning', 'exit_interview', 'final_procedures'
    )),
    
    -- Task configuration
    is_mandatory BOOLEAN DEFAULT true,
    estimated_hours DECIMAL(4,2) DEFAULT 1.0,
    sort_order INTEGER DEFAULT 0, -- For ordering tasks within template
    
    -- Dependencies and conditions
    depends_on_task_ids UUID[], -- Array of task IDs this depends on
    conditional_logic JSONB, -- Conditions for when this task applies
    
    -- Assignment
    default_assignee_role TEXT CHECK (default_assignee_role IN (
        'departing_employee', 'direct_manager', 'hr_representative', 
        'it_administrator', 'security_officer', 'department_head', 'custom'
    )),
    custom_assignee_role TEXT, -- When default_assignee_role = 'custom'
    
    -- Completion requirements
    requires_evidence BOOLEAN DEFAULT false,
    evidence_types TEXT[], -- ['document', 'screenshot', 'signature', 'confirmation']
    requires_approval BOOLEAN DEFAULT false,
    approval_role TEXT, -- Who needs to approve completion
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Document templates required for offboarding tasks
CREATE TABLE IF NOT EXISTS api.offboarding_document_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES api.clients(id) ON DELETE CASCADE,
    task_template_id UUID REFERENCES api.offboarding_task_templates(id) ON DELETE CASCADE,
    template_id UUID REFERENCES api.offboarding_templates(id) ON DELETE CASCADE, -- Can be template-wide or task-specific
    
    -- Document details
    name TEXT NOT NULL,
    description TEXT,
    document_type TEXT NOT NULL CHECK (document_type IN (
        'checklist', 'form', 'agreement', 'handover_document', 
        'knowledge_base', 'contact_list', 'procedure_guide', 'other'
    )),
    
    -- Document configuration
    is_template BOOLEAN DEFAULT true, -- If true, creates blank template for completion
    template_content TEXT, -- Template content/structure
    is_mandatory BOOLEAN DEFAULT true,
    
    -- File handling
    file_format TEXT, -- Expected file format (pdf, docx, etc.)
    max_file_size_mb INTEGER DEFAULT 10,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Active offboarding processes (instances of templates)
CREATE TABLE IF NOT EXISTS api.offboarding_processes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES api.clients(id) ON DELETE CASCADE,
    template_id UUID NOT NULL REFERENCES api.offboarding_templates(id),
    
    -- Employee information (anonymous for privacy)
    employee_uid TEXT NOT NULL, -- Anonymous employee identifier
    employee_department TEXT,
    employee_role TEXT,
    employee_seniority TEXT,
    manager_uid TEXT, -- Anonymous manager identifier
    
    -- Process details
    process_name TEXT NOT NULL, -- Customizable name for this process
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN (
        'draft', 'pending_approval', 'active', 'completed', 'cancelled', 'overdue'
    )),
    
    -- Timeline
    target_completion_date DATE,
    actual_start_date DATE,
    actual_completion_date DATE,
    
    -- Process metadata
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    complexity_score INTEGER CHECK (complexity_score BETWEEN 1 AND 5),
    estimated_total_hours DECIMAL(6,2),
    
    -- Approval tracking
    manager_approved_at TIMESTAMPTZ,
    manager_approved_by TEXT,
    hr_approved_at TIMESTAMPTZ,
    hr_approved_by TEXT,
    security_approved_at TIMESTAMPTZ,
    security_approved_by TEXT,
    
    -- Process notes and customizations
    notes TEXT,
    custom_fields JSONB, -- For client-specific additional fields
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by TEXT -- Employee UID who initiated process
);

-- Active tasks within offboarding processes
CREATE TABLE IF NOT EXISTS api.offboarding_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES api.clients(id) ON DELETE CASCADE,
    process_id UUID NOT NULL REFERENCES api.offboarding_processes(id) ON DELETE CASCADE,
    task_template_id UUID REFERENCES api.offboarding_task_templates(id), -- NULL if custom task
    
    -- Task details (copied from template but editable)
    name TEXT NOT NULL,
    description TEXT,
    instructions TEXT,
    category TEXT NOT NULL,
    
    -- Task status and assignment
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
        'pending', 'in_progress', 'waiting_for_approval', 'completed', 
        'cancelled', 'blocked', 'overdue'
    )),
    assigned_to_uid TEXT, -- Anonymous assignee identifier
    assigned_to_role TEXT,
    assigned_at TIMESTAMPTZ,
    
    -- Timeline
    due_date DATE,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    estimated_hours DECIMAL(4,2),
    actual_hours DECIMAL(4,2),
    
    -- Dependencies
    depends_on_task_ids UUID[],
    blocks_task_ids UUID[], -- Tasks that depend on this one
    
    -- Completion and approval
    completion_notes TEXT,
    evidence_files TEXT[], -- Array of file references/URLs
    requires_approval BOOLEAN DEFAULT false,
    approved_at TIMESTAMPTZ,
    approved_by TEXT,
    approval_notes TEXT,
    
    -- Task metadata
    is_mandatory BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    custom_fields JSONB,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Documents created/uploaded for offboarding tasks
CREATE TABLE IF NOT EXISTS api.offboarding_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES api.clients(id) ON DELETE CASCADE,
    process_id UUID NOT NULL REFERENCES api.offboarding_processes(id) ON DELETE CASCADE,
    task_id UUID REFERENCES api.offboarding_tasks(id) ON DELETE CASCADE,
    document_template_id UUID REFERENCES api.offboarding_document_templates(id),
    
    -- Document details
    name TEXT NOT NULL,
    description TEXT,
    document_type TEXT NOT NULL,
    
    -- File information
    file_reference TEXT, -- Reference to stored file (Supabase storage, etc.)
    file_name TEXT,
    file_size_mb DECIMAL(5,2),
    file_format TEXT,
    
    -- Document status
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN (
        'draft', 'submitted', 'approved', 'rejected', 'revision_required'
    )),
    
    -- Review and approval
    reviewed_by TEXT, -- Anonymous reviewer identifier
    reviewed_at TIMESTAMPTZ,
    review_notes TEXT,
    
    -- Document metadata
    version INTEGER DEFAULT 1,
    is_final BOOLEAN DEFAULT false,
    custom_fields JSONB,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    uploaded_by TEXT -- Anonymous uploader identifier
);

-- Audit trail for offboarding processes
CREATE TABLE IF NOT EXISTS api.offboarding_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES api.clients(id) ON DELETE CASCADE,
    process_id UUID REFERENCES api.offboarding_processes(id) ON DELETE CASCADE,
    task_id UUID REFERENCES api.offboarding_tasks(id) ON DELETE CASCADE,
    
    -- Audit details
    action TEXT NOT NULL, -- 'created', 'updated', 'completed', 'approved', etc.
    entity_type TEXT NOT NULL CHECK (entity_type IN ('process', 'task', 'document', 'template')),
    entity_id UUID NOT NULL,
    
    -- Change tracking
    old_values JSONB,
    new_values JSONB,
    
    -- Actor information
    actor_uid TEXT, -- Anonymous identifier of who performed action
    actor_role TEXT,
    
    -- Audit metadata
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    ip_address INET,
    user_agent TEXT,
    
    -- Additional context
    notes TEXT,
    system_generated BOOLEAN DEFAULT false
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_offboarding_templates_client_type ON api.offboarding_templates(client_id, template_type);
CREATE INDEX IF NOT EXISTS idx_offboarding_templates_department ON api.offboarding_templates(client_id, department, role_category);
CREATE INDEX IF NOT EXISTS idx_offboarding_task_templates_template ON api.offboarding_task_templates(template_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_offboarding_processes_status ON api.offboarding_processes(client_id, status);
CREATE INDEX IF NOT EXISTS idx_offboarding_processes_employee ON api.offboarding_processes(client_id, employee_uid);
CREATE INDEX IF NOT EXISTS idx_offboarding_tasks_process ON api.offboarding_tasks(process_id, status);
CREATE INDEX IF NOT EXISTS idx_offboarding_tasks_assignee ON api.offboarding_tasks(client_id, assigned_to_uid, status);
CREATE INDEX IF NOT EXISTS idx_offboarding_documents_process ON api.offboarding_documents(process_id, status);
CREATE INDEX IF NOT EXISTS idx_offboarding_audit_process ON api.offboarding_audit_log(process_id, timestamp);

-- Row Level Security (RLS) Policies
ALTER TABLE api.offboarding_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.offboarding_task_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.offboarding_document_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.offboarding_processes ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.offboarding_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.offboarding_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.offboarding_audit_log ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for client isolation
CREATE POLICY offboarding_templates_client_isolation ON api.offboarding_templates
    FOR ALL USING (client_id = (SELECT auth.uid()::uuid));

CREATE POLICY offboarding_task_templates_client_isolation ON api.offboarding_task_templates
    FOR ALL USING (client_id = (SELECT auth.uid()::uuid));

CREATE POLICY offboarding_document_templates_client_isolation ON api.offboarding_document_templates
    FOR ALL USING (client_id = (SELECT auth.uid()::uuid));

CREATE POLICY offboarding_processes_client_isolation ON api.offboarding_processes
    FOR ALL USING (client_id = (SELECT auth.uid()::uuid));

CREATE POLICY offboarding_tasks_client_isolation ON api.offboarding_tasks
    FOR ALL USING (client_id = (SELECT auth.uid()::uuid));

CREATE POLICY offboarding_documents_client_isolation ON api.offboarding_documents
    FOR ALL USING (client_id = (SELECT auth.uid()::uuid));

CREATE POLICY offboarding_audit_log_client_isolation ON api.offboarding_audit_log
    FOR ALL USING (client_id = (SELECT auth.uid()::uuid));

-- Add triggers for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_offboarding_templates_updated_at BEFORE UPDATE
    ON api.offboarding_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_offboarding_task_templates_updated_at BEFORE UPDATE
    ON api.offboarding_task_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_offboarding_document_templates_updated_at BEFORE UPDATE
    ON api.offboarding_document_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_offboarding_processes_updated_at BEFORE UPDATE
    ON api.offboarding_processes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_offboarding_tasks_updated_at BEFORE UPDATE
    ON api.offboarding_tasks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_offboarding_documents_updated_at BEFORE UPDATE
    ON api.offboarding_documents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Add audit triggers for change tracking
CREATE OR REPLACE FUNCTION create_audit_log()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO api.offboarding_audit_log (
            client_id, entity_type, entity_id, action, new_values, system_generated
        ) VALUES (
            NEW.client_id, TG_TABLE_NAME::text, NEW.id, 'created', row_to_json(NEW), true
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO api.offboarding_audit_log (
            client_id, entity_type, entity_id, action, old_values, new_values, system_generated
        ) VALUES (
            NEW.client_id, TG_TABLE_NAME::text, NEW.id, 'updated', row_to_json(OLD), row_to_json(NEW), true
        );
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO api.offboarding_audit_log (
            client_id, entity_type, entity_id, action, old_values, system_generated
        ) VALUES (
            OLD.client_id, TG_TABLE_NAME::text, OLD.id, 'deleted', row_to_json(OLD), true
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

-- Create audit triggers
CREATE TRIGGER offboarding_processes_audit AFTER INSERT OR UPDATE OR DELETE
    ON api.offboarding_processes FOR EACH ROW EXECUTE FUNCTION create_audit_log();

CREATE TRIGGER offboarding_tasks_audit AFTER INSERT OR UPDATE OR DELETE
    ON api.offboarding_tasks FOR EACH ROW EXECUTE FUNCTION create_audit_log();

CREATE TRIGGER offboarding_documents_audit AFTER INSERT OR UPDATE OR DELETE
    ON api.offboarding_documents FOR EACH ROW EXECUTE FUNCTION create_audit_log();

-- Create helpful views for common queries
CREATE OR REPLACE VIEW api.offboarding_process_summary AS
SELECT 
    p.id,
    p.client_id,
    p.process_name,
    p.status,
    p.employee_uid,
    p.employee_department,
    p.employee_role,
    p.target_completion_date,
    p.actual_completion_date,
    p.priority,
    t.name as template_name,
    t.template_type,
    
    -- Task statistics
    COUNT(ot.id) as total_tasks,
    COUNT(CASE WHEN ot.status = 'completed' THEN 1 END) as completed_tasks,
    COUNT(CASE WHEN ot.status = 'in_progress' THEN 1 END) as in_progress_tasks,
    COUNT(CASE WHEN ot.status = 'overdue' THEN 1 END) as overdue_tasks,
    
    -- Progress calculation
    CASE 
        WHEN COUNT(ot.id) = 0 THEN 0
        ELSE ROUND((COUNT(CASE WHEN ot.status = 'completed' THEN 1 END)::decimal / COUNT(ot.id)) * 100, 1)
    END as completion_percentage,
    
    p.created_at,
    p.updated_at
FROM api.offboarding_processes p
LEFT JOIN api.offboarding_templates t ON p.template_id = t.id
LEFT JOIN api.offboarding_tasks ot ON p.id = ot.process_id
GROUP BY p.id, t.name, t.template_type;

-- Comments for documentation
COMMENT ON TABLE api.offboarding_templates IS 'Template definitions for offboarding processes, supporting company-wide and department-specific variants';
COMMENT ON TABLE api.offboarding_task_templates IS 'Task templates within offboarding processes, with dependencies and conditional logic';
COMMENT ON TABLE api.offboarding_document_templates IS 'Document templates required for offboarding tasks and processes';
COMMENT ON TABLE api.offboarding_processes IS 'Active offboarding process instances, created from templates';
COMMENT ON TABLE api.offboarding_tasks IS 'Active tasks within offboarding processes, with status tracking and assignment';
COMMENT ON TABLE api.offboarding_documents IS 'Documents created and uploaded during offboarding processes';
COMMENT ON TABLE api.offboarding_audit_log IS 'Comprehensive audit trail for all offboarding-related changes';
COMMENT ON VIEW api.offboarding_process_summary IS 'Summary view of offboarding processes with task statistics and completion percentages';