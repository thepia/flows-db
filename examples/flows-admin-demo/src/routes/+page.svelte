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
import { AlertCircle, Briefcase, Plus, UserMinus, UserPlus, Users, Settings } from 'lucide-svelte';
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

// Load mock offboarding data
function loadOffboardingData() {
  const mockData = getMockOffboardingData();
  offboardingTemplates = mockData.templates;
  offboardingProcesses = mockData.processes;
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
		<div class="border-b border-gray-200 mb-8">
			<nav class="-mb-px flex space-x-8">
				<!-- People Tab -->
				<button
					data-testid="tab-people"
					data-active={activeTab === 'people'}
					on:click={() => activeTab = 'people'}
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
							<Button variant="outline">
								<Plus class="w-4 h-4 mr-2" />
								New Process
							</Button>
						</div>
					</div>

					<!-- Processes Table/List -->
					<ProcessList 
						processes={offboardingProcesses}
						onProcessSelect={(process) => selectedProcess = process}
					/>
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
			{/if}
		{/if}
	</main>

<!-- Floating Status Button -->
<FloatingStatusButton />

