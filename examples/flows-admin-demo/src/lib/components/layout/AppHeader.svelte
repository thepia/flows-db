<script lang="ts">
import { goto } from '$app/navigation';
import { page } from '$app/stores';
import { Button } from '$lib/components/ui/button';
import { client, loadingProgress } from '$lib/stores/data';
import { ArrowLeft, ChevronLeft, Settings, User } from 'lucide-svelte';
import LogoWrapper from '../branding/LogoWrapper.svelte';
import { NotificationBell, NotificationPanel } from '$lib/components/notifications';

// Props
export const title: string = 'Flows Dashboard';
export const showBackButton: boolean = false;

// Notification state
let showNotifications = false;

// Navigation handlers
function navigateToSettings() {
  console.log('Settings button clicked - navigating to /settings');
  window.location.href = '/settings';
}

function navigateBack() {
  console.log('Back button clicked - navigating to home');
  window.location.href = '/';
}

function toggleNotifications() {
  showNotifications = !showNotifications;
}

function closeNotifications() {
  showNotifications = false;
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
							<div class="text-sm text-gray-400">
								<div class="flex items-center space-x-2">
									<div class="w-4 h-4 border-2 border-blue-200 border-t-blue-600 rounded-full animate-spin"></div>
									<span>
										{$loadingProgress.stage} ({$loadingProgress.current}/{$loadingProgress.total})
										{#if $loadingProgress.message}
											• {$loadingProgress.message}
										{/if}
									</span>
								</div>
								{#if $loadingProgress.total > 0}
									<div class="w-48 bg-gray-200 rounded-full h-1.5 mt-1">
										<div 
											class="bg-blue-600 h-1.5 rounded-full transition-all duration-300" 
											style="width: {($loadingProgress.current / $loadingProgress.total) * 100}%"
										></div>
									</div>
								{/if}
							</div>
						{/if}
					{/if}
				</div>
			</div>

			<!-- Right section with icon buttons -->
			<div class="flex items-center space-x-2">
				<!-- Settings button (only show on main page) -->
				{#if !showBackButton}
					<button 
						type="button"
						on:click={navigateToSettings}
						class="inline-flex items-center justify-center w-9 h-9 rounded-md hover:bg-gray-100 text-gray-600"
						title="Settings"
					>
						<Settings class="w-5 h-5" />
					</button>
				{/if}

				<!-- Notifications -->
				<NotificationBell 
					onClick={toggleNotifications}
					size="md"
				/>

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

<!-- Notification Panel -->
<NotificationPanel 
	isOpen={showNotifications}
	onClose={closeNotifications}
/>

<style>
	/* Ensure consistent icon button styling */
	:global(.w-9) {
		width: 2.25rem !important;
	}
	:global(.h-9) {
		height: 2.25rem !important;
	}
</style>