#!/usr/bin/env node

import { createClient } from '@supabase/supabase-js';
import chalk from 'chalk';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL || 'https://jstbkvkurjsopuwhlsvy.supabase.co';
const supabaseServiceKey =
  process.env.SUPABASE_SERVICE_ROLE_KEY ||
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpzdGJrdmt1cmpzb3B1d2hsc3Z5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MDk2NjU2OCwiZXhwIjoyMDY2NTQyNTY4fQ.vSSYVzitJDrQQYer1cW-SU_ZSEUtVyIOKsogHjy3h58';

// Test with different schema configurations
const configs = [
  { name: 'Default', config: {} },
  { name: 'API Schema', config: { db: { schema: 'api' } } },
  { name: 'Public Schema', config: { db: { schema: 'public' } } },
];

async function testConfig(name, config) {
  console.log(chalk.blue(`\n--- Testing ${name} Configuration ---`));

  const supabase = createClient(supabaseUrl, supabaseServiceKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
    ...config,
  });

  // Test different table access patterns
  const tests = [
    { name: 'people (no schema)', table: 'people' },
    { name: 'api.people (with schema)', table: 'api.people' },
    { name: 'employees (old table)', table: 'employees' },
    { name: 'clients', table: 'clients' },
  ];

  for (const test of tests) {
    try {
      const { data, error } = await supabase.from(test.table).select('id').limit(1);

      if (error) {
        console.log(chalk.red(`  ❌ ${test.name}: ${error.message}`));
      } else {
        console.log(chalk.green(`  ✅ ${test.name}: Success (${data?.length || 0} rows)`));
      }
    } catch (err) {
      console.log(chalk.red(`  ❌ ${test.name}: ${err.message}`));
    }
  }
}

async function main() {
  console.log(chalk.blue.bold('🔍 Testing Database Table Access\n'));

  for (const { name, config } of configs) {
    await testConfig(name, config);
  }

  console.log(chalk.blue('\n--- Summary ---'));
  console.log('This test helps identify the correct schema and table configuration.');
}

main();
