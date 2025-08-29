import { expect, test } from '@playwright/test';

test.describe('Applications Tabs Rendering', () => {
  test.beforeEach(async ({ page }) => {
    // Start from a clean state
    await page.goto('/');

    // Wait for the page to be fully loaded
    await page.waitForLoadState('networkidle');

    // Wait for applications to load (check debug text)
    await page.waitForFunction(
      () => {
        const debugSpan = document.querySelector('span.text-blue-500.text-xs');
        return debugSpan && debugSpan.textContent && debugSpan.textContent.includes('Loaded=true');
      },
      { timeout: 10000 }
    );
  });

  test('should display application tabs after data loads', async ({ page }) => {
    // Wait for loading to complete
    await page.waitForSelector('[data-testid="loading-indicator"]', {
      state: 'hidden',
      timeout: 10000,
    });

    // Check if any application tabs are visible
    const applicationTabs = await page
      .locator('[data-testid^="tab-"][data-testid$="boarding"]')
      .all();

    console.log(`Found ${applicationTabs.length} application tabs`);

    // Should have at least one application tab
    expect(applicationTabs.length).toBeGreaterThan(0);

    // Log what tabs were found
    for (const tab of applicationTabs) {
      const testId = await tab.getAttribute('data-testid');
      const text = await tab.textContent();
      console.log(`Tab found: ${testId} with text: ${text}`);
    }
  });

  test('should show debug text with application count', async ({ page }) => {
    // Wait for loading to complete
    await page.waitForSelector('[data-testid="loading-indicator"]', {
      state: 'hidden',
      timeout: 10000,
    });

    // Look for the debug text
    const debugText = await page.locator('span.text-blue-500.text-xs').textContent();
    console.log(`Debug text found: ${debugText}`);

    // Should show a number
    expect(debugText).toMatch(/Apps=\d+/);

    // Extract the number
    const match = debugText.match(/Apps=(\d+)/);
    if (match) {
      const appCount = Number.parseInt(match[1]);
      console.log(`Application count: ${appCount}`);
      expect(appCount).toBeGreaterThan(0);
    }
  });

  test('should have correct reactive behavior', async ({ page }) => {
    // Enable console logging
    page.on('console', (msg) => {
      if (msg.text().includes('Applications')) {
        console.log('Browser console:', msg.text());
      }
    });

    // Navigate to the page
    await page.goto('/');

    // Wait for applications to load
    await page.waitForFunction(
      () => {
        // Check if the debug span exists and has content
        const debugSpan = document.querySelector('span.text-blue-500.text-xs');
        return debugSpan && debugSpan.textContent && debugSpan.textContent !== 'Apps=0';
      },
      { timeout: 10000 }
    );

    // Verify the applications loaded message appears in console
    const messages = await page.evaluate(() => {
      // Get console messages that were logged
      return window.consoleMessages || [];
    });

    console.log('Captured console messages:', messages);
  });

  test('should render specific application tabs', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('[data-testid="loading-indicator"]', {
      state: 'hidden',
      timeout: 10000,
    });

    // Look for specific tabs (using actual test IDs from the system)
    const onboardingTab = page.locator('[data-testid="tab-employee-onboarding"]');
    const offboardingTab = page.locator('[data-testid="tab-knowledge-offboarding"]');

    // Check visibility
    const onboardingVisible = await onboardingTab.isVisible().catch(() => false);
    const offboardingVisible = await offboardingTab.isVisible().catch(() => false);

    console.log('Onboarding tab visible:', onboardingVisible);
    console.log('Offboarding tab visible:', offboardingVisible);

    // At least one should be visible
    expect(onboardingVisible || offboardingVisible).toBe(true);
  });

  test('should auto-select first application tab if no valid tab selected', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('[data-testid="loading-indicator"]', {
      state: 'hidden',
      timeout: 10000,
    });

    // Check which tab is active
    const activeTab = await page.locator('[data-active="true"]').first();
    const activeTabId = await activeTab.getAttribute('data-testid');

    console.log('Active tab:', activeTabId);

    // Should have an active tab
    expect(activeTabId).toBeTruthy();
  });
});
