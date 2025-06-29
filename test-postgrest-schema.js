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
    }
  }
);

async function testSchema() {
  console.log('🔍 Testing PostgREST schema exposure...\n');
  
  // Test direct REST API call to see what PostgREST exposes
  const baseUrl = process.env.SUPABASE_URL.replace('/rest/v1', '');
  const apiKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  
  try {
    console.log('Testing PostgREST root endpoint...');
    const response = await fetch(`${baseUrl}/rest/v1/`, {
      headers: {
        'apikey': apiKey,
        'Authorization': `Bearer ${apiKey}`
      }
    });
    
    if (!response.ok) {
      console.log(`❌ Root endpoint failed: ${response.status} ${response.statusText}`);
    } else {
      const data = await response.json();
      console.log('PostgREST root response:', data);
      
      // Try OpenAPI endpoint instead
      console.log('\nTrying OpenAPI endpoint...');
      const openApiResponse = await fetch(`${baseUrl}/rest/v1/?apikey=${apiKey}`, {
        headers: {
          'Accept': 'application/openapi+json'
        }
      });
      
      if (openApiResponse.ok) {
        const openApiData = await openApiResponse.json();
        const paths = Object.keys(openApiData.paths || {});
        console.log(`\nFound ${paths.length} API paths`);
        
        // Check for enrollment paths
        const enrollmentPaths = paths.filter(p => p.includes('enrollment'));
        console.log('Enrollment paths:', enrollmentPaths);
        
        // Check for people paths
        const peoplePaths = paths.filter(p => p.includes('people'));
        console.log('People paths:', peoplePaths);
      }
    }
    
    // Try direct table query
    console.log('\nTesting direct people_enrollments query...');
    const enrollmentResponse = await fetch(`${baseUrl}/rest/v1/people_enrollments?limit=1`, {
      headers: {
        'apikey': apiKey,
        'Authorization': `Bearer ${apiKey}`,
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }
    });
    
    console.log(`Response status: ${enrollmentResponse.status}`);
    console.log(`Response headers:`, Object.fromEntries(enrollmentResponse.headers.entries()));
    
    if (enrollmentResponse.status === 406) {
      console.log('❌ 406 Error - Schema not recognized by PostgREST');
      const errorText = await enrollmentResponse.text();
      console.log('Error response:', errorText);
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

testSchema();