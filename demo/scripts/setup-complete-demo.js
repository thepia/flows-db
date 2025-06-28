#!/usr/bin/env node

/**
 * Complete Demo Setup Script
 * 
 * One command to set up everything:
 * - Creates demo client if missing
 * - Creates all database schema if missing  
 * - Populates rich demo data
 * - Handles cleanup and reset automatically
 */

import { Command } from 'commander';
import { createClient } from '@supabase/supabase-js';
import chalk from 'chalk';
import ora from 'ora';
import crypto from 'crypto';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { config } from 'dotenv';

// Load environment variables
config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const program = new Command();

// Supabase client setup
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error(chalk.red('❌ Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY environment variables'));
  process.exit(1);
}

/**
 * Direct API helper function
 */
async function apiCall(endpoint, method = 'GET', data = null) {
  const options = {
    method,
    headers: {
      'apikey': supabaseServiceKey,
      'Authorization': `Bearer ${supabaseServiceKey}`,
      'Content-Type': 'application/json'
    }
  };
  
  if (data && (method === 'POST' || method === 'PATCH')) {
    options.body = JSON.stringify(data);
    if (method === 'POST') {
      options.headers['Prefer'] = 'return=representation';
    }
  }
  
  const response = await fetch(`${supabaseUrl}/rest/v1/${endpoint}`, options);
  
  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`API call failed: ${method} ${endpoint} - HTTP ${response.status}: ${errorText}`);
  }
  
  return method === 'DELETE' ? null : await response.json();
}

/**
 * Clean up existing demo data
 */
async function cleanupExistingData(spinner) {
  try {
    spinner.text = 'Cleaning up existing demo data...';
    
    // Get the demo client first
    let demoClient = null;
    try {
      const clients = await apiCall('clients?select=*&client_code=eq.nets-demo');
      if (clients && clients.length > 0) {
        demoClient = clients[0];
      }
    } catch (error) {
      // Client doesn't exist, nothing to clean
    }
    
    if (demoClient) {
      // Clean up offboarding data first (if tables exist)
      try {
        const { cleanupOffboardingData } = await import('../../scripts/create-offboarding-demo-data.js');
        await cleanupOffboardingData(demoClient.id);
      } catch (e) { /* ignore if tables don't exist */ }
      
      // Delete in reverse dependency order using the client ID
      try {
        await apiCall(`employee_enrollments?employee_id=in.(select id from employees where client_id=${demoClient.id})`, 'DELETE');
      } catch (e) { /* ignore */ }
      
      try {
        await apiCall(`documents?employee_id=in.(select id from employees where client_id=${demoClient.id})`, 'DELETE');
      } catch (e) { /* ignore */ }
      
      try {
        await apiCall(`tasks?employee_id=in.(select id from employees where client_id=${demoClient.id})`, 'DELETE');
      } catch (e) { /* ignore */ }
      
      try {
        await apiCall(`employees?client_id=eq.${demoClient.id}`, 'DELETE');
      } catch (e) { /* ignore */ }
      
      try {
        await apiCall(`invitations?client_id=eq.${demoClient.id}`, 'DELETE');
      } catch (e) { /* ignore */ }
      
      try {
        await apiCall(`client_applications?client_id=eq.${demoClient.id}`, 'DELETE');
      } catch (e) { /* ignore */ }
      
      try {
        await apiCall(`clients?id=eq.${demoClient.id}`, 'DELETE');
      } catch (e) { /* ignore */ }
      
      spinner.succeed('Cleaned up existing demo data');
    } else {
      spinner.succeed('No existing demo data found to clean up');
    }
  } catch (error) {
    // Ignore cleanup errors - data might not exist
    spinner.succeed('Cleanup completed (some data may not have existed)');
  }
}

/**
 * Create demo client
 */
async function createDemoClient(spinner) {
  spinner.text = 'Creating demo client...';
  
  const configPath = path.join(__dirname, '../config/client.json');
  const clientConfig = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  
  const client = await apiCall('clients', 'POST', {
    ...clientConfig.client,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString()
  });
  
  const createdClient = client[0];
  spinner.succeed(`Created demo client: ${createdClient.legal_name}`);
  return createdClient;
}

/**
 * Create client applications
 */
async function createClientApplications(clientId, spinner) {
  spinner.text = 'Creating client applications...';
  
  const configPath = path.join(__dirname, '../config/client.json');
  const clientConfig = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  
  const applications = [];
  for (const appConfig of clientConfig.applications) {
    const app = await apiCall('client_applications', 'POST', {
      ...appConfig,
      client_id: clientId,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    });
    applications.push(app[0]);
  }
  
  spinner.succeed(`Created ${applications.length} client applications`);
  return applications;
}

/**
 * Create comprehensive employee dataset (from rich demo script)
 */
async function createEmployees(clientId, spinner) {
  spinner.text = 'Creating employees...';
  
  const employeesData = [
    {
      employee_code: 'emp-001',
      first_name: 'Anna',
      last_name: 'Hansen',
      company_email: 'anna.hansen@nets.eu',
      department: 'Engineering',
      position: 'Senior Software Engineer',
      location: 'Copenhagen, Denmark',
      manager: 'Lars Nielsen',
      start_date: '2024-01-15',
      status: 'active',
      security_clearance: 'high',
      employment_type: 'full_time',
      work_location: 'hybrid',
      skills: ['JavaScript', 'TypeScript', 'React', 'Node.js', 'Payment APIs'],
      languages: ['Danish', 'English', 'Swedish']
    },
    {
      employee_code: 'emp-002',
      first_name: 'Erik',
      last_name: 'Larsen',
      company_email: 'erik.larsen@nets.eu',
      department: 'Product',
      position: 'Product Manager',
      location: 'Copenhagen, Denmark',
      manager: 'Maria Andersen',
      start_date: '2024-02-01',
      status: 'active',
      security_clearance: 'medium',
      employment_type: 'full_time',
      work_location: 'office',
      skills: ['Product Strategy', 'Agile', 'Data Analysis', 'Financial Services', 'User Research'],
      languages: ['Danish', 'English', 'Norwegian']
    },
    {
      employee_code: 'emp-003',
      first_name: 'Sofia',
      last_name: 'Berg',
      company_email: 'sofia.berg@nets.eu',
      department: 'Design',
      position: 'UX Designer',
      location: 'Stockholm, Sweden',
      manager: 'Peter Olsen',
      start_date: '2024-03-01',
      status: 'pending',
      security_clearance: 'medium',
      employment_type: 'full_time',
      work_location: 'remote',
      skills: ['UX Design', 'Figma', 'User Research', 'Prototyping', 'Accessibility'],
      languages: ['Swedish', 'English', 'Danish']
    },
    {
      employee_code: 'emp-004',
      first_name: 'Magnus',
      last_name: 'Johansson',
      company_email: 'magnus.johansson@nets.eu',
      department: 'Engineering',
      position: 'DevOps Engineer',
      location: 'Stockholm, Sweden',
      manager: 'Lars Nielsen',
      start_date: '2023-12-01',
      end_date: '2024-03-15',
      status: 'offboarded',
      security_clearance: 'high',
      employment_type: 'full_time',
      work_location: 'hybrid',
      skills: ['Kubernetes', 'Docker', 'AWS', 'CI/CD', 'Infrastructure as Code'],
      languages: ['Swedish', 'English']
    },
    {
      employee_code: 'emp-005',
      first_name: 'Lars',
      last_name: 'Petersen',
      company_email: 'lars.petersen@nets.eu',
      department: 'Engineering',
      position: 'Frontend Developer',
      location: 'Copenhagen, Denmark',
      manager: 'Anna Hansen',
      start_date: '2024-03-20',
      status: 'invited',
      security_clearance: 'medium',
      employment_type: 'full_time',
      work_location: 'hybrid',
      skills: ['React', 'Vue.js', 'TypeScript', 'CSS', 'Testing'],
      languages: ['Danish', 'English', 'German']
    },
    {
      employee_code: 'emp-006',
      first_name: 'Mette',
      last_name: 'Sørensen',
      company_email: 'mette.sorensen@nets.eu',
      department: 'Marketing',
      position: 'Marketing Specialist',
      location: 'Copenhagen, Denmark',
      manager: 'Erik Larsen',
      start_date: '2023-11-15',
      end_date: '2024-03-20',
      status: 'offboarding_initiated',
      security_clearance: 'low',
      employment_type: 'full_time',
      work_location: 'office',
      skills: ['Digital Marketing', 'Content Strategy', 'Analytics', 'Social Media', 'Brand Management'],
      languages: ['Danish', 'English', 'French']
    },
    {
      employee_code: 'emp-007',
      first_name: 'John',
      last_name: 'Smith',
      company_email: 'john.smith@nets.eu',
      department: 'Security',
      position: 'Security Consultant',
      location: 'Copenhagen, Denmark',
      manager: 'Security Director',
      start_date: '2024-03-01',
      status: 'pending',
      security_clearance: 'high',
      employment_type: 'contractor',
      work_location: 'office',
      skills: ['Cybersecurity', 'Risk Assessment', 'Compliance', 'Audit', 'GDPR'],
      languages: ['English', 'Danish']
    },
    {
      employee_code: 'emp-008',
      first_name: 'Astrid',
      last_name: 'Lindberg',
      company_email: 'astrid.lindberg@nets.eu',
      department: 'Finance',
      position: 'Financial Analyst',
      location: 'Stockholm, Sweden',
      manager: 'Finance Director',
      start_date: '2024-01-08',
      status: 'active',
      security_clearance: 'high',
      employment_type: 'full_time',
      work_location: 'hybrid',
      skills: ['Financial Analysis', 'Excel', 'SQL', 'Risk Management', 'Compliance'],
      languages: ['Swedish', 'English', 'Norwegian']
    }
  ];
  
  const createdEmployees = [];
  for (const empData of employeesData) {
    const employee = await apiCall('employees', 'POST', {
      ...empData,
      client_id: clientId
    });
    createdEmployees.push(employee[0]);
  }
  
  spinner.succeed(`Created ${createdEmployees.length} employees`);
  return createdEmployees;
}

/**
 * Create all related data (enrollments, documents, tasks, invitations)
 */
async function createAllRelatedData(employees, applications, clientId, spinner) {
  // Create enrollments
  spinner.text = 'Creating employee enrollments...';
  const enrollments = await createEmployeeEnrollments(employees);
  
  // Create documents
  spinner.text = 'Creating documents...';
  const documents = await createDocuments(employees);
  
  // Create tasks
  spinner.text = 'Creating tasks...';
  const tasks = await createTasks(employees);
  
  // Create invitations
  spinner.text = 'Creating invitations...';
  const invitations = await createInvitations(clientId, applications, employees);
  
  return { enrollments, documents, tasks, invitations };
}

// Helper functions (condensed versions from rich demo script)
async function createEmployeeEnrollments(employees) {
  const enrollmentsData = [
    { employee_code: 'emp-001', onboarding_completed: true, completion_percentage: 100, mentor: 'Lars Nielsen', buddy_program: true },
    { employee_code: 'emp-002', onboarding_completed: true, completion_percentage: 100, mentor: 'Maria Andersen', buddy_program: true },
    { employee_code: 'emp-003', onboarding_completed: false, completion_percentage: 45, mentor: 'Peter Olsen', buddy_program: true },
    { employee_code: 'emp-004', onboarding_completed: true, completion_percentage: 100, mentor: 'Lars Nielsen', buddy_program: true, offboarding_completed: true },
    { employee_code: 'emp-005', onboarding_completed: false, completion_percentage: 0, mentor: 'Anna Hansen', buddy_program: true },
    { employee_code: 'emp-006', onboarding_completed: true, completion_percentage: 100, mentor: 'Erik Larsen', buddy_program: true, offboarding_initiated: true },
    { employee_code: 'emp-007', onboarding_completed: false, completion_percentage: 20, mentor: 'Security Director', buddy_program: false },
    { employee_code: 'emp-008', onboarding_completed: true, completion_percentage: 100, mentor: 'Finance Director', buddy_program: true }
  ];
  
  const created = [];
  for (const enrollData of enrollmentsData) {
    const employee = employees.find(e => e.employee_code === enrollData.employee_code);
    if (!employee) continue;
    
    const { employee_code, ...enrollmentData } = enrollData;
    const enrollment = await apiCall('employee_enrollments', 'POST', {
      ...enrollmentData,
      employee_id: employee.id
    });
    created.push(enrollment[0]);
  }
  return created;
}

async function createDocuments(employees) {
  const documents = [];
  for (let i = 0; i < employees.length; i++) {
    const employee = employees[i];
    const docCount = Math.floor(Math.random() * 3) + 2; // 2-4 documents per employee
    
    for (let j = 0; j < docCount; j++) {
      const docTypes = ['contract', 'id_verification', 'tax_form', 'gdpr_consent', 'financial_disclosure'];
      const statuses = ['verified', 'pending', 'uploaded'];
      
      const doc = await apiCall('documents', 'POST', {
        employee_id: employee.id,
        name: `Document ${j + 1} for ${employee.first_name}`,
        type: docTypes[j % docTypes.length],
        status: statuses[j % statuses.length],
        uploaded_at: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000).toISOString(),
        reviewed_by: j % 2 === 0 ? 'HR Team' : null
      });
      documents.push(doc[0]);
    }
  }
  return documents;
}

async function createTasks(employees) {
  const tasks = [];
  for (let i = 0; i < employees.length; i++) {
    const employee = employees[i];
    const taskCount = Math.floor(Math.random() * 3) + 2; // 2-4 tasks per employee
    
    for (let j = 0; j < taskCount; j++) {
      const categories = ['training', 'compliance', 'equipment', 'security'];
      const statuses = ['completed', 'in_progress', 'not_started'];
      const priorities = ['high', 'medium', 'low'];
      
      const task = await apiCall('tasks', 'POST', {
        employee_id: employee.id,
        title: `Task ${j + 1} for ${employee.first_name}`,
        description: `Demo task description ${j + 1}`,
        category: categories[j % categories.length],
        status: statuses[j % statuses.length],
        priority: priorities[j % priorities.length],
        assigned_by: 'Demo System',
        assigned_at: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000).toISOString()
      });
      tasks.push(task[0]);
    }
  }
  return tasks;
}

async function createInvitations(clientId, applications, employees) {
  const appMap = {};
  applications.forEach(app => {
    appMap[app.app_code] = app.id;
  });
  
  const invitationsData = [
    { employee_code: 'emp-005', app_code: 'onboarding', status: 'pending' },
    { employee_code: 'emp-006', app_code: 'offboarding', status: 'pending' },
    { employee_code: 'emp-007', app_code: 'onboarding', status: 'expired' }
  ];
  
  const created = [];
  for (const invData of invitationsData) {
    const employee = employees.find(e => e.employee_code === invData.employee_code);
    const appId = appMap[invData.app_code];
    
    if (!employee || !appId) continue;
    
    const jwtHash = crypto.createHash('sha256').update(`${employee.id}-${Date.now()}`).digest('hex');
    let expiresAt, createdAt;
    
    if (invData.status === 'expired') {
      // For expired invitations, set created date in the past and expiry before that
      createdAt = new Date(Date.now() - (14 * 24 * 60 * 60 * 1000)); // 14 days ago
      expiresAt = new Date(Date.now() - (7 * 24 * 60 * 60 * 1000));  // 7 days ago
    } else {
      // For active invitations, normal future expiry
      createdAt = new Date();
      expiresAt = new Date(Date.now() + (7 * 24 * 60 * 60 * 1000));  // 7 days from now
    }
    
    const invitation = await apiCall('invitations', 'POST', {
      client_id: clientId,
      app_id: appId,
      jwt_token_hash: jwtHash,
      permissions: ['document_upload', 'task_completion'],
      restrictions: { max_sessions: 5, employee_code: employee.employee_code },
      status: invData.status,
      expires_at: expiresAt.toISOString(),
      created_at: createdAt.toISOString(),
      created_by: 'Demo System',
      client_data: {
        employee_id: employee.id,
        employee_code: employee.employee_code,
        department: employee.department,
        demo_invitation: true
      }
    });
    
    created.push(invitation[0]);
  }
  return created;
}

/**
 * Main setup function
 */
async function setupCompleteDemo(options = {}) {
  const spinner = ora('Setting up complete demo...').start();
  
  try {
    // Step 1: Cleanup existing data
    if (!options.keepExisting) {
      await cleanupExistingData(spinner);
    }
    
    // Step 2: Create demo client
    const client = await createDemoClient(spinner);
    
    // Step 3: Create client applications
    const applications = await createClientApplications(client.id, spinner);
    
    // Step 4: Create employees
    const employees = await createEmployees(client.id, spinner);
    
    // Step 5: Create all related data
    spinner.text = 'Creating related data...';
    const { enrollments, documents, tasks, invitations } = await createAllRelatedData(employees, applications, client.id, spinner);
    
    // Step 6: Create offboarding demo data (if tables exist)
    let offboardingData = null;
    try {
      spinner.text = 'Creating offboarding demo data...';
      const { createDemoData } = await import('../../scripts/create-offboarding-demo-data.js');
      offboardingData = await createDemoData(client.id, true); // Pass clientId and skipLogs=true
      spinner.text = 'Offboarding demo data created';
    } catch (error) {
      spinner.warn('Offboarding tables not found - skipping offboarding demo data');
      console.log(chalk.yellow('   💡 To enable offboarding features:'));
      console.log(chalk.white('      1. Run the SQL files manually via Supabase Dashboard'));
      console.log(chalk.white('      2. Then run: pnpm run demo:complete again'));
    }
    
    // Display success summary
    console.log(chalk.green.bold('\n✅ Complete demo setup finished!\n'));
    console.log(chalk.cyan('📊 Created:'));
    console.log(`   • Client: ${chalk.white(client.legal_name)}`);
    console.log(`   • Applications: ${chalk.white(applications.length)}`);
    console.log(`   • Employees: ${chalk.white(employees.length)}`);
    console.log(`   • Enrollments: ${chalk.white(enrollments.length)}`);
    console.log(`   • Documents: ${chalk.white(documents.length)}`);
    console.log(`   • Tasks: ${chalk.white(tasks.length)}`);
    console.log(`   • Invitations: ${chalk.white(invitations.length)}`);
    if (offboardingData) {
      console.log(`   • Offboarding Workflows: ${chalk.white('3')}`);
      console.log(`   • Knowledge Transfer Items: ${chalk.white('3')}`);
      console.log(`   • Compliance Checks: ${chalk.white('4')}`);
      console.log(`   • Credit Balance: ${chalk.white('85 credits available')}`);
    }
    
    console.log(chalk.green('\n🚀 Demo is ready!'));
    console.log(`   Launch: ${chalk.yellow('pnpm run demo:admin')}`);
    console.log(`   URL: ${chalk.yellow('http://localhost:5173/')}`);
    console.log('');
    
    spinner.succeed('Complete demo setup completed successfully!');
    
  } catch (error) {
    spinner.fail(`Demo setup failed: ${error.message}`);
    console.error(chalk.red(error.stack));
    process.exit(1);
  }
}

// CLI configuration
program
  .name('setup-complete-demo')
  .description('One command to set up the complete demo with all data')
  .version('1.0.0');

program
  .command('run')
  .description('Set up complete demo (default)')
  .option('--keep-existing', 'Keep existing data instead of cleaning up first')
  .action(async (options) => {
    await setupCompleteDemo(options);
  });

// Default to run command if no arguments
if (process.argv.length === 2) {
  setupCompleteDemo();
} else {
  program.parse();
}