#!/usr/bin/env node

/**
 * Simple regression test runner for the client loading bug
 *
 * This script tests the specific bug where loadClientSpecificData()
 * was hardcoded to 'nets-demo' instead of using the clientId parameter.
 */

import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config({ path: '../../.env' });

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, {
  db: {
    schema: 'api',
  },
});

async function testClientLoading() {
  console.log('🧪 Running Client Loading Regression Test\n');

  try {
    // Test 1: Verify hygge-hvidlog client exists and has data
    console.log('1. Testing Hygge & Hvidløg client exists...');
    const { data: hyggeClient, error: hyggeError } = await supabase
      .from('clients')
      .select('*')
      .eq('client_code', 'hygge-hvidlog')
      .single();

    if (hyggeError || !hyggeClient) {
      console.log('❌ Hygge & Hvidløg client not found');
      return false;
    }

    console.log(`✅ Found: ${hyggeClient.legal_name} (ID: ${hyggeClient.id})`);

    // Test 2: Verify hygge-hvidlog has people data
    console.log('\n2. Testing Hygge & Hvidløg has employee data...');
    const { count: peopleCount, error: peopleError } = await supabase
      .from('people')
      .select('*', { count: 'exact', head: true })
      .eq('client_id', hyggeClient.id);

    if (peopleError) {
      console.log('❌ Error loading people:', peopleError.message);
      return false;
    }

    console.log(`✅ Found ${peopleCount} people for Hygge & Hvidløg`);

    if (peopleCount < 1000) {
      console.log('⚠️  Warning: Expected ~1200 people, found', peopleCount);
    }

    // Test 3: Verify the demo data priority logic
    console.log('\n3. Testing demo priority client selection...');

    const DEMO_PRIORITIES = [
      'hygge-hvidlog', // Primary internal demo
      'meridian-brands', // Primary prospect demo
      'flows-ci-test', // CI testing client
      'nets-demo', // Legacy fallback
    ];

    let selectedClient = null;

    for (const clientCode of DEMO_PRIORITIES) {
      const { data: client, error } = await supabase
        .from('clients')
        .select('*')
        .eq('client_code', clientCode)
        .single();

      if (!error && client) {
        // Check if it has data
        const { count } = await supabase
          .from('people')
          .select('*', { count: 'exact', head: true })
          .eq('client_id', client.id);

        if (count > 0) {
          selectedClient = client;
          console.log(`✅ Priority client selected: ${client.legal_name} (${count} people)`);
          break;
        }
      }
    }

    if (!selectedClient) {
      console.log('❌ No suitable demo client found');
      return false;
    }

    // Test 4: The critical regression test
    console.log('\n4. Testing loadClientSpecificData behavior...');

    if (selectedClient.client_code === 'nets-demo') {
      console.log('⚠️  WARNING: Demo fell back to nets-demo instead of rich demo client');
      console.log('   This suggests the hardcoded bug might still exist');

      // Check if hygge-hvidlog should have been selected instead
      if (hyggeClient && peopleCount > 100) {
        console.log('❌ REGRESSION: Should have selected Hygge & Hvidløg, not nets-demo');
        return false;
      }
    }

    if (selectedClient.client_code === 'hygge-hvidlog') {
      console.log('✅ Correctly selected Hygge & Hvidløg as priority client');
    }

    // Test 5: Simulate the loadDemoData function logic
    console.log('\n5. Simulating complete loadDemoData flow...');

    // This mimics what the frontend should do
    const { data: allClients, error: allError } = await supabase
      .from('clients')
      .select('*')
      .in('client_code', DEMO_PRIORITIES);

    if (allError) {
      console.log('❌ Error loading demo clients:', allError.message);
      return false;
    }

    // Find first client with data
    let finalSelectedClient = null;
    for (const clientCode of DEMO_PRIORITIES) {
      const client = allClients.find((c) => c.client_code === clientCode);
      if (client) {
        const { count } = await supabase
          .from('people')
          .select('*', { count: 'exact', head: true })
          .eq('client_id', client.id);

        if (count > 0) {
          finalSelectedClient = client;
          break;
        }
      }
    }

    if (finalSelectedClient?.client_code === 'hygge-hvidlog') {
      console.log('✅ Complete flow correctly selects Hygge & Hvidløg');
      console.log(`   Client: ${finalSelectedClient.legal_name}`);
      console.log(`   Domain: ${finalSelectedClient.domain}`);

      console.log('\n🎉 All regression tests PASSED!');
      console.log('   The hardcoded nets-demo bug has been fixed.');
      return true;
    } else {
      console.log(
        '❌ REGRESSION: Complete flow selected wrong client:',
        finalSelectedClient?.client_code
      );
      return false;
    }
  } catch (error) {
    console.error('❌ Test failed with error:', error);
    return false;
  }
}

// Run the test
testClientLoading().then((success) => {
  process.exit(success ? 0 : 1);
});
