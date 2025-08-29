#!/usr/bin/env node

/**
 * Add Remaining Associates to Hygge & Hvidløg
 * (The ones that failed due to constraint issues)
 */

import chalk from 'chalk';
import dotenv from 'dotenv';

dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

const headers = {
  apikey: supabaseServiceKey,
  Authorization: `Bearer ${supabaseServiceKey}`,
  'Content-Type': 'application/json',
};

async function addRemainingAssociates() {
  try {
    // Get Hygge & Hvidløg client ID
    const clientResponse = await fetch(
      `${supabaseUrl}/rest/v1/clients?select=id&client_code=eq.hygge-hvidlog`,
      {
        headers,
      }
    );
    const clients = await clientResponse.json();
    const clientId = clients[0].id;

    // Define the 4 missing associates with corrected constraints
    const remainingAssociates = [
      // Consultants
      {
        client_id: clientId,
        person_code: 'assoc-005',
        first_name: 'Ingrid',
        last_name: 'Svendsen',
        company_email: 'ingrid.svendsen@consultants.hygge-hvidlog.dk',
        department: 'Marketing & Communications',
        position: 'Brand Consultant',
        location: 'Copenhagen, Denmark',
        associate_status: 'consultant',
        employment_status: null,
        start_date: '2024-01-15',
        employment_type: null,
        work_location: 'hybrid',
        skills: ['Brand Strategy', 'Digital Marketing', 'Sustainable Branding', 'Nordic Markets'],
        languages: ['Danish', 'English', 'Swedish'],
      },
      {
        client_id: clientId,
        person_code: 'assoc-006',
        first_name: 'Torben',
        last_name: 'Andreasen',
        company_email: 'torben.andreasen@consultants.hygge-hvidlog.dk',
        department: 'Operations',
        position: 'Supply Chain Consultant',
        location: 'Aalborg, Denmark',
        associate_status: 'consultant',
        employment_status: null,
        start_date: '2024-02-01',
        employment_type: null,
        work_location: 'remote',
        skills: ['Supply Chain', 'Logistics', 'Procurement', 'Sustainable Sourcing'],
        languages: ['Danish', 'English', 'Dutch'],
      },
      // Contractors
      {
        client_id: clientId,
        person_code: 'assoc-007',
        first_name: 'Elena',
        last_name: 'Borg',
        company_email: 'elena.borg@contractors.hygge-hvidlog.dk',
        department: 'IT & Development',
        position: 'DevOps Contractor',
        location: 'Stockholm, Sweden',
        associate_status: 'contractor',
        employment_status: null,
        start_date: '2024-03-01',
        employment_type: null,
        work_location: 'remote',
        skills: ['DevOps', 'Cloud Infrastructure', 'Kubernetes', 'CI/CD', 'Security'],
        languages: ['Swedish', 'English', 'Finnish'],
      },
      {
        client_id: clientId,
        person_code: 'assoc-008',
        first_name: 'Jan',
        last_name: 'Vestergaard',
        company_email: 'jan.vestergaard@contractors.hygge-hvidlog.dk',
        department: 'Quality Assurance',
        position: 'Food Safety Contractor',
        location: 'Odense, Denmark',
        associate_status: 'contractor',
        employment_status: null,
        start_date: '2024-04-01',
        employment_type: null,
        work_location: 'office',
        skills: ['Food Safety', 'Quality Control', 'HACCP', 'EU Food Regulations'],
        languages: ['Danish', 'English', 'German'],
      },
    ];

    console.log(chalk.blue('🤝 Adding remaining 4 associates...'));

    for (const associate of remainingAssociates) {
      const response = await fetch(`${supabaseUrl}/rest/v1/people`, {
        method: 'POST',
        headers: {
          ...headers,
          Prefer: 'return=minimal',
        },
        body: JSON.stringify(associate),
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error(
          chalk.red(`❌ Error adding ${associate.first_name} ${associate.last_name}: ${errorText}`)
        );
      } else {
        console.log(
          chalk.green(
            `✅ Added ${associate.first_name} ${associate.last_name} (${associate.associate_status})`
          )
        );
      }
    }

    console.log(chalk.green('\n🎉 Remaining associates added successfully!'));
  } catch (error) {
    console.error(chalk.red('❌ Error:'), error);
  }
}

addRemainingAssociates();
