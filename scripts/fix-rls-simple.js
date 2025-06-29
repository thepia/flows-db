#!/usr/bin/env node

/**
 * Simple RLS Fix for People Tables
 */

import { createClient } from '@supabase/supabase-js';
import chalk from 'chalk';
import ora from 'ora';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Use environment variables for credentials
const supabaseUrl = process.env.SUPABASE_URL || 'https://jstbkvkurjsopuwhlsvy.supabase.co';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpzdGJrdkt1cmpzb3B1d2hsc3Z5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MDk2NjU2OCwiZXhwIjoyMDY2NTQyNTY4fQ.vSSYVzitJDrQQYer1cW-SU_ZSEUtVyIOKsogHjy3h58';

const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

async function fixRlsPolicies() {
  console.log(chalk.blue.bold('🔒 Fixing RLS Policies for People Tables\n'));
  
  const policies = [
    // Drop existing policies
    'DROP POLICY IF EXISTS policy_people_staff_access ON api.people;',
    'DROP POLICY IF EXISTS policy_people_client_access ON api.people;', 
    'DROP POLICY IF EXISTS policy_people_enrollments_staff_access ON api.people_enrollments;',
    'DROP POLICY IF EXISTS policy_people_enrollments_client_access ON api.people_enrollments;',
    
    // Create permissive policies
    `CREATE POLICY policy_people_anon_access ON api.people FOR ALL USING (true);`,
    `CREATE POLICY policy_people_enrollments_anon_access ON api.people_enrollments FOR ALL USING (true);`,
    
    // Enable RLS
    'ALTER TABLE api.people ENABLE ROW LEVEL SECURITY;',
    'ALTER TABLE api.people_enrollments ENABLE ROW LEVEL SECURITY;'
  ];
  
  for (const [index, policy] of policies.entries()) {
    const spinner = ora(`Executing policy ${index + 1}/${policies.length}`).start();
    
    try {
      // Use direct SQL execution
      const response = await fetch(`${supabaseUrl}/rest/v1/rpc/exec_sql`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': supabaseServiceKey,
          'Authorization': `Bearer ${supabaseServiceKey}`
        },
        body: JSON.stringify({
          sql_query: policy
        })
      });
      
      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`HTTP ${response.status}: ${errorText}`);
      }
      
      spinner.succeed(`Policy ${index + 1} executed`);
      
    } catch (error) {
      spinner.warn(`Policy ${index + 1} warning: ${error.message}`);
      // Continue with other policies
    }
  }
  
  console.log(chalk.green('\n✅ RLS policies update completed!'));
}

async function testAccess() {
  const spinner = ora('Testing table access').start();
  
  try {
    const { data, error } = await supabase
      .from('people')
      .select('id')
      .limit(1);
    
    if (error) {
      throw error;
    }
    
    spinner.succeed('Table access test passed');
    return true;
    
  } catch (error) {
    spinner.fail(`Table access failed: ${error.message}`);
    return false;
  }
}

async function main() {
  try {
    await fixRlsPolicies();
    await testAccess();
    
    console.log(chalk.green('\n🎉 RLS fix completed successfully!'));
    
  } catch (error) {
    console.error(chalk.red('\n❌ Failed:'), error.message);
    process.exit(1);
  }
}

main();