#!/usr/bin/env node

import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    },
    db: {
      schema: 'api'
    }
  }
);

async function clearHyggeData() {
  console.log('🧹 Clearing hygge-hvidlog data...');
  
  // Get hygge client
  const { data: hyggeClient } = await supabase
    .from('clients')
    .select('id')
    .eq('client_code', 'hygge-hvidlog')
    .single();
  
  if (hyggeClient) {
    console.log('Found hygge client:', hyggeClient.id);
    
    // Delete all people for this client
    const { error } = await supabase
      .from('people')
      .delete()
      .eq('client_id', hyggeClient.id);
    
    if (error) {
      console.error('Error clearing data:', error);
    } else {
      console.log('✅ Hygge data cleared successfully');
    }
  }
}

clearHyggeData();