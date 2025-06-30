<script lang="ts">
import { page } from '$app/stores';
import { onMount } from 'svelte';
import '../app.pcss';
import AppHeader from '$lib/components/layout/AppHeader.svelte';

// Determine page context
$: isSettingsPage = $page.url.pathname === '/settings';
$: pageTitle = isSettingsPage ? 'Settings' : 'Flows';

// Initialize error reporting and store bridge on app startup
onMount(async () => {
  try {
    // Initialize error reporting
    const { initializeAdminErrorReporting, enableGlobalAdminErrorReporting } = await import(
      '../lib/config/errorReporting.js'
    );

    await initializeAdminErrorReporting();
    enableGlobalAdminErrorReporting();

    // Initialize store bridge for legacy compatibility
    const { initializeStoreBridge } = await import('../lib/stores/store-bridge');
    initializeStoreBridge();

    console.log('[Admin Demo] Application initialized with error reporting and store bridge');
  } catch (error) {
    console.error('[Admin Demo] Failed to initialize application:', error);
  }
});
</script>

<div class="min-h-screen bg-gray-50">
	<AppHeader title={pageTitle} showBackButton={isSettingsPage} />
	<main>
		<slot />
	</main>
</div>