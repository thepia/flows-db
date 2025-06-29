#!/usr/bin/env node

import dotenv from 'dotenv';
import { createClient } from '@supabase/supabase-js';

dotenv.config({ path: '../../.env' });

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
  {
    db: {
      schema: 'api',
    },
  }
);

function randomDate(start: Date, end: Date): Date {
  return new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime()));
}

async function addEnrollments() {
  console.log('🔄 Adding enrollment data...');
  
  // Get Hygge & Hvidløg people
  const { data: hyggeClient } = await supabase
    .from('clients')
    .select('id')
    .eq('client_code', 'hygge-hvidlog')
    .single();
  
  if (!hyggeClient) {
    console.error('Hygge client not found');
    return;
  }
  
  // Get active people for this client
  const { data: people } = await supabase
    .from('people')
    .select('id')
    .eq('client_id', hyggeClient.id)
    .eq('employment_status', 'active')
    .limit(20);
  
  if (!people || people.length === 0) {
    console.error('No active people found');
    return;
  }
  
  console.log(`Found ${people.length} active people`);
  
  // Create enrollments
  const enrollments = people.map(person => ({
    person_id: person.id,
    onboarding_completed: Math.random() > 0.3,
    completion_percentage: Math.floor(Math.random() * 100),
    last_activity: randomDate(
      new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
      new Date()
    ).toISOString(),
  }));
  
  const { error } = await supabase.from('people_enrollments').insert(enrollments);
  
  if (error) {
    console.error('Error inserting enrollments:', error);
  } else {
    console.log(`✅ Added ${enrollments.length} enrollment records`);
  }
}

addEnrollments();