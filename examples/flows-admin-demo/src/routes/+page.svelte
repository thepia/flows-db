<script lang="ts">
	import { onMount } from 'svelte';
	import { 
		client, 
		clients,
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
	import DashboardHeader from "$lib/components/dashboard/DashboardHeader.svelte";
	import DashboardMetrics from "$lib/components/dashboard/DashboardMetrics.svelte";
	import EmployeeDirectory from "$lib/components/employee/EmployeeDirectory.svelte";
	import InvitationsSidebar from "$lib/components/dashboard/InvitationsSidebar.svelte";
	import LoadingAnimation from "$lib/components/shared/LoadingAnimation.svelte";
	import { AlertCircle } from "lucide-svelte";

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

<div class="min-h-screen bg-gray-50">
	<!-- Header -->
	<DashboardHeader clientName={$client?.name || ''} loading={$loading} />

	<main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
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

		{/if}
	</main>

	<!-- Floating Status Button -->
	<FloatingStatusButton />
</div>

