#!/usr/bin/env node

import { createClient } from '@supabase/supabase-js';
import chalk from 'chalk';
import dotenv from 'dotenv';
import ora from 'ora';

// Load environment variables
dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL || 'https://jstbkvkurjsopuwhlsvy.supabase.co';
const supabaseServiceKey =
  process.env.SUPABASE_SERVICE_ROLE_KEY ||
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpzdGJrdmt1cmpzb3B1d2hsc3Z5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MDk2NjU2OCwiZXhwIjoyMDY2NTQyNTY4fQ.vSSYVzitJDrQQYer1cW-SU_ZSEUtVyIOKsogHjy3h58';

const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
  db: {
    schema: 'api',
  },
});

async function createEnrollments() {
  console.log(chalk.blue.bold('👥 Creating People Enrollments\n'));

  const spinner = ora('Fetching existing people').start();

  try {
    // Get all people
    const { data: people, error: peopleError } = await supabase.from('people').select('*');

    if (peopleError) {
      throw peopleError;
    }

    spinner.succeed(`Found ${people?.length || 0} people`);

    if (!people || people.length === 0) {
      console.log(chalk.yellow('No people found. Skipping enrollment creation.'));
      return;
    }

    // Check existing enrollments
    const { data: existingEnrollments, error: enrollmentError } = await supabase
      .from('people_enrollments')
      .select('person_id');

    const existingPersonIds = new Set(existingEnrollments?.map((e) => e.person_id) || []);

    // Create enrollments for people without them
    const newEnrollments = [];
    for (const person of people) {
      if (!existingPersonIds.has(person.id)) {
        newEnrollments.push({
          person_id: person.id,
          onboarding_completed: person.employment_status === 'active',
          completion_percentage: person.employment_status === 'active' ? 100 : 50,
          onboarding_status: person.employment_status === 'active' ? 'completed' : 'in_progress',
          offboarding_status: person.employment_status === 'former' ? 'completed' : 'not_started',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        });
      }
    }

    if (newEnrollments.length > 0) {
      const createSpinner = ora(`Creating ${newEnrollments.length} new enrollments`).start();

      const { data: created, error: createError } = await supabase
        .from('people_enrollments')
        .insert(newEnrollments)
        .select();

      if (createError) {
        createSpinner.fail(`Failed to create enrollments: ${createError.message}`);
        throw createError;
      }

      createSpinner.succeed(`Created ${created?.length || 0} enrollments`);
    } else {
      console.log(chalk.green('All people already have enrollments'));
    }
  } catch (error) {
    spinner.fail(`Error: ${error.message}`);
    throw error;
  }
}

async function verifyEnrollments() {
  const spinner = ora('Verifying enrollments').start();

  try {
    const { data, error } = await supabase.from('people_enrollments').select('*');

    if (error) {
      throw error;
    }

    spinner.succeed(`Total enrollments: ${data?.length || 0}`);

    // Test the problematic query
    const testSpinner = ora('Testing problematic queries').start();

    // Get some person IDs
    const { data: people } = await supabase.from('people').select('id').limit(2);

    if (people && people.length > 0) {
      const personIds = people.map((p) => p.id);

      // Test the IN query
      const { data: testData, error: testError } = await supabase
        .from('people_enrollments')
        .select('person_id, onboarding_completed, completion_percentage')
        .in('person_id', personIds);

      if (testError) {
        testSpinner.fail(`IN query failed: ${testError.message}`);
      } else {
        testSpinner.succeed(`IN query successful: ${testData?.length || 0} results`);
      }
    }
  } catch (error) {
    spinner.fail(`Verification failed: ${error.message}`);
  }
}

async function main() {
  try {
    await createEnrollments();
    await verifyEnrollments();

    console.log(chalk.green('\n✅ Enrollment setup completed!'));
  } catch (error) {
    console.error(chalk.red('\n❌ Failed:'), error.message);
    process.exit(1);
  }
}

main();
