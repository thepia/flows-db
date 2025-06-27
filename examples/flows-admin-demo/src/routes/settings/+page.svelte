<script lang="ts">
	import SettingsPanel from '$lib/components/settings/SettingsPanel.svelte';
	import DashboardHeader from '$lib/components/dashboard/DashboardHeader.svelte';
	import { client } from '$lib/stores/data';
</script>

<svelte:head>
	<title>Settings - Flows Admin Demo</title>
</svelte:head>

<div class="min-h-screen bg-gray-50">
	<!-- Header -->
	<DashboardHeader clientName={$client?.name || ''} loading={false} />
	
	<main class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
		<SettingsPanel />
	</main>
</div>