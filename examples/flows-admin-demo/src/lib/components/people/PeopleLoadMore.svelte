<script lang="ts">
import { Button } from '$lib/components/ui/button';
import { Users } from 'lucide-svelte';

export let currentCount: number;
export let totalCount: number;
export let hasActiveFilters: boolean = false;

$: shouldShowLoadMore = !hasActiveFilters && totalCount > currentCount;
</script>

{#if shouldShowLoadMore}
	<!-- Load More Section -->
	<div class="mt-8 text-center">
		<div class="bg-white p-6 rounded-lg border border-gray-200">
			<p class="text-sm text-gray-600 mb-4">
				Showing {currentCount} of {totalCount} people
			</p>
			<Button variant="outline" disabled>
				<Users class="w-4 h-4 mr-2" />
				Load More People (Coming Soon)
			</Button>
			<p class="text-xs text-gray-500 mt-2">
				Full pagination will be implemented in the next update
			</p>
		</div>
	</div>
{/if}