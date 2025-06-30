# Demo Data Troubleshooting Guide

This guide helps diagnose and fix common issues with client switching and data persistence in the flows-admin-demo application.

## Quick Diagnostic Commands

Open browser console and run these commands to diagnose issues:

```javascript
// Check current localStorage settings
JSON.parse(localStorage.getItem('flows-admin-demo-settings'))

// Check if client switching function is available
window.getCurrentClientId?.() 

// Manually test client switching
localStorage.setItem('flows-admin-demo-settings', JSON.stringify({
  selectedClient: 'test-demo',
  selectedBranding: 'test-demo',
  allowRealClients: false,
  availableBrandings: [],
  lastUpdated: new Date().toISOString()
}))

// Clear all settings to reset
localStorage.removeItem('flows-admin-demo-settings')
```

## Common Issues and Solutions

### Issue 1: App Always Loads Default Client (hygge-hvidlog)

**Symptoms:**
- Settings page shows "test-demo" as selected
- Main app always loads Hygge & Hvidløg data
- Page refresh ignores localStorage selection

**Root Cause:** loadDemoData() not reading from localStorage

**Debug Steps:**
1. Check console for: `[loadDemoData] Loading data for current client: test-demo`
2. If missing, loadDemoData() isn't using getCurrentClientId()
3. If shows "hygge-hvidlog" instead of "test-demo", localStorage not being read

**Solution:**
```typescript
// In loadDemoData(), ensure this pattern:
const currentClientId = getCurrentClientId(); // Must be first line
console.log(`[loadDemoData] Loading data for current client: ${currentClientId}`);
```

### Issue 2: Settings Changes Don't Update Main App

**Symptoms:**
- Can change client in settings
- Settings page shows new selection
- Main app data doesn't change
- No reactive loading occurs

**Root Cause:** Settings panel using wrong data types or missing reactive loading

**Debug Steps:**
1. Check console for: `[SettingsPanel] Client changed to: test-demo`
2. Verify reactive block triggers: `$: if (initialized && $settings?.selectedClient...`
3. Check if client lookup by code works: `$clients.find(c => c.code === $settings.selectedClient)`

**Solution:**
```typescript
// Settings panel must use client.code
async function handleClientChange(clientCode: string) {
  settingsStore.selectClient(clientCode); // Store client code
  
  const selectedClient = $clients.find((c) => c.code === clientCode);
  if (selectedClient) {
    await loadClientData(selectedClient.id); // Use database ID for loading
  }
}

// Reactive loading must convert code to ID
$: if ($settings?.selectedClient) {
  const clientToLoad = $clients.find(c => c.code === $settings.selectedClient);
  if (clientToLoad) {
    loadClientData(clientToLoad.id);
  }
}
```

### Issue 3: FloatingStatusButton Shows Wrong Client

**Symptoms:**
- Dropdown shows empty or wrong selection
- Client codes display as {} or undefined
- Switching doesn't work

**Root Cause:** Dropdown value using wrong data type or clientStore not synced

**Debug Steps:**
1. Check dropdown value: `value={$clientStore.currentClient?.client_id || ''}`
2. Should be: `value={$clientStore.currentClient?.client_code || ''}`
3. Check options: `<option value={c.client_code}>`

**Solution:**
```svelte
<!-- Use client_code consistently -->
<select value={getCurrentClientId()}>
  {#each $clientStore.clients as c}
    <option value={c.client_code}>
      {c.legal_name} ({c.client_code})
    </option>
  {/each}
</select>
```

### Issue 4: Multiple localStorage Keys Conflict

**Symptoms:**
- `selectedClientId` and `flows-admin-demo-settings` both exist
- Inconsistent behavior between components
- Settings reset unexpectedly

**Root Cause:** Competing localStorage systems from previous implementations

**Debug Steps:**
1. Check for multiple keys: `Object.keys(localStorage).filter(k => k.includes('client'))`
2. Look for old patterns: `localStorage.getItem('selectedClientId')`

**Solution:**
```typescript
// Remove old keys
localStorage.removeItem('selectedClientId');

// Use only the unified settings system
import { getCurrentClientId, setCurrentClientId } from '$lib/utils/client-persistence';
```

### Issue 5: Data Loads But Wrong Client Shown in UI

**Symptoms:**
- Console shows correct client loading
- Data appears to be for right client
- UI still shows old client name/branding

**Root Cause:** Legacy client store not syncing with localStorage selection

**Debug Steps:**
1. Check store bridge initialization
2. Verify client transformation in store bridge
3. Check if legacy `client` store is being updated

**Solution:**
Ensure store bridge is working or remove dependency on legacy stores:
```typescript
// In main page, ensure legacy store gets updated
await loadDemoData(); // This should update legacy client store
```

## Debugging Console Patterns

### Healthy Client Switch Sequence
```
[FloatingStatusButton] User selected client: test-demo
[ClientService] Client stored in localStorage: test-demo
[MainPage] onMount starting...
[MainPage] Loading demo data (uses localStorage for client selection)
[loadDemoData] Loading data for current client: test-demo
[loadDemoData] Found client: test-demo
```

### Problematic Patterns
```
// Wrong: Always loading default
[loadDemoData] Loading data for current client: hygge-hvidlog

// Wrong: Not reading localStorage
[loadDemoData] No stored selection, trying priority clients

// Wrong: Data type mismatch
[SettingsPanel] Client changed to: 123 (database ID instead of code)

// Wrong: Multiple restoration
[loadDemoData] Found stored client selection: test-demo
[ClientStore] Attempting to restore stored client: hygge-hvidlog
```

## Performance Issues

### Issue: Slow Client Switching

**Symptoms:**
- Long delay after selecting client
- Multiple network requests
- UI freezes during switch

**Root Cause:** Complex orchestration instead of simple refresh

**Solution:**
Use the ultra-simple pattern:
```typescript
// Just store and refresh - let normal loading handle the rest
setCurrentClientId(clientId);
await goto('/', { replaceState: true, invalidateAll: true });
```

### Issue: Excessive Data Loading

**Symptoms:**
- Same client data loaded multiple times
- Console shows repeated loading messages
- Network tab shows duplicate requests

**Root Cause:** Multiple systems triggering data loads

**Solution:**
- Use `lastLoadedClientId` tracking in reactive blocks
- Ensure only one system manages data loading per client switch

## Data Consistency Checks

### Verify localStorage Format
```javascript
// Should look like this:
{
  "selectedClient": "test-demo",        // client_code, not ID
  "selectedBranding": "test-demo",
  "allowRealClients": false,
  "availableBrandings": [...],
  "lastUpdated": "2024-01-15T10:30:00.000Z"
}
```

### Verify Client Data Format
```javascript
// Database client should have both:
{
  "id": "uuid-database-id",
  "client_code": "test-demo",           // Used for localStorage
  "legal_name": "Test Demo Company",
  // ... other fields
}
```

## Testing Procedures

### Manual Test Sequence
1. **Reset state**: Clear localStorage and refresh
2. **Check default**: Should load hygge-hvidlog initially
3. **Settings change**: Select test-demo in settings, verify main app updates
4. **Persistence**: Refresh page, should still show test-demo
5. **Dropdown change**: Use FloatingStatusButton to switch to meridian-brands
6. **Cross-navigation**: Navigate to different pages, client should persist

### Automated Test Ideas
```typescript
// Test localStorage persistence
expect(getCurrentClientId()).toBe('hygge-hvidlog'); // default
setCurrentClientId('test-demo');
expect(getCurrentClientId()).toBe('test-demo');

// Test settings sync
settingsStore.selectClient('meridian-brands');
expect(getCurrentClientId()).toBe('meridian-brands');
```

## Recovery Procedures

### Complete Reset
```javascript
// Clear all localStorage
localStorage.clear();

// Refresh page
window.location.reload();

// Should default to hygge-hvidlog
```

### Force Specific Client
```javascript
// Set specific client and refresh
localStorage.setItem('flows-admin-demo-settings', JSON.stringify({
  selectedClient: 'test-demo',
  selectedBranding: 'test-demo', 
  allowRealClients: false,
  availableBrandings: [],
  lastUpdated: new Date().toISOString()
}));
window.location.reload();
```

## Prevention Checklist

When implementing new client-related features:

- [ ] Only use client codes in localStorage, never database IDs
- [ ] Use getCurrentClientId()/setCurrentClientId() for all localStorage access
- [ ] Test both settings panel and FloatingStatusButton switching
- [ ] Verify persistence across page reloads
- [ ] Check console logs for correct sequence
- [ ] Test with multiple clients (hygge-hvidlog, test-demo, meridian-brands)
- [ ] Ensure no competing localStorage keys are created
- [ ] Verify UI shows correct client immediately after switch