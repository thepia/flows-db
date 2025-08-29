#!/usr/bin/env node

/**
 * Populate Process Data - Create actual onboarding/offboarding processes
 * to match the people data that already exists
 */

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, {
  db: {
    schema: 'api',
  },
});

async function populateProcessData() {
  console.log('🔄 Populating process data...\n');

  try {
    // Get all clients
    const { data: clients, error: clientsError } = await supabase
      .from('clients')
      .select('id, client_code, legal_name');

    if (clientsError) throw clientsError;

    for (const client of clients) {
      console.log(`📊 Processing client: ${client.legal_name} (${client.client_code})`);

      // Get people for this client
      const { data: people, error: peopleError } = await supabase
        .from('people')
        .select('id, person_code, first_name, last_name, department, position, employment_status')
        .eq('client_id', client.id);

      if (peopleError) {
        console.warn(`❌ Error loading people for ${client.client_code}:`, peopleError);
        continue;
      }

      console.log(`   📋 Found ${people.length} people`);

      // Create default offboarding template if it doesn't exist
      const { data: templates, error: templateError } = await supabase
        .from('offboarding_templates')
        .select('id')
        .eq('client_id', client.id)
        .eq('is_default', true)
        .limit(1);

      if (templateError) {
        console.warn(`❌ Error loading templates for ${client.client_code}:`, templateError);
        continue;
      }

      let templateId;
      if (!templates || templates.length === 0) {
        // Create default template
        const { data: newTemplate, error: createTemplateError } = await supabase
          .from('offboarding_templates')
          .insert({
            client_id: client.id,
            name: 'Standard Offboarding Process',
            description: 'Default offboarding process for all employees',
            template_type: 'company_wide',
            estimated_duration_days: 14,
            complexity_score: 2,
            is_active: true,
            is_default: true,
            requires_manager_approval: true,
            requires_hr_approval: true,
            auto_assign_tasks: true,
            created_by: 'system-demo',
          })
          .select('id')
          .single();

        if (createTemplateError) {
          console.warn(
            `❌ Error creating template for ${client.client_code}:`,
            createTemplateError
          );
          continue;
        }
        templateId = newTemplate.id;
        console.log(`   ✅ Created default offboarding template`);
      } else {
        templateId = templates[0].id;
      }

      // Create enrollment data for people
      const enrollments = [];
      const processes = [];

      people.forEach((person, index) => {
        // 70% get enrollment records (ongoing onboarding)
        if (index < people.length * 0.7) {
          const completionPercentage = Math.floor(Math.random() * 80) + 10; // 10-90%
          enrollments.push({
            person_id: person.id,
            onboarding_completed: completionPercentage >= 95,
            completion_percentage: completionPercentage,
            mentor: 'Demo Mentor',
            buddy_program: Math.random() > 0.5,
            last_activity: new Date().toISOString(),
          });
        }

        // 15% get offboarding processes
        if (index < people.length * 0.15) {
          const statuses = ['draft', 'pending_approval', 'active'];
          const priorities = ['low', 'medium', 'high'];
          processes.push({
            client_id: client.id,
            template_id: templateId,
            employee_uid: person.person_code,
            employee_department: person.department,
            employee_role: person.position,
            process_name: `${person.first_name} ${person.last_name} Offboarding`,
            status: statuses[Math.floor(Math.random() * statuses.length)],
            priority: priorities[Math.floor(Math.random() * priorities.length)],
            target_completion_date: new Date(
              Date.now() + (Math.floor(Math.random() * 30) + 15) * 24 * 60 * 60 * 1000
            ).toISOString(),
            created_by: 'demo-system',
          });
        }
      });

      // Insert enrollment data
      if (enrollments.length > 0) {
        const { error: enrollmentInsertError } = await supabase
          .from('people_enrollments')
          .insert(enrollments);

        if (enrollmentInsertError) {
          console.warn(
            `❌ Error inserting enrollments for ${client.client_code}:`,
            enrollmentInsertError
          );
        } else {
          console.log(`   ✅ Created ${enrollments.length} enrollment records`);
        }
      }

      // Insert process data (try with smaller batches to avoid constraint issues)
      if (processes.length > 0) {
        console.log(`   📋 Attempting to insert ${processes.length} processes in batches...`);

        let successCount = 0;
        const batchSize = 1; // Insert one at a time to isolate issues

        for (let i = 0; i < processes.length; i += batchSize) {
          const batch = processes.slice(i, i + batchSize);

          try {
            // Try without audit logging by using a simplified insert
            const { error: processInsertError } = await supabase
              .from('offboarding_processes')
              .insert(
                batch.map((p) => ({
                  client_id: p.client_id,
                  template_id: p.template_id,
                  employee_uid: p.employee_uid,
                  employee_department: p.employee_department,
                  employee_role: p.employee_role,
                  process_name: p.process_name,
                  status: p.status,
                  priority: p.priority,
                  target_completion_date: p.target_completion_date,
                  created_by: p.created_by,
                }))
              );

            if (processInsertError) {
              console.warn(`   ❌ Batch ${i + 1}: ${processInsertError.message}`);
              if (processInsertError.code === '23514') {
                console.warn(`   💡 Audit log constraint issue - may need schema fix`);
                break; // Stop trying if it's the constraint issue
              }
            } else {
              successCount += batch.length;
            }
          } catch (e) {
            console.warn(`   ❌ Batch ${i + 1} failed:`, e.message);
          }
        }

        if (successCount > 0) {
          console.log(`   ✅ Created ${successCount} offboarding processes`);
        } else {
          console.log(`   ⚠️  No processes created due to database constraints`);
        }
      }

      console.log(
        `   📊 Summary: ${enrollments.length} onboarding, ${processes.length} offboarding\n`
      );
    }

    console.log('✅ Process data population completed!');
  } catch (error) {
    console.error('💥 Error populating process data:', error);
    process.exit(1);
  }
}

// Main execution
if (require.main === module) {
  populateProcessData().catch(console.error);
}

module.exports = { populateProcessData };
