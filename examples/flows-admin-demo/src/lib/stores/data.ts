import { writable } from 'svelte/store';
import { reportSupabaseError } from '../config/errorReporting.js';
import { supabase } from '../supabase.js';
import type {
  Application,
  Client,
  DocumentStatus,
  Employee,
  EmployeeEnrollment,
  Invitation,
  TaskStatus,
} from '../types.js';

// Simple hash function for browser (demo purposes)
async function generateSimpleHash(input: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(input);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  const hashHex = hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
  return hashHex;
}

// Store state
export const loading = writable(false);
export const error = writable<string | null>(null);

// Data stores
export const client = writable<Client | null>(null);
export const clients = writable<Client[]>([]);
export const applications = writable<Application[]>([]);
export const employees = writable<Employee[]>([]);
export const enrollments = writable<EmployeeEnrollment[]>([]);
export const documents = writable<DocumentStatus[]>([]);
export const tasks = writable<TaskStatus[]>([]);
export const invitations = writable<Invitation[]>([]);

// Helper function to transform database employee to UI format
function transformEmployee(dbEmployee: any): Employee {
  // Map legacy database status values to new UI status values
  const mapLegacyStatus = (legacyStatus: string): string => {
    switch (legacyStatus) {
      case 'active':
        return 'active';
      case 'offboarded':
        return 'previous';
      case 'future':
        return 'future';
      case 'invited':
      case 'pending':
      case 'offboarding_initiated':
      default:
        return 'other';
    }
  };

  return {
    id: dbEmployee.id,
    email: dbEmployee.company_email,
    firstName: dbEmployee.first_name,
    lastName: dbEmployee.last_name,
    department: dbEmployee.department,
    position: dbEmployee.position,
    startDate: dbEmployee.start_date,
    status: mapLegacyStatus(dbEmployee.status),
    phone: '', // Not in database schema
    manager: dbEmployee.manager || '',
    location: dbEmployee.location,
  };
}

// Helper function to transform database enrollment to UI format
function transformEnrollment(
  dbEnrollment: any,
  dbDocuments: any[],
  dbTasks: any[]
): EmployeeEnrollment {
  // Transform documents
  const documentsStatus = dbDocuments.map(
    (doc: any): DocumentStatus => ({
      id: doc.id,
      name: doc.name,
      type: doc.type,
      status: doc.status,
      uploadedAt: doc.uploaded_at,
      reviewedAt: doc.reviewed_at,
      reviewedBy: doc.reviewed_by,
    })
  );

  // Transform tasks
  const tasksStatus = dbTasks.map(
    (task: any): TaskStatus => ({
      id: task.id,
      title: task.title,
      description: task.description,
      category: task.category,
      status: task.status,
      assignedAt: task.assigned_at,
      completedAt: task.completed_at,
      dueDate: task.due_date,
      assignedBy: task.assigned_by,
      priority: task.priority,
    })
  );

  return {
    employeeId: dbEnrollment.employee_id,
    onboardingCompleted: dbEnrollment.onboarding_completed,
    documentsStatus,
    tasksStatus,
    lastActivity: dbEnrollment.last_activity,
    completionPercentage: dbEnrollment.completion_percentage,
  };
}

// Helper function to transform database invitation to UI format
function transformInvitation(dbInvitation: any): Invitation {
  const clientData = dbInvitation.client_data || {};

  return {
    id: dbInvitation.id,
    companyEmail: clientData.company_email || '',
    privateEmail: clientData.private_email || '',
    firstName: clientData.first_name || '',
    lastName: clientData.last_name || '',
    department: clientData.department || '',
    position: clientData.position || '',
    invitationType: dbInvitation.app_code === 'onboarding' ? 'onboarding' : 'offboarding',
    status: dbInvitation.status,
    createdAt: dbInvitation.created_at,
    sentAt: dbInvitation.first_used_at,
    expiresAt: dbInvitation.expires_at,
    acceptedAt: dbInvitation.accepted_at,
    createdBy: dbInvitation.created_by,
    invitationCode: dbInvitation.invitation_code || '',
    applicationId: dbInvitation.app_id,
  };
}

// Load all clients from Supabase
export async function loadAllClients() {
  try {
    const { data: clientsData, error: clientsError } = await supabase
      .from('clients')
      .select('*')
      .order('legal_name');

    if (clientsError) {
      await reportSupabaseError('clients', 'select', clientsError);
      throw clientsError;
    }

    if (clientsData) {
      const transformedClients: Client[] = clientsData.map((clientData: any) => ({
        id: clientData.id,
        name: clientData.legal_name,
        code: clientData.client_code,
        domain: clientData.domain,
        tier: clientData.tier,
        status: clientData.status,
        region: clientData.region || 'EU',
      }));
      clients.set(transformedClients);
      return transformedClients;
    }
    return [];
  } catch (err) {
    console.error('Failed to load clients:', err);
    return [];
  }
}

// Load data for a specific client
export async function loadClientData(clientId: string) {
  loading.set(true);
  error.set(null);

  try {
    // Load specific client data
    const { data: clientData, error: clientError } = await supabase
      .from('clients')
      .select('*')
      .eq('id', clientId)
      .single();

    if (clientError) {
      await reportSupabaseError('clients', 'select', clientError, { id: clientId });
      throw clientError;
    }

    if (clientData) {
      const transformedClient: Client = {
        id: clientData.id,
        name: clientData.legal_name,
        code: clientData.client_code,
        domain: clientData.domain,
        tier: clientData.tier,
        status: clientData.status,
        region: clientData.region || 'EU',
      };
      client.set(transformedClient);

      // Load rest of the data using the existing logic...
      await loadClientSpecificData(clientData.id);
    }
  } catch (err) {
    const errorMessage = err instanceof Error ? err.message : 'Unknown error loading client data';
    error.set(errorMessage);
    console.error('Error loading client data:', err);
  } finally {
    loading.set(false);
  }
}

// Helper function to load client-specific data
async function loadClientSpecificData(clientId: string) {
  loading.set(true);
  error.set(null);

  try {
    // Load client data
    const { data: clientData, error: clientError } = await supabase
      .from('clients')
      .select('*')
      .eq('client_code', 'nets-demo')
      .single();

    if (clientError) {
      await reportSupabaseError('clients', 'select', clientError, { filter: 'nets-demo' });
      throw clientError;
    }

    if (clientData) {
      const transformedClient: Client = {
        id: clientData.id,
        name: clientData.legal_name,
        code: clientData.client_code,
        domain: clientData.domain,
        tier: clientData.tier,
        status: clientData.status,
        region: clientData.region || 'EU',
      };
      client.set(transformedClient);

      // Load applications
      const { data: appsData, error: appsError } = await supabase
        .from('client_applications')
        .select('*')
        .eq('client_id', clientData.id);

      if (appsError) {
        await reportSupabaseError('client_applications', 'select', appsError, {
          client_id: clientData.id,
        });
        throw appsError;
      }

      if (appsData && appsData.length > 0) {
        const transformedApps: Application[] = appsData.map((app: any) => ({
          id: app.id,
          clientId: app.client_id,
          name: app.app_name,
          code: app.app_code,
          type: app.app_code.includes('onboarding') ? 'onboarding' : 'offboarding',
          status: app.status,
          version: app.app_version || '1.0.0',
          description: app.app_description,
          features: Array.isArray(app.features) ? app.features : [],
          configuration: app.configuration || {},
          permissions: app.permissions || {},
          maxConcurrentUsers: app.max_concurrent_users || 50,
          lastAccessed: app.last_accessed,
          createdAt: app.created_at,
        }));
        applications.set(transformedApps);
      } else {
        // Fallback to mock applications if none found in database
        const mockApps: Application[] = [
          {
            id: 'app-offboarding-001',
            clientId: clientData.id,
            name: 'Employee Offboarding',
            code: 'offboarding',
            type: 'offboarding',
            status: 'active',
            version: '1.0.0',
            description: 'Task-oriented employee offboarding and departure management',
            features: ['task-management', 'document-upload', 'compliance-tracking'],
            configuration: {},
            permissions: {},
            maxConcurrentUsers: 50,
            lastAccessed: new Date().toISOString(),
            createdAt: new Date().toISOString(),
          },
          {
            id: 'app-onboarding-001',
            clientId: clientData.id,
            name: 'Employee Onboarding',
            code: 'onboarding',
            type: 'onboarding',
            status: 'active',
            version: '1.0.0',
            description: 'Streamlined employee onboarding and setup',
            features: ['invitation-management', 'document-collection', 'task-tracking'],
            configuration: {},
            permissions: {},
            maxConcurrentUsers: 50,
            lastAccessed: new Date().toISOString(),
            createdAt: new Date().toISOString(),
          }
        ];
        applications.set(mockApps);
      }

      // Load employees
      const { data: employeesData, error: employeesError } = await supabase
        .from('employees')
        .select('*')
        .eq('client_id', clientData.id);

      if (employeesError) {
        await reportSupabaseError('employees', 'select', employeesError, {
          client_id: clientData.id,
        });
        throw employeesError;
      }

      if (employeesData) {
        const transformedEmployees: Employee[] = employeesData.map(transformEmployee);
        employees.set(transformedEmployees);

        // Load enrollments with related data
        const enrollmentsData: EmployeeEnrollment[] = [];

        for (const employee of employeesData) {
          // Get enrollment
          const { data: enrollmentData } = await supabase
            .from('employee_enrollments')
            .select('*')
            .eq('employee_id', employee.id)
            .single();

          // Get documents
          const { data: documentsData } = await supabase
            .from('documents')
            .select('*')
            .eq('employee_id', employee.id);

          // Get tasks
          const { data: tasksData } = await supabase
            .from('tasks')
            .select('*')
            .eq('employee_id', employee.id);

          if (enrollmentData) {
            enrollmentsData.push(
              transformEnrollment(enrollmentData, documentsData || [], tasksData || [])
            );
          }

          // Store individual documents and tasks for global access
          if (documentsData) {
            documents.update((docs) => [
              ...docs,
              ...documentsData.map(
                (doc: any): DocumentStatus => ({
                  id: doc.id,
                  name: doc.name,
                  type: doc.type,
                  status: doc.status,
                  uploadedAt: doc.uploaded_at,
                  reviewedAt: doc.reviewed_at,
                  reviewedBy: doc.reviewed_by,
                })
              ),
            ]);
          }

          if (tasksData) {
            tasks.update((tasks) => [
              ...tasks,
              ...tasksData.map(
                (task: any): TaskStatus => ({
                  id: task.id,
                  title: task.title,
                  description: task.description,
                  category: task.category,
                  status: task.status,
                  assignedAt: task.assigned_at,
                  completedAt: task.completed_at,
                  dueDate: task.due_date,
                  assignedBy: task.assigned_by,
                  priority: task.priority,
                })
              ),
            ]);
          }
        }

        enrollments.set(enrollmentsData);
      }

      // Load invitations
      const { data: invitationsData, error: invitationsError } = await supabase
        .from('invitations')
        .select(
          `
          *,
          client_applications!inner(app_code)
        `
        )
        .eq('client_id', clientData.id);

      if (invitationsError) {
        await reportSupabaseError('invitations', 'select', invitationsError, {
          client_id: clientData.id,
        });
        throw invitationsError;
      }

      if (invitationsData) {
        const transformedInvitations: Invitation[] = invitationsData.map((inv: any) => {
          const transformed = transformInvitation(inv);
          // Add app_code for invitationType
          if (inv.client_applications?.app_code) {
            transformed.invitationType =
              inv.client_applications.app_code === 'onboarding' ? 'onboarding' : 'offboarding';
          }
          return transformed;
        });
        invitations.set(transformedInvitations);
      }
    }
  } catch (err) {
    console.error('Error loading demo data:', err);
    const errorMessage = err instanceof Error ? err.message : 'Failed to load demo data';
    error.set(errorMessage);

    // Report the overall data loading error
    await reportSupabaseError('general', 'select', err, {
      operation: 'loadDemoData',
      stage: 'unknown',
    });
  } finally {
    loading.set(false);
  }
}

// Load demo data using default client (backwards compatibility)
export async function loadDemoData() {
  loading.set(true);
  error.set(null);

  try {
    // Try to load the default demo client (nets-demo)
    const { data: clientData, error: clientError } = await supabase
      .from('clients')
      .select('*')
      .eq('client_code', 'nets-demo')
      .single();

    if (clientError) {
      // If nets-demo doesn't exist, try to load any demo client
      const { data: demoClients, error: demoError } = await supabase
        .from('clients')
        .select('*')
        .ilike('client_code', '%demo%')
        .limit(1);

      if (demoError || !demoClients || demoClients.length === 0) {
        // If no demo clients, load the first available client
        const { data: anyClient, error: anyError } = await supabase
          .from('clients')
          .select('*')
          .limit(1);

        if (anyError || !anyClient || anyClient.length === 0) {
          throw new Error('No clients found in database');
        }

        await loadClientData(anyClient[0].id);
        return;
      }

      await loadClientData(demoClients[0].id);
      return;
    }

    if (clientData) {
      await loadClientData(clientData.id);
    }
  } catch (err) {
    const errorMessage = err instanceof Error ? err.message : 'Failed to load demo data';
    error.set(errorMessage);
    console.error('Error loading demo data:', err);

    await reportSupabaseError('general', 'select', err, {
      operation: 'loadDemoData',
    });
  } finally {
    loading.set(false);
  }
}

// Helper function to get employee enrollment
export function getEmployeeEnrollment(employeeId: string) {
  let result: EmployeeEnrollment | undefined;
  enrollments.subscribe((enrollments) => {
    result = enrollments.find((e) => e.employeeId === employeeId);
  })();
  return result;
}

// Helper function to get employee invitations
export function getEmployeeInvitations(employeeId: string) {
  let employee: Employee | undefined;
  let result: Invitation[] = [];

  employees.subscribe((employees) => {
    employee = employees.find((e) => e.id === employeeId);
  })();

  if (employee) {
    invitations.subscribe((invitations) => {
      result = invitations.filter(
        (inv) => inv.companyEmail === employee!.email || inv.privateEmail === employee!.email
      );
    })();
  }

  return result;
}

// Helper function to get application by type
export function getApplicationByType(type: 'onboarding' | 'offboarding') {
  let result: Application | undefined;
  applications.subscribe((applications) => {
    result = applications.find((app) => app.type === type);
  })();
  return result;
}

// Create a new invitation in the database
export async function createInvitation(invitationData: {
  companyEmail: string;
  privateEmail: string;
  firstName: string;
  lastName: string;
  department: string;
  position: string;
  invitationType: 'onboarding' | 'offboarding';
  associationStartDate?: string;
  associationEndDate?: string;
}) {
  try {
    // Get current client data
    let currentClient: Client | null = null;
    client.subscribe((c) => (currentClient = c))();

    if (!currentClient) {
      throw new Error('No client data available');
    }

    // Get the application for this invitation type
    const application = getApplicationByType(invitationData.invitationType);
    if (!application) {
      throw new Error(`No ${invitationData.invitationType} application found`);
    }

    // Generate invitation code (uppercase per database constraint)
    const invitationCode = `${currentClient.code.toUpperCase()}-${Date.now()}`;

    // Generate JWT token with proper structure
    const timestamp = Date.now();
    const jwtPayload = {
      iss: 'api.thepia.com',
      aud: 'flows.thepia.net',
      sub: `inv-${invitationCode}`,
      exp: Math.floor((Date.now() + 7 * 24 * 60 * 60 * 1000) / 1000), // 7 days
      iat: Math.floor(Date.now() / 1000),
      invitation: {
        invitee: {
          fullName: `${invitationData.firstName} ${invitationData.lastName}`,
          companyEmail: invitationData.companyEmail,
          privateEmail: invitationData.privateEmail,
        },
        position: invitationData.position,
        department: invitationData.department,
        type: invitationData.invitationType,
        // Optional association dates
        ...(invitationData.associationStartDate || invitationData.associationEndDate
          ? {
              association: {
                ...(invitationData.associationStartDate
                  ? { startDate: invitationData.associationStartDate }
                  : {}),
                ...(invitationData.associationEndDate
                  ? { endDate: invitationData.associationEndDate }
                  : {}),
              },
            }
          : {}),
      },
    };

    // Generate JWT token hash
    const jwtTokenHash = await generateSimpleHash(JSON.stringify(jwtPayload));

    // Set expiration date (7 days from now)
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    // Prepare invitation data for database
    const dbInvitationData = {
      client_id: currentClient.id,
      app_id: application.id,
      invitation_code: invitationCode,
      jwt_token_hash: jwtTokenHash,
      client_data: {
        company_email: invitationData.companyEmail,
        private_email: invitationData.privateEmail,
        first_name: invitationData.firstName,
        last_name: invitationData.lastName,
        department: invitationData.department,
        position: invitationData.position,
      },
      status: 'pending',
      expires_at: expiresAt.toISOString(),
      created_by: 'admin@thepia.com', // In production, this would be the current user
    };

    // Insert into database
    const { data: newInvitation, error } = await supabase
      .from('invitations')
      .insert(dbInvitationData)
      .select(
        `
        *,
        client_applications!inner(app_code)
      `
      )
      .single();

    if (error) {
      await reportSupabaseError('invitations', 'insert', error, {
        client_id: currentClient.id,
        app_id: application.id,
      });
      throw error;
    }

    // Transform to UI format
    const transformedInvitation = transformInvitation(newInvitation);
    if (newInvitation.client_applications?.app_code) {
      transformedInvitation.invitationType =
        newInvitation.client_applications.app_code === 'onboarding' ? 'onboarding' : 'offboarding';
    }

    // Update local store
    invitations.update((current) => [...current, transformedInvitation]);

    return transformedInvitation;
  } catch (err) {
    console.error('Error creating invitation:', err);
    await reportSupabaseError('invitations', 'insert', err, {
      operation: 'createInvitation',
      invitationData,
    });
    throw err;
  }
}

// Create a new employee in the database
export async function createEmployee(employeeData: {
  firstName: string;
  lastName: string;
  companyEmail: string;
  department: string;
  position: string;
  location: string;
  manager?: string;
  startDate?: string;
  endDate?: string;
  employmentType: 'full_time' | 'part_time' | 'contractor' | 'intern';
  workLocation: 'office' | 'remote' | 'hybrid';
  status: 'active' | 'previous' | 'future' | 'other';
  securityClearance: 'low' | 'medium' | 'high';
}) {
  try {
    // Get current client data
    let currentClient: Client | null = null;
    client.subscribe((c) => (currentClient = c))();

    if (!currentClient) {
      throw new Error('No client data available');
    }

    // Generate employee code (using client code + timestamp)
    const employeeCode = `${currentClient.code}-emp-${Date.now()}`;

    // Map new status values to legacy database values (temporary until schema update)
    const mapStatusToLegacy = (status: 'active' | 'previous' | 'future' | 'other'): string => {
      switch (status) {
        case 'active':
          return 'active';
        case 'previous':
          return 'offboarded';
        case 'future':
          return 'future';
        case 'other':
          return 'pending';
        default:
          return 'active';
      }
    };

    // Prepare employee data for database
    const dbEmployeeData = {
      client_id: currentClient.id,
      employee_code: employeeCode,
      first_name: employeeData.firstName,
      last_name: employeeData.lastName,
      company_email: employeeData.companyEmail,
      department: employeeData.department,
      position: employeeData.position,
      location: employeeData.location,
      manager: employeeData.manager || null,
      start_date: employeeData.startDate || null,
      end_date: employeeData.endDate || null,
      employment_type: employeeData.employmentType,
      work_location: employeeData.workLocation,
      status: mapStatusToLegacy(employeeData.status),
      security_clearance: employeeData.securityClearance,
      skills: [],
      languages: [],
    };

    // Insert into database
    const { data: newEmployee, error } = await supabase
      .from('employees')
      .insert(dbEmployeeData)
      .select('*')
      .single();

    if (error) {
      await reportSupabaseError('employees', 'insert', error, {
        client_id: currentClient.id,
        employee_code: employeeCode,
      });
      throw error;
    }

    // Transform to UI format
    const transformedEmployee = transformEmployee(newEmployee);

    // Update local store
    employees.update((current) => [...current, transformedEmployee]);

    return transformedEmployee;
  } catch (err) {
    console.error('Error creating employee:', err);
    await reportSupabaseError('employees', 'insert', err, {
      operation: 'createEmployee',
      employeeData,
    });
    throw err;
  }
}

// Get meaningful business metrics for dashboard
export async function getClientMetrics() {
  try {
    // Get current client data
    let currentClient: Client | null = null;
    client.subscribe((c) => (currentClient = c))();

    if (!currentClient) {
      throw new Error('No client data available');
    }

    // For now, use a simplified approach based on existing data
    // TODO: Replace with proper database functions after schema migration

    // Get all employees for this client
    const { data: employeeData, error: employeeError } = await supabase
      .from('employees')
      .select('id, status')
      .eq('client_id', currentClient.id);

    if (employeeError) {
      await reportSupabaseError('employees', 'select', employeeError, {
        client_id: currentClient.id,
      });
      throw employeeError;
    }

    // Get all enrollments for these employees
    const employeeIds = employeeData?.map((e) => e.id) || [];

    if (employeeIds.length === 0) {
      return { onboardingCount: 0, offboardingCount: 0 };
    }

    const { data: enrollmentData, error: enrollmentError } = await supabase
      .from('employee_enrollments')
      .select('employee_id, onboarding_completed, completion_percentage')
      .in('employee_id', employeeIds);

    if (enrollmentError) {
      await reportSupabaseError('employee_enrollments', 'select', enrollmentError, {
        client_id: currentClient.id,
      });
      throw enrollmentError;
    }

    // Get onboarding and offboarding invitations
    const { data: invitationData, error: invitationError } = await supabase
      .from('invitations')
      .select(
        `
        client_data,
        client_applications!inner(app_code)
      `
      )
      .eq('client_id', currentClient.id)
      .eq('status', 'pending');

    if (invitationError) {
      await reportSupabaseError('invitations', 'select', invitationError, {
        client_id: currentClient.id,
      });
      throw invitationError;
    }

    // Calculate simplified metrics
    // Onboarding: Employees with incomplete onboarding (completion < 100%)
    const onboardingCount =
      enrollmentData?.filter((e) => !e.onboarding_completed && e.completion_percentage < 100)
        .length || 0;

    // Offboarding: Count of pending offboarding invitations (simplified)
    const offboardingCount =
      invitationData?.filter((inv) => inv.client_applications?.app_code === 'offboarding').length ||
      0;

    return {
      onboardingCount,
      offboardingCount,
    };
  } catch (err) {
    console.error('Error getting client metrics:', err);
    await reportSupabaseError('general', 'metrics', err, {
      operation: 'getClientMetrics',
    });

    // Return fallback values instead of throwing
    return {
      onboardingCount: 0,
      offboardingCount: 0,
    };
  }
}
