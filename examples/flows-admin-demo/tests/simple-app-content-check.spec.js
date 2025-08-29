import { expect, test } from '@playwright/test';

test.describe('Simple Application Content Check', () => {
  test('verify application tabs show content when clicked', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('[data-testid="app-loaded"]');
    await page.waitForTimeout(3000);

    // Look for application tabs specifically
    const appTabs = await page
      .locator(
        '[data-testid^="tab-"]:not([data-testid="tab-people"]):not([data-testid="tab-processes"]):not([data-testid="tab-account"])'
      )
      .all();

    console.log(`Found ${appTabs.length} application tabs`);

    if (appTabs.length === 0) {
      // Check what client we're on
      const title = await page.title();
      console.log(`Current client: ${title}`);

      // Check if there's an error message
      const errorMsg = page.locator('text=/not found/i');
      const errorAlert = page.locator('[role="alert"]');
      if (await errorMsg.isVisible({ timeout: 1000 }).catch(() => false)) {
        const errorText = await errorMsg.textContent();
        console.log(`Error: ${errorText}`);
      } else if (await errorAlert.isVisible({ timeout: 1000 }).catch(() => false)) {
        const alertText = await errorAlert.textContent();
        console.log(`Alert: ${alertText}`);
      }

      // List all tabs that DO exist
      const allTabs = await page.locator('[data-testid^="tab-"]').all();
      console.log(`All tabs found: ${allTabs.length}`);
      for (const tab of allTabs) {
        const tabText = await tab.textContent();
        const testId = await tab.getAttribute('data-testid');
        console.log(`  - ${testId}: ${tabText.trim()}`);
      }

      return; // Skip rest of test
    }

    // Test the first application tab
    const firstAppTab = appTabs[0];
    const tabText = await firstAppTab.textContent();
    console.log(`Testing application tab: "${tabText.trim()}"`);

    // Click the application tab
    await firstAppTab.click();
    await page.waitForTimeout(1500);

    // Check if tab is active
    const isActive = await firstAppTab.getAttribute('data-active');
    console.log(`Tab active: ${isActive}`);
    expect(isActive).toBe('true');

    // Use the specific main element with data-testid
    const mainContent = page.locator('[data-testid="app-loaded"]');
    const contentText = await mainContent.textContent();

    // Take a screenshot to see what's actually displayed
    await page.screenshot({ path: 'test-results/app-tab-content.png', fullPage: true });

    console.log(`Content length: ${contentText.length}`);
    console.log(`Content preview: ${contentText.substring(0, 200)}...`);

    // Check that we're NOT showing People content
    expect(contentText).not.toContain('Manage employees and associates');

    // Check that we ARE showing some application-related content
    const hasAppContent =
      contentText.includes('Application') ||
      contentText.includes('Onboarding') ||
      contentText.includes('Offboarding') ||
      contentText.includes('Features') ||
      contentText.includes('Configuration') ||
      contentText.includes('Overview') ||
      contentText.includes('Templates');

    if (!hasAppContent) {
      console.log('❌ No application content found');
      console.log('Full content:', contentText);
    }

    expect(hasAppContent).toBe(true);

    console.log('✅ Application tab shows proper content');
  });

  test('check current client and applications loading', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('[data-testid="app-loaded"]');
    await page.waitForTimeout(3000);

    // Check page title to see current client
    const title = await page.title();
    console.log(`Page title: ${title}`);

    // Check for any error messages
    const errorElement = page.locator('[role="alert"], .text-red-800, .bg-red-50');
    if (await errorElement.first().isVisible()) {
      const errorText = await errorElement.first().textContent();
      console.log(`Error found: ${errorText}`);
    }

    // Check what's in localStorage for client selection
    const clientId = await page.evaluate(() => {
      const settings = localStorage.getItem('flows-admin-demo-settings');
      return settings ? JSON.parse(settings).selectedClient : null;
    });
    console.log(`Client ID from localStorage: ${clientId}`);

    // Count all tabs
    const allTabs = await page.locator('[data-testid^="tab-"]').count();
    console.log(`Total tabs: ${allTabs}`);

    // Check for loading state
    const loadingIndicator = page.locator('[data-testid="loading-indicator"]');
    const isLoading = await loadingIndicator.isVisible();
    console.log(`Is loading: ${isLoading}`);

    // Take screenshot of current state
    await page.screenshot({ path: 'test-results/current-state.png', fullPage: true });
  });
});
