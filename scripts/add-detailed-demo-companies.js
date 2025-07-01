#!/usr/bin/env node

import dotenv from 'dotenv';
import chalk from 'chalk';

// Load environment variables
dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error(chalk.red('❌ Missing required environment variables'));
  console.error('Required: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY');
  process.exit(1);
}

const headers = {
  'apikey': supabaseServiceKey,
  'Authorization': `Bearer ${supabaseServiceKey}`,
  'Content-Type': 'application/json'
};

async function addDetailedDemoCompanies() {
  try {
    console.log(chalk.blue('🏢 Adding detailed demo companies...'));

    // Define the two detailed demo companies
    const demoCompanies = [
      {
        legal_name: 'Hygge & Hvidløg A/S',
        client_code: 'hygge-hvidlog',
        domain: 'hygge-hvidlog.thepia.net',
        tier: 'enterprise',
        status: 'active',
        region: 'EU',
        max_users: 1200,
        max_storage_gb: 100
      },
      {
        legal_name: 'Meridian Brands International',
        client_code: 'meridian-brands', 
        domain: 'meridian-brands.thepia.net',
        tier: 'enterprise',
        status: 'active',
        region: 'APAC',
        max_users: 15500,
        max_storage_gb: 100
      }
    ];

    console.log(chalk.yellow('📝 Creating demo companies...'));
    
    // Insert companies using upsert
    for (const company of demoCompanies) {
      const response = await fetch(`${supabaseUrl}/rest/v1/clients`, {
        method: 'POST',
        headers: {
          ...headers,
          'Prefer': 'resolution=merge-duplicates'
        },
        body: JSON.stringify(company)
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error(chalk.red(`❌ Error creating ${company.legal_name}: HTTP ${response.status} - ${errorText}`));
      } else {
        console.log(chalk.green(`✅ Created/updated ${company.legal_name}`));
      }
    }

    // Get the created companies to get their IDs
    const companiesResponse = await fetch(`${supabaseUrl}/rest/v1/clients?select=id,legal_name,client_code&client_code=in.(hygge-hvidlog,meridian-brands)`, {
      headers
    });

    if (!companiesResponse.ok) {
      const errorText = await companiesResponse.text();
      console.error(chalk.red(`❌ Error fetching companies: HTTP ${companiesResponse.status} - ${errorText}`));
      return;
    }

    const companies = await companiesResponse.json();

    if (!companies || companies.length === 0) {
      console.log(chalk.yellow('⚠️  No demo companies found after creation'));
      return;
    }

    console.log(chalk.yellow('\n📱 Creating demo applications...'));

    // Define applications for each company
    const hyggeCompany = companies.find(c => c.client_code === 'hygge-hvidlog');
    const meridianCompany = companies.find(c => c.client_code === 'meridian-brands');

    const applications = [];

    if (hyggeCompany) {
      applications.push(
        {
          client_id: hyggeCompany.id,
          app_code: 'employee-onboarding',
          app_name: 'Employee Onboarding',
          app_version: '2.1.0',
          app_description: 'Comprehensive onboarding for sustainable food technology company with multilingual support',
          status: 'active',
          configuration: {
            theme: 'hygge',
            locale: 'da-DK',
            branding: {
              primary_color: '#2F5233',
              secondary_color: '#8FBC8F',
              accent_color: '#DAA520'
            },
            features: {
              multilingual: true,
              sustainability_training: true,
              remote_onboarding: true
            }
          },
          features: [
            'document-capture',
            'task-management', 
            'video-onboarding',
            'multilingual-support',
            'sustainability-training',
            'remote-work-setup'
          ],
          max_concurrent_users: 200
        },
        {
          client_id: hyggeCompany.id,
          app_code: 'knowledge-offboarding',
          app_name: 'Knowledge Transfer & Offboarding', 
          app_version: '1.8.0',
          app_description: 'Knowledge preservation and sustainable transition processes',
          status: 'active',
          configuration: {
            theme: 'hygge',
            locale: 'da-DK',
            knowledge_retention: true,
            sustainability_focus: true
          },
          features: [
            'knowledge-transfer',
            'documentation',
            'mentorship-matching',
            'sustainable-transition'
          ],
          max_concurrent_users: 150
        }
      );
    }

    if (meridianCompany) {
      applications.push(
        {
          client_id: meridianCompany.id,
          app_code: 'rapid-onboarding',
          app_name: 'Rapid Market Onboarding',
          app_version: '3.2.1',
          app_description: 'Fast-paced onboarding for high-velocity consumer products environment',
          status: 'active',
          configuration: {
            theme: 'corporate',
            locale: 'en-SG',
            branding: {
              primary_color: '#1E3A8A',
              secondary_color: '#3B82F6',
              accent_color: '#F59E0B'
            },
            features: {
              rapid_deployment: true,
              multi_region: true,
              mobile_first: true
            }
          },
          features: [
            'mobile-onboarding',
            'rapid-deployment',
            'multi-region',
            'digital-signatures',
            'automated-workflows',
            'performance-tracking'
          ],
          max_concurrent_users: 500
        },
        {
          client_id: meridianCompany.id,
          app_code: 'offboarding-management',
          app_name: 'Offboarding',
          app_version: '2.7.0',
          app_description: 'High-volume offboarding and transition management for fast-paced environment',
          status: 'active',
          configuration: {
            theme: 'corporate',
            locale: 'en-SG',
            high_volume: true,
            automated_workflows: true
          },
          features: [
            'bulk-operations',
            'automated-handover',
            'knowledge-capture',
            'exit-analytics',
            'compliance-tracking'
          ],
          max_concurrent_users: 300
        }
      );
    }

    // Insert applications
    for (const app of applications) {
      const response = await fetch(`${supabaseUrl}/rest/v1/client_applications`, {
        method: 'POST',
        headers: {
          ...headers,
          'Prefer': 'resolution=merge-duplicates'
        },
        body: JSON.stringify(app)
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error(chalk.red(`❌ Error creating application ${app.app_name}: HTTP ${response.status} - ${errorText}`));
      } else {
        console.log(chalk.green(`✅ Created/updated application ${app.app_name}`));
      }
    }

    // Update last_accessed for applications to simulate usage
    const companyIds = companies.map(c => c.id);
    const updateData = {
      last_accessed: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(), // 2 hours ago
      updated_at: new Date().toISOString()
    };

    const updateResponse = await fetch(`${supabaseUrl}/rest/v1/client_applications?client_id=in.(${companyIds.join(',')})`, {
      method: 'PATCH',
      headers,
      body: JSON.stringify(updateData)
    });

    if (!updateResponse.ok) {
      const errorText = await updateResponse.text();
      console.error(chalk.red(`❌ Error updating last_accessed: HTTP ${updateResponse.status} - ${errorText}`));
    }

    // Final verification
    console.log(chalk.blue('\n🔍 Verifying demo companies...'));
    
    const finalCompaniesResponse = await fetch(`${supabaseUrl}/rest/v1/clients?select=id,legal_name,client_code,tier,status,region,created_at&client_code=in.(hygge-hvidlog,meridian-brands)&order=legal_name`, {
      headers
    });

    if (!finalCompaniesResponse.ok) {
      const errorText = await finalCompaniesResponse.text();
      console.error(chalk.red(`❌ Error fetching final companies: HTTP ${finalCompaniesResponse.status} - ${errorText}`));
      return;
    }

    const finalCompanies = await finalCompaniesResponse.json();

    if (!finalCompanies || finalCompanies.length === 0) {
      console.log(chalk.yellow('⚠️  No detailed demo companies found'));
      return;
    }

    console.log(chalk.green('\n✅ Detailed demo companies created successfully:'));
    finalCompanies.forEach(company => {
      console.log(chalk.cyan(`   • ${company.legal_name} (${company.client_code})`));
      console.log(chalk.gray(`     Tier: ${company.tier} | Status: ${company.status} | Region: ${company.region}`));
    });

    // Check applications for these companies
    const finalCompanyIds = finalCompanies.map(c => c.id).filter(id => id);
    
    if (finalCompanyIds.length === 0) {
      console.log(chalk.yellow('⚠️  No company IDs found for application lookup'));
      return;
    }
    
    const finalApplicationsResponse = await fetch(`${supabaseUrl}/rest/v1/client_applications?select=app_name,app_code,app_version,status,client_id&client_id=in.(${finalCompanyIds.join(',')})`, {
      headers
    });

    if (!finalApplicationsResponse.ok) {
      const errorText = await finalApplicationsResponse.text();
      console.error(chalk.red(`❌ Error fetching final applications: HTTP ${finalApplicationsResponse.status} - ${errorText}`));
      return;
    }

    const finalApplications = await finalApplicationsResponse.json();

    if (finalApplications && finalApplications.length > 0) {
      console.log(chalk.green(`\n📱 Created ${finalApplications.length} applications across demo companies:`));
      
      for (const company of finalCompanies) {
        const companyApps = finalApplications.filter(app => app.client_id === company.id);
        if (companyApps.length > 0) {
          console.log(chalk.cyan(`\n   ${company.legal_name}:`));
          companyApps.forEach(app => {
            console.log(chalk.gray(`     • ${app.app_name} (${app.app_code}) v${app.app_version}`));
          });
        }
      }
    }

    console.log(chalk.green('\n🎉 Detailed demo companies setup completed!'));

  } catch (error) {
    console.error(chalk.red('❌ Unexpected error:'), error);
    process.exit(1);
  }
}

// Execute if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  addDetailedDemoCompanies();
}

export { addDetailedDemoCompanies };