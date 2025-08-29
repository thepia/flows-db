/**
 * Global setup for Playwright tests
 * This runs once before all tests
 */

export default async function globalSetup() {
  console.log('🚀 Starting global test setup...');

  // Set up test environment variables
  process.env.NODE_ENV = 'test';

  // Any global setup tasks can go here
  // - Database seeding
  // - Authentication setup
  // - Test data generation

  console.log('✅ Global test setup complete');
}
