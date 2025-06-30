/**
 * Test utilities for client switching tests
 */

import { vi } from 'vitest';

/**
 * Setup test environment with common mocks
 */
export function setupTestEnvironment() {
  // Mock window and location
  Object.defineProperty(window, 'location', {
    value: {
      hostname: 'localhost',
      search: '',
      href: 'http://localhost:5174'
    },
    writable: true
  });

  // Mock crypto for JWT generation
  Object.defineProperty(window, 'crypto', {
    value: {
      subtle: {
        digest: vi.fn().mockResolvedValue(new ArrayBuffer(32))
      }
    },
    writable: true
  });

  // Mock TextEncoder
  global.TextEncoder = vi.fn().mockImplementation(() => ({
    encode: vi.fn().mockReturnValue(new Uint8Array([1, 2, 3, 4]))
  }));

  // Mock console methods to reduce noise in tests
  vi.spyOn(console, 'log').mockImplementation(() => {});
  vi.spyOn(console, 'warn').mockImplementation(() => {});
  vi.spyOn(console, 'info').mockImplementation(() => {});
}

/**
 * Cleanup test environment
 */
export function cleanupTestEnvironment() {
  vi.restoreAllMocks();
  vi.clearAllMocks();
}

/**
 * Create mock client data for testing
 */
export function createMockClient(overrides: Partial<any> = {}) {
  return {
    client_id: 'mock-client-123',
    client_code: 'mock-client',
    legal_name: 'Mock Client Corp',
    industry: 'Technology',
    domain: 'mock-client.com',
    tier: 'pro',
    status: 'active',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    ...overrides
  };
}

/**
 * Create multiple mock clients for testing
 */
export function createMockClients() {
  return [
    createMockClient({
      client_id: 'hygge-hvidlog',
      client_code: 'hygge-hvidlog',
      legal_name: 'Hygge & Hvidløg ApS',
      industry: 'Food & Beverage'
    }),
    createMockClient({
      client_id: 'meridian-brands',
      client_code: 'meridian-brands',
      legal_name: 'Meridian Brands International',
      industry: 'Consumer Goods'
    }),
    createMockClient({
      client_id: 'nets-demo',
      client_code: 'nets-demo',
      legal_name: 'Nets Demo Corporation',
      industry: 'Financial Services'
    })
  ];
}

/**
 * Wait for async operations to complete
 */
export function waitForAsync(ms: number = 0) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Mock Supabase responses
 */
export function mockSupabaseResponse(data: any, error: any = null) {
  return {
    data,
    error,
    status: error ? 400 : 200,
    statusText: error ? 'Bad Request' : 'OK'
  };
}

/**
 * Mock localStorage for consistent testing
 */
export function createMockLocalStorage() {
  let store: Record<string, string> = {};
  
  return {
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
    key: vi.fn((index: number) => Object.keys(store)[index] || null),
    get length() {
      return Object.keys(store).length;
    }
  };
}