// Notification Types and Interfaces for flows-admin-demo

export type NotificationType = 
  | 'onboarding_reminder'
  | 'document_review'
  | 'task_assignment'
  | 'process_update'
  | 'deadline_reminder'
  | 'system_alert'
  | 'invitation_sent'
  | 'completion_milestone'
  | 'manager_action_required'
  | 'hr_review_needed';

export type NotificationPriority = 'low' | 'medium' | 'high' | 'urgent';

export type NotificationStatus = 'unread' | 'read' | 'archived' | 'dismissed';

export type NotificationChannel = 'in_app' | 'email' | 'sms' | 'push' | 'slack';

export interface NotificationStakeholder {
  id: string;
  type: 'employee' | 'manager' | 'hr' | 'admin' | 'system';
  name: string;
  email: string;
  avatar?: string;
}

export interface NotificationAction {
  id: string;
  label: string;
  type: 'primary' | 'secondary' | 'danger';
  href?: string;
  action?: string;
  payload?: Record<string, any>;
}

export interface NotificationMetadata {
  processId?: string;
  personId?: string;
  documentId?: string;
  taskId?: string;
  invitationId?: string;
  applicationId?: string;
  clientId?: string;
}

export interface Notification {
  id: string;
  type: NotificationType;
  title: string;
  message: string;
  priority: NotificationPriority;
  status: NotificationStatus;
  channels: NotificationChannel[];
  
  // Stakeholder information
  from: NotificationStakeholder;
  to: NotificationStakeholder[];
  
  // Timestamps
  createdAt: string;
  scheduledFor?: string;
  readAt?: string;
  archivedAt?: string;
  expiresAt?: string;
  
  // Actions and metadata
  actions?: NotificationAction[];
  metadata?: NotificationMetadata;
  
  // Client context
  clientId: string;
  applicationId: string;
}

export interface NotificationPreferences {
  userId: string;
  clientId: string;
  
  // Channel preferences by notification type
  channelPreferences: Record<NotificationType, NotificationChannel[]>;
  
  // General settings
  enableBatching: boolean;
  batchingInterval: number; // minutes
  quietHoursEnabled: boolean;
  quietHoursStart?: string; // HH:MM format
  quietHoursEnd?: string; // HH:MM format
  timezone: string;
  
  // Frequency limits
  maxDailyNotifications: number;
  enableUrgentOverride: boolean;
}

export interface NotificationFilter {
  status?: NotificationStatus[];
  type?: NotificationType[];
  priority?: NotificationPriority[];
  dateRange?: {
    start: string;
    end: string;
  };
  stakeholder?: string;
  clientId?: string;
  applicationId?: string;
}

export interface NotificationStats {
  total: number;
  unread: number;
  byType: Record<NotificationType, number>;
  byPriority: Record<NotificationPriority, number>;
  byStatus: Record<NotificationStatus, number>;
}

// Service interfaces
export interface NotificationService {
  // Core operations
  getNotifications(filter?: NotificationFilter): Promise<Notification[]>;
  getNotification(id: string): Promise<Notification | null>;
  markAsRead(id: string): Promise<void>;
  markAsUnread(id: string): Promise<void>;
  archiveNotification(id: string): Promise<void>;
  dismissNotification(id: string): Promise<void>;
  
  // Bulk operations
  markAllAsRead(filter?: NotificationFilter): Promise<void>;
  archiveAll(filter?: NotificationFilter): Promise<void>;
  
  // Statistics and analytics
  getStats(filter?: NotificationFilter): Promise<NotificationStats>;
  
  // Real-time subscriptions
  subscribe(callback: (notification: Notification) => void): () => void;
  subscribeToStats(callback: (stats: NotificationStats) => void): () => void;
  
  // Demo and testing
  generateDemoNotifications(count?: number): Promise<Notification[]>;
  clearAllNotifications(): Promise<void>;
}

// Demo data generators
export interface NotificationDemoConfig {
  clientId: string;
  applicationId: string;
  stakeholders: NotificationStakeholder[];
  scenarios: NotificationScenario[];
}

export interface NotificationScenario {
  id: string;
  name: string;
  description: string;
  notifications: Partial<Notification>[];
  frequency: 'once' | 'daily' | 'weekly' | 'random';
}

// Event types for real-time updates
export type NotificationEvent = 
  | { type: 'notification_created'; notification: Notification }
  | { type: 'notification_updated'; notification: Notification }
  | { type: 'notification_deleted'; notificationId: string }
  | { type: 'stats_updated'; stats: NotificationStats };