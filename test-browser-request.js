#!/usr/bin/env node

import dotenv from 'dotenv';

dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL;
const apiKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

async function testBrowserLikeRequest() {
  console.log('🔍 Testing browser-like request to people_enrollments...\n');
  
  // Simulate exactly what the browser is sending
  const url = `${supabaseUrl}/rest/v1/people_enrollments?select=person_id%2Conboarding_completed%2Ccompletion_percentage&person_id=in.%28%22b885d5f5-7c02-4e6d-b1b0-5f1b3f1f5c5f%22%29`;
  
  try {
    console.log('URL:', url);
    
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'apikey': apiKey,
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
        'X-Client-Info': 'supabase-js/2.39.0',
      }
    });
    
    console.log('Status:', response.status, response.statusText);
    console.log('Headers:', Object.fromEntries(response.headers.entries()));
    
    if (response.status === 406) {
      const text = await response.text();
      console.log('\n406 Error Response:', text);
      
      // Try without the complex query
      console.log('\n\nTrying simpler query...');
      const simpleResponse = await fetch(`${supabaseUrl}/rest/v1/people_enrollments?limit=1`, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'apikey': apiKey,
          'Authorization': `Bearer ${apiKey}`,
        }
      });
      
      console.log('Simple query status:', simpleResponse.status);
      if (simpleResponse.ok) {
        const data = await simpleResponse.json();
        console.log('Simple query data:', data);
      }
    } else {
      const data = await response.json();
      console.log('Response data:', data);
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

testBrowserLikeRequest();