# Demo Data Architecture

This document describes the client persistence and demo data loading patterns in the flows-admin-demo application.

## Overview

The demo application supports switching between multiple demo clients (companies) with persistent user selection across page reloads. This document captures the correct implementation patterns after fixing several competing systems and data format inconsistencies.

## Core Principles

### 1. Ultra-Simple localStorage Pattern
- **When you need currentClient** → query localStorage
- **If not set** → set default and return it  
- **ONLY time localStorage gets set** → when user actively selects a different client

### 2. Single Source of Truth
- All client persistence uses `flows-admin-demo-settings.selectedClient`
- Always stores `client_code` (e.g., "test-demo", "hygge-hvidlog") - NEVER database IDs
- No competing localStorage keys or restoration systems

### 3. Consistent Data Types
- **localStorage**: Always stores client codes ("test-demo")
- **Database queries**: Use client codes to find database IDs
- **Legacy compatibility**: Transform between formats as needed

## Implementation Components

### Core Persistence Layer

#### `/src/lib/utils/client-persistence.ts`
Ultra-simple client persistence that uses the existing settings system:

```typescript
/**
 * Get current client ID from localStorage
 * If not set, sets default and returns it
 */
export function getCurrentClientId(): string {
  const settings = LocalStorageManager.loadSettings();
  let clientId = settings?.selectedClient;
  
  if (!clientId) {
    clientId = DEFAULT_CLIENT_ID; // 'hygge-hvidlog'
    const updatedSettings = LocalStorageManager.mergeWithDefaults({
      selectedClient: clientId
    });
    LocalStorageManager.saveSettings(updatedSettings);
  }
  
  return clientId;
}

/**
 * Set current client ID in localStorage
 * ONLY called when user actively selects a different client
 */
export function setCurrentClientId(clientId: string): void {
  const currentSettings = LocalStorageManager.loadSettings() || LocalStorageManager.getDefaultSettings();
  const updatedSettings = {
    ...currentSettings,
    selectedClient: clientId,
    lastUpdated: new Date().toISOString()
  };
  LocalStorageManager.saveSettings(updatedSettings);
}
```

### Main Data Loading

#### `/src/lib/stores/data.ts - loadDemoData()`
The main data loading function that respects localStorage:

```typescript
export async function loadDemoData() {
  try {
    // Get current client from localStorage (single source of truth)
    const currentClientId = getCurrentClientId();
    console.log(`[loadDemoData] Loading data for current client: ${currentClientId}`);

    // Try to load the current client
    const { data: clientData, error: clientError } = await supabase
      .from('clients')
      .select('*')
      .eq('client_code', currentClientId) // Use client_code, not ID
      .single();

    if (!clientError && clientData) {
      console.log(`[loadDemoData] Found client: ${clientData.client_code}`);
      await loadClientData(clientData.id); // Use database ID for data loading
      return;
    }

    // If current client doesn't exist, try fallback priorities
    console.warn(`[loadDemoData] Current client ${currentClientId} not found, trying fallbacks`);
    // ... fallback logic
  }
}
```

### Settings Panel Integration

#### `/src/lib/components/settings/SettingsPanel.svelte`
Settings panel must use client codes consistently:

```typescript
// Handle client selection - MUST use client.code, not client.id
async function handleClientChange(clientCode: string) {
  const selectedClient = $clients.find((c) => c.code === clientCode);
  if (!selectedClient) {
    console.error('Client not found:', clientCode);
    return;
  }

  // Store client code in settings (not database ID)
  settingsStore.selectClient(clientCode);

  // Load data using database ID
  await loadClientData(selectedClient.id);
}

// Reactive loading - MUST convert client code to database ID
$: if (initialized && $settings?.selectedClient && $settings.selectedClient !== lastLoadedClientId) {
  lastLoadedClientId = $settings.selectedClient;
  
  // Find client by code to get database ID
  const clientToLoad = $clients.find(c => c.code === $settings.selectedClient);
  if (clientToLoad) {
    loadClientData(clientToLoad.id).catch((error) => {
      console.error('Failed to load selected client data:', error);
    });
  }
}

// Template - MUST compare with client.code
{@const isSelected = $settings?.selectedClient === client.code}
<button on:click={() => handleClientChange(client.code)}>
```

### Main Page Initialization

#### `/src/routes/+page.svelte`
Main page initialization should always call loadDemoData():

```typescript
onMount(async () => {
  // Initialize settings
  settingsStore.init();
  
  // Load legacy clients for backward compatibility
  await loadAllClients();
  
  // loadDemoData now uses localStorage as single source of truth - always call it
  console.log('[MainPage] Loading demo data (uses localStorage for client selection)');
  await loadDemoData();
  
  // ... rest of initialization
});
```

### Client Switching Components

#### FloatingStatusButton
For quick client switching with immediate effect:

```typescript
on:change={async (e) => {
  const clientId = e.target.value;
  console.log(`[FloatingStatusButton] User selected client: ${clientId}`);
  
  if (clientId) {
    try {
      isSwitchingClient = true;
      // Ultra-simple: just store in localStorage and refresh
      setCurrentClientId(clientId);
      console.log(`[FloatingStatusButton] Client stored in localStorage, refreshing page`);
      
      // Refresh the page - loadDemoData will use the stored client
      await goto('/', { replaceState: true, invalidateAll: true });
      isOpen = false;
    } catch (error) {
      console.error('[FloatingStatusButton] Failed to switch client:', error);
    } finally {
      isSwitchingClient = false;
    }
  }
}}
```

## Data Flow Diagrams

### Application Startup
```
1. Main page onMount()
2. → settingsStore.init()
3. → loadDemoData()
4. → getCurrentClientId()
5. → localStorage.getItem('flows-admin-demo-settings')
6. → settings.selectedClient (e.g., "test-demo")
7. → supabase.from('clients').eq('client_code', 'test-demo')
8. → loadClientData(database_id)
```

### User Changes Client in Settings
```
1. User clicks client in settings
2. → handleClientChange(client.code)
3. → settingsStore.selectClient(clientCode)
4. → LocalStorageManager.saveSettings({selectedClient: clientCode})
5. → Reactive block detects change
6. → Find client by code to get database ID
7. → loadClientData(database_id)
```

### User Changes Client in FloatingStatusButton
```
1. User selects client in dropdown
2. → setCurrentClientId(clientCode)
3. → LocalStorageManager.saveSettings({selectedClient: clientCode})
4. → goto('/', {invalidateAll: true})
5. → Page refreshes, main onMount() runs
6. → loadDemoData() uses stored client
```

## Common Pitfalls and Solutions

### ❌ Problem: Competing localStorage Systems
**Wrong:** Having both `selectedClientId` and `flows-admin-demo-settings.selectedClient`

**Right:** Use only `flows-admin-demo-settings.selectedClient` via LocalStorageManager

### ❌ Problem: Data Type Inconsistency  
**Wrong:** Sometimes storing client database IDs, sometimes client codes

**Right:** ALWAYS store client codes in localStorage, convert to database IDs for queries

### ❌ Problem: Multiple Restoration Systems
**Wrong:** Both clientStore auto-restore AND loadDemoData() reading localStorage

**Right:** Only loadDemoData() reads localStorage, other systems follow its lead

### ❌ Problem: Settings Panel Using Database IDs
**Wrong:** `handleClientChange(client.id)` and `isSelected = settings.selectedClient === client.id`

**Right:** `handleClientChange(client.code)` and `isSelected = settings.selectedClient === client.code`

## Testing Checklist

When implementing client persistence features:

- [ ] App loads stored client on startup (not always default)
- [ ] Settings page shows correct selected client on reload
- [ ] Changing client in settings immediately updates main app
- [ ] FloatingStatusButton shows correct current client
- [ ] Client changes persist across page reloads
- [ ] localStorage contains only client codes, never database IDs
- [ ] Console logs show correct client loading sequence
- [ ] No competing localStorage keys exist

## Available Demo Clients

Default priority order for fallbacks:

1. **hygge-hvidlog** - Primary internal demo (European food tech)
2. **meridian-brands** - Primary prospect demo (Global consumer products)  
3. **test-demo** - Testing client
4. **nets-demo** - Legacy fallback

## File Locations

- **Core persistence**: `/src/lib/utils/client-persistence.ts`
- **Main data loading**: `/src/lib/stores/data.ts` (loadDemoData function)
- **Settings integration**: `/src/lib/components/settings/SettingsPanel.svelte`
- **Settings storage**: `/src/lib/utils/localStorage.ts` (LocalStorageManager)
- **Quick switching**: `/src/lib/components/FloatingStatusButton.svelte`
- **Main initialization**: `/src/routes/+page.svelte`

## Debug Logging

Key console log patterns to look for:

```
[loadDemoData] Loading data for current client: test-demo
[loadDemoData] Found client: test-demo
[SettingsPanel] Client changed to: test-demo
[FloatingStatusButton] User selected client: test-demo
[ClientService] Client stored in localStorage: test-demo
```

## Future Implementation Guidelines

1. **Always use client codes** in localStorage, never database IDs
2. **Single restoration point** - only loadDemoData() reads localStorage  
3. **Consistent data flow** - getCurrentClientId() → client_code → database query
4. **Immediate feedback** - settings changes should trigger reactive data loading
5. **Simple switching** - FloatingStatusButton stores + refreshes, no complex orchestration