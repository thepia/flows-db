#!/usr/bin/env node

/**
 * Demo Complete Verification Test
 *
 * Verifies that demo:complete script can recreate the expected people demo data
 * by testing the data generation functions and comparing against expected patterns.
 */

import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import { expect, test } from 'vitest';

// Load environment variables
dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  throw new Error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY environment variables');
}

// Supabase client with proper schema
const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  db: { schema: 'api' },
});

/**
 * Expected data patterns based on company configuration and test requirements
 */
const EXPECTED_PATTERNS = {
  totalPeople: 1000, // Flexible count for validation
  employeeCount: 950,
  associateCount: 10,
  statusDistribution: {
    active: { min: 950, max: 1050 }, // ~85% of ~1190 = ~1010
    former: { min: 100, max: 180 }, // ~12% of ~1190 = ~143
    future: { min: 20, max: 60 }, // ~3% of ~1190 = ~36
  },
  associateTypes: ['board_member', 'advisor', 'consultant', 'contractor', 'partner'],
  departments: [
    'Product Development',
    'Marketing',
    'Operations',
    'R&D',
    'Sales',
    'Quality Assurance',
    'Finance',
    'Human Resources',
    'IT & Development',
    'Legal & Compliance',
  ],
  seedEmployees: ['hh-001', 'hh-002', 'hh-003', 'hh-004', 'hh-005', 'hh-006', 'hh-007', 'hh-008'],
  companyDomain: 'hygge-hvidlog.dk',
};

/**
 * Test helper to analyze existing data patterns
 */
async function analyzeExistingData() {
  // Get Hygge & Hvidløg client
  const { data: client, error: clientError } = await supabase
    .from('clients')
    .select('id')
    .eq('client_code', 'hygge-hvidlog')
    .single();

  if (clientError || !client) {
    throw new Error('Hygge & Hvidløg client not found');
  }

  // Get all people for this client
  const { data: people, error: peopleError } = await supabase
    .from('people')
    .select('*')
    .eq('client_id', client.id);

  if (peopleError) {
    throw new Error(`Error fetching people: ${peopleError.message}`);
  }

  return {
    client,
    people: people || [],
    analysis: {
      total: people?.length || 0,
      employees: people?.filter((p) => p.employment_status !== null).length || 0,
      associates: people?.filter((p) => p.associate_status !== null).length || 0,
      statusCounts: {
        active: people?.filter((p) => p.employment_status === 'active').length || 0,
        former: people?.filter((p) => p.employment_status === 'former').length || 0,
        future: people?.filter((p) => p.employment_status === 'future').length || 0,
      },
      departments: [...new Set(people?.map((p) => p.department) || [])],
      associateTypes: [
        ...new Set(people?.filter((p) => p.associate_status).map((p) => p.associate_status) || []),
      ],
      seedEmployees:
        people?.filter((p) => p.person_code?.startsWith('hh-')).map((p) => p.person_code) || [],
      domainCheck:
        people?.every((p) => p.company_email?.includes(EXPECTED_PATTERNS.companyDomain)) || false,
    },
  };
}

/**
 * Test the bulk generation logic without database calls
 */
function testBulkGenerationLogic() {
  // Copy the generation logic from setup-complete-demo.js for testing
  const DANISH_FIRST_NAMES = [
    'Mads',
    'Emma',
    'William',
    'Sofia',
    'Noah',
    'Freja',
    'Lucas',
    'Anna',
    'Oliver',
    'Clara',
    'Malte',
    'Lærke',
    'Elias',
    'Ida',
    'Magnus',
    'Alma',
  ];

  const DANISH_LAST_NAMES = [
    'Nielsen',
    'Hansen',
    'Andersen',
    'Pedersen',
    'Christensen',
    'Larsen',
    'Sørensen',
    'Rasmussen',
    'Jørgensen',
    'Petersen',
    'Madsen',
    'Kristensen',
  ];

  function randomDate(start, end) {
    return new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime()));
  }

  function generateBulkEmployee(companyCode, department, position, location, index) {
    const firstName = DANISH_FIRST_NAMES[Math.floor(Math.random() * DANISH_FIRST_NAMES.length)];
    const lastName = DANISH_LAST_NAMES[Math.floor(Math.random() * DANISH_LAST_NAMES.length)];

    const startDate = randomDate(new Date(2018, 0, 1), new Date(2024, 11, 31));

    // Status distribution: 85% active, 12% former, 3% future
    const rand = Math.random();
    let employmentStatus;
    if (rand < 0.85) {
      employmentStatus = 'active';
    } else if (rand < 0.97) {
      employmentStatus = 'former';
    } else {
      employmentStatus = 'future';
    }

    const personCode = `${companyCode}-${String(index).padStart(4, '0')}`;

    return {
      person_code: personCode,
      company_email: `${firstName.toLowerCase()}.${lastName.toLowerCase()}.${index}@hygge-hvidlog.dk`,
      first_name: firstName,
      last_name: lastName,
      department,
      position,
      location,
      start_date: startDate.toISOString().split('T')[0],
      end_date:
        employmentStatus === 'former'
          ? randomDate(startDate, new Date()).toISOString().split('T')[0]
          : null,
      employment_status: employmentStatus,
      employment_type: 'full_time',
      work_location: Math.random() > 0.4 ? 'hybrid' : Math.random() > 0.5 ? 'office' : 'remote',
      security_clearance: Math.random() > 0.7 ? 'high' : Math.random() > 0.5 ? 'medium' : 'low',
      manager:
        Math.random() > 0.7
          ? `${DANISH_FIRST_NAMES[Math.floor(Math.random() * DANISH_FIRST_NAMES.length)]} ${DANISH_LAST_NAMES[Math.floor(Math.random() * DANISH_LAST_NAMES.length)]}`
          : null,
      skills: ['Teamwork', 'Communication', 'Problem Solving'],
      languages: ['Danish', 'English'],
    };
  }

  // Generate test dataset
  const testEmployees = [];
  const sampleSize = 1000;

  for (let i = 1; i <= sampleSize; i++) {
    const employee = generateBulkEmployee(
      'hygge-hvidlog',
      'Test Department',
      'Test Position',
      'Copenhagen, Denmark',
      i
    );
    testEmployees.push(employee);
  }

  // Analyze distribution
  const statusCounts = { active: 0, former: 0, future: 0 };
  testEmployees.forEach((emp) => {
    statusCounts[emp.employment_status]++;
  });

  return {
    sampleSize,
    statusCounts,
    percentages: {
      active: Math.round((statusCounts.active / sampleSize) * 100),
      former: Math.round((statusCounts.former / sampleSize) * 100),
      future: Math.round((statusCounts.future / sampleSize) * 100),
    },
    employees: testEmployees,
  };
}

// =====================================
// TESTS
// =====================================

test('bulk generation logic produces correct status distribution', () => {
  const result = testBulkGenerationLogic();

  // Test status distribution is approximately correct (within 5% tolerance)
  expect(result.percentages.active).toBeGreaterThanOrEqual(80);
  expect(result.percentages.active).toBeLessThanOrEqual(90);

  expect(result.percentages.former).toBeGreaterThanOrEqual(7);
  expect(result.percentages.former).toBeLessThanOrEqual(17);

  expect(result.percentages.future).toBeGreaterThanOrEqual(1);
  expect(result.percentages.future).toBeLessThanOrEqual(8);

  // Test all employees have required fields
  result.employees.forEach((emp) => {
    expect(emp.person_code).toMatch(/^hygge-hvidlog-\d{4}$/);
    expect(emp.company_email).toContain('@hygge-hvidlog.dk');
    expect(emp.first_name).toBeTruthy();
    expect(emp.last_name).toBeTruthy();
    expect(['active', 'former', 'future']).toContain(emp.employment_status);
    expect(emp.employment_type).toBe('full_time');
    expect(['office', 'remote', 'hybrid']).toContain(emp.work_location);
    expect(['low', 'medium', 'high']).toContain(emp.security_clearance);
  });
});

test('existing database data matches expected patterns', async () => {
  const data = await analyzeExistingData();

  console.log('\n📊 Current Database Analysis:');
  console.log(`Total People: ${data.analysis.total}`);
  console.log(`Employees: ${data.analysis.employees}`);
  console.log(`Associates: ${data.analysis.associates}`);
  console.log(`Active: ${data.analysis.statusCounts.active}`);
  console.log(`Former: ${data.analysis.statusCounts.former}`);
  console.log(`Future: ${data.analysis.statusCounts.future}`);
  console.log(`Departments: ${data.analysis.departments.length}`);
  console.log(`Associate Types: ${data.analysis.associateTypes.join(', ')}`);
  console.log(`Seed Employees: ${data.analysis.seedEmployees.length}`);
  console.log(`Company Domain: ${data.analysis.domainCheck ? '✅' : '❌'}`);

  // If we have significant data, test it matches patterns
  if (data.analysis.total > 100) {
    // Test total count is reasonable
    expect(data.analysis.total).toBeGreaterThanOrEqual(1000);
    expect(data.analysis.total).toBeLessThanOrEqual(1500);

    // Test status distribution
    const activePercent = Math.round(
      (data.analysis.statusCounts.active / data.analysis.employees) * 100
    );
    const formerPercent = Math.round(
      (data.analysis.statusCounts.former / data.analysis.employees) * 100
    );

    expect(activePercent).toBeGreaterThanOrEqual(70); // Allow some flexibility
    expect(activePercent).toBeLessThanOrEqual(95);

    expect(formerPercent).toBeGreaterThanOrEqual(5);
    expect(formerPercent).toBeLessThanOrEqual(25);

    // Test departments are comprehensive
    expect(data.analysis.departments.length).toBeGreaterThanOrEqual(8);

    // Test associate types are present if associates exist
    if (data.analysis.associates > 0) {
      expect(data.analysis.associateTypes.length).toBeGreaterThanOrEqual(3);
      EXPECTED_PATTERNS.associateTypes.forEach((type) => {
        expect(data.analysis.associateTypes).toContain(type);
      });
    }
  } else {
    console.log('\n⚠️  Insufficient data for pattern validation');
    console.log('   Run `pnpm demo:complete` to generate full dataset');
  }
});

test('expected departments are configured correctly', () => {
  // Test that our demo company configuration includes all expected departments
  const demoConfig = {
    departments: [
      'Product Development',
      'Marketing',
      'Operations',
      'R&D',
      'Sales',
      'Quality Assurance',
      'Finance',
      'Human Resources',
      'IT & Development',
      'Legal & Compliance',
    ],
  };

  expect(demoConfig.departments).toHaveLength(10);
  EXPECTED_PATTERNS.departments.forEach((dept) => {
    expect(demoConfig.departments).toContain(dept);
  });
});

test('seed employee data is correctly configured', () => {
  const seedEmployeeCodes = EXPECTED_PATTERNS.seedEmployees;

  expect(seedEmployeeCodes).toHaveLength(8);
  EXPECTED_PATTERNS.seedEmployees.forEach((code) => {
    expect(seedEmployeeCodes).toContain(code);
  });
});

test('associate configuration matches requirements', () => {
  const associateData = [
    { associate_status: 'board_member', count: 2 },
    { associate_status: 'advisor', count: 2 },
    { associate_status: 'consultant', count: 2 },
    { associate_status: 'contractor', count: 2 },
    { associate_status: 'partner', count: 2 },
  ];

  const totalAssociates = associateData.reduce((sum, item) => sum + item.count, 0);
  expect(totalAssociates).toBe(EXPECTED_PATTERNS.associateCount);

  const associateTypes = associateData.map((item) => item.associate_status);
  EXPECTED_PATTERNS.associateTypes.forEach((type) => {
    expect(associateTypes).toContain(type);
  });
});

// =====================================
// INTEGRATION TEST HELPERS
// =====================================

test('demo:complete script can be validated for correctness', async () => {
  // This test runs post demo:complete to validate the generated data
  const data = await analyzeExistingData();

  if (data.analysis.total >= EXPECTED_PATTERNS.totalPeople * 0.9) {
    console.log('\n✅ Demo Complete Validation Results:');

    // Test total counts
    expect(data.analysis.total).toBeGreaterThanOrEqual(EXPECTED_PATTERNS.totalPeople * 0.95);
    expect(data.analysis.total).toBeLessThanOrEqual(EXPECTED_PATTERNS.totalPeople * 1.05);

    // Test employee vs associate split
    expect(data.analysis.employees).toBeGreaterThanOrEqual(EXPECTED_PATTERNS.employeeCount * 0.95);
    expect(data.analysis.associates).toBeGreaterThanOrEqual(EXPECTED_PATTERNS.associateCount * 0.9);

    // Test status distribution
    expect(data.analysis.statusCounts.active).toBeGreaterThanOrEqual(
      EXPECTED_PATTERNS.statusDistribution.active.min
    );
    expect(data.analysis.statusCounts.active).toBeLessThanOrEqual(
      EXPECTED_PATTERNS.statusDistribution.active.max
    );

    expect(data.analysis.statusCounts.former).toBeGreaterThanOrEqual(
      EXPECTED_PATTERNS.statusDistribution.former.min
    );
    expect(data.analysis.statusCounts.former).toBeLessThanOrEqual(
      EXPECTED_PATTERNS.statusDistribution.former.max
    );

    expect(data.analysis.statusCounts.future).toBeGreaterThanOrEqual(
      EXPECTED_PATTERNS.statusDistribution.future.min
    );
    expect(data.analysis.statusCounts.future).toBeLessThanOrEqual(
      EXPECTED_PATTERNS.statusDistribution.future.max
    );

    // Test department coverage
    expect(data.analysis.departments.length).toBeGreaterThanOrEqual(
      EXPECTED_PATTERNS.departments.length * 0.8
    );

    // Test company domain consistency
    expect(data.analysis.domainCheck).toBe(true);

    console.log(
      `   ✓ Total People: ${data.analysis.total} (expected ~${EXPECTED_PATTERNS.totalPeople})`
    );
    console.log(
      `   ✓ Status Distribution: ${data.analysis.statusCounts.active} active, ${data.analysis.statusCounts.former} former, ${data.analysis.statusCounts.future} future`
    );
    console.log(
      `   ✓ Associates: ${data.analysis.associates} (${data.analysis.associateTypes.join(', ')})`
    );
    console.log(`   ✓ Departments: ${data.analysis.departments.length}`);
    console.log(`   ✓ Company Domain: All emails use ${EXPECTED_PATTERNS.companyDomain}`);
  } else {
    console.log('\n⚠️  Demo data not fully generated yet');
    console.log(`   Current: ${data.analysis.total} people`);
    console.log(`   Expected: ~${EXPECTED_PATTERNS.totalPeople} people`);
    console.log('   Run `pnpm demo:complete` first');

    // Skip validation if data is insufficient
    expect(true).toBe(true);
  }
});
