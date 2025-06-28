export interface Employee {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  department: string;
  position: string;
  startDate: string;
  status: 'active' | 'previous' | 'future' | 'other';
  avatar?: string;
  phone?: string;
  manager?: string;
  location: string;
}

export interface EmployeeEnrollment {
  employeeId: string;
  onboardingCompleted: boolean;
  documentsStatus: DocumentStatus[];
  tasksStatus: TaskStatus[];
  lastActivity: string;
  completionPercentage: number;
}

export interface DocumentStatus {
  id: string;
  name: string;
  type: 'contract' | 'id_verification' | 'tax_form' | 'handbook' | 'other';
  status: 'pending' | 'uploaded' | 'verified' | 'rejected';
  uploadedAt?: string;
  reviewedAt?: string;
  reviewedBy?: string;
  comments?: string;
}

export interface TaskStatus {
  id: string;
  title: string;
  description: string;
  category: 'onboarding' | 'training' | 'compliance' | 'equipment' | 'other';
  status: 'not_started' | 'in_progress' | 'completed' | 'overdue';
  assignedAt: string;
  dueDate?: string;
  completedAt?: string;
  assignedBy: string;
  priority: 'low' | 'medium' | 'high';
}

export interface Invitation {
  id: string;
  companyEmail: string;
  privateEmail: string;
  firstName: string;
  lastName: string;
  department: string;
  position: string;
  invitationType: 'onboarding' | 'offboarding';
  status: 'pending' | 'sent' | 'accepted' | 'expired' | 'revoked';
  createdAt: string;
  sentAt?: string;
  expiresAt: string;
  acceptedAt?: string;
  createdBy: string;
  invitationCode?: string;
  applicationId: string;
}

export interface Client {
  id: string;
  name: string;
  code: string;
  domain: string;
  tier: 'free' | 'pro' | 'enterprise';
  status: 'active' | 'suspended' | 'deactivated';
  region: string;
}

export interface Application {
  id: string;
  clientId: string;
  name: string;
  code: string;
  type: 'onboarding' | 'offboarding';
  status: 'active' | 'inactive' | 'maintenance' | 'deprecated';
  version: string;
  description?: string;
  features: string[];
  configuration: Record<string, any>;
  permissions: Record<string, any>;
  maxConcurrentUsers: number;
  lastAccessed?: string;
  createdAt: string;
}

export interface BrandingConfig {
  id: string;
  name: string;
  displayName: string;
  type: 'package' | 'local';
  path: string; // npm package name or local folder path
  isDefault?: boolean;
}

export interface DemoSettings {
  selectedBranding: string; // BrandingConfig.id
  selectedClient: string; // Client.id
  allowRealClients: boolean;
  availableBrandings: BrandingConfig[];
  lastUpdated: string;
}

export interface SettingsState {
  settings: DemoSettings;
  loading: boolean;
  error: string | null;
}

export interface DemoCompany {
  id: string;
  name: string;
  displayName: string;
  industry: string;
  description: string;
  employeeCount: number;
  onboardingCount: number;
  offboardingCount: number;
  demoType: 'prospect' | 'internal' | 'training';
  complexity: 'simple' | 'standard' | 'complex';
  isActive: boolean;
  lastGenerated?: string;
  generationStatus: 'not_generated' | 'generating' | 'completed' | 'error';
}

export interface DemoGenerationConfig {
  companyId: string;
  employeeCount: number;
  onboardingCount: number;
  offboardingCount: number;
  includeHistoricalData: boolean;
  generateDocuments: boolean;
  generateTasks: boolean;
  complexity: 'simple' | 'standard' | 'complex';
}

export interface DemoMetrics {
  totalCompanies: number;
  totalEmployees: number;
  activeProcesses: number;
  completedProcesses: number;
  totalDocuments: number;
  totalTasks: number;
  lastUpdated: string;
}

export interface DemoTemplate {
  id: string;
  name: string;
  type: 'document' | 'task' | 'workflow';
  category: string;
  description: string;
  isActive: boolean;
  usageCount: number;
}

export interface DemoAction {
  id: string;
  type: 'generate' | 'reset' | 'export' | 'import';
  companyId?: string;
  status: 'pending' | 'running' | 'completed' | 'error';
  progress: number;
  message: string;
  startedAt: string;
  completedAt?: string;
}
