/**
 * Regression test for client loading logic
 * 
 * Tests the critical bug where loadClientSpecificData() was hardcoded to 'nets-demo'
 * and overrode the correct client selection from loadDemoData().
 * 
 * This test ensures that:
 * 1. Priority clients (hygge-hvidlog, meridian-brands) load correctly
 * 2. No hardcoded client codes override the selection
 * 3. The client store contains the expected client data
 */

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { get } from 'svelte/store';

// Mock Supabase client
const mockSupabaseClient = {
  from: vi.fn(() => ({
    select: vi.fn(() => ({
      eq: vi.fn(() => ({
        single: vi.fn()
      })),
      limit: vi.fn(() => ({
        eq: vi.fn(() => ({}))
      })),
      in: vi.fn(() => ({}))
    }))
  }))
};

// Mock the supabase module
vi.mock('$lib/supabase', () => ({
  supabase: mockSupabaseClient
}));

// Mock error reporting
vi.mock('$lib/utils/errorReporter', () => ({
  reportSupabaseError: vi.fn()
}));

// Import the data store after mocking
const { loadDemoData, client } = await import('$lib/stores/data');

describe('Client Loading Regression Tests', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    // Reset client store
    client.set(null);
  });

  it('should load hygge-hvidlog as priority client without hardcoded override', async () => {
    // Mock the client data responses
    const hyggeClient = {
      id: 'hygge-client-id',
      client_code: 'hygge-hvidlog',
      legal_name: 'Hygge & Hvidløg A/S',
      domain: 'hygge-hvidlog.dk'
    };

    const mockChainMethods = {
      single: vi.fn()
    };

    const mockSelectChain = {
      eq: vi.fn(() => mockChainMethods),
      limit: vi.fn(() => ({ eq: vi.fn(() => ({})) })),
      in: vi.fn(() => ({}))
    };

    const mockFromChain = {
      select: vi.fn(() => mockSelectChain)
    };

    mockSupabaseClient.from.mockReturnValue(mockFromChain);

    // Setup responses for the chain of calls
    mockChainMethods.single
      .mockResolvedValueOnce({ data: [hyggeClient], error: null }) // loadDemoData clients query
      .mockResolvedValueOnce({ data: hyggeClient, error: null })    // loadClientData specific client
      .mockResolvedValueOnce({ data: hyggeClient, error: null });   // loadClientSpecificData (the bug fix)

    // Mock empty responses for other data
    mockSelectChain.eq.mockReturnValue({ data: [], error: null });
    mockSelectChain.limit.mockReturnValue({ eq: vi.fn(() => ({ data: [], error: null })) });
    mockSelectChain.in.mockReturnValue({ data: [], error: null });

    // Execute the function
    await loadDemoData();

    // Verify that loadClientSpecificData was called with the correct client ID (not hardcoded)
    const fromCalls = mockSupabaseClient.from.mock.calls;
    const selectCalls = mockFromChain.select.mock.calls;
    const eqCalls = mockSelectChain.eq.mock.calls;

    // Find the call to load client data in loadClientSpecificData
    const clientLoadCall = eqCalls.find(call => 
      call[0] === 'id' && call[1] === 'hygge-client-id'
    );

    expect(clientLoadCall).toBeDefined();
    expect(clientLoadCall[0]).toBe('id');
    expect(clientLoadCall[1]).toBe('hygge-client-id');

    // Verify no hardcoded 'nets-demo' calls
    const hardcodedCall = eqCalls.find(call => 
      call[0] === 'client_code' && call[1] === 'nets-demo'
    );

    expect(hardcodedCall).toBeUndefined();

    // Verify the client store has the correct client
    const currentClient = get(client);
    expect(currentClient?.client_code).toBe('hygge-hvidlog');
    expect(currentClient?.legal_name).toBe('Hygge & Hvidløg A/S');
  });

  it('should load meridian-brands as second priority without fallback to nets-demo', async () => {
    // Mock no hygge-hvidlog client, but meridian-brands exists
    const meridianClient = {
      id: 'meridian-client-id',
      client_code: 'meridian-brands',
      legal_name: 'Meridian Brands International',
      domain: 'meridianbrands.com'
    };

    const mockChainMethods = {
      single: vi.fn()
    };

    const mockSelectChain = {
      eq: vi.fn(() => mockChainMethods),
      limit: vi.fn(() => ({ eq: vi.fn(() => ({})) })),
      in: vi.fn(() => ({}))
    };

    const mockFromChain = {
      select: vi.fn(() => mockSelectChain)
    };

    mockSupabaseClient.from.mockReturnValue(mockFromChain);

    // Setup responses: hygge-hvidlog not found, meridian-brands found
    mockChainMethods.single
      .mockResolvedValueOnce({ data: [meridianClient], error: null }) // loadDemoData clients query
      .mockResolvedValueOnce({ data: null, error: { message: 'Not found' } })     // hygge-hvidlog not found
      .mockResolvedValueOnce({ data: meridianClient, error: null })   // meridian-brands found
      .mockResolvedValueOnce({ data: meridianClient, error: null });  // loadClientSpecificData

    // Mock empty responses for other data
    mockSelectChain.eq.mockReturnValue({ data: [], error: null });
    mockSelectChain.limit.mockReturnValue({ eq: vi.fn(() => ({ data: [], error: null })) });
    mockSelectChain.in.mockReturnValue({ data: [], error: null });

    await loadDemoData();

    // Verify the client store has meridian-brands, not nets-demo
    const currentClient = get(client);
    expect(currentClient?.client_code).toBe('meridian-brands');
    expect(currentClient?.legal_name).toBe('Meridian Brands International');

    // Verify no hardcoded 'nets-demo' calls
    const eqCalls = mockSelectChain.eq.mock.calls;
    const hardcodedCall = eqCalls.find(call => 
      call[0] === 'client_code' && call[1] === 'nets-demo'
    );

    expect(hardcodedCall).toBeUndefined();
  });

  it('should use client ID parameter, not hardcoded client_code in loadClientSpecificData', async () => {
    // This test specifically targets the regression bug
    const testClient = {
      id: 'test-client-id-123',
      client_code: 'test-client',
      legal_name: 'Test Client Corp'
    };

    const mockChainMethods = {
      single: vi.fn().mockResolvedValue({ data: testClient, error: null })
    };

    const mockSelectChain = {
      eq: vi.fn(() => mockChainMethods),
      limit: vi.fn(() => ({ eq: vi.fn(() => ({ data: [], error: null })) })),
      in: vi.fn(() => ({ data: [], error: null }))
    };

    const mockFromChain = {
      select: vi.fn(() => mockSelectChain)
    };

    mockSupabaseClient.from.mockReturnValue(mockFromChain);

    // Import the loadClientSpecificData function directly (if exported for testing)
    // Or call loadDemoData with specific setup
    const { loadClientData } = await import('$lib/stores/data');
    
    // Call loadClientData with a specific client ID
    await loadClientData('test-client-id-123');

    // Verify that the query used 'id' field with the parameter, not 'client_code' with hardcoded value
    const eqCalls = mockSelectChain.eq.mock.calls;
    
    const correctCall = eqCalls.find(call => 
      call[0] === 'id' && call[1] === 'test-client-id-123'
    );
    
    expect(correctCall).toBeDefined();
    expect(correctCall[0]).toBe('id');
    expect(correctCall[1]).toBe('test-client-id-123');

    // Verify NO calls with hardcoded 'nets-demo'
    const badCall = eqCalls.find(call => 
      call[0] === 'client_code' && call[1] === 'nets-demo'
    );
    
    expect(badCall).toBeUndefined();
  });

  it('should respect localStorage client preferences', async () => {
    // Mock localStorage with hygge-hvidlog preference
    const mockLocalStorage = {
      getItem: vi.fn((key) => {
        if (key === 'flows-admin-demo-client-code') return 'hygge-hvidlog';
        return null;
      }),
      setItem: vi.fn()
    };

    global.localStorage = mockLocalStorage;

    const hyggeClient = {
      id: 'hygge-client-id',
      client_code: 'hygge-hvidlog',
      legal_name: 'Hygge & Hvidløg A/S'
    };

    const mockChainMethods = {
      single: vi.fn().mockResolvedValue({ data: hyggeClient, error: null })
    };

    const mockSelectChain = {
      eq: vi.fn(() => mockChainMethods),
      limit: vi.fn(() => ({ eq: vi.fn(() => ({ data: [], error: null })) })),
      in: vi.fn(() => ({ data: [], error: null }))
    };

    const mockFromChain = {
      select: vi.fn(() => mockSelectChain)
    };

    mockSupabaseClient.from.mockReturnValue(mockFromChain);

    await loadDemoData();

    // Verify localStorage was checked
    expect(mockLocalStorage.getItem).toHaveBeenCalledWith('flows-admin-demo-client-code');

    // Verify the correct client was loaded
    const currentClient = get(client);
    expect(currentClient?.client_code).toBe('hygge-hvidlog');
  });
});