<script lang="ts">
import FloatingStatusButton from '$lib/components/FloatingStatusButton.svelte';
import TabContentRouter from '$lib/components/TabContentRouter.svelte';
import AppNavigation from '$lib/components/navigation/AppNavigation.svelte';
import { getMockOffboardingData, getTasksForProcess } from '$lib/mockData/offboarding';
import {
  applications,
  client,
  error,
  getClientMetrics,
  loadDemoData,
  loading,
} from '$lib/stores/data';
import { supabase } from '$lib/supabase';
import { onMount } from 'svelte';

// Tab state
let activeTab = 'people';

// Reactive selectedApp calculation that updates when either activeTab or applications change
$: selectedApp = $applications?.find((app) => app.code === activeTab) || null;

// Applications reactive logic with proper guards
$: applicationsLoaded = $applications && Array.isArray($applications) && $applications.length > 0;

// State for different tabs
let offboardingView = 'overview';
let selectedTemplate = null;
let selectedProcess = null;
let offboardingTemplates = [];
let offboardingProcesses = [];
let allProcesses = [];
let offboardingTasks = [];

// Account state
let tfcBalance = null;
let recentInvoices = [];
let accountContacts = [];
let loadingAccount = false;

// Process filtering
let processFilters = {
  status: null,
  timeframe: null,
  search: '',
  department: null,
  priority: null,
  template: null,
};
let showProcessList = false;

// Functions from original component
function applyProcessFilter(filterType, filterValue) {
  processFilters = {
    status: null,
    timeframe: null,
    search: '',
    department: null,
    priority: null,
    template: null,
  };
  processFilters[filterType] = filterValue;
  showProcessList = true;
}

function clearProcessFilters() {
  processFilters = {
    status: null,
    timeframe: null,
    search: '',
    department: null,
    priority: null,
    template: null,
  };
  showProcessList = false;
}

async function generateProcessData() {
  console.log('🔄 Starting process data generation...');

  try {
    const { data: clientData, error: clientError } = await supabase
      .from('clients')
      .select('id, client_code')
      .eq('client_code', 'hygge-hvidlog')
      .single();

    if (clientError) {
      console.error('❌ Error fetching client:', clientError);
      alert('Error: Could not find hygge-hvidlog client');
      return;
    }

    if (!clientData) {
      console.error('❌ Hygge & Hvidløg client not found');
      alert('Error: hygge-hvidlog client not found in database');
      return;
    }

    console.log(`📊 Working with client: ${clientData.client_code}`);
    alert('Demo process data generation completed!');
  } catch (err) {
    console.error('Error generating process data:', err);
    alert('Error generating process data: ' + err.message);
  }
}

async function loadAccountData() {
  if (!$client?.id) return;

  loadingAccount = true;

  try {
    // Load TFC balance, invoices, and contacts
    // Simplified for now - full implementation would be in AccountService
    recentInvoices = [];
    accountContacts = [];
  } catch (error) {
    console.error('Error loading account data:', error);
  } finally {
    loadingAccount = false;
  }
}

// Load data and metrics on mount
onMount(async () => {
  await loadDemoData();

  // Load offboarding mock data
  offboardingTemplates = getMockOffboardingData().templates;
  offboardingProcesses = getMockOffboardingData().processes;
  allProcesses = [...offboardingProcesses];

  // Load metrics
  try {
    const metrics = await getClientMetrics();
    console.log('📊 Metrics loaded:', metrics);
  } catch (error) {
    console.error('Error loading metrics:', error);
  }

  // Load account data
  await loadAccountData();
});

// Handle tab changes
function handleTabChange(event) {
  activeTab = event.detail.tab;
  console.log('🔄 Tab changed to:', activeTab);
}

// Application tab clicks
$: {
  if (applicationsLoaded) {
    const validTabs = ['people', 'processes', 'account', ...$applications.map((app) => app.code)];
    if (!validTabs.includes(activeTab)) {
      activeTab = 'people';
    }
  }
}
</script>

<svelte:head>
  <title>
    Flows Admin - {$client?.name || 'Loading...'}
  </title>
</svelte:head>

<main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8" data-testid="app-loaded">
  <!-- Navigation -->
  <AppNavigation 
    bind:activeTab
    applications={$applications}
    {applicationsLoaded}
    on:tabChange={handleTabChange}
  />

  <!-- Content Router -->
  <TabContentRouter 
    {activeTab}
    {selectedApp}
    loading={$loading}
    error={$error}
    {allProcesses}
    bind:selectedProcess
    {generateProcessData}
    {recentInvoices}
    {accountContacts}
    {loadingAccount}
  />

  <!-- Floating Status -->
  <FloatingStatusButton />
</main>