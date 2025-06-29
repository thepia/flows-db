#!/usr/bin/env node

/**
 * Update Company Information
 * 
 * Updates the demo companies with rich, detailed information from DEMO_COMPANIES.md
 */

import { createClient } from '@supabase/supabase-js';
import { config } from 'dotenv';

// Load environment variables
config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  {
    db: {
      schema: 'api'
    }
  }
);

// Company information updates
const COMPANY_UPDATES = {
  'hygge-hvidlog': {
    legal_name: 'Hygge & Hvidløg A/S',
    name: 'Hygge & Hvidløg',
    industry: 'Sustainable Food Technology & Wellness Products',
    description: 'B2B2C sustainable food technology company specializing in plant-based protein alternatives, fermentation technologies, and wellness food products. Danish design philosophy meets innovative food science.',
    tier: 'enterprise',
    status: 'active',
    founded_year: 1987,
    headquarters_location: 'Copenhagen, Denmark',
    employee_count: 1200,
    business_model: 'B2B2C',
    company_size: 'mid_enterprise',
    geographic_scope: 'international',
    primary_market: 'europe',
    sustainability_focus: true,
    innovation_level: 'high'
  },
  'meridian-brands': {
    legal_name: 'Meridian Brands International',
    name: 'Meridian Brands',
    industry: 'Consumer Products & Lifestyle Brands',
    description: 'Portfolio of consumer lifestyle brands spanning personal care, home goods, food & beverages, and digital lifestyle products. Operates in 47 countries with strong presence in emerging markets.',
    tier: 'enterprise',
    status: 'active',
    founded_year: 1952,
    headquarters_location: 'Singapore',
    employee_count: 15500,
    business_model: 'B2C',
    company_size: 'large_enterprise',
    geographic_scope: 'global',
    primary_market: 'global',
    brand_portfolio_size: 47,
    market_presence: 'established_multinational'
  }
};

// Update company information
async function updateCompanyInfo() {
  console.log('🏢 Updating company information...\n');

  for (const [clientCode, updates] of Object.entries(COMPANY_UPDATES)) {
    console.log(`📝 Updating ${updates.legal_name}...`);

    const { error } = await supabase
      .from('clients')
      .update(updates)
      .eq('client_code', clientCode);

    if (error) {
      console.error(`  ❌ Error updating ${clientCode}:`, error);
    } else {
      console.log(`  ✅ Updated company information`);
    }
  }
}

// Create admin access records for existing contacts
async function createAdminAccess() {
  console.log('\n🔐 Creating admin access records...\n');

  const { data: contacts } = await supabase
    .from('account_contacts')
    .select('*');

  if (!contacts || contacts.length === 0) {
    console.log('  No contacts found');
    return;
  }

  for (const contact of contacts) {
    // Check if admin access already exists
    const { data: existingAccess } = await supabase
      .from('admin_access')
      .select('id')
      .eq('contact_id', contact.id)
      .single();

    if (existingAccess) {
      console.log(`  ⏭️  Admin access already exists for ${contact.first_name} ${contact.last_name}`);
      continue;
    }

    // Create admin access based on contact type
    const accessLevel = contact.contact_type === 'primary' ? 'owner' : 
                       contact.contact_type === 'billing' ? 'billing_only' : 
                       'admin';

    const { error: accessError } = await supabase
      .from('admin_access')
      .insert({
        client_id: contact.client_id,
        contact_id: contact.id,
        access_level: accessLevel,
        can_purchase_credits: contact.can_purchase_credits || false,
        can_view_billing: contact.can_view_billing || false,
        can_view_usage_analytics: contact.contact_type !== 'billing',
        can_manage_account_settings: contact.contact_type === 'primary',
        can_manage_users: contact.can_manage_users || false,
        can_initiate_workflows: contact.contact_type !== 'billing',
        can_view_credit_transactions: contact.can_view_billing || false,
        status: 'active',
        granted_at: new Date(Date.now() - 730 * 24 * 60 * 60 * 1000).toISOString() // 2 years ago
      });

    if (accessError) {
      console.error(`  ❌ Error creating admin access for ${contact.first_name} ${contact.last_name}:`, accessError);
    } else {
      console.log(`  ✅ Created ${accessLevel} access for ${contact.first_name} ${contact.last_name}`);
    }
  }
}

// Main execution
async function main() {
  console.log('🚀 Updating company information and admin access...\n');

  await updateCompanyInfo();
  await createAdminAccess();

  console.log('\n✅ Company information update complete!');
}

// Run the script
main();