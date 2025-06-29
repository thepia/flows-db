<script lang="ts">
import { goto } from '$app/navigation';
import { Button } from '$lib/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '$lib/components/ui/card';
import { Input } from '$lib/components/ui/input';
import { EmployeeCard } from '$lib/components/employee';
import { employees, loading, loadDemoData, people, totalPeopleCount } from '$lib/stores/data';
import { UserPlus, Search, Filter, Users, Briefcase } from 'lucide-svelte';
import { onMount } from 'svelte';

// Search and filter state
let searchTerm = '';
let selectedStatus = 'all';
let selectedType = 'all';

// Load data on mount
onMount(() => {
  loadDemoData();
});

// Filter options
const statusOptions = [
  { value: 'all', label: 'All Status' },
  { value: 'active', label: 'Active' },
  { value: 'former', label: 'Former' },
  { value: 'future', label: 'Future' },
];

const typeOptions = [
  { value: 'all', label: 'All Types' },
  { value: 'employee', label: 'Employees' },
  { value: 'associate', label: 'Associates' },
];

// Filtered people based on search and filters
$: filteredPeople = $people.filter((person) => {
  // Search filter
  const matchesSearch = searchTerm === '' || 
    person.firstName.toLowerCase().includes(searchTerm.toLowerCase()) ||
    person.lastName.toLowerCase().includes(searchTerm.toLowerCase()) ||
    person.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
    person.department.toLowerCase().includes(searchTerm.toLowerCase()) ||
    person.position.toLowerCase().includes(searchTerm.toLowerCase());

  // Status filter
  const matchesStatus = selectedStatus === 'all' || 
    (selectedStatus === 'active' && person.employmentStatus === 'active') ||
    (selectedStatus === 'former' && person.employmentStatus === 'former') ||
    (selectedStatus === 'future' && person.employmentStatus === 'future');

  // Type filter
  const matchesType = selectedType === 'all' ||
    (selectedType === 'employee' && person.employmentStatus) ||
    (selectedType === 'associate' && person.associateStatus);

  return matchesSearch && matchesStatus && matchesType;
});

// Statistics
$: totalPeople = $totalPeopleCount || $people.length;
$: activeEmployees = $people.filter(p => p.employmentStatus === 'active').length;
$: associates = $people.filter(p => p.associateStatus).length;
$: futureEmployees = $people.filter(p => p.employmentStatus === 'future').length;
</script>

<svelte:head>
	<title>People - Flows Admin</title>
</svelte:head>

<div class="min-h-screen bg-gray-50 py-8">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
		<!-- Header -->
		<div class="mb-8">
			<div class="flex items-center justify-between">
				<div>
					<h1 class="text-3xl font-bold text-gray-900">People</h1>
					<p class="text-gray-600 mt-2">Manage employees and associates in your organization</p>
				</div>
				<Button on:click={() => goto('/people/new')} class="bg-primary hover:bg-primary/90">
					<UserPlus class="w-4 h-4 mr-2" />
					Add Person
				</Button>
			</div>
		</div>

		<!-- Statistics Cards -->
		<div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
			<Card>
				<CardContent class="pt-6">
					<div class="flex items-center">
						<div class="flex-shrink-0">
							<Users class="h-8 w-8 text-blue-600" />
						</div>
						<div class="ml-5 w-0 flex-1">
							<dl>
								<dt class="text-sm font-medium text-gray-500 truncate">Total People</dt>
								<dd class="text-lg font-medium text-gray-900">{totalPeople}</dd>
							</dl>
						</div>
					</div>
				</CardContent>
			</Card>

			<Card>
				<CardContent class="pt-6">
					<div class="flex items-center">
						<div class="flex-shrink-0">
							<div class="h-8 w-8 bg-green-100 rounded-full flex items-center justify-center">
								<div class="h-4 w-4 bg-green-600 rounded-full"></div>
							</div>
						</div>
						<div class="ml-5 w-0 flex-1">
							<dl>
								<dt class="text-sm font-medium text-gray-500 truncate">Active Employees</dt>
								<dd class="text-lg font-medium text-gray-900">{activeEmployees}</dd>
							</dl>
						</div>
					</div>
				</CardContent>
			</Card>

			<Card>
				<CardContent class="pt-6">
					<div class="flex items-center">
						<div class="flex-shrink-0">
							<Briefcase class="h-8 w-8 text-purple-600" />
						</div>
						<div class="ml-5 w-0 flex-1">
							<dl>
								<dt class="text-sm font-medium text-gray-500 truncate">Associates</dt>
								<dd class="text-lg font-medium text-gray-900">{associates}</dd>
							</dl>
						</div>
					</div>
				</CardContent>
			</Card>

			<Card>
				<CardContent class="pt-6">
					<div class="flex items-center">
						<div class="flex-shrink-0">
							<div class="h-8 w-8 bg-orange-100 rounded-full flex items-center justify-center">
								<div class="h-4 w-4 bg-orange-600 rounded-full"></div>
							</div>
						</div>
						<div class="ml-5 w-0 flex-1">
							<dl>
								<dt class="text-sm font-medium text-gray-500 truncate">Future Employees</dt>
								<dd class="text-lg font-medium text-gray-900">{futureEmployees}</dd>
							</dl>
						</div>
					</div>
				</CardContent>
			</Card>
		</div>

		<!-- Search and Filters -->
		<Card class="mb-8">
			<CardHeader>
				<CardTitle class="flex items-center">
					<Search class="w-5 h-5 mr-2" />
					Search & Filter
				</CardTitle>
			</CardHeader>
			<CardContent>
				<div class="grid grid-cols-1 md:grid-cols-3 gap-4">
					<!-- Search Input -->
					<div>
						<label for="search" class="block text-sm font-medium text-gray-700 mb-2">
							Search People
						</label>
						<div class="relative">
							<Search class="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
							<Input
								id="search"
								type="text"
								placeholder="Search by name, email, department..."
								bind:value={searchTerm}
								class="pl-10"
							/>
						</div>
					</div>

					<!-- Status Filter -->
					<div>
						<label for="status-filter" class="block text-sm font-medium text-gray-700 mb-2">
							Filter by Status
						</label>
						<select
							id="status-filter"
							bind:value={selectedStatus}
							class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
						>
							{#each statusOptions as option}
								<option value={option.value}>{option.label}</option>
							{/each}
						</select>
					</div>

					<!-- Type Filter -->
					<div>
						<label for="type-filter" class="block text-sm font-medium text-gray-700 mb-2">
							Filter by Type
						</label>
						<select
							id="type-filter"
							bind:value={selectedType}
							class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
						>
							{#each typeOptions as option}
								<option value={option.value}>{option.label}</option>
							{/each}
						</select>
					</div>
				</div>

				<!-- Active Filters Display -->
				{#if searchTerm || selectedStatus !== 'all' || selectedType !== 'all'}
					<div class="mt-4 flex items-center space-x-2">
						<span class="text-sm text-gray-500">Active filters:</span>
						{#if searchTerm}
							<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
								Search: {searchTerm}
							</span>
						{/if}
						{#if selectedStatus !== 'all'}
							<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
								Status: {statusOptions.find(o => o.value === selectedStatus)?.label}
							</span>
						{/if}
						{#if selectedType !== 'all'}
							<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-purple-100 text-purple-800">
								Type: {typeOptions.find(o => o.value === selectedType)?.label}
							</span>
						{/if}
						<Button
							variant="ghost"
							size="sm"
							on:click={() => {
								searchTerm = '';
								selectedStatus = 'all';
								selectedType = 'all';
							}}
							class="text-xs"
						>
							Clear all
						</Button>
					</div>
				{/if}

				<!-- Results Count -->
				<div class="mt-4 text-sm text-gray-600">
					Showing {filteredPeople.length} of {totalPeople} people
				</div>
			</CardContent>
		</Card>

		<!-- People Grid -->
		{#if $loading}
			<div class="flex justify-center items-center py-12">
				<div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
			</div>
		{:else if filteredPeople.length === 0}
			<Card>
				<CardContent class="py-12">
					<div class="text-center">
						<Users class="mx-auto h-12 w-12 text-gray-400" />
						<h3 class="mt-2 text-sm font-medium text-gray-900">No people found</h3>
						<p class="mt-1 text-sm text-gray-500">
							{#if searchTerm || selectedStatus !== 'all' || selectedType !== 'all'}
								Try adjusting your search or filter criteria.
							{:else}
								Get started by adding your first person.
							{/if}
						</p>
						{#if !searchTerm && selectedStatus === 'all' && selectedType === 'all'}
							<div class="mt-6">
								<Button on:click={() => goto('/people/new')}>
									<UserPlus class="w-4 h-4 mr-2" />
									Add Person
								</Button>
							</div>
						{/if}
					</div>
				</CardContent>
			</Card>
		{:else}
			<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
				{#each filteredPeople as person (person.id)}
					<EmployeeCard employee={person} />
				{/each}
			</div>

			<!-- Load More Section -->
			{#if !searchTerm && selectedStatus === 'all' && selectedType === 'all' && $totalPeopleCount > $people.length}
				<div class="mt-8 text-center">
					<div class="bg-white p-6 rounded-lg border border-gray-200">
						<p class="text-sm text-gray-600 mb-4">
							Showing {$people.length} of {$totalPeopleCount} people
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
		{/if}
	</div>
</div>