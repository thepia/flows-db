<script lang="ts">
	import { onMount } from 'svelte';
	import { 
		client, 
		clients,
		applications,
		employees, 
		invitations, 
		enrollments, 
		loading, 
		error, 
		loadDemoData,
		loadAllClients, 
		getClientMetrics
	} from "$lib/stores/data";
	import { settingsStore } from '$lib/stores/settings';
	import FloatingStatusButton from "$lib/components/FloatingStatusButton.svelte";
	import DashboardMetrics from "$lib/components/dashboard/DashboardMetrics.svelte";
	import EmployeeDirectory from "$lib/components/employee/EmployeeDirectory.svelte";
	import InvitationsSidebar from "$lib/components/dashboard/InvitationsSidebar.svelte";
	import LoadingAnimation from "$lib/components/shared/LoadingAnimation.svelte";
	import { AlertCircle, UserPlus, Users, Briefcase } from "lucide-svelte";
	import { Button } from "$lib/components/ui/button";

	// Tab state
	let activeTab = 'people';

	// Metrics state
	let onboardingCount = 0;
	let offboardingCount = 0;
	let metricsLoading = false;

	// Load data on component mount
	onMount(async () => {
		// Initialize settings and load all clients first
		settingsStore.init();
		await loadAllClients();
		
		// Load demo data (falls back to default client if no settings)
		await loadDemoData();
		await loadMetrics();
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
	$: totalEmployees = $employees.length;
	$: pendingInvitations = $invitations.filter(inv => inv.status === 'pending').length;
</script>

<svelte:head>
	<title>Flows Admin - {$client?.name || 'Loading...'}</title>
</svelte:head>

<main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
		<!-- Tab Navigation -->
		<div class="border-b border-gray-200 mb-8">
			<nav class="-mb-px flex space-x-8">
				<!-- People Tab -->
				<button
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

				<!-- Application Tabs -->
				{#each $applications as app}
					<button
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
			<div class="flex items-center justify-center py-16">
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
				<div class="space-y-8">
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
			{:else}
				<!-- Application Tab Content -->
				{@const selectedApp = $applications.find(app => app.code === activeTab)}
				{#if selectedApp}
					<div class="space-y-8">
						<!-- Application Dashboard Header -->
						<div class="flex justify-between items-start">
							<div>
								<h2 class="text-xl font-semibold text-gray-900">{selectedApp.name}</h2>
								<p class="text-sm text-gray-500 mt-1">
									{selectedApp.type === 'onboarding' ? 'Onboarding' : 'Offboarding'} Management
								</p>
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
	</main>

<!-- Floating Status Button -->
<FloatingStatusButton />

