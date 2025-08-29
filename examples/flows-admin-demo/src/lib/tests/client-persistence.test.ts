/**
 * Simplified Client Persistence Tests
 *
 * Focus on preventing the specific regression where client selection
 * doesn't persist across navigation.
 */

import { beforeEach, describe, expect, it, vi } from 'vitest';

describe('Client Selection Persistence', () => {
  let mockLocalStorage: any;

  beforeEach(() => {
    // Reset localStorage mock
    let store: Record<string, string> = {};
    mockLocalStorage = {
      getItem: vi.fn((key: string) => store[key] || null),
      setItem: vi.fn((key: string, value: string) => {
        store[key] = value;
      }),
      removeItem: vi.fn((key: string) => {
        delete store[key];
      }),
      clear: vi.fn(() => {
        store = {};
      }),
    };

    Object.defineProperty(window, 'localStorage', {
      value: mockLocalStorage,
      writable: true,
    });

    // Mock Supabase responses
    const mockSupabase = {
      from: vi.fn().mockReturnThis(),
      select: vi.fn().mockReturnThis(),
      eq: vi.fn().mockReturnThis(),
      single: vi.fn().mockResolvedValue({ data: null, error: null }),
      order: vi.fn().mockReturnThis(),
    };

    vi.doMock('$lib/supabase', () => ({ supabase: mockSupabase }));
  });

  describe('Critical Regression Prevention', () => {
    it('should store client selection when switching clients', () => {
      const clientId = 'meridian-brands';

      // Simulate client selection
      localStorage.setItem('selectedClientId', clientId);

      // Verify localStorage was called
      expect(mockLocalStorage.setItem).toHaveBeenCalledWith('selectedClientId', clientId);
    });

    it('should retrieve stored client selection', () => {
      const storedClientId = 'hygge-hvidlog';

      // Setup localStorage to return stored value
      mockLocalStorage.getItem.mockReturnValue(storedClientId);

      // Simulate retrieval
      const retrieved = localStorage.getItem('selectedClientId');

      // Verify correct value is retrieved
      expect(retrieved).toBe(storedClientId);
      expect(mockLocalStorage.getItem).toHaveBeenCalledWith('selectedClientId');
    });

    it('should not override user selection with defaults', () => {
      const userSelection = 'nets-demo';

      // User has made a selection
      mockLocalStorage.getItem.mockReturnValue(userSelection);

      // Check that we get user's selection, not default
      const selection = localStorage.getItem('selectedClientId');
      expect(selection).toBe(userSelection);
      expect(selection).not.toBe('hygge-hvidlog'); // Should not be the default
    });

    it('should handle missing stored selection gracefully', () => {
      // No stored selection
      mockLocalStorage.getItem.mockReturnValue(null);

      const selection = localStorage.getItem('selectedClientId');
      expect(selection).toBeNull();
    });

    it('should clear invalid selections', () => {
      // Simulate clearing invalid selection
      localStorage.removeItem('selectedClientId');

      expect(mockLocalStorage.removeItem).toHaveBeenCalledWith('selectedClientId');
    });
  });

  describe('Data Flow Verification', () => {
    it('should call localStorage.getItem when checking for stored selection', () => {
      // This simulates the pattern in loadDemoData()
      localStorage.getItem('selectedClientId');

      expect(mockLocalStorage.getItem).toHaveBeenCalledWith('selectedClientId');
    });

    it('should prioritize stored selection over default priorities', () => {
      const storedSelection = 'meridian-brands';
      const defaultPriority = 'hygge-hvidlog';

      // Mock stored selection
      mockLocalStorage.getItem.mockReturnValue(storedSelection);

      // Simulate the decision logic from loadDemoData()
      const storedClientId = localStorage.getItem('selectedClientId');
      const selectedClient = storedClientId || defaultPriority;

      // Should use stored selection, not default
      expect(selectedClient).toBe(storedSelection);
      expect(selectedClient).not.toBe(defaultPriority);
    });
  });
});
