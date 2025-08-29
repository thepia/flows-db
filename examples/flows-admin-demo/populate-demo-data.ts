#!/usr/bin/env node

import { createClient } from '@supabase/supabase-js';
// Script to populate the demo companies with data
import dotenv from 'dotenv';
import { generateDemoDataForCompany } from './src/lib/services/demoDataGenerator.js';

// Load environment variables from root directory
dotenv.config({ path: '../../.env' });

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('❌ Missing required environment variables');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  db: {
    schema: 'api',
  },
});

async function populateDemoData() {
  console.log('🚀 Starting demo data population...');

  try {
    console.log('\n📊 Phase 2: Populating Hygge & Hvidløg A/S...');

    // Clear existing data first
    console.log('🧹 Clearing existing data for hygge-hvidlog...');
    const hyggeClient = await supabase
      .from('clients')
      .select('id')
      .eq('client_code', 'hygge-hvidlog')
      .single();
    if (hyggeClient.data) {
      await supabase.from('people').delete().eq('client_id', hyggeClient.data.id);
    }

    // Generate data for Hygge & Hvidløg (medium-scale European company)
    await generateDemoDataForCompany(
      {
        companyId: 'hygge-hvidlog',
        employeeCount: 1200,
        onboardingCount: 50,
        offboardingCount: 30,
      },
      (progress: number, message: string) => {
        console.log(`  [${progress}%] ${message}`);
      }
    );

    console.log('✅ Hygge & Hvidløg data generation completed!');

    console.log('\n📊 Phase 2b: Populating Meridian Brands International...');

    // Clear existing data first
    console.log('🧹 Clearing existing data for meridian-brands...');
    const meridianClient = await supabase
      .from('clients')
      .select('id')
      .eq('client_code', 'meridian-brands')
      .single();
    if (meridianClient.data) {
      await supabase.from('people').delete().eq('client_id', meridianClient.data.id);
    }

    // Generate data for Meridian Brands (large-scale global enterprise)
    await generateDemoDataForCompany(
      {
        companyId: 'meridian-brands',
        employeeCount: 2500,
        onboardingCount: 120,
        offboardingCount: 80,
      },
      (progress: number, message: string) => {
        console.log(`  [${progress}%] ${message}`);
      }
    );

    console.log('✅ Meridian Brands data generation completed!');

    // Verify the data was created
    console.log('\n🔍 Verifying generated data...');

    const hyggeVerifyClient = await supabase
      .from('clients')
      .select('id')
      .eq('client_code', 'hygge-hvidlog')
      .single();
    const meridianVerifyClient = await supabase
      .from('clients')
      .select('id')
      .eq('client_code', 'meridian-brands')
      .single();

    const { count: hyggeEmployees } = await supabase
      .from('people')
      .select('*', { count: 'exact', head: true })
      .eq('client_id', hyggeVerifyClient.data.id);
    const { count: meridianEmployees } = await supabase
      .from('people')
      .select('*', { count: 'exact', head: true })
      .eq('client_id', meridianVerifyClient.data.id);

    console.log(`📈 Hygge & Hvidløg: ${hyggeEmployees} people created`);
    console.log(`📈 Meridian Brands: ${meridianEmployees} people created`);

    console.log('\n🎉 Demo data population completed successfully!');
    console.log('\n💡 Next steps:');
    console.log('  1. Refresh the demo app to see Hygge & Hvidløg loaded by default');
    console.log('  2. Switch between demo companies in Settings');
    console.log('  3. Test the rich datasets and custom branding');
  } catch (error) {
    console.error('❌ Error during data population:', error);
    process.exit(1);
  }
}

populateDemoData();
