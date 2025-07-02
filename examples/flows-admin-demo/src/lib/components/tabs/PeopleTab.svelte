<script lang="ts">
import { createEventDispatcher } from 'svelte';
import { 
  PeopleHeader, 
  PeopleStatsCards, 
  PeopleFilters, 
  PeopleActiveFilters, 
  PeopleGrid, 
  PeopleLoadMore 
} from '$lib/components/people';
import { people, totalPeopleCount, loading } from '$lib/stores/data';

const dispatch = createEventDispatcher();

// People tab search and filter state
let searchTerm = '';
let selectedStatus = 'all';
let selectedType = 'all';

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
    person.employmentStatus === selectedStatus;

  // Type filter (employment vs associate)
  const matchesType = selectedType === 'all' || 
    (selectedType === 'employee' && person.employmentStatus) ||
    (selectedType === 'associate' && person.associateStatus);

  return matchesSearch && matchesStatus && matchesType;
});

// Statistics for People tab
$: totalPeople = $totalPeopleCount || $people.length;
$: activeEmployees = $people.filter(p => p.employmentStatus === 'active').length;
$: associates = $people.filter(p => p.associateStatus).length;
$: futureEmployees = $people.filter(p => p.employmentStatus === 'future').length;

// Helper for active filters check
$: hasActiveFilters = searchTerm || selectedStatus !== 'all' || selectedType !== 'all';
</script>

<!-- People Tab Content -->
<div class="space-y-6" data-testid="view-people">
  <PeopleHeader />

  <PeopleStatsCards 
    {totalPeople}
    {activeEmployees}
    {associates}
    {futureEmployees}
  />

  <PeopleFilters 
    bind:searchTerm
    bind:selectedStatus
    bind:selectedType
  />

  <PeopleActiveFilters 
    bind:searchTerm
    bind:selectedStatus
    bind:selectedType
    filteredCount={filteredPeople.length}
    totalCount={totalPeople}
  />

  <PeopleGrid 
    people={filteredPeople}
    loading={$loading}
    {hasActiveFilters}
  />

  <PeopleLoadMore 
    currentCount={$people.length}
    totalCount={$totalPeopleCount || 0}
    {hasActiveFilters}
  />
</div>