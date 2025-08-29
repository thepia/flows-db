#!/usr/bin/env node

/**
 * Test Offboarding Process Insert
 *
 * This script tests if the audit log trigger fix allows offboarding processes to be created
 */

import { createClient } from '@supabase/supabase-js';
import { config } from 'dotenv';

// Load environment variables
config();

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, {
  db: {
    schema: 'api',
  },
});

async function testOffboardingInsert() {
  console.log('🧪 Testing offboarding process insert...');

  try {
    // Get hygge-hvidlog client
    const { data: client, error: clientError } = await supabase
      .from('clients')
      .select('id, client_code')
      .eq('client_code', 'hygge-hvidlog')
      .single();

    if (clientError || !client) {
      console.error('❌ Could not find hygge-hvidlog client:', clientError);
      return;
    }

    console.log('✅ Found client:', client.client_code);

    // Get a template
    const { data: template, error: templateError } = await supabase
      .from('offboarding_templates')
      .select('id, name')
      .eq('client_id', client.id)
      .single();

    if (templateError || !template) {
      console.error('❌ Could not find offboarding template:', templateError);
      return;
    }

    console.log('✅ Found template:', template.name);

    // Get one person
    const { data: person, error: personError } = await supabase
      .from('people')
      .select('id, person_code, first_name, last_name, department, position')
      .eq('client_id', client.id)
      .limit(1)
      .single();

    if (personError || !person) {
      console.error('❌ Could not find person:', personError);
      return;
    }

    console.log('✅ Found person:', person.first_name, person.last_name);

    // Try to insert a test offboarding process
    console.log('🔄 Attempting to create offboarding process...');

    const { data: process, error: processError } = await supabase
      .from('offboarding_processes')
      .insert({
        client_id: client.id,
        template_id: template.id,
        employee_uid: person.person_code,
        employee_department: person.department,
        employee_role: person.position,
        process_name: `${person.first_name} ${person.last_name} Test Offboarding`,
        status: 'draft',
        priority: 'medium',
        target_completion_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
        created_by: 'test-script',
      })
      .select();

    if (processError) {
      console.error('❌ Process creation failed:', processError);

      if (processError.code === '23514') {
        console.log('💡 This is still the audit log constraint issue.');
        console.log('   Please ensure you ran: /schemas/13_fix_offboarding_audit_trigger.sql');
      }
      return;
    }

    console.log('✅ Successfully created offboarding process!');
    console.log('   Process ID:', process[0].id);
    console.log('   Process name:', process[0].process_name);

    // Check if audit log entry was created
    const { data: auditEntry, error: auditError } = await supabase
      .from('offboarding_audit_log')
      .select('*')
      .eq('entity_id', process[0].id)
      .single();

    if (auditError) {
      console.warn('⚠️  Could not verify audit log entry:', auditError);
    } else {
      console.log('✅ Audit log entry created with entity_type:', auditEntry.entity_type);
    }

    // Clean up the test process
    const { error: deleteError } = await supabase
      .from('offboarding_processes')
      .delete()
      .eq('id', process[0].id);

    if (deleteError) {
      console.warn('⚠️  Could not clean up test process:', deleteError);
    } else {
      console.log('🧹 Test process cleaned up');
    }

    console.log('\n🎉 Audit log trigger is working! You can now run the populate script.');
  } catch (error) {
    console.error('💥 Test failed:', error);
  }
}

// Run the test
testOffboardingInsert();
