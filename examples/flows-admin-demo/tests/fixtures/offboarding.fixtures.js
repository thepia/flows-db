/**
 * Test fixtures for offboarding tests
 * Provides consistent mock data for testing
 */

export const mockOffboardingTemplates = [
  {
    id: 'template-001',
    name: 'Standard Employee Offboarding',
    description: 'Standard process for regular employee departures',
    template_type: 'company_wide',
    department: null,
    role_category: null,
    seniority_level: 'all',
    estimated_duration_days: 14,
    complexity_score: 2,
    task_count: 12,
    usage_count: 45,
    is_default: true,
    requires_manager_approval: true,
    requires_hr_approval: false,
    requires_security_review: false,
    created_at: '2024-01-15T10:00:00Z'
  },
  {
    id: 'template-002',
    name: 'Engineering Department Offboarding',
    description: 'Specialized process for engineering team members',
    template_type: 'department_specific',
    department: 'Engineering',
    role_category: 'technical',
    seniority_level: 'mid_level',
    estimated_duration_days: 21,
    complexity_score: 4,
    task_count: 18,
    usage_count: 12,
    is_default: false,
    requires_manager_approval: true,
    requires_hr_approval: true,
    requires_security_review: true,
    created_at: '2024-02-01T14:30:00Z'
  },
  {
    id: 'template-003',
    name: 'Sales Team Offboarding',
    description: 'Client relationship handover focused process',
    template_type: 'department_specific',
    department: 'Sales',
    role_category: 'client_facing',
    seniority_level: 'senior',
    estimated_duration_days: 10,
    complexity_score: 3,
    task_count: 15,
    usage_count: 8,
    is_default: false,
    requires_manager_approval: true,
    requires_hr_approval: false,
    requires_security_review: false,
    created_at: '2024-03-10T09:15:00Z'
  }
];

export const mockOffboardingProcesses = [
  {
    id: 'process-001',
    process_name: 'John Smith Offboarding',
    template_id: 'template-001',
    employee_id: 'emp-001',
    employee_name: 'John Smith',
    employee_department: 'Engineering',
    status: 'active',
    priority: 'standard',
    completion_percentage: 45,
    target_completion_date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
    actual_start_date: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
    actual_completion_date: null,
    overdue_tasks: 1,
    total_tasks: 12,
    completed_tasks: 5,
    created_at: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString()
  },
  {
    id: 'process-002',
    process_name: 'Sarah Johnson Offboarding',
    template_id: 'template-003',
    employee_id: 'emp-002',
    employee_name: 'Sarah Johnson',
    employee_department: 'Sales',
    status: 'pending_approval',
    priority: 'urgent',
    completion_percentage: 0,
    target_completion_date: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString(),
    actual_start_date: null,
    actual_completion_date: null,
    overdue_tasks: 0,
    total_tasks: 15,
    completed_tasks: 0,
    created_at: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString()
  },
  {
    id: 'process-003',
    process_name: 'Mike Wilson Offboarding',
    template_id: 'template-001',
    employee_id: 'emp-003',
    employee_name: 'Mike Wilson',
    employee_department: 'Marketing',
    status: 'completed',
    priority: 'standard',
    completion_percentage: 100,
    target_completion_date: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString(),
    actual_start_date: new Date(Date.now() - 25 * 24 * 60 * 60 * 1000).toISOString(),
    actual_completion_date: new Date(Date.now() - 8 * 24 * 60 * 60 * 1000).toISOString(),
    overdue_tasks: 0,
    total_tasks: 12,
    completed_tasks: 12,
    created_at: new Date(Date.now() - 25 * 24 * 60 * 60 * 1000).toISOString()
  }
];

export const mockOffboardingTasks = [
  {
    id: 'task-001',
    process_id: 'process-001',
    task_name: 'Return laptop and equipment',
    description: 'Collect and inventory all company equipment',
    status: 'completed',
    priority: 'high',
    assigned_to: 'IT Department',
    due_date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
    completed_date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
    estimated_hours: 1,
    actual_hours: 0.5,
    task_order: 1,
    dependencies: [],
    documents_required: ['Equipment Checklist', 'Return Receipt']
  },
  {
    id: 'task-002',
    process_id: 'process-001',
    task_name: 'Knowledge transfer session',
    description: 'Transfer critical knowledge to team members',
    status: 'in_progress',
    priority: 'critical',
    assigned_to: 'John Smith',
    due_date: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000).toISOString(),
    completed_date: null,
    estimated_hours: 4,
    actual_hours: 2,
    task_order: 2,
    dependencies: ['task-001'],
    documents_required: ['Knowledge Transfer Template', 'Technical Documentation']
  },
  {
    id: 'task-003',
    process_id: 'process-001',
    task_name: 'Disable system access',
    description: 'Revoke all system access and permissions',
    status: 'pending',
    priority: 'critical',
    assigned_to: 'Security Team',
    due_date: new Date(Date.now() + 1 * 24 * 60 * 60 * 1000).toISOString(),
    completed_date: null,
    estimated_hours: 0.5,
    actual_hours: 0,
    task_order: 3,
    dependencies: ['task-002'],
    documents_required: ['Access Revocation Form']
  },
  {
    id: 'task-004',
    process_id: 'process-001',
    task_name: 'Exit interview',
    description: 'Conduct final exit interview',
    status: 'blocked',
    priority: 'medium',
    assigned_to: 'HR Department',
    due_date: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000).toISOString(),
    completed_date: null,
    estimated_hours: 1,
    actual_hours: 0,
    task_order: 4,
    dependencies: [],
    documents_required: ['Exit Interview Form', 'Feedback Survey'],
    blocked_reason: 'Waiting for employee availability'
  }
];

export const mockOffboardingMetrics = {
  activeProcesses: 3,
  endingSoon: 1,
  recentlyCompleted: 5,
  needsAttention: 2,
  pastYearCompleted: 45,
  avgCompletionDays: 12,
  totalProcesses: 48,
  overdue: 1,
  pendingApproval: 1
};

export const mockEmployees = [
  {
    id: 'emp-001',
    name: 'John Smith',
    email: 'john.smith@company.com',
    department: 'Engineering',
    position: 'Senior Software Engineer',
    status: 'active'
  },
  {
    id: 'emp-002',
    name: 'Sarah Johnson',
    email: 'sarah.johnson@company.com',
    department: 'Sales',
    position: 'Account Manager',
    status: 'offboarding'
  },
  {
    id: 'emp-003',
    name: 'Mike Wilson',
    email: 'mike.wilson@company.com',
    department: 'Marketing',
    position: 'Marketing Specialist',
    status: 'terminated'
  }
];

export const mockApiResponses = {
  '/api/offboarding/templates': {
    data: mockOffboardingTemplates,
    success: true,
    total: mockOffboardingTemplates.length
  },
  '/api/offboarding/processes': {
    data: mockOffboardingProcesses,
    success: true,
    total: mockOffboardingProcesses.length
  },
  '/api/offboarding/tasks': {
    data: mockOffboardingTasks,
    success: true,
    total: mockOffboardingTasks.length
  },
  '/api/offboarding/metrics': {
    data: mockOffboardingMetrics,
    success: true
  },
  '/api/employees': {
    data: mockEmployees,
    success: true,
    total: mockEmployees.length
  }
};