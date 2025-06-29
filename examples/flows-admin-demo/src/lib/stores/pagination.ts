/**
 * Pagination and Lazy Loading Store
 * 
 * Implements efficient pagination for people and processes to avoid N+1 queries
 * and improve performance with large datasets (1000+ records).
 */

import { writable, derived, get } from 'svelte/store';
import { supabase } from '$lib/supabase';
import type { Person, ProcessSummary } from '$lib/types';

// Pagination configuration
export const PAGINATION_CONFIG = {
  PEOPLE_PAGE_SIZE: 25,
  PROCESSES_PAGE_SIZE: 20,
  PRELOAD_PAGES: 1, // Number of pages to preload ahead
} as const;

// Pagination state for people
export const peoplePagination = writable({
  currentPage: 0,
  pageSize: PAGINATION_CONFIG.PEOPLE_PAGE_SIZE,
  totalCount: 0,
  totalPages: 0,
  isLoading: false,
  hasNextPage: false,
  hasPreviousPage: false,
  loadedPages: new Set<number>(),
});

// Pagination state for processes  
export const processesPagination = writable({
  currentPage: 0,
  pageSize: PAGINATION_CONFIG.PROCESSES_PAGE_SIZE,
  totalCount: 0,
  totalPages: 0,
  isLoading: false,
  hasNextPage: false,
  hasPreviousPage: false,
  loadedPages: new Set<number>(),
});

// Paginated data stores
export const paginatedPeople = writable<Map<number, Person[]>>(new Map());
export const paginatedProcesses = writable<Map<number, ProcessSummary[]>>(new Map());

// Current page data (derived from paginated stores)
export const currentPeoplePage = derived(
  [paginatedPeople, peoplePagination],
  ([$paginatedPeople, $pagination]) => {
    return $paginatedPeople.get($pagination.currentPage) || [];
  }
);

export const currentProcessesPage = derived(
  [paginatedProcesses, processesPagination],
  ([$paginatedProcesses, $pagination]) => {
    return $paginatedProcesses.get($pagination.currentPage) || [];
  }
);

/**
 * Load a page of people with efficient bulk queries
 */
export async function loadPeoplePage(
  clientId: string, 
  page: number, 
  options: {
    includeEnrollments?: boolean;
    search?: string;
    filters?: Record<string, any>;
  } = {}
) {
  const pagination = get(peoplePagination);
  const { pageSize } = pagination;
  const offset = page * pageSize;

  // Update loading state
  peoplePagination.update(p => ({ ...p, isLoading: true }));

  try {
    // Step 1: Get total count (only on first load)
    let totalCount = pagination.totalCount;
    if (page === 0 || totalCount === 0) {
      const { count, error: countError } = await supabase
        .from('people')
        .select('*', { count: 'exact', head: true })
        .eq('client_id', clientId);

      if (countError) throw countError;
      totalCount = count || 0;
    }

    // Step 2: Build query with filters
    let query = supabase
      .from('people')
      .select('*')
      .eq('client_id', clientId)
      .order('created_at', { ascending: false })
      .range(offset, offset + pageSize - 1);

    // Apply search filter
    if (options.search) {
      query = query.or(`first_name.ilike.%${options.search}%,last_name.ilike.%${options.search}%,person_code.ilike.%${options.search}%`);
    }

    // Apply additional filters
    if (options.filters) {
      Object.entries(options.filters).forEach(([key, value]) => {
        if (value !== null && value !== undefined) {
          query = query.eq(key, value);
        }
      });
    }

    // Step 3: Load people for this page
    const { data: peopleData, error: peopleError } = await query;
    if (peopleError) throw peopleError;

    const people: Person[] = peopleData?.map(transformPerson) || [];

    // Step 4: Optionally load enrollments in bulk (efficient way)
    if (options.includeEnrollments && people.length > 0) {
      const personIds = people.map(p => p.id);
      
      // Single query to get all enrollments for this page
      const { data: enrollmentsData } = await supabase
        .from('people_enrollments')
        .select('*')
        .in('person_id', personIds);

      // Attach enrollment data to people
      const enrollmentMap = new Map(
        enrollmentsData?.map(e => [e.person_id, e]) || []
      );

      people.forEach(person => {
        const enrollment = enrollmentMap.get(person.id);
        if (enrollment) {
          person.enrollment = {
            onboardingCompleted: enrollment.onboarding_completed,
            completionPercentage: enrollment.completion_percentage,
            lastActivity: enrollment.last_activity,
          };
        }
      });
    }

    // Step 5: Update stores
    paginatedPeople.update(pages => {
      const newPages = new Map(pages);
      newPages.set(page, people);
      return newPages;
    });

    const totalPages = Math.ceil(totalCount / pageSize);
    peoplePagination.update(p => ({
      ...p,
      currentPage: page,
      totalCount,
      totalPages,
      hasNextPage: page < totalPages - 1,
      hasPreviousPage: page > 0,
      loadedPages: new Set([...p.loadedPages, page]),
      isLoading: false,
    }));

    return people;

  } catch (error) {
    console.error('Error loading people page:', error);
    peoplePagination.update(p => ({ ...p, isLoading: false }));
    throw error;
  }
}

/**
 * Load a page of processes
 */
export async function loadProcessesPage(
  clientId: string,
  page: number,
  options: {
    status?: string;
    search?: string;
  } = {}
) {
  const pagination = get(processesPagination);
  const { pageSize } = pagination;
  const offset = page * pageSize;

  processesPagination.update(p => ({ ...p, isLoading: true }));

  try {
    // Get total count
    let totalCount = pagination.totalCount;
    if (page === 0 || totalCount === 0) {
      const { count, error: countError } = await supabase
        .from('offboarding_processes')
        .select('*', { count: 'exact', head: true })
        .eq('client_id', clientId);

      if (countError) throw countError;
      totalCount = count || 0;
    }

    // Build query
    let query = supabase
      .from('offboarding_processes')
      .select(`
        *,
        people:person_id(first_name, last_name, person_code),
        tasks:offboarding_tasks(id, title, status, due_date)
      `)
      .eq('client_id', clientId)
      .order('created_at', { ascending: false })
      .range(offset, offset + pageSize - 1);

    if (options.status) {
      query = query.eq('status', options.status);
    }

    if (options.search) {
      query = query.ilike('title', `%${options.search}%`);
    }

    const { data: processesData, error: processesError } = await query;
    if (processesError) throw processesError;

    const processes: ProcessSummary[] = processesData?.map(transformProcess) || [];

    // Update stores
    paginatedProcesses.update(pages => {
      const newPages = new Map(pages);
      newPages.set(page, processes);
      return newPages;
    });

    const totalPages = Math.ceil(totalCount / pageSize);
    processesPagination.update(p => ({
      ...p,
      currentPage: page,
      totalCount,
      totalPages,
      hasNextPage: page < totalPages - 1,
      hasPreviousPage: page > 0,
      loadedPages: new Set([...p.loadedPages, page]),
      isLoading: false,
    }));

    return processes;

  } catch (error) {
    console.error('Error loading processes page:', error);
    processesPagination.update(p => ({ ...p, isLoading: false }));
    throw error;
  }
}

/**
 * Navigate to next page
 */
export async function nextPeoplePage(clientId: string) {
  const pagination = get(peoplePagination);
  if (pagination.hasNextPage) {
    await loadPeoplePage(clientId, pagination.currentPage + 1);
  }
}

/**
 * Navigate to previous page
 */
export async function previousPeoplePage(clientId: string) {
  const pagination = get(peoplePagination);
  if (pagination.hasPreviousPage) {
    await loadPeoplePage(clientId, pagination.currentPage - 1);
  }
}

/**
 * Go to specific page
 */
export async function goToPeoplePage(clientId: string, page: number) {
  const pagination = get(peoplePagination);
  if (page >= 0 && page < pagination.totalPages) {
    await loadPeoplePage(clientId, page);
  }
}

/**
 * Search people with pagination
 */
export async function searchPeople(clientId: string, searchTerm: string) {
  // Reset to first page for new search
  peoplePagination.update(p => ({ 
    ...p, 
    currentPage: 0,
    totalCount: 0,
    loadedPages: new Set()
  }));
  
  // Clear existing data
  paginatedPeople.set(new Map());
  
  // Load first page with search
  return loadPeoplePage(clientId, 0, { search: searchTerm });
}

/**
 * Reset pagination state
 */
export function resetPeoplePagination() {
  peoplePagination.set({
    currentPage: 0,
    pageSize: PAGINATION_CONFIG.PEOPLE_PAGE_SIZE,
    totalCount: 0,
    totalPages: 0,
    isLoading: false,
    hasNextPage: false,
    hasPreviousPage: false,
    loadedPages: new Set(),
  });
  paginatedPeople.set(new Map());
}

export function resetProcessesPagination() {
  processesPagination.set({
    currentPage: 0,
    pageSize: PAGINATION_CONFIG.PROCESSES_PAGE_SIZE,
    totalCount: 0,
    totalPages: 0,
    isLoading: false,
    hasNextPage: false,
    hasPreviousPage: false,
    loadedPages: new Set(),
  });
  paginatedProcesses.set(new Map());
}

// Helper transform functions (implement based on your existing transform functions)
function transformPerson(data: any): Person {
  return {
    id: data.id,
    personCode: data.person_code,
    firstName: data.first_name,
    lastName: data.last_name,
    email: data.company_email,
    department: data.department,
    position: data.position,
    location: data.location,
    startDate: data.start_date,
    employmentStatus: data.employment_status,
    employmentType: data.employment_type,
    workLocation: data.work_location,
    manager: data.manager,
    securityClearance: data.security_clearance,
    skills: data.skills || [],
    languages: data.languages || [],
    createdAt: data.created_at,
    updatedAt: data.updated_at,
  };
}

function transformProcess(data: any): ProcessSummary {
  return {
    id: data.id,
    title: data.title || `Process for ${data.people?.first_name} ${data.people?.last_name}`,
    personName: `${data.people?.first_name} ${data.people?.last_name}`,
    personCode: data.people?.person_code,
    status: data.status,
    progress: calculateProgress(data.tasks || []),
    dueDate: data.target_completion_date,
    createdAt: data.created_at,
    tasksCount: data.tasks?.length || 0,
    completedTasks: data.tasks?.filter((t: any) => t.status === 'completed').length || 0,
  };
}

function calculateProgress(tasks: any[]): number {
  if (tasks.length === 0) return 0;
  const completed = tasks.filter(t => t.status === 'completed').length;
  return Math.round((completed / tasks.length) * 100);
}