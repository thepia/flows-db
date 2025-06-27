<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import '../app.pcss';
	import AppHeader from '$lib/components/layout/AppHeader.svelte';

	// Determine page context
	$: isSettingsPage = $page.url.pathname === '/settings';
	$: pageTitle = isSettingsPage ? 'Settings' : 'Flows';

	// Initialize error reporting on app startup
	onMount(async () => {
		try {
			const { initializeAdminErrorReporting, enableGlobalAdminErrorReporting } = 
				await import('../lib/config/errorReporting.js');
			
			await initializeAdminErrorReporting();
			enableGlobalAdminErrorReporting();
			
			console.log('[Admin Demo] Application initialized with error reporting');
		} catch (error) {
			console.error('[Admin Demo] Failed to initialize error reporting:', error);
		}
	});
</script>

<div class="min-h-screen bg-gray-50">
	<AppHeader title={pageTitle} showBackButton={isSettingsPage} />
	<main>
		<slot />
	</main>
</div>