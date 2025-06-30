# Shell Architecture Pattern

## Philosophy: Coordinator vs Implementor

Instead of breaking the main component into many small pieces, embrace it as an **Application Shell** that:
- Coordinates between domains
- Manages navigation state
- Handles demo/production switches
- Orchestrates data loading

## Recommended Structure

```typescript
// +page.svelte (remains large but focused)
<script>
  // ONLY coordination logic
  import { demoContext } from '$lib/stores/demo/demo-context.store';
  import { clientStore } from '$lib/stores/domains/client/client.store';
  
  // Navigation coordination
  let activeTab = 'people';
  
  // Demo/production coordination
  $: if ($demoContext.isDemoMode && !$demoContext.demoDataGenerated) {
    // Coordinate demo data generation across domains
    coordinateDemoSetup();
  }
  
  // Domain coordination (not domain logic)
  $: if ($clientStore.currentClient) {
    // Tell all domains about client change
    coordinateClientSwitch($clientStore.currentClient.client_id);
  }
</script>

<!-- Each tab is a domain coordinator -->
{#if activeTab === 'people'}
  <PeopleDomainCoordinator {clientId} />
{:else if activeTab === 'processes'}
  <ProcessesDomainCoordinator {clientId} />
{/if}
```

## Benefits of Shell Pattern

1. **Clear Responsibility:** Shell coordinates, domains implement
2. **Demo/Production Bridge:** Shell handles environment differences
3. **State Synchronization:** One place for cross-domain coordination
4. **Navigation Logic:** Centralized tab/routing management

## What NOT to extract from shell:
- Cross-domain coordination logic
- Demo/production switching
- Navigation state management
- Error boundary handling

## What TO extract to domain coordinators:
- Domain-specific business logic
- Data transformation
- Domain UI composition
- Domain error handling