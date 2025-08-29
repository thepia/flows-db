/**
 * Global teardown for Playwright tests
 * This runs once after all tests
 */

export default async function globalTeardown() {
  console.log('🧹 Starting global test teardown...');

  // Any global cleanup tasks can go here
  // - Database cleanup
  // - Test data removal
  // - Resource cleanup

  console.log('✅ Global test teardown complete');
}
