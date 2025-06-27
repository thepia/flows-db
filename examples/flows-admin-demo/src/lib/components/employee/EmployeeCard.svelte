<script lang="ts">
	import { Button } from "$lib/components/ui/button";
	import EmployeeStatusBadge from "./EmployeeStatusBadge.svelte";
	import type { Employee, EmployeeEnrollment } from "$lib/types";

	// Props
	export let employee: Employee;
	export let enrollment: EmployeeEnrollment | undefined = undefined;
	export let onSelect: ((employee: Employee) => void) | undefined = undefined;
	export let compact: boolean = false;

	// Helper function for completion percentage color
	function getCompletionColor(percentage: number) {
		if (percentage >= 80) return 'text-green-600';
		if (percentage >= 50) return 'text-yellow-600';
		return 'text-red-600';
	}

	// Handle click
	function handleClick() {
		onSelect?.(employee);
	}
</script>

<div 
	class="flex items-center justify-between p-4 border rounded-lg hover:bg-gray-50 transition-colors {compact ? 'p-3' : 'p-4'}"
	class:cursor-pointer={onSelect}
	on:click={handleClick}
	on:keydown={(e) => e.key === 'Enter' && handleClick()}
	role={onSelect ? 'button' : undefined}
	tabindex={onSelect ? 0 : undefined}
>
	<div class="flex items-center space-x-4">
		<div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
			<span class="text-sm font-medium text-primary">
				{employee.firstName[0]}{employee.lastName[0]}
			</span>
		</div>
		<div>
			<h3 class="font-medium text-gray-900">
				{employee.firstName} {employee.lastName}
			</h3>
			<p class="text-sm text-gray-500">{employee.position}</p>
			{#if !compact}
				<p class="text-xs text-gray-400">{employee.department} • {employee.location}</p>
			{/if}
		</div>
	</div>
	
	<div class="flex items-center space-x-4">
		{#if enrollment && !compact}
			<div class="text-right">
				<div class="text-sm font-medium {getCompletionColor(enrollment.completionPercentage)}">
					{enrollment.completionPercentage}% Complete
				</div>
				<div class="text-xs text-gray-500">
					{enrollment.documentsStatus.length} docs, {enrollment.tasksStatus.length} tasks
				</div>
			</div>
		{/if}
		
		<EmployeeStatusBadge status={employee.status} size={compact ? 'sm' : 'md'} />
		
		{#if !compact}
			<Button variant="outline" size="sm" href="/employees/{employee.id}">
				View Details
			</Button>
		{/if}
	</div>
</div>