<script lang="ts">
	import { onMount } from 'svelte';
	import '../app.pcss';

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

<main>
	<slot />
</main>