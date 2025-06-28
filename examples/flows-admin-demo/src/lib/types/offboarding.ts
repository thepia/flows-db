// Shadow Organization Offboarding Types
// External monitoring model with privacy-first design

// =====================================================
// CORE OFFBOARDING WORKFLOW TYPES
// =====================================================

export interface OffboardingWorkflow {
  id: string;
  client_id: string;
  app_id?: string;

  // Employee identification (anonymous UID only, no PII)
  employee_uid: string;
  workflow_type: 'offboarding' | 'internal_transfer' | 'role_change' | 'retirement';

  // Workflow status and lifecycle
  status:
    | 'initiated'
    | 'knowledge_transfer'
    | 'coordination'
    | 'verification'
    | 'completed'
    | 'cancelled';
  priority: 'low' | 'standard' | 'high' | 'urgent';

  // Timeline tracking
  initiated_date: string; // ISO date
  expected_last_day?: string;
  knowledge_transfer_deadline?: string;
  final_completion_deadline?: string;
  actual_completion_date?: string;

  // External coordination status
  exit_interview_scheduled: boolean;
  exit_interview_completed: boolean;
  knowledge_transfer_completed: boolean;
  documentation_submitted: boolean;
  handover_verified: boolean;
  compliance_verified: boolean;

  // Credit system integration (175 EUR per offboarding workflow)
  credit_consumed: boolean;
  credit_transaction_id?: string;
  credit_amount: number; // Default 175.00

  // Employee context (categories only, no PII)
  department_category?: string; // 'technical', 'sales', 'operations', 'leadership', 'support'
  seniority_level?: 'junior' | 'mid_level' | 'senior' | 'principal' | 'leadership' | 'executive';
  role_type?: string; // 'individual_contributor', 'team_lead', 'manager', 'director', 'specialist'

  // Workflow complexity assessment
  workflow_complexity: 'simple' | 'standard' | 'complex' | 'executive';
  estimated_knowledge_transfer_hours: number; // Default 8
  number_of_direct_reports: number; // Default 0
  number_of_key_relationships: number; // Default 0

  // Process coordination
  assigned_coordinator?: string; // Role, not name
  requires_legal_review: boolean;
  requires_security_clearance_review: boolean;
  requires_client_notification: boolean;

  // External system coordination flags
  employer_asset_return_required: boolean;
  employer_system_access_review_required: boolean;
  employer_payroll_coordination_required: boolean;

  // Knowledge transfer categorization
  has_critical_system_knowledge: boolean;
  has_client_relationships: boolean;
  has_vendor_relationships: boolean;
  has_specialized_processes: boolean;
  has_team_leadership_responsibilities: boolean;

  // Communication and documentation
  preferred_communication_method: string; // Default 'platform_messaging'
  documentation_language: string; // Default 'en'
  requires_translation: boolean;

  // Timestamps and audit
  created_at: string;
  updated_at: string;
  created_by: string; // Role or system that initiated

  // Auto-deletion compliance (Shadow platform requirement)
  deletion_scheduled_at: string; // Default NOW() + 90 days
  deletion_warning_sent: boolean;
}

// =====================================================
// KNOWLEDGE TRANSFER TYPES
// =====================================================

export interface KnowledgeTransferItem {
  id: string;
  offboarding_workflow_id: string;

  // Knowledge categorization
  knowledge_type:
    | 'process_documentation'
    | 'client_relationships'
    | 'vendor_relationships'
    | 'project_handover'
    | 'system_knowledge'
    | 'tribal_knowledge'
    | 'team_procedures'
    | 'compliance_knowledge'
    | 'training_materials'
    | 'institutional_memory';

  // Knowledge details (employee-provided, no PII)
  title: string;
  description?: string;
  business_impact: 'low' | 'medium' | 'high' | 'critical';
  urgency: 'low' | 'standard' | 'high' | 'immediate';

  // Transfer coordination
  successor_role?: string; // Role/title, not person name
  successor_identified: boolean;
  backup_successor_identified: boolean;

  // Documentation and transfer progress
  documentation_status: 'pending' | 'in_progress' | 'completed' | 'not_required';
  handover_session_required: boolean;
  handover_session_scheduled: boolean;
  handover_session_completed: boolean;

  // Verification and quality assurance
  documentation_reviewed: boolean;
  successor_confirmation_received: boolean;
  knowledge_verified: boolean;

  // Timeline tracking
  target_completion_date?: string;
  actual_completion_date?: string;
  estimated_hours: number; // Default 2.0
  actual_hours?: number;

  // External coordination
  requires_client_introduction: boolean;
  requires_vendor_introduction: boolean;
  requires_system_access_coordination: boolean;
  requires_legal_review: boolean;

  // Quality metrics
  complexity_score?: number; // 1-10
  knowledge_uniqueness_score?: number; // 1-10
  business_continuity_risk?: 'minimal' | 'low' | 'medium' | 'high' | 'severe';

  // Documentation attachments (references only)
  has_written_documentation: boolean;
  has_process_diagrams: boolean;
  has_video_walkthroughs: boolean;
  has_contact_lists: boolean;

  // Timestamps
  created_at: string;
  updated_at: string;
}

// =====================================================
// COMPLIANCE TRACKING TYPES
// =====================================================

export interface OffboardingComplianceCheck {
  id: string;
  offboarding_workflow_id: string;

  // Compliance category and details
  compliance_type:
    | 'exit_interview'
    | 'knowledge_transfer_verification'
    | 'documentation_handover'
    | 'project_transition_confirmation'
    | 'client_notification_completion'
    | 'vendor_notification_completion'
    | 'team_transition_briefing'
    | 'security_clearance_review'
    | 'legal_document_completion'
    | 'hr_policy_compliance'
    | 'equipment_return_coordination'
    | 'system_access_review_coordination'
    | 'payroll_coordination_verification';

  // Compliance status and tracking
  required: boolean;
  criticality: 'optional' | 'standard' | 'important' | 'critical';
  status: 'pending' | 'in_progress' | 'completed' | 'not_applicable' | 'waived';

  // Responsibility and coordination
  responsible_party?: string; // Role/department responsible
  coordinator_assigned?: string; // Shadow platform coordinator role
  requires_external_coordination: boolean; // Requires employer's internal systems

  // Verification and documentation
  completion_evidence?: string; // Description of how compliance was verified
  verified_by?: string; // Role of person who verified completion
  verification_date?: string;
  waiver_reason?: string; // If compliance check was waived
  waiver_approved_by?: string; // Role of person who approved waiver

  // Timeline management
  due_date?: string;
  reminder_sent: boolean;
  escalation_triggered: boolean;
  completed_date?: string;

  // Risk assessment
  non_compliance_risk?: 'minimal' | 'low' | 'medium' | 'high' | 'severe';
  business_impact_if_missed?: string;
  legal_impact_if_missed?: string;

  // External dependencies
  depends_on_employer_systems: boolean;
  depends_on_third_party: boolean;
  dependency_description?: string;

  // Timestamps
  created_at: string;
  updated_at: string;
}

// =====================================================
// COMMUNICATION COORDINATION TYPES
// =====================================================

export interface OffboardingCommunication {
  id: string;
  offboarding_workflow_id: string;

  // Communication type and purpose
  communication_type:
    | 'exit_interview'
    | 'knowledge_handover_meeting'
    | 'client_notification_call'
    | 'vendor_notification_call'
    | 'team_announcement_meeting'
    | 'project_transition_session'
    | 'documentation_review_session'
    | 'compliance_verification_meeting'
    | 'final_wrap_up_call';

  // Scheduling information (privacy-conscious)
  scheduled_date?: string;
  scheduled_time?: string;
  duration_minutes: number; // Default 60
  timezone: string; // Default 'UTC'

  // Meeting coordination
  meeting_platform?: string; // 'zoom', 'teams', 'meet', 'phone', 'in_person'
  meeting_link_provided: boolean;
  calendar_invites_sent: boolean;

  // Participants (roles only, no personal names)
  participant_roles: string[]; // ['departing_employee', 'manager', 'hr_representative', 'successor', 'coordinator']
  facilitator_role?: string;
  required_participants: number; // Default 1
  confirmed_participants: number; // Default 0

  // Communication status
  status: 'scheduled' | 'confirmed' | 'in_progress' | 'completed' | 'cancelled' | 'rescheduled';
  rescheduled_from_date?: string;
  rescheduled_reason?: string;
  cancellation_reason?: string;

  // Preparation and documentation
  agenda_provided: boolean;
  preparation_materials_sent: boolean;
  pre_meeting_requirements_met: boolean;

  // Meeting outcomes
  notes_captured: boolean;
  action_items_assigned: boolean;
  follow_up_required: boolean;
  follow_up_scheduled: boolean;

  // Quality and effectiveness
  objectives_met: boolean;
  participant_satisfaction_score?: number; // 1-10
  meeting_effectiveness_score?: number; // 1-10

  // External coordination needs
  requires_client_participation: boolean;
  requires_vendor_participation: boolean;
  requires_legal_presence: boolean;
  requires_security_clearance: boolean;

  // Documentation and follow-up
  summary_document_created: boolean;
  action_items_tracked: boolean;
  decisions_documented: boolean;
  next_steps_clarified: boolean;

  // Timestamps
  created_at: string;
  updated_at: string;
}

// =====================================================
// CREDIT SYSTEM TYPES
// =====================================================

export interface CreditTransaction {
  id: string;
  client_id: string;
  transaction_type: 'purchase' | 'usage' | 'refund' | 'adjustment' | 'bonus';

  // Credit and pricing information
  credit_amount: number; // Positive for purchase/bonus, negative for usage
  price_per_credit: number; // Default 175.00 EUR
  total_amount: number; // Total transaction amount in EUR
  currency: string; // Default 'EUR'

  // Usage tracking (for 'usage' transactions)
  workflow_type?: 'onboarding' | 'offboarding' | 'role_change' | 'internal_transfer';
  workflow_id?: string; // Reference to offboarding_workflows.id
  employee_uid?: string; // Anonymous employee UID

  // Purchase tracking
  payment_method?:
    | 'credit_card'
    | 'bank_transfer'
    | 'invoice'
    | 'purchase_order'
    | 'stripe'
    | 'paypal';
  payment_reference?: string;
  invoice_number?: string;

  // Bulk pricing and discounts
  base_price_per_credit: number; // Default 175.00
  discount_percentage: number; // Default 0.00
  discount_reason?: string; // 'bulk_purchase', 'loyalty_discount', 'promotional', 'emergency_premium'

  // Special pricing
  emergency_offboarding: boolean; // 350 EUR for urgent departures
  bulk_restructuring: boolean; // 125 EUR for bulk offboardings

  // Transaction metadata
  description?: string;
  internal_notes?: string;

  // Audit and compliance
  created_by: string; // Role/system that created transaction
  approved_by?: string;
  approved_at?: string;

  // Timestamps
  created_at: string;
  updated_at: string;
}

export interface ClientCreditBalance {
  client_id: string;

  // Credit balance tracking
  total_purchased: number;
  total_used: number;
  total_refunded: number;
  total_adjustments: number;

  // Calculated balances
  current_balance: number; // Computed: total_purchased + adjustments - used - refunded
  reserved_credits: number;
  available_credits: number; // Computed: current_balance - reserved

  // Alert and automation thresholds
  low_balance_threshold: number; // Default 10
  critical_balance_threshold: number; // Default 5
  auto_replenish_enabled: boolean;
  auto_replenish_threshold: number; // Default 5
  auto_replenish_amount: number; // Default 50

  // Purchase history
  total_spent: number; // Total amount spent on credits
  average_credit_price: number; // Computed: total_spent / total_purchased

  // Usage patterns
  last_purchase_at?: string;
  last_usage_at?: string;
  last_auto_replenish_at?: string;

  // Lifecycle tracking
  first_purchase_date?: string;
  most_recent_activity: string;

  // Timestamps
  created_at: string;
  updated_at: string;
}

export interface WorkflowCreditUsage {
  id: string;
  client_id: string;
  workflow_id: string;
  workflow_type: 'onboarding' | 'offboarding' | 'role_change' | 'internal_transfer';

  // Employee context (anonymous)
  employee_uid: string;

  // Credit usage details
  credits_consumed: number; // Default 1
  credit_rate: number; // Default 175.00
  total_cost: number;

  // Pricing context
  pricing_tier: 'standard' | 'emergency' | 'bulk' | 'promotional';
  emergency_surcharge: boolean;
  bulk_discount: boolean;
  promotional_discount_applied?: string;

  // Usage tracking
  reserved_at?: string;
  consumed_at: string;
  workflow_initiated_at?: string;
  workflow_completed_at?: string;

  // Credit transaction reference
  credit_transaction_id: string;

  // Workflow outcome tracking
  workflow_status?: string;
  workflow_completion_success?: boolean;
  refund_eligible: boolean;
  refund_processed: boolean;

  // Business context
  department_category?: string;
  seniority_level?: string;
  workflow_complexity?: string;

  // Timestamps
  created_at: string;
  updated_at: string;
}

// =====================================================
// WORKFLOW SUMMARY AND ANALYTICS TYPES
// =====================================================

export interface OffboardingWorkflowSummary {
  workflow: OffboardingWorkflow;
  knowledge_transfer_items: KnowledgeTransferItem[];
  compliance_checks: OffboardingComplianceCheck[];
  communications: OffboardingCommunication[];
  progress: {
    total_knowledge_items: number;
    completed_knowledge_items: number;
    total_compliance_checks: number;
    completed_compliance_checks: number;
    completion_percentage: number;
  };
}

export interface CreditUsageAnalytics {
  period: {
    start_date: string;
    end_date: string;
  };
  summary: {
    total_workflows: number;
    total_credits_consumed: number;
    total_cost: number;
    average_cost_per_workflow: number;
  };
  by_workflow_type: Array<{
    workflow_type: string;
    workflow_count: number;
    total_credits: number;
    total_cost: number;
    avg_rate: number;
    emergency_count: number;
    bulk_count: number;
  }>;
  monthly_trends: Array<{
    month: string;
    workflows: number;
    credits: number;
    cost: number;
  }>;
}

// =====================================================
// FORM AND UI TYPES
// =====================================================

export interface CreateOffboardingWorkflowRequest {
  client_id: string;
  employee_uid: string;
  expected_last_day?: string;
  department_category?: string;
  seniority_level?: OffboardingWorkflow['seniority_level'];
  workflow_complexity?: OffboardingWorkflow['workflow_complexity'];
  priority?: OffboardingWorkflow['priority'];
}

export interface CreateKnowledgeTransferItemRequest {
  offboarding_workflow_id: string;
  knowledge_type: KnowledgeTransferItem['knowledge_type'];
  title: string;
  description?: string;
  business_impact?: KnowledgeTransferItem['business_impact'];
  urgency?: KnowledgeTransferItem['urgency'];
  successor_role?: string;
  estimated_hours?: number;
}

export interface ScheduleCommunicationRequest {
  offboarding_workflow_id: string;
  communication_type: OffboardingCommunication['communication_type'];
  scheduled_date: string;
  scheduled_time?: string;
  duration_minutes?: number;
  participant_roles: string[];
  facilitator_role?: string;
  meeting_platform?: string;
}

export interface UpdateComplianceCheckRequest {
  id: string;
  status: OffboardingComplianceCheck['status'];
  completion_evidence?: string;
  verified_by?: string;
  verification_date?: string;
  waiver_reason?: string;
}

// =====================================================
// API RESPONSE TYPES
// =====================================================

export interface ApiResponse<T> {
  data: T;
  error?: string;
  message?: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  per_page: number;
  total_pages: number;
}

export interface OffboardingDashboardData {
  active_workflows: OffboardingWorkflow[];
  pending_compliance_checks: OffboardingComplianceCheck[];
  upcoming_communications: OffboardingCommunication[];
  credit_balance: ClientCreditBalance;
  recent_activity: Array<{
    type:
      | 'workflow_created'
      | 'knowledge_completed'
      | 'compliance_verified'
      | 'communication_scheduled';
    timestamp: string;
    description: string;
    workflow_id?: string;
  }>;
  metrics: {
    workflows_this_month: number;
    completion_rate: number;
    average_completion_days: number;
    knowledge_transfer_success_rate: number;
  };
}
