<script lang="ts">
import EmployeeDirectory from '$lib/components/employee/EmployeeDirectory.svelte';
import { Card, CardContent, CardHeader, CardTitle } from '$lib/components/ui/card';
import { employees, invitations } from '$lib/stores/data';
import { Calendar, CheckCircle, FileText, UserMinus, Users } from 'lucide-svelte';

// Filter employees and invitations related to offboarding
$: offboardingEmployees = $employees.filter(emp => 
  emp.status === 'previous' || emp.status === 'other'
);

$: offboardingInvitations = $invitations.filter(inv => 
  inv.invitationType === 'offboarding'
);

$: recentOffboardingInvitations = offboardingInvitations.slice(0, 5);

// Calculate completion rate based on invitations status
$: completionRate = offboardingInvitations.length > 0 
  ? Math.round((offboardingInvitations.filter(inv => inv.status === 'accepted').length / offboardingInvitations.length) * 100)
  : 0;

// Department statistics for offboarding
$: departmentStats = offboardingEmployees.reduce((acc, emp) => {
  if (!acc[emp.department]) acc[emp.department] = 0;
  acc[emp.department]++;
  return acc;
}, {} as Record<string, number>);
</script>

<div class="space-y-6">
  <!-- Statistics Overview -->
  <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
    <Card>
      <CardHeader class="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle class="text-sm font-medium">Currently Offboarding</CardTitle>
        <UserMinus class="w-4 h-4 text-muted-foreground" />
      </CardHeader>
      <CardContent>
        <div class="text-2xl font-bold">{offboardingEmployees.length}</div>
        <p class="text-xs text-muted-foreground">Employees leaving</p>
      </CardContent>
    </Card>

    <Card>
      <CardHeader class="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle class="text-sm font-medium">Offboarding Process</CardTitle>
        <CheckCircle class="w-4 h-4 text-muted-foreground" />
      </CardHeader>
      <CardContent>
        <div class="text-2xl font-bold">{completionRate}%</div>
        <p class="text-xs text-muted-foreground">Completion rate</p>
      </CardContent>
    </Card>

    <Card>
      <CardHeader class="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle class="text-sm font-medium">Pending Invitations</CardTitle>
        <Calendar class="w-4 h-4 text-muted-foreground" />
      </CardHeader>
      <CardContent>
        <div class="text-2xl font-bold">
          {offboardingInvitations.filter(inv => inv.status === 'pending').length}
        </div>
        <p class="text-xs text-muted-foreground">Awaiting response</p>
      </CardContent>
    </Card>

    <Card>
      <CardHeader class="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle class="text-sm font-medium">Total Invitations</CardTitle>
        <FileText class="w-4 h-4 text-muted-foreground" />
      </CardHeader>
      <CardContent>
        <div class="text-2xl font-bold">{offboardingInvitations.length}</div>
        <p class="text-xs text-muted-foreground">Sent invitations</p>
      </CardContent>
    </Card>
  </div>

  <!-- Main Content -->
  <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
    <!-- Offboarding Employees -->
    <Card>
      <CardHeader>
        <CardTitle>Employees Leaving</CardTitle>
      </CardHeader>
      <CardContent>
        {#if offboardingEmployees.length > 0}
          <EmployeeDirectory employees={offboardingEmployees} compact={true} />
        {:else}
          <div class="text-center py-8">
            <UserMinus class="w-12 h-12 text-gray-300 mx-auto mb-4" />
            <p class="text-gray-500">No employees currently in offboarding process</p>
          </div>
        {/if}
      </CardContent>
    </Card>

    <!-- Recent Invitations -->
    <Card>
      <CardHeader>
        <CardTitle>Recent Offboarding Invitations</CardTitle>
      </CardHeader>
      <CardContent>
        {#if recentOffboardingInvitations.length > 0}
          <div class="space-y-3">
            {#each recentOffboardingInvitations as invitation}
              <div class="border rounded-lg p-3">
                <div class="flex items-center justify-between">
                  <div>
                    <p class="font-medium text-sm">
                      {invitation.firstName} {invitation.lastName}
                    </p>
                    <p class="text-xs text-gray-500">{invitation.companyEmail}</p>
                    <p class="text-xs text-gray-400">
                      {invitation.department} • {invitation.position}
                    </p>
                  </div>
                  <div class="text-right">
                    <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium {
                      invitation.status === 'pending' ? 'bg-yellow-100 text-yellow-800' :
                      invitation.status === 'sent' ? 'bg-blue-100 text-blue-800' :
                      invitation.status === 'accepted' ? 'bg-green-100 text-green-800' :
                      'bg-gray-100 text-gray-800'
                    }">
                      {invitation.status}
                    </span>
                    <p class="text-xs text-gray-400 mt-1">
                      {new Date(invitation.createdAt).toLocaleDateString()}
                    </p>
                  </div>
                </div>
              </div>
            {/each}
          </div>
        {:else}
          <div class="text-center py-8">
            <Calendar class="w-12 h-12 text-gray-300 mx-auto mb-4" />
            <p class="text-gray-500">No offboarding invitations sent yet</p>
          </div>
        {/if}
      </CardContent>
    </Card>
  </div>

  <!-- Department Breakdown -->
  {#if Object.keys(departmentStats).length > 0}
    <Card>
      <CardHeader>
        <CardTitle>Departures by Department</CardTitle>
      </CardHeader>
      <CardContent>
        <div class="space-y-3">
          {#each Object.entries(departmentStats) as [department, count]}
            <div class="flex items-center justify-between">
              <span class="font-medium">{department}</span>
              <span class="text-sm text-gray-600">{count} employee{count !== 1 ? 's' : ''}</span>
            </div>
          {/each}
        </div>
      </CardContent>
    </Card>
  {/if}
</div>