<script lang="ts">
	import type { Employee } from "$lib/types";

	export let status: Employee['status'];
	export let size: 'sm' | 'md' | 'lg' = 'md';

	// Size mappings
	$: sizeClasses = {
		sm: 'px-1.5 py-0.5 text-xs',
		md: 'px-2.5 py-0.5 text-xs', 
		lg: 'px-3 py-1 text-sm'
	}[size];

	// Status color mappings
	$: statusClasses = {
		active: 'text-green-600 bg-green-50 border-green-200',
		previous: 'text-gray-600 bg-gray-50 border-gray-200', 
		future: 'text-blue-600 bg-blue-50 border-blue-200',
		other: 'text-yellow-600 bg-yellow-50 border-yellow-200'
	}[status] || 'text-gray-600 bg-gray-50 border-gray-200';

	// Status display text with better formatting
	$: displayText = {
		active: 'Active',
		previous: 'Previous', 
		future: 'Future',
		other: 'Other'
	}[status] || status;

	// Status descriptions for tooltips
	$: description = {
		active: 'Currently employed',
		previous: 'Former employee',
		future: 'Starting soon', 
		other: 'Special status'
	}[status] || status;
</script>

<span 
	class="inline-flex items-center rounded-full border font-medium {sizeClasses} {statusClasses}"
	title="Employee status: {description}"
>
	{displayText}
</span>