<script lang="ts">
import DashboardMetrics from '$lib/components/dashboard/DashboardMetrics.svelte';
import InvitationsSidebar from '$lib/components/dashboard/InvitationsSidebar.svelte';
import EmployeeDirectory from '$lib/components/employee/EmployeeDirectory.svelte';
import FloatingStatusButton from '$lib/components/FloatingStatusButton.svelte';
import LoadingAnimation from '$lib/components/shared/LoadingAnimation.svelte';
import OffboardingDashboard from '$lib/components/offboarding/OffboardingDashboard.svelte';
import TemplateManager from '$lib/components/offboarding/TemplateManager.svelte';
import ProcessManager from '$lib/components/offboarding/ProcessManager.svelte';
import TaskManager from '$lib/components/offboarding/TaskManager.svelte';
import ProcessList from '$lib/components/offboarding/ProcessList.svelte';
import { Button } from '$lib/components/ui/button';
import {
  applications,
  client,
  clients,
  employees,
  enrollments,
  error,
  getClientMetrics,
  invitations,
  loadAllClients,
  loadDemoData,
  loading,
  totalPeopleCount,
} from '$lib/stores/data';
import { settingsStore } from '$lib/stores/settings';
import { supabase } from '$lib/supabase';
import { AlertCircle, Briefcase, Plus, UserMinus, UserPlus, Users, Settings, CreditCard, FileText, Shield, Download } from 'lucide-svelte';
import TFCManagementPanel from '$lib/components/tfc/TFCManagementPanel.svelte';
import { onMount } from 'svelte';
import { getMockOffboardingData, getTasksForProcess } from '$lib/mockData/offboarding';

// Tab state
let activeTab = 'people';

// Metrics state
let onboardingCount = 0;
let offboardingCount = 0;

// Offboarding state
let offboardingView = 'overview'; // 'overview', 'templates', 'processes', 'tasks'
let selectedTemplate = null;
let selectedProcess = null;
let offboardingTemplates = [];
let offboardingProcesses = [];
let allProcesses = []; // For the main Processes tab
let offboardingTasks = [];
let metricsLoading = false;

// Process filtering state
let processFilters = {
	status: null,
	timeframe: null,
	search: '',
	department: null,
	priority: null,
	template: null
};
let showProcessList = false;

// Account/TFC state
let tfcBalance = null;
let recentInvoices = [];
let accountContacts = [];
let loadingAccount = false;

// Filter handling functions
function applyProcessFilter(filterType, filterValue) {
	// Reset filters
	processFilters = {
		status: null,
		timeframe: null,
		search: '',
		department: null,
		priority: null,
		template: null
	};
	
	// Apply specific filter
	processFilters[filterType] = filterValue;
	showProcessList = true;
	
	// Scroll to process list
	setTimeout(() => {
		const processListElement = document.getElementById('process-list-section');
		if (processListElement) {
			processListElement.scrollIntoView({ behavior: 'smooth' });
		}
	}, 100);
}

function clearProcessFilters() {
	processFilters = {
		status: null,
		timeframe: null,
		search: '',
		department: null,
		priority: null,
		template: null
	};
	showProcessList = false;
}

// Helper function to format currency
function formatCurrency(amount, currency = 'EUR') {
	if (!amount) return `${currency} 0`;
	return `${currency} ${parseFloat(amount).toLocaleString()}`;
}

// Load account data (TFC balance, invoices, contacts)
async function loadAccountData() {
	if (!$client?.id) return;
	
	loadingAccount = true;
	try {
		// Load TFC balance
		const { data: balanceData, error: balanceError } = await supabase
			.from('tfc_client_balances')
			.select('*')
			.eq('client_id', $client.id)
			.single();
		
		if (balanceError) {
			console.warn('No TFC balance found:', balanceError);
			tfcBalance = null;
		} else {
			tfcBalance = balanceData;
		}
		
		// Load recent invoices (last 5)
		const { data: invoicesData, error: invoicesError } = await supabase
			.from('tfc_invoices')
			.select('*')
			.eq('client_id', $client.id)
			.order('invoice_date', { ascending: false })
			.limit(5);
		
		if (invoicesError) {
			console.warn('Error loading invoices:', invoicesError);
			recentInvoices = [];
		} else {
			recentInvoices = invoicesData || [];
		}
		
		// Load account contacts
		const { data: contactsData, error: contactsError } = await supabase
			.from('account_contacts')
			.select('*')
			.eq('client_id', $client.id)
			.order('created_at', { ascending: true });
		
		if (contactsError) {
			console.warn('Error loading contacts:', contactsError);
			accountContacts = [];
		} else {
			accountContacts = contactsData || [];
		}
		
		console.log('📊 Account data loaded:', {
			balance: tfcBalance,
			invoices: recentInvoices.length,
			contacts: accountContacts.length
		});
		
	} catch (error) {
		console.error('Error loading account data:', error);
	} finally {
		loadingAccount = false;
	}
}

// Generate demo process data
async function generateProcessData() {
	console.log('🔄 Starting process data generation...');
	
	try {
		// Get the current client (Hygge & Hvidløg)
		const { data: clientData, error: clientError } = await supabase
			.from('clients')
			.select('id, client_code')
			.eq('client_code', 'hygge-hvidlog')
			.single();
			
		if (clientError) {
			console.error('❌ Error fetching client:', clientError);
			alert('Error: Could not find hygge-hvidlog client');
			return;
		}
		
		if (!clientData) {
			console.error('❌ Hygge & Hvidløg client not found');
			alert('Error: hygge-hvidlog client not found in database');
			return;
		}

		console.log(`📊 Working with client: ${clientData.client_code}`);

		// Get all people for this client
		const { data: people, error: peopleError } = await supabase
			.from('people')
			.select('id, person_code, first_name, last_name, department, position')
			.eq('client_id', clientData.id);
			
		if (peopleError) {
			console.error('❌ Error fetching people:', peopleError);
			alert('Error fetching people: ' + peopleError.message);
			return;
		}

		console.log(`👥 Found ${people?.length || 0} people`);

		if (!people || people.length === 0) {
			console.error('❌ No people found for client');
			alert('Error: No people found for this client');
			return;
		}
		
		// Create enrollments for 70% of people (onboarding)
		const enrollmentCount = Math.floor(people.length * 0.7);
		const enrollments = [];
		
		for (let i = 0; i < enrollmentCount; i++) {
			const person = people[i];
			const completionPercentage = Math.floor(Math.random() * 80) + 10;
			
			enrollments.push({
				person_id: person.id,
				onboarding_completed: completionPercentage >= 95,
				completion_percentage: completionPercentage,
				mentor: 'Demo Mentor',
				buddy_program: Math.random() > 0.5,
				last_activity: new Date().toISOString()
			});
		}
		
		console.log(`📝 Creating ${enrollments.length} enrollment records...`);
		
		// Insert enrollments
		const { error: enrollmentError } = await supabase
			.from('people_enrollments')
			.insert(enrollments);
			
		if (enrollmentError) {
			console.error('❌ Error creating enrollments:', enrollmentError);
			alert('Error creating enrollments: ' + enrollmentError.message);
			return;
		}
		
		console.log('✅ Created enrollment records');
		
		// Create offboarding template if needed
		let { data: template } = await supabase
			.from('offboarding_templates')
			.select('id')
			.eq('client_id', clientData.id)
			.eq('is_default', true)
			.single();
			
		if (!template) {
			const { data: newTemplate, error: templateError } = await supabase
				.from('offboarding_templates')
				.insert({
					client_id: clientData.id,
					name: 'Standard Offboarding Process',
					description: 'Default offboarding process for all employees',
					template_type: 'company_wide',
					estimated_duration_days: 14,
					complexity_score: 2,
					is_active: true,
					is_default: true,
					requires_manager_approval: true,
					requires_hr_approval: true,
					auto_assign_tasks: true,
					created_by: 'system-demo'
				})
				.select('id')
				.single();
				
			if (templateError) {
				console.error('❌ Error creating template:', templateError);
				alert('Error creating template: ' + templateError.message);
				return;
			}
			template = newTemplate;
			console.log('✅ Created offboarding template');
		}
		
		// Create offboarding processes for 15% of people
		const processCount = Math.floor(people.length * 0.15);
		const processes = [];
		const statuses = ['draft', 'pending_approval', 'active'];
		const priorities = ['low', 'medium', 'high'];
		
		for (let i = 0; i < processCount; i++) {
			const person = people[i + enrollmentCount]; // Use different people than enrollment
			if (!person) break;
			
			processes.push({
				client_id: clientData.id,
				template_id: template.id,
				employee_uid: person.person_code,
				employee_department: person.department,
				employee_role: person.position,
				process_name: `${person.first_name} ${person.last_name} Offboarding`,
				status: statuses[Math.floor(Math.random() * statuses.length)],
				priority: priorities[Math.floor(Math.random() * priorities.length)],
				target_completion_date: new Date(Date.now() + (Math.floor(Math.random() * 30) + 15) * 24 * 60 * 60 * 1000).toISOString(),
				created_by: 'demo-system'
			});
		}
		
		console.log(`📋 Creating ${processes.length} offboarding processes...`);
		
		// Insert processes
		const { error: processError } = await supabase
			.from('offboarding_processes')
			.insert(processes);
			
		if (processError) {
			console.error('❌ Error creating processes:', processError);
			alert('Error creating processes: ' + processError.message);
			return;
		}
		
		console.log('✅ Created offboarding processes');
		
		// Reload data to see the changes
		await loadProcessesData();
		await loadMetrics();
		
		alert(`🎉 Success! Created ${enrollments.length} onboarding enrollments and ${processes.length} offboarding processes!`);
		
	} catch (error) {
		console.error('❌ Process data generation failed:', error);
		alert('Error: ' + error.message);
	}
}

// Load mock offboarding data
function loadOffboardingData() {
  const mockData = getMockOffboardingData();
  offboardingTemplates = mockData.templates;
  offboardingProcesses = mockData.processes;
}

// Load real processes from database
async function loadProcessesData() {
  if (!$client) return;
  
  try {
    // Load offboarding processes from database
    const { data: processesData, error: processesError } = await supabase
      .from('offboarding_processes')
      .select(`
        *,
        offboarding_templates:template_id(name, description)
      `)
      .eq('client_id', $client.id)
      .order('created_at', { ascending: false });

    if (processesError) {
      console.warn('Error loading processes:', processesError);
      // Fallback to mock data
      loadOffboardingData();
      allProcesses = offboardingProcesses;
      return;
    }

    // Transform database processes to match UI format
    allProcesses = processesData?.map(process => {
      // Extract custom fields if they exist
      const customFields = process.custom_fields || {};
      
      // Extract person name from process_name (format: "FirstName LastName - Reason")
      const nameParts = process.process_name?.split(' - ');
      const personName = nameParts?.[0] || process.employee_uid;
      
      return {
        id: process.id,
        process_name: process.process_name || `Process for ${process.employee_uid}`,
        employee_name: personName,
        employee_uid: process.employee_uid,
        employee_department: process.employee_department,
        employee_role: process.employee_role,
        employee_seniority: process.employee_seniority,
        status: process.status,
        priority: process.priority,
        completion_percentage: customFields.completion_percentage || calculateProcessProgress(process),
        total_tasks: customFields.total_tasks || 0,
        completed_tasks: customFields.completed_tasks || 0,
        overdue_tasks: customFields.overdue_tasks || 0,
        target_completion_date: process.target_completion_date,
        actual_start_date: process.actual_start_date,
        actual_completion_date: process.actual_completion_date,
        created_at: process.created_at,
        estimated_total_hours: process.estimated_total_hours,
        complexity_score: process.complexity_score,
        manager_uid: process.manager_uid,
        manager_approved_at: process.manager_approved_at,
        hr_approved_at: process.hr_approved_at,
        security_approved_at: process.security_approved_at,
        notes: process.notes,
        template_id: process.template_id,
        templateName: process.offboarding_templates?.name || 'Standard Process',
        // Additional UI fields for backward compatibility
        title: process.process_name || `Process for ${process.employee_uid}`,
        personName: personName,
        personCode: process.employee_uid,
        progress: customFields.completion_percentage || calculateProcessProgress(process),
        dueDate: process.target_completion_date,
        department: process.employee_department,
        role: process.employee_role
      };
    }) || [];

    console.log(`Loaded ${allProcesses.length} processes from database`);
    
  } catch (error) {
    console.error('Failed to load processes:', error);
    // Fallback to mock data
    loadOffboardingData();
    allProcesses = offboardingProcesses;
  }
}

// Calculate process progress (placeholder - would need tasks data)
function calculateProcessProgress(process) {
  // For now, estimate based on status
  switch (process.status) {
    case 'draft': return 0;
    case 'pending_approval': return 10;
    case 'active': return 50;
    case 'completed': return 100;
    case 'cancelled': return 0;
    case 'overdue': return 30;
    default: return 0;
  }
}

// Load data on component mount
onMount(async () => {
  // Initialize settings and load all clients first
  settingsStore.init();
  await loadAllClients();

  // Load demo data (falls back to default client if no settings)
  await loadDemoData();
  await loadMetrics();
  
  // Load mock offboarding data
  loadOffboardingData();
  
  // Load real processes data
  await loadProcessesData();
});

// Load business metrics
async function loadMetrics() {
  if (!$client) return;

  metricsLoading = true;
  try {
    const metrics = await getClientMetrics();
    onboardingCount = metrics.onboardingCount;
    offboardingCount = metrics.offboardingCount;
  } catch (err) {
    console.error('Failed to load metrics:', err);
  } finally {
    metricsLoading = false;
  }
}

// Reactive to client changes
$: if ($client) {
  loadMetrics();
  loadAccountData();
}

// Dashboard statistics (reactive to store changes)
$: totalEmployees = $totalPeopleCount || $employees.length;
$: pendingInvitations = $invitations.filter((inv) => inv.status === 'pending').length;
</script>

<svelte:head>
	<title>Flows Admin - {$client?.name || 'Loading...'}</title>
</svelte:head>

<main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8" data-testid="app-loaded">
		<!-- Tab Navigation -->
		<div class="sticky top-0 z-10 bg-gray-50 border-b border-gray-200 mb-8 -mx-4 px-4 sm:-mx-6 sm:px-6 lg:-mx-8 lg:px-8 pt-2 pb-1">
			<nav class="-mb-px flex space-x-8">
				<!-- People Tab -->
				<button
					data-testid="tab-people"
					data-active={activeTab === 'people'}
					on:click={() => {
						console.log('🔥 PEOPLE TAB CLICKED!');
						activeTab = 'people';
					}}
					class="py-2 px-1 border-b-2 font-medium text-sm {
						activeTab === 'people' 
							? 'border-blue-500 text-blue-600' 
							: 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
					}"
				>
					<Users class="w-4 h-4 mr-2 inline" />
					People
				</button>

				<!-- Processes Tab -->
				<button
					data-testid="tab-processes"
					data-active={activeTab === 'processes'}
					on:click={() => activeTab = 'processes'}
					class="py-2 px-1 border-b-2 font-medium text-sm {
						activeTab === 'processes' 
							? 'border-blue-500 text-blue-600' 
							: 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
					}"
				>
					<Settings class="w-4 h-4 mr-2 inline" />
					Processes
				</button>

				<!-- Application Tabs -->
				{#each $applications as app}
					<button
						data-testid="tab-{app.code}"
						data-active={activeTab === app.code}
						on:click={() => activeTab = app.code}
						class="py-2 px-1 border-b-2 font-medium text-sm {
							activeTab === app.code 
								? 'border-blue-500 text-blue-600' 
								: 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
						}"
					>
						<Briefcase class="w-4 h-4 mr-2 inline" />
						{app.name}
					</button>
				{/each}

				<!-- Account Tab -->
				<button
					data-testid="tab-account"
					data-active={activeTab === 'account'}
					on:click={() => activeTab = 'account'}
					class="py-2 px-1 border-b-2 font-medium text-sm {
						activeTab === 'account' 
							? 'border-blue-500 text-blue-600' 
							: 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
					}"
				>
					<Settings class="w-4 h-4 mr-2 inline" />
					Account
				</button>
			</nav>
		</div>
		<!-- Loading State -->
		{#if $loading}
			<div class="flex items-center justify-center py-16" data-testid="loading-indicator">
				<LoadingAnimation message="Loading your demo workspace..." size="lg" />
			</div>
		{:else if $error}
			<div class="bg-red-50 border border-red-200 rounded-lg p-4 mb-8">
				<div class="flex">
					<AlertCircle class="w-5 h-5 text-red-400 mr-2" />
					<div>
						<h3 class="text-sm font-medium text-red-800">Error loading data</h3>
						<p class="text-sm text-red-700 mt-1">{$error}</p>
					</div>
				</div>
			</div>
		{:else}
			<!-- Tab Content -->
			{#if activeTab === 'people'}
				<!-- People Tab Content -->
				<div class="space-y-8" data-testid="view-people">
					<!-- Dashboard Stats -->
					<DashboardMetrics 
						{totalEmployees}
						{onboardingCount}
						{offboardingCount}
						{pendingInvitations}
						loading={metricsLoading}
					/>

					<!-- Main Content Grid: Employee Directory + Sidebar -->
					<div class="grid grid-cols-1 xl:grid-cols-3 gap-8">
						<!-- Employee Directory -->
						<div class="xl:col-span-2">
							<EmployeeDirectory 
								employees={$employees}
								enrollments={$enrollments}
								loading={false}
							/>
						</div>

						<!-- Sidebar: Recent Invitations -->
						<div class="xl:col-span-1">
							<InvitationsSidebar 
								invitations={$invitations}
								loading={false}
							/>
						</div>
					</div>
				</div>
			{:else if activeTab === 'processes'}
				<!-- Processes Tab Content -->
				<div class="space-y-8" data-testid="view-processes">
					<!-- Processes Header -->
					<div class="flex justify-between items-center">
						<div>
							<h2 class="text-2xl font-bold text-gray-900">Processes</h2>
							<p class="text-gray-600">Manage and track all processes across applications</p>
						</div>
						<div class="flex space-x-3">
							<button 
								class="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
								on:click={generateProcessData}
							>
								<Plus class="w-4 h-4 mr-2" />
								Generate Demo Data
							</button>
							<Button variant="outline">
								<Plus class="w-4 h-4 mr-2" />
								New Process
							</Button>
						</div>
					</div>

					<!-- Processes Table/List -->
					<ProcessList 
						processes={allProcesses}
						onProcessSelect={(process) => selectedProcess = process}
					/>
					
					{#if allProcesses.length === 0}
						<div class="text-center py-12">
							<div class="text-gray-500">
								<p class="text-lg font-medium">No processes found</p>
								<p class="text-sm mt-2">Processes will appear here as people are enrolled in onboarding/offboarding workflows</p>
							</div>
						</div>
					{/if}
				</div>
			{:else}
				<!-- Application Tab Content -->
				{@const selectedApp = $applications.find(app => app.code === activeTab)}
				{#if selectedApp}
					{#if selectedApp.type === 'offboarding'}
						<!-- Task-Oriented Offboarding Application -->
						<div class="space-y-6">
							<!-- Application Header -->
							<div class="flex justify-between items-start">
								<div>
									<div class="flex items-center gap-3 mb-2">
										<h2 class="text-xl font-semibold text-gray-900">{selectedApp.name}</h2>
										<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium {
											selectedApp.status === 'active' ? 'bg-green-100 text-green-800' :
											selectedApp.status === 'maintenance' ? 'bg-yellow-100 text-yellow-800' :
											selectedApp.status === 'deprecated' ? 'bg-red-100 text-red-800' :
											'bg-gray-100 text-gray-800'
										}">
											{selectedApp.status}
										</span>
										<span class="text-sm text-gray-400">v{selectedApp.version}</span>
									</div>
									<p class="text-sm text-gray-500 mt-1">
										Task-oriented employee offboarding and departure management
									</p>
									<div class="flex items-center gap-4 mt-2 text-xs text-gray-400">
										<span>Process Templates</span>
										<span>Task Management</span>
										<span>Department-Specific</span>
									</div>
								</div>
								
								<!-- Navigation Tabs -->
								<div class="flex items-center gap-2">
									<Button 
										data-testid="offboarding-view-overview"
										data-active={offboardingView === 'overview'}
										variant={offboardingView === 'overview' ? 'default' : 'outline'}
										size="sm"
										on:click={() => offboardingView = 'overview'}
									>
										Overview
									</Button>
									<Button 
										data-testid="offboarding-view-templates"
										data-active={offboardingView === 'templates'}
										variant={offboardingView === 'templates' ? 'default' : 'outline'}
										size="sm"
										on:click={() => offboardingView = 'templates'}
									>
										Templates
									</Button>
									<Button 
										data-testid="offboarding-view-processes"
										data-active={offboardingView === 'processes'}
										variant={offboardingView === 'processes' ? 'default' : 'outline'}
										size="sm"
										on:click={() => offboardingView = 'processes'}
									>
										Processes
									</Button>
									{#if selectedProcess}
										<Button 
											data-testid="offboarding-view-tasks"
											data-active={offboardingView === 'tasks'}
											variant={offboardingView === 'tasks' ? 'default' : 'outline'}
											size="sm"
											on:click={() => offboardingView = 'tasks'}
										>
											Tasks
										</Button>
									{/if}
								</div>
							</div>

							<!-- View Content -->
							{#if offboardingView === 'overview'}
								<div data-testid="view-overview">
								<OffboardingDashboard 
									processes={offboardingProcesses}
									employees={$employees}
									onFilterByStatus={(status) => {
										applyProcessFilter('status', status);
									}}
									onFilterByTimeframe={(timeframe) => {
										applyProcessFilter('timeframe', timeframe);
									}}
									onViewProcess={(process) => {
										selectedProcess = process;
										offboardingTasks = getTasksForProcess(process.id);
										offboardingView = 'tasks';
									}}
									onCreateOffboarding={() => {
										offboardingView = 'templates';
									}}
									loading={$loading}
								/>
								</div>
							{:else if offboardingView === 'templates'}
								<div data-testid="view-templates">
								<TemplateManager 
									templates={offboardingTemplates}
									onTemplateSelect={(template) => {
										selectedTemplate = template;
										// Show processes using this template
										applyProcessFilter('template', template.id);
									}}
									onCreateTemplate={() => {
										console.log('Create new template');
									}}
									onEditTemplate={(template) => {
										console.log('Edit template:', template);
									}}
									loading={$loading}
								/>
								</div>
							{:else if offboardingView === 'processes'}
								<div data-testid="view-processes">
								<ProcessManager 
									processes={offboardingProcesses}
									onProcessSelect={(process) => {
										selectedProcess = process;
										offboardingTasks = getTasksForProcess(process.id);
										offboardingView = 'tasks';
									}}
									onCreateProcess={() => {
										offboardingView = 'templates';
									}}
									onUpdateProcessStatus={(processId, status) => {
										console.log('Update process status:', processId, status);
									}}
									loading={$loading}
								/>
								</div>
							{:else if offboardingView === 'tasks' && selectedProcess}
								<div data-testid="view-tasks">
								<TaskManager 
									process={selectedProcess}
									tasks={offboardingTasks}
									onTaskUpdate={(taskId, updates) => {
										console.log('Update task:', taskId, updates);
									}}
									onTaskComplete={(taskId) => {
										console.log('Complete task:', taskId);
									}}
									onTaskStart={(taskId) => {
										console.log('Start task:', taskId);
									}}
									onAddNote={(taskId, note) => {
										console.log('Add note to task:', taskId, note);
									}}
									onUploadDocument={(taskId, file) => {
										console.log('Upload document for task:', taskId, file);
									}}
									loading={$loading}
								/>
								</div>
							{/if}
							
							<!-- Process List - Always shown when filters are applied -->
							{#if showProcessList}
								<ProcessList 
									processes={offboardingProcesses}
									filters={processFilters}
									onClearFilters={clearProcessFilters}
									onProcessSelect={(process) => {
										selectedProcess = process;
										offboardingTasks = getTasksForProcess(process.id);
										offboardingView = 'tasks';
									}}
									loading={$loading}
								/>
							{/if}
						</div>
					{:else}
						<!-- Other Applications - Show Generic View -->
						<div class="space-y-8">
						<!-- Application Dashboard Header -->
						<div class="flex justify-between items-start">
							<div>
								<div class="flex items-center gap-3 mb-2">
									<h2 class="text-xl font-semibold text-gray-900">{selectedApp.name}</h2>
									<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium {
										selectedApp.status === 'active' ? 'bg-green-100 text-green-800' :
										selectedApp.status === 'maintenance' ? 'bg-yellow-100 text-yellow-800' :
										selectedApp.status === 'deprecated' ? 'bg-red-100 text-red-800' :
										'bg-gray-100 text-gray-800'
									}">
										{selectedApp.status}
									</span>
									<span class="text-sm text-gray-400">v{selectedApp.version}</span>
								</div>
								<p class="text-sm text-gray-500 mt-1">
									{selectedApp.description || `${selectedApp.type === 'onboarding' ? 'Onboarding' : 'Offboarding'} Management Application`}
								</p>
								<div class="flex items-center gap-4 mt-2 text-xs text-gray-400">
									<span>Max Users: {selectedApp.maxConcurrentUsers}</span>
									<span>Features: {selectedApp.features.length}</span>
									{#if selectedApp.lastAccessed}
										<span>Last Accessed: {new Date(selectedApp.lastAccessed).toLocaleDateString()}</span>
									{/if}
								</div>
							</div>
							<Button variant="outline" href="/invitations/new">
								<UserPlus class="w-4 h-4 mr-2" />
								New Invitation
							</Button>
						</div>

						<!-- Application Metrics -->
						<div class="grid grid-cols-1 md:grid-cols-4 gap-4">
							<div class="bg-white p-6 rounded-lg shadow-sm border">
								<p class="text-sm font-medium text-gray-600">Active Invitations</p>
								<p class="text-2xl font-bold text-gray-900 mt-1">
									{$invitations.filter(inv => inv.applicationId === selectedApp.id && inv.status === 'sent').length}
								</p>
							</div>
							<div class="bg-white p-6 rounded-lg shadow-sm border">
								<p class="text-sm font-medium text-gray-600">Pending Invitations</p>
								<p class="text-2xl font-bold text-gray-900 mt-1">
									{$invitations.filter(inv => inv.applicationId === selectedApp.id && inv.status === 'pending').length}
								</p>
							</div>
							<div class="bg-white p-6 rounded-lg shadow-sm border">
								<p class="text-sm font-medium text-gray-600">People Assigned</p>
								<p class="text-2xl font-bold text-gray-900 mt-1">
									{$employees.filter(emp => emp.status === 'active').length}
								</p>
							</div>
							<div class="bg-white p-6 rounded-lg shadow-sm border">
								<p class="text-sm font-medium text-gray-600">Completed This Month</p>
								<p class="text-2xl font-bold text-gray-900 mt-1">
									{$invitations.filter(inv => inv.applicationId === selectedApp.id && inv.status === 'accepted').length}
								</p>
							</div>
						</div>

						<!-- Application Features & Configuration -->
						<div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
							<!-- Features -->
							<div class="bg-white rounded-lg shadow-sm border">
								<div class="px-6 py-4 border-b">
									<h3 class="text-lg font-medium text-gray-900">Application Features</h3>
								</div>
								<div class="p-6">
									{#if selectedApp.features.length > 0}
										<div class="grid grid-cols-1 gap-3">
											{#each selectedApp.features as feature}
												<div class="flex items-center gap-3">
													<div class="w-2 h-2 bg-green-500 rounded-full"></div>
													<span class="text-sm text-gray-700 capitalize">
														{feature.replace(/-/g, ' ').replace(/_/g, ' ')}
													</span>
												</div>
											{/each}
										</div>
									{:else}
										<p class="text-sm text-gray-500">No features configured</p>
									{/if}
								</div>
							</div>

							<!-- Configuration -->
							<div class="bg-white rounded-lg shadow-sm border">
								<div class="px-6 py-4 border-b">
									<h3 class="text-lg font-medium text-gray-900">Configuration</h3>
								</div>
								<div class="p-6">
									{#if Object.keys(selectedApp.configuration).length > 0}
										<div class="space-y-3">
											{#each Object.entries(selectedApp.configuration) as [key, value]}
												<div class="flex justify-between items-start">
													<span class="text-sm font-medium text-gray-600 capitalize">
														{key.replace(/_/g, ' ')}:
													</span>
													<span class="text-sm text-gray-900 text-right max-w-48 truncate">
														{typeof value === 'object' ? JSON.stringify(value) : String(value)}
													</span>
												</div>
											{/each}
										</div>
									{:else}
										<p class="text-sm text-gray-500">Using default configuration</p>
									{/if}
								</div>
							</div>
						</div>

						<!-- Application-specific Invitations -->
						<div class="bg-white rounded-lg shadow-sm border">
							<div class="px-6 py-4 border-b">
								<h3 class="text-lg font-medium text-gray-900">Recent {selectedApp.name} Invitations</h3>
							</div>
							<div class="divide-y">
								{#each $invitations.filter(inv => inv.applicationId === selectedApp.id).slice(0, 5) as invitation}
									<div class="px-6 py-4">
										<div class="flex items-center justify-between">
											<div>
												<p class="text-sm font-medium text-gray-900">
													{invitation.firstName} {invitation.lastName}
												</p>
												<p class="text-sm text-gray-500">{invitation.companyEmail}</p>
											</div>
											<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium {
												invitation.status === 'pending' ? 'bg-yellow-100 text-yellow-800' :
												invitation.status === 'sent' ? 'bg-blue-100 text-blue-800' :
												invitation.status === 'accepted' ? 'bg-green-100 text-green-800' :
												'bg-gray-100 text-gray-800'
											}">
												{invitation.status}
											</span>
										</div>
									</div>
								{/each}
								{#if $invitations.filter(inv => inv.applicationId === selectedApp.id).length === 0}
									<div class="px-6 py-8 text-center text-gray-500">
										No invitations for this application yet
									</div>
								{/if}
							</div>
						</div>
					</div>
					{/if}
				{/if}
			{:else if activeTab === 'account'}
				<!-- Account Tab Content -->
				<div class="space-y-8" data-testid="view-account">
					<!-- Account Header -->
					<div class="flex justify-between items-center">
						<div>
							<h2 class="text-2xl font-bold text-gray-900">Account Management</h2>
							<p class="text-gray-600">Manage your company account, billing, and access</p>
						</div>
					</div>

					<!-- Account Overview Grid -->
					<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
						<!-- Company Information -->
						<div class="lg:col-span-2 space-y-6">
							<!-- Company Details Card -->
							<div class="bg-white rounded-lg shadow-sm border">
								<div class="px-6 py-4 border-b">
									<h3 class="text-lg font-medium text-gray-900">Company Information</h3>
								</div>
								<div class="p-6">
									<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
										<div>
											<label class="block text-sm font-medium text-gray-700 mb-1">Company Name</label>
											<div class="text-sm text-gray-900">{$client?.legal_name || $client?.name || 'Loading...'}</div>
										</div>
										<div>
											<label class="block text-sm font-medium text-gray-700 mb-1">Client Code</label>
											<div class="text-sm text-gray-900 font-mono">{$client?.client_code || $client?.code || 'Loading...'}</div>
										</div>
										<div>
											<label class="block text-sm font-medium text-gray-700 mb-1">Industry</label>
											<div class="text-sm text-gray-900">{$client?.industry || 'Not specified'}</div>
										</div>
										<div>
											<label class="block text-sm font-medium text-gray-700 mb-1">Domain</label>
											<div class="text-sm text-gray-900">{$client?.domain || 'Not specified'}</div>
										</div>
										<div>
											<label class="block text-sm font-medium text-gray-700 mb-1">Account Tier</label>
											<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium {
												$client?.tier === 'enterprise' ? 'bg-purple-100 text-purple-800' :
												$client?.tier === 'pro' ? 'bg-blue-100 text-blue-800' :
												'bg-gray-100 text-gray-800'
											}">
												{$client?.tier || 'standard'}
											</span>
										</div>
										<div>
											<label class="block text-sm font-medium text-gray-700 mb-1">Status</label>
											<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium {
												$client?.status === 'active' ? 'bg-green-100 text-green-800' :
												$client?.status === 'trial' ? 'bg-yellow-100 text-yellow-800' :
												'bg-gray-100 text-gray-800'
											}">
												{$client?.status || 'active'}
											</span>
										</div>
									</div>
									
									{#if $client?.description}
										<div class="mt-4">
											<label class="block text-sm font-medium text-gray-700 mb-1">Company Description</label>
											<div class="text-sm text-gray-600 leading-relaxed">{$client.description}</div>
										</div>
									{/if}
								</div>
							</div>

							<!-- Comprehensive TFC Management Panel -->
							<TFCManagementPanel clientId={$client?.id} />

							<!-- Recent Invoices -->
							<div class="bg-white rounded-lg shadow-sm border">
								<div class="px-6 py-4 border-b">
									<div class="flex justify-between items-center">
										<h3 class="text-lg font-medium text-gray-900">Recent Invoices</h3>
										<button class="text-blue-600 hover:text-blue-700 text-sm font-medium">View All</button>
									</div>
								</div>
								<div class="divide-y">
									{#if loadingAccount}
										<div class="px-6 py-8 text-center text-gray-500">
											<LoadingAnimation message="Loading invoices..." size="sm" />
										</div>
									{:else if recentInvoices.length > 0}
										{#each recentInvoices as invoice}
											<div class="px-6 py-4 flex items-center justify-between">
												<div class="flex items-center gap-4">
													<FileText class="w-5 h-5 text-gray-400" />
													<div>
														<div class="font-medium text-gray-900">{invoice.invoice_number}</div>
														<div class="text-sm text-gray-500">
															{new Date(invoice.invoice_date).toLocaleDateString()} 
															{#if invoice.line_items && invoice.line_items.length > 0}
																• {invoice.line_items.map(item => item.description).join(', ')}
															{/if}
														</div>
													</div>
												</div>
												<div class="flex items-center gap-4">
													<div class="text-right">
														<div class="font-medium text-gray-900">{formatCurrency(invoice.total_amount, invoice.currency)}</div>
														<span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium {
															invoice.status === 'paid' ? 'bg-green-100 text-green-800' :
															invoice.status === 'overdue' ? 'bg-red-100 text-red-800' :
															invoice.status === 'sent' ? 'bg-yellow-100 text-yellow-800' :
															'bg-gray-100 text-gray-800'
														}">
															{invoice.status}
														</span>
													</div>
													<button class="text-gray-400 hover:text-gray-600" title="Download Invoice">
														<Download class="w-4 h-4" />
													</button>
												</div>
											</div>
										{/each}
									{:else}
										<div class="px-6 py-8 text-center text-gray-500">
											<div class="text-lg font-medium">No invoices yet</div>
											<div class="text-sm mt-1">Invoices will appear here after TFC purchases</div>
										</div>
									{/if}
								</div>
							</div>

							<!-- TFC Transaction History -->
							<div class="bg-white rounded-lg shadow-sm border">
								<div class="px-6 py-4 border-b">
									<div class="flex justify-between items-center">
										<h3 class="text-lg font-medium text-gray-900">TFC Transaction History</h3>
										<button class="text-blue-600 hover:text-blue-700 text-sm font-medium">View All</button>
									</div>
								</div>
								<div class="divide-y">
									{#each [
										{ 
											id: 'tfc-001', 
											type: 'purchase', 
											date: '2024-06-15', 
											description: '2,500 TFC Purchase (30% bulk discount)', 
											credits: '+2,500', 
											amount: '€262,500', 
											status: 'completed',
											tier: 'bulk_tier_2'
										},
										{ 
											id: 'tfc-002', 
											type: 'usage', 
											date: '2024-06-14', 
											description: 'Offboarding: Maria Schmidt', 
											credits: '-1', 
											amount: '€105', 
											status: 'completed',
											workflow: 'offboarding'
										},
										{ 
											id: 'tfc-003', 
											type: 'usage', 
											date: '2024-06-14', 
											description: 'Onboarding: Lars Petersen', 
											credits: '-1', 
											amount: '€105', 
											status: 'completed',
											workflow: 'onboarding'
										},
										{ 
											id: 'tfc-004', 
											type: 'purchase', 
											date: '2024-05-15', 
											description: '1,000 TFC Purchase (25% bulk discount)', 
											credits: '+1,000', 
											amount: '€112,500', 
											status: 'completed',
											tier: 'bulk_tier_1'
										}
									] as transaction}
										<div class="px-6 py-4">
											<div class="flex items-start justify-between">
												<div class="flex items-start gap-3">
													<div class="w-2 h-2 rounded-full mt-2 {
														transaction.type === 'purchase' ? 'bg-green-500' :
														transaction.type === 'usage' ? 'bg-blue-500' :
														'bg-gray-400'
													}"></div>
													<div>
														<div class="font-medium text-gray-900 text-sm">{transaction.description}</div>
														<div class="text-xs text-gray-500 mt-1">
															{transaction.date} • Transaction ID: {transaction.id}
															{#if transaction.tier}
																• {transaction.tier === 'bulk_tier_1' ? '25% discount' : '30% discount'}
															{/if}
														</div>
													</div>
												</div>
												<div class="text-right">
													<div class="font-medium text-sm {
														transaction.type === 'purchase' ? 'text-green-600' :
														transaction.type === 'usage' ? 'text-blue-600' :
														'text-gray-900'
													}">
														{transaction.credits} TFC
													</div>
													<div class="text-xs text-gray-500">{transaction.amount}</div>
												</div>
											</div>
										</div>
									{/each}
								</div>
								<div class="px-6 py-4 bg-gray-50 text-center">
									<button class="text-blue-600 hover:text-blue-700 text-sm font-medium">
										Export Transaction History
									</button>
								</div>
							</div>
						</div>

						<!-- Sidebar -->
						<div class="space-y-6">
							<!-- Payment Method -->
							<div class="bg-white rounded-lg shadow-sm border">
								<div class="px-6 py-4 border-b">
									<h3 class="text-lg font-medium text-gray-900">Payment Method</h3>
								</div>
								<div class="p-6">
									<div class="flex items-center gap-3 mb-4">
										<CreditCard class="w-8 h-8 text-gray-400" />
										<div>
											<div class="font-medium text-gray-900">•••• •••• •••• 4242</div>
											<div class="text-sm text-gray-500">Expires 12/2027</div>
										</div>
									</div>
									<button class="text-blue-600 hover:text-blue-700 text-sm font-medium">
										Update Payment Method
									</button>
								</div>
							</div>

							<!-- Account Contacts -->
							<div class="bg-white rounded-lg shadow-sm border">
								<div class="px-6 py-4 border-b">
									<div class="flex justify-between items-center">
										<h3 class="text-lg font-medium text-gray-900">Account Contacts</h3>
										<button class="text-blue-600 hover:text-blue-700 text-sm font-medium">
											Add Contact
										</button>
									</div>
								</div>
								<div class="p-6">
									{#if loadingAccount}
										<div class="flex justify-center py-4">
											<LoadingAnimation message="Loading contacts..." size="sm" />
										</div>
									{:else if accountContacts.length > 0}
										<div class="space-y-4">
											{#each accountContacts as contact}
												<div class="flex items-start gap-3 p-3 rounded-lg border border-gray-100 hover:border-gray-200 transition-colors">
													<div class="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
														<span class="text-xs font-medium text-blue-600">
															{contact.first_name?.charAt(0)}{contact.last_name?.charAt(0)}
														</span>
													</div>
													<div class="flex-1 min-w-0">
														<div class="flex items-center gap-2">
															<h4 class="font-medium text-gray-900 text-sm">{contact.first_name} {contact.last_name}</h4>
															{#if contact.is_primary_contact}
																<span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
																	Primary
																</span>
															{/if}
														</div>
														<div class="text-sm text-gray-600">{contact.email}</div>
														{#if contact.job_title}
															<div class="text-sm text-gray-500">{contact.job_title}</div>
														{/if}
														{#if contact.department}
															<div class="text-xs text-gray-400">{contact.department}</div>
														{/if}
														<div class="mt-2 flex flex-wrap gap-1">
															{#if contact.can_purchase_credits}
																<span class="inline-flex items-center px-1.5 py-0.5 rounded text-xs font-medium bg-green-100 text-green-700">Purchase</span>
															{/if}
															{#if contact.can_view_billing}
																<span class="inline-flex items-center px-1.5 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-700">Billing</span>
															{/if}
															{#if contact.can_manage_users}
																<span class="inline-flex items-center px-1.5 py-0.5 rounded text-xs font-medium bg-purple-100 text-purple-700">Users</span>
															{/if}
														</div>
													</div>
												</div>
											{/each}
										</div>
									{:else}
										<div class="text-center py-6 text-gray-500">
											<div class="text-sm font-medium">No contacts found</div>
											<div class="text-xs mt-1">Add contacts to manage account access</div>
										</div>
									{/if}
								</div>
							</div>

							<!-- TFC Account Settings -->
							<div class="bg-white rounded-lg shadow-sm border">
								<div class="px-6 py-4 border-b">
									<h3 class="text-lg font-medium text-gray-900">TFC Settings</h3>
								</div>
								<div class="p-6 space-y-4">
									{#if tfcBalance}
										<div>
											<label class="block text-sm font-medium text-gray-700 mb-2">Auto-Replenish</label>
											<div class="flex items-center gap-3">
												<input type="checkbox" class="rounded border-gray-300" checked={tfcBalance.auto_replenish_enabled} disabled />
												<span class="text-sm text-gray-600">
													{#if tfcBalance.auto_replenish_enabled}
														Automatically purchase {tfcBalance.auto_replenish_amount} TFC when balance drops below {tfcBalance.auto_replenish_threshold}
													{:else}
														Auto-replenish disabled
													{/if}
												</span>
											</div>
										</div>
										
										<div>
											<label class="block text-sm font-medium text-gray-700 mb-1">Balance Alerts</label>
											<div class="text-sm text-gray-600">
												Low balance: {tfcBalance.low_balance_threshold} TFC • Critical: {tfcBalance.critical_balance_threshold} TFC
											</div>
										</div>
									{:else}
										<div>
											<label class="block text-sm font-medium text-gray-700 mb-2">Auto-Replenish</label>
											<div class="text-sm text-gray-500">TFC settings will appear here once configured</div>
										</div>
									{/if}
									
									<div>
										<label class="block text-sm font-medium text-gray-700 mb-1">Preferred Currency</label>
										<div class="text-sm text-gray-900">
											{#if tfcBalance?.preferred_currency}
												{tfcBalance.preferred_currency} ({tfcBalance.preferred_currency === 'EUR' ? 'Euro' : 'Swiss Franc'})
											{:else}
												EUR (Euro)
											{/if}
										</div>
									</div>
									
									<div>
										<label class="block text-sm font-medium text-gray-700 mb-1">Billing Contact</label>
										{#if accountContacts.length > 0}
											{@const primaryContact = accountContacts.find(c => c.is_primary_contact) || accountContacts[0]}
											<div class="text-sm text-gray-600">{primaryContact.first_name} {primaryContact.last_name} ({primaryContact.job_title || 'Contact'})</div>
										{:else}
											<div class="text-sm text-gray-500">No billing contact set</div>
										{/if}
									</div>
								</div>
							</div>

							<!-- Security & Compliance -->
							<div class="bg-white rounded-lg shadow-sm border">
								<div class="px-6 py-4 border-b">
									<h3 class="text-lg font-medium text-gray-900">Security & Compliance</h3>
								</div>
								<div class="p-6">
									<div class="space-y-3 text-sm">
										<div class="flex items-center justify-between">
											<span class="text-gray-700">Two-Factor Authentication</span>
											<span class="text-green-600 font-medium">Enabled</span>
										</div>
										<div class="flex items-center justify-between">
											<span class="text-gray-700">GDPR Compliance</span>
											<span class="text-green-600 font-medium">Active</span>
										</div>
										<div class="flex items-center justify-between">
											<span class="text-gray-700">Data Retention</span>
											<span class="text-gray-600">7 years</span>
										</div>
										<div class="flex items-center justify-between">
											<span class="text-gray-700">Audit Logs</span>
											<span class="text-green-600 font-medium">Enabled</span>
										</div>
									</div>
									<div class="mt-4 pt-4 border-t">
										<button class="flex items-center gap-2 text-blue-600 hover:text-blue-700 text-sm font-medium">
											<Shield class="w-4 h-4" />
											Security Settings
										</button>
									</div>
								</div>
							</div>
						</div>
					</div>
				</div>
			{/if}
		{/if}
	</main>

<!-- Floating Status Button -->
<FloatingStatusButton />

