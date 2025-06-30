/**
 * Ultra-simple localStorage-based client persistence
 * Single source of truth for current client selection
 * Uses the existing settings system for consistency
 */

import { LocalStorageManager } from './localStorage';

const DEFAULT_CLIENT_ID = 'hygge-hvidlog';

/**
 * Get current client ID from localStorage
 * If not set, sets default and returns it
 */
export function getCurrentClientId(): string {
  if (typeof window === 'undefined') {
    return DEFAULT_CLIENT_ID;
  }
  
  const settings = LocalStorageManager.loadSettings();
  let clientId = settings?.selectedClient;
  
  if (!clientId) {
    clientId = DEFAULT_CLIENT_ID;
    // Update settings with default client
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
  if (typeof window === 'undefined') return;
  
  const currentSettings = LocalStorageManager.loadSettings() || LocalStorageManager.getDefaultSettings();
  const updatedSettings = {
    ...currentSettings,
    selectedClient: clientId,
    lastUpdated: new Date().toISOString()
  };
  LocalStorageManager.saveSettings(updatedSettings);
}

/**
 * Clear stored client selection
 */
export function clearCurrentClientId(): void {
  if (typeof window === 'undefined') return;
  LocalStorageManager.clearSettings();
}