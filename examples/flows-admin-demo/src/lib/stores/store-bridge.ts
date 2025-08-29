/**
 * Store Bridge: Synchronizes legacy data.ts store with new domain stores
 * This is a temporary bridge during the migration from legacy to domain stores
 */

import { get } from 'svelte/store';
import { client, loadClientData } from './data';
import { clientStore } from './domains/client/client.store';

let isInitialized = false;
let currentSubscription: (() => void) | null = null;

/**
 * Initialize the bridge between legacy and new stores
 */
export function initializeStoreBridge() {
  if (isInitialized) {
    console.log('[StoreBridge] Bridge already initialized');
    return;
  }

  console.log('[StoreBridge] Initializing bridge between legacy and domain stores');

  // Subscribe to changes in the new clientStore
  currentSubscription = clientStore.currentClient.subscribe(async (newClient) => {
    console.log('[StoreBridge] clientStore.currentClient changed:', newClient);
    const legacyClient = get(client);
    console.log('[StoreBridge] Legacy client:', legacyClient);

    // Only update if there's actually a change and it's different from legacy
    if (newClient && (!legacyClient || legacyClient.client_id !== newClient.client_id)) {
      console.log(
        `[StoreBridge] New client selected: ${newClient.client_code}, updating legacy store`
      );

      try {
        // Transform new domain client to legacy format
        const legacyClientData = {
          id: newClient.client_id,
          client_id: newClient.client_id,
          code: newClient.client_code,
          client_code: newClient.client_code,
          name: newClient.legal_name,
          legal_name: newClient.legal_name,
          industry: newClient.industry,
          domain: newClient.domain,
          tier: newClient.tier,
          status: newClient.status,
          created_at: newClient.created_at,
          updated_at: newClient.updated_at,
        };

        // Update legacy client store
        client.set(legacyClientData);

        // Trigger legacy data loading for the new client
        await loadClientData(newClient.client_id);

        console.log(
          `[StoreBridge] ✅ Legacy store updated and data loaded for ${newClient.client_code}`
        );
      } catch (error) {
        console.error(`[StoreBridge] ❌ Failed to sync client data:`, error);
      }
    }
  });

  isInitialized = true;
}

/**
 * Clean up the bridge (for testing or cleanup)
 */
export function destroyStoreBridge() {
  if (currentSubscription) {
    currentSubscription();
    currentSubscription = null;
  }
  isInitialized = false;
  console.log('[StoreBridge] Bridge destroyed');
}

/**
 * Check if bridge is active
 */
export function isBridgeActive(): boolean {
  return isInitialized && currentSubscription !== null;
}
