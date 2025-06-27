<script lang="ts">
	import { onMount } from 'svelte';
	import { Button } from "$lib/components/ui/button";
	import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "$lib/components/ui/card";
	import { 
		AlertCircle, 
		CheckCircle2, 
		XCircle, 
		RefreshCw, 
		Activity, 
		Wifi, 
		WifiOff,
		Shield,
		User,
		Database,
		Zap
	} from "lucide-svelte";
	
	// Status states
	let isOpen = false;
	let errorReportingConfig: any = null;
	let queueSize = 0;
	let lastRefresh = '';
	
	// Service status (future)
	let authStatus = 'connected'; // 'connected' | 'disconnected' | 'error'
	let serviceWorkerStatus = 'not-supported'; // 'active' | 'installing' | 'waiting' | 'not-supported'
	let databaseStatus = 'connected'; // 'connected' | 'disconnected' | 'error'
	
	async function loadSystemStatus() {
		try {
			// Load error reporting status
			const { getAdminErrorReportingConfig } = await import('../config/errorReporting.js');
			const { getAdminErrorReportQueueSize } = await import('../utils/errorReporter.js');
			
			errorReportingConfig = await getAdminErrorReportingConfig();
			queueSize = getAdminErrorReportQueueSize();
			lastRefresh = new Date().toLocaleTimeString();
			
			// TODO: Add other status checks
			// - Auth status (check if Supabase is connected)
			// - Service worker status
			// - Database connectivity
			
		} catch (error) {
			console.error('Failed to load system status:', error);
		}
	}

	async function flushErrorReports() {
		try {
			const { flushAdminErrorReports } = await import('../config/errorReporting.js');
			await flushAdminErrorReports();
			await loadSystemStatus();
		} catch (error) {
			console.error('Failed to flush error reports:', error);
		}
	}

	async function testErrorReporting() {
		try {
			const { reportAdminFlowError } = await import('../config/errorReporting.js');
			await reportAdminFlowError('ui-interaction', new Error('Test error from floating status'), {
				test: true,
				timestamp: Date.now()
			});
			console.log('[Admin Demo] Test error report sent from floating status');
		} catch (error) {
			console.error('Failed to send test error report:', error);
		}
	}

	function toggleStatus() {
		isOpen = !isOpen;
		if (isOpen) {
			loadSystemStatus();
		}
	}

	onMount(() => {
		loadSystemStatus();
		
		// Refresh status every 10 seconds
		const interval = setInterval(loadSystemStatus, 10000);
		return () => clearInterval(interval);
	});

	// Overall system health indicator
	$: overallStatus = (() => {
		if (!errorReportingConfig) return 'loading';
		
		const hasErrors = queueSize > 0;
		const errorReportingOk = errorReportingConfig?.enabled;
		const authOk = authStatus === 'connected';
		const dbOk = databaseStatus === 'connected';
		
		if (hasErrors) return 'error';
		if (!errorReportingOk || !authOk || !dbOk) return 'warning';
		return 'good';
	})();

	$: statusIcon = overallStatus === 'good' ? CheckCircle2 : 
	               overallStatus === 'warning' ? AlertCircle : 
	               overallStatus === 'error' ? XCircle : Activity;
	
	$: statusColor = overallStatus === 'good' ? 'text-green-600' : 
	                overallStatus === 'warning' ? 'text-yellow-600' : 
	                overallStatus === 'error' ? 'text-red-600' : 'text-gray-600';

	$: ringColor = overallStatus === 'good' ? 'ring-green-500' : 
	              overallStatus === 'warning' ? 'ring-yellow-500' : 
	              overallStatus === 'error' ? 'ring-red-500' : 'ring-gray-500';
</script>

<!-- Floating Status Button -->
<div class="fixed bottom-4 right-4 z-50">
	{#if isOpen}
		<!-- Status Popover -->
		<div class="absolute bottom-16 right-0 w-80 mb-2">
			<Card class="shadow-lg border-2">
				<CardHeader class="pb-3">
					<div class="flex items-center justify-between">
						<CardTitle class="flex items-center gap-2 text-sm">
							<svelte:component this={statusIcon} class="w-4 h-4 {statusColor}" />
							System Status
						</CardTitle>
						<Button 
							variant="ghost" 
							size="sm" 
							on:click={toggleStatus}
							class="h-6 w-6 p-0"
						>
							✕
						</Button>
					</div>
					<CardDescription class="text-xs">
						Development environment monitoring
					</CardDescription>
				</CardHeader>
				<CardContent class="space-y-4 text-xs">
					<!-- Error Reporting Status -->
					<div class="space-y-2">
						<h4 class="font-medium text-sm flex items-center gap-2">
							<Zap class="w-3 h-3" />
							Error Reporting
						</h4>
						{#if errorReportingConfig}
							<div class="pl-5 space-y-1">
								<div class="flex justify-between">
									<span class="text-muted-foreground">Status:</span>
									<span class="px-2 py-0.5 text-xs rounded {errorReportingConfig.enabled ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'}">
										{errorReportingConfig.enabled ? 'Enabled' : 'Disabled'}
									</span>
								</div>
								<div class="flex justify-between">
									<span class="text-muted-foreground">Queue:</span>
									<span class="px-2 py-0.5 text-xs rounded {queueSize > 0 ? 'bg-red-100 text-red-800' : 'bg-gray-100 text-gray-800'}">
										{queueSize} pending
									</span>
								</div>
								<div class="flex justify-between">
									<span class="text-muted-foreground">Endpoint:</span>
									<span class="text-right max-w-[120px] truncate font-mono">{errorReportingConfig.serverType}</span>
								</div>
							</div>
						{:else}
							<div class="pl-5 text-muted-foreground">Loading...</div>
						{/if}
					</div>

					<!-- Authentication Status -->
					<div class="space-y-2">
						<h4 class="font-medium text-sm flex items-center gap-2">
							<User class="w-3 h-3" />
							Authentication
						</h4>
						<div class="pl-5 space-y-1">
							<div class="flex justify-between">
								<span class="text-muted-foreground">Supabase:</span>
								<span class="px-2 py-0.5 text-xs rounded bg-green-100 text-green-800">
									Connected
								</span>
							</div>
							<div class="flex justify-between">
								<span class="text-muted-foreground">Mode:</span>
								<span class="text-muted-foreground">Demo/Service Role</span>
							</div>
						</div>
					</div>

					<!-- Database Status -->
					<div class="space-y-2">
						<h4 class="font-medium text-sm flex items-center gap-2">
							<Database class="w-3 h-3" />
							Database
						</h4>
						<div class="pl-5 space-y-1">
							<div class="flex justify-between">
								<span class="text-muted-foreground">Connection:</span>
								<span class="px-2 py-0.5 text-xs rounded bg-green-100 text-green-800">
									Connected
								</span>
							</div>
							<div class="flex justify-between">
								<span class="text-muted-foreground">Client:</span>
								<span class="text-muted-foreground">nets-demo</span>
							</div>
						</div>
					</div>

					<!-- Service Worker Status (Future) -->
					<div class="space-y-2">
						<h4 class="font-medium text-sm flex items-center gap-2">
							<Shield class="w-3 h-3" />
							Service Worker
						</h4>
						<div class="pl-5 space-y-1">
							<div class="flex justify-between">
								<span class="text-muted-foreground">Status:</span>
								<span class="px-2 py-0.5 text-xs rounded bg-gray-100 text-gray-800">
									Not Implemented
								</span>
							</div>
						</div>
					</div>
					
					<!-- Actions -->
					<div class="flex gap-2 pt-2 border-t">
						<Button 
							variant="outline" 
							size="sm" 
							on:click={loadSystemStatus}
							class="text-xs h-7"
						>
							<RefreshCw class="w-3 h-3 mr-1" />
							Refresh
						</Button>
						
						{#if errorReportingConfig?.enabled}
							<Button 
								variant="outline" 
								size="sm" 
								on:click={testErrorReporting}
								class="text-xs h-7"
							>
								Test Error
							</Button>
							
							{#if queueSize > 0}
								<Button 
									variant="outline" 
									size="sm" 
									on:click={flushErrorReports}
									class="text-xs h-7"
								>
									Flush ({queueSize})
								</Button>
							{/if}
						{/if}
					</div>
					
					{#if lastRefresh}
						<div class="text-muted-foreground text-xs pt-2 border-t">
							Last updated: {lastRefresh}
						</div>
					{/if}
				</CardContent>
			</Card>
		</div>
	{/if}

	<!-- Floating Button -->
	<Button 
		on:click={toggleStatus}
		class="w-12 h-12 rounded-full shadow-lg ring-2 {ringColor} ring-offset-2 transition-all hover:scale-105"
		variant={overallStatus === 'good' ? 'default' : overallStatus === 'warning' ? 'secondary' : 'destructive'}
	>
		<svelte:component this={statusIcon} class="w-5 h-5" />
	</Button>
</div>

<!-- Click outside to close -->
{#if isOpen}
	<div 
		class="fixed inset-0 z-40"
		on:click={toggleStatus}
		on:keydown={(e) => e.key === 'Escape' && toggleStatus()}
		role="button"
		tabindex="0"
	></div>
{/if}