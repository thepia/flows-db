<script lang="ts">
	import { onMount } from 'svelte';
	import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "$lib/components/ui/card";
	import { Button } from "$lib/components/ui/button";
	import { 
		settingsStore, 
		settings, 
		selectedBranding, 
		isSettingsLoading, 
		settingsError,
		getAvailableClients 
	} from '$lib/stores/settings';
	import { clients, loadAllClients, loadClientData } from '$lib/stores/data';
	import type { BrandingConfig } from '$lib/types';
	import { Settings, Palette, Building2, Plus, Trash2, RotateCcw, Save, AlertTriangle, Database, ArrowRight } from 'lucide-svelte';

	// Component state
	let newBrandingName = '';
	let newBrandingPath = '';
	let newBrandingType: 'package' | 'local' = 'package';
	let showAddBranding = false;
	let initialized = false;
	let loadingClientData = false;

	// Initialize settings on mount
	onMount(async () => {
		// Initialize settings first
		settingsStore.init();
		
		// Load all clients so they're available for selection
		await loadAllClients();
		
		// Mark as initialized
		initialized = true;
	});

	// Track the last loaded client to avoid re-loading
	let lastLoadedClientId = '';

	// Load data for selected client when settings change
	$: if (initialized && $settings?.selectedClient && $settings.selectedClient !== lastLoadedClientId) {
		lastLoadedClientId = $settings.selectedClient;
		loadClientData($settings.selectedClient).catch(error => {
			console.error('Failed to load selected client data:', error);
		});
	}

	// Reactive available clients (with safety checks)
	$: availableClients = ($clients && $settings) ? getAvailableClients($clients, $settings) : [];

	// Handle branding selection
	function handleBrandingChange(brandingId: string) {
		settingsStore.selectBranding(brandingId);
	}

	// Handle client selection
	async function handleClientChange(clientId: string) {
		settingsStore.selectClient(clientId);
		
		// Also load the data for this client
		if (clientId) {
			loadingClientData = true;
			try {
				await loadClientData(clientId);
			} catch (error) {
				console.error('Failed to load client data:', error);
			} finally {
				loadingClientData = false;
			}
		}
	}

	// Manual data loading function
	async function loadSelectedClientData() {
		if (!$settings?.selectedClient) return;
		
		loadingClientData = true;
		try {
			await loadClientData($settings.selectedClient);
		} catch (error) {
			console.error('Failed to load client data:', error);
		} finally {
			loadingClientData = false;
		}
	}

	// Handle real clients toggle
	function handleRealClientsToggle(checked: boolean) {
		settingsStore.toggleRealClients(checked);
	}

	// Add new branding
	function addNewBranding() {
		if (!newBrandingName.trim() || !newBrandingPath.trim()) return;

		const branding: BrandingConfig = {
			id: newBrandingName.toLowerCase().replace(/\s+/g, '-'),
			name: newBrandingName,
			displayName: newBrandingName,
			type: newBrandingType,
			path: newBrandingPath
		};

		settingsStore.addBranding(branding);
		
		// Reset form
		newBrandingName = '';
		newBrandingPath = '';
		newBrandingType = 'package';
		showAddBranding = false;
	}

	// Remove branding
	function removeBranding(brandingId: string) {
		if (confirm('Are you sure you want to remove this branding configuration?')) {
			settingsStore.removeBranding(brandingId);
		}
	}

	// Reset settings
	function resetSettings() {
		if (confirm('Are you sure you want to reset all settings to defaults? This cannot be undone.')) {
			settingsStore.reset();
		}
	}

	// Format last updated date
	function formatLastUpdated(dateString: string) {
		return new Date(dateString).toLocaleString();
	}
</script>

{#if initialized && $settings}
<div class="space-y-6">
	<!-- Header -->
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-2xl font-bold text-gray-900 flex items-center">
				<Settings class="w-6 h-6 mr-3" />
				Demo Settings
			</h1>
			<p class="text-sm text-gray-500 mt-1">
				Configure branding, client selection, and demo preferences
			</p>
		</div>
		<Button variant="outline" on:click={resetSettings}>
			<RotateCcw class="w-4 h-4 mr-2" />
			Reset to Defaults
		</Button>
	</div>

	{#if $settingsError}
		<Card class="border-red-200 bg-red-50">
			<CardContent class="pt-4">
				<div class="flex items-center text-red-800">
					<AlertTriangle class="w-5 h-5 mr-2" />
					<span>Settings Error: {$settingsError}</span>
					<Button variant="ghost" size="sm" on:click={() => settingsStore.clearError()} class="ml-auto">
						Dismiss
					</Button>
				</div>
			</CardContent>
		</Card>
	{/if}

	<!-- Branding Configuration -->
	<Card>
		<CardHeader>
			<CardTitle class="flex items-center">
				<Palette class="w-5 h-5 mr-2" />
				Branding Configuration
			</CardTitle>
			<CardDescription>
				Select the branding package or local directory to use for the demo interface
			</CardDescription>
		</CardHeader>
		<CardContent class="space-y-4">
			<!-- Current Selection -->
			<div>
				<label for="selected-branding" class="block text-sm font-medium text-gray-700 mb-2">
					Selected Branding
				</label>
				<select 
					id="selected-branding"
					value={$settings?.selectedBranding || ''}
					on:change={(e) => handleBrandingChange(e.target.value)}
					class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
				>
					<option value="">Select branding...</option>
					{#each ($settings?.availableBrandings || []) as branding}
						<option value={branding.id}>
							{branding.displayName} ({branding.type})
							{branding.isDefault ? ' - Default' : ''}
						</option>
					{/each}
				</select>
			</div>

			<!-- Current Branding Details -->
			{#if $selectedBranding}
				<div class="p-3 bg-gray-50 rounded-lg">
					<div class="grid grid-cols-2 gap-4 text-sm">
						<div>
							<span class="font-medium text-gray-700">Path:</span>
							<span class="ml-2 font-mono text-gray-600">{$selectedBranding.path}</span>
						</div>
						<div>
							<span class="font-medium text-gray-700">Type:</span>
							<span class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
								{$selectedBranding.type}
							</span>
						</div>
					</div>
				</div>
			{/if}

			<hr class="border-gray-200" />

			<!-- Available Brandings -->
			<div>
				<div class="flex items-center justify-between mb-3">
					<label class="text-sm font-medium text-gray-700">Available Brandings</label>
					<Button variant="outline" size="sm" on:click={() => showAddBranding = !showAddBranding}>
						<Plus class="w-4 h-4 mr-1" />
						Add Custom
					</Button>
				</div>

				<div class="space-y-2">
					{#each ($settings?.availableBrandings || []) as branding}
						<div class="flex items-center justify-between p-3 border rounded-lg">
							<div>
								<div class="font-medium">{branding.displayName}</div>
								<div class="text-sm text-gray-500 font-mono">{branding.path}</div>
							</div>
							<div class="flex items-center space-x-2">
								<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
									{branding.type}
								</span>
								{#if branding.isDefault}
									<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
										default
									</span>
								{:else}
									<Button 
										variant="ghost" 
										size="sm" 
										on:click={() => removeBranding(branding.id)}
										class="text-red-600 hover:text-red-700"
									>
										<Trash2 class="w-4 h-4" />
									</Button>
								{/if}
							</div>
						</div>
					{/each}
				</div>

				<!-- Add Branding Form -->
				{#if showAddBranding}
					<div class="mt-4 p-4 border rounded-lg bg-gray-50">
						<div class="space-y-3">
							<div>
								<label for="new-branding-name" class="block text-sm font-medium text-gray-700 mb-1">
									Display Name
								</label>
								<input 
									id="new-branding-name"
									type="text"
									bind:value={newBrandingName} 
									placeholder="e.g., My Custom Branding"
									class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
								/>
							</div>
							<div>
								<label for="new-branding-type" class="block text-sm font-medium text-gray-700 mb-1">
									Type
								</label>
								<select 
									id="new-branding-type"
									bind:value={newBrandingType}
									class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
								>
									<option value="package">NPM Package</option>
									<option value="local">Local Directory</option>
								</select>
							</div>
							<div>
								<label for="new-branding-path" class="block text-sm font-medium text-gray-700 mb-1">
									{newBrandingType === 'package' ? 'Package Name' : 'Local Path'}
								</label>
								<input 
									id="new-branding-path"
									type="text"
									bind:value={newBrandingPath} 
									placeholder={newBrandingType === 'package' ? '@company/branding' : '/path/to/branding'}
									class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
								/>
							</div>
							<div class="flex space-x-2">
								<Button on:click={addNewBranding} disabled={!newBrandingName.trim() || !newBrandingPath.trim()}>
									<Save class="w-4 h-4 mr-1" />
									Add Branding
								</Button>
								<Button variant="outline" on:click={() => showAddBranding = false}>
									Cancel
								</Button>
							</div>
						</div>
					</div>
				{/if}
			</div>
		</CardContent>
	</Card>

	<!-- Client Selection -->
	<Card>
		<CardHeader>
			<CardTitle class="flex items-center">
				<Building2 class="w-5 h-5 mr-2" />
				Client Selection
			</CardTitle>
			<CardDescription>
				Choose which client data to display in the demo
			</CardDescription>
		</CardHeader>
		<CardContent class="space-y-4">
			<!-- Real Clients Access -->
			<div class="flex items-center space-x-3 p-3 bg-yellow-50 border border-yellow-200 rounded-lg">
				<input 
					id="allow-real-clients"
					type="checkbox"
					checked={$settings?.allowRealClients || false}
					on:change={(e) => handleRealClientsToggle(e.target.checked)}
					class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
				/>
				<div>
					<label for="allow-real-clients" class="font-medium text-yellow-800">
						Allow Real Client Data
					</label>
					<p class="text-sm text-yellow-700">
						Enable access to production client data (use with caution)
					</p>
				</div>
			</div>

			<!-- Client Selection -->
			<div>
				<label for="selected-client" class="block text-sm font-medium text-gray-700 mb-2">
					Selected Client
				</label>
				<select 
					id="selected-client"
					value={$settings?.selectedClient || ''}
					on:change={(e) => handleClientChange(e.target.value)}
					class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
				>
					<option value="">Select client...</option>
					{#each availableClients as client}
						<option value={client.id}>
							{client.name} ({client.tier} - {client.status})
						</option>
					{/each}
				</select>
			</div>

			<!-- Available Clients Summary -->
			<div class="flex items-center justify-between">
				<div class="text-sm text-gray-600">
					Showing {availableClients.length} available client{availableClients.length !== 1 ? 's' : ''}
					{#if !($settings?.allowRealClients || false)}
						(demo/test clients only)
					{/if}
				</div>
				
				{#if $settings?.selectedClient}
					<div class="flex items-center space-x-2">
						<Button 
							variant="outline" 
							size="sm" 
							on:click={loadSelectedClientData}
							disabled={loadingClientData}
						>
							{#if loadingClientData}
								<div class="w-4 h-4 border-2 border-blue-600 border-t-transparent rounded-full animate-spin mr-2"></div>
								Loading...
							{:else}
								<Database class="w-4 h-4 mr-2" />
								Load Data
							{/if}
						</Button>
						<Button variant="outline" size="sm" href="/">
							<ArrowRight class="w-4 h-4 mr-2" />
							View Dashboard
						</Button>
					</div>
				{/if}
			</div>
		</CardContent>
	</Card>

	<!-- Settings Info -->
	<Card>
		<CardHeader>
			<CardTitle class="text-base">Settings Information</CardTitle>
		</CardHeader>
		<CardContent>
			<div class="grid grid-cols-2 gap-4 text-sm">
				<div>
					<span class="font-medium text-gray-700">Last Updated:</span>
					<span class="ml-2 text-gray-600">
						{$settings?.lastUpdated ? formatLastUpdated($settings.lastUpdated) : 'Not available'}
					</span>
				</div>
				<div>
					<span class="font-medium text-gray-700">Storage:</span>
					<span class="ml-2 text-gray-600">Browser localStorage</span>
				</div>
			</div>
		</CardContent>
	</Card>
</div>
{:else}
<!-- Loading state -->
<div class="flex items-center justify-center py-16">
	<div class="text-center">
		<div class="w-8 h-8 bg-blue-500 rounded-full animate-bounce mx-auto mb-4"></div>
		<p class="text-gray-600">Loading settings...</p>
	</div>
</div>
{/if}