<script lang="ts">
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { Button } from "$lib/components/ui/button";
	import { Settings, Inbox, User, ArrowLeft, ChevronLeft } from "lucide-svelte";
	import { client } from '$lib/stores/data';
	import LogoWrapper from '../branding/LogoWrapper.svelte';

	// Props
	export let title: string = 'Flows Dashboard';
	export let showBackButton: boolean = false;

	// Navigation handlers
	function navigateToSettings() {
		goto('/settings');
	}

	function navigateBack() {
		goto('/');
	}

	// Placeholder handlers for future functionality
	function openInbox() {
		console.log('Inbox clicked - feature coming soon');
	}

	function openProfile() {
		console.log('Profile clicked - feature coming soon');
	}
</script>

<header class="bg-white border-b border-gray-200">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
		<div class="flex items-center justify-between h-16">
			<!-- Left section -->
			<div class="flex items-center">
				{#if showBackButton}
					<Button 
						variant="ghost" 
						size="sm" 
						on:click={navigateBack}
						class="mr-4 -ml-2"
					>
						<ArrowLeft class="w-5 h-5" />
					</Button>
				{:else}
					<!-- Thepia Logo -->
					<div class="w-8 h-8 mr-3">
						<LogoWrapper variant="square" />
					</div>
				{/if}
				<div>
					<h1 class="text-2xl font-bold text-gray-900">{title}</h1>
					{#if !showBackButton}
						{#if $client}
							<p class="text-sm text-gray-500">
								{$client.name} • {$client.tier} tier • {$client.status} • {$client.region}
							</p>
						{:else}
							<p class="text-sm text-gray-400">Loading client...</p>
						{/if}
					{/if}
				</div>
			</div>

			<!-- Right section with icon buttons -->
			<div class="flex items-center space-x-2">
				<!-- Settings button (only show on main page) -->
				{#if !showBackButton}
					<Button 
						variant="ghost" 
						size="icon"
						on:click={navigateToSettings}
						class="w-9 h-9 rounded-md hover:bg-gray-100"
						title="Settings"
					>
						<Settings class="w-5 h-5 text-gray-600" />
					</Button>
				{/if}

				<!-- Inbox button -->
				<Button 
					variant="ghost" 
					size="icon"
					on:click={openInbox}
					class="w-9 h-9 rounded-md hover:bg-gray-100"
					title="Inbox"
				>
					<Inbox class="w-5 h-5 text-gray-600" />
				</Button>

				<!-- Profile button -->
				<Button 
					variant="ghost" 
					size="icon"
					on:click={openProfile}
					class="w-9 h-9 rounded-full hover:bg-gray-100"
					title="Profile"
				>
					<User class="w-5 h-5 text-gray-600" />
				</Button>
			</div>
		</div>
	</div>
</header>

<style>
	/* Ensure consistent icon button styling */
	:global(.w-9) {
		width: 2.25rem !important;
	}
	:global(.h-9) {
		height: 2.25rem !important;
	}
</style>