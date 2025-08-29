import { expect, test } from '@playwright/test';

test.describe('Debug Application Content', () => {
  test('should debug what happens when clicking application tabs', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('[data-testid="app-loaded"]');
    await page.waitForTimeout(3000);

    // Log current activeTab value
    const activeTab = await page.evaluate(() => {
      // Try to access the Svelte component's activeTab variable
      return window.location.href;
    });
    console.log('Current URL:', activeTab);

    // Get application tabs
    const appTabs = await page
      .locator(
        '[data-testid^="tab-"]:not([data-testid="tab-people"]):not([data-testid="tab-processes"]):not([data-testid="tab-account"])'
      )
      .all();

    if (appTabs.length === 0) {
      console.log('❌ No application tabs found');
      return;
    }

    console.log(`Found ${appTabs.length} application tabs`);

    for (let i = 0; i < appTabs.length; i++) {
      const tab = appTabs[i];
      const tabText = await tab.textContent();
      const testId = await tab.getAttribute('data-testid');
      const isActive = await tab.getAttribute('data-active');

      console.log(`\\nTab ${i + 1}: "${tabText.trim()}" (${testId}) - Active: ${isActive}`);

      // Click the tab
      console.log(`Clicking tab: ${tabText.trim()}`);
      await tab.click();
      await page.waitForTimeout(2000);

      // Check if tab is now active
      const newIsActive = await tab.getAttribute('data-active');
      console.log(`After click - Active: ${newIsActive}`);

      // Look for any visible application content
      const contentElements = await page.locator('main h1, main h2, main h3').all();
      console.log(`Found ${contentElements.length} headers in main content`);

      for (const header of contentElements) {
        const headerText = await header.textContent();
        if (headerText && headerText.trim()) {
          console.log(`  Header: "${headerText.trim()}"`);
        }
      }

      // Check for specific application content indicators
      const metricsVisible = await page
        .locator('text="Active Invitations"')
        .isVisible()
        .catch(() => false);
      const overviewBtnVisible = await page
        .locator('[data-testid="offboarding-view-overview"]')
        .isVisible()
        .catch(() => false);
      const templatesBtnVisible = await page
        .locator('[data-testid="offboarding-view-templates"]')
        .isVisible()
        .catch(() => false);

      console.log(`  Metrics dashboard visible: ${metricsVisible}`);
      console.log(`  Offboarding overview button visible: ${overviewBtnVisible}`);
      console.log(`  Offboarding templates button visible: ${templatesBtnVisible}`);

      // Get all text content to see what's actually rendered
      const allText = await page.locator('[data-testid="app-loaded"]').textContent();
      const contentLength = allText.length;
      const preview = allText.substring(0, 300).replace(/\\s+/g, ' ').trim();

      console.log(`  Total content length: ${contentLength}`);
      console.log(`  Content preview: "${preview}..."`);

      // Take a screenshot for this tab
      await page.screenshot({
        path: `test-results/debug-tab-${i + 1}-${testId}.png`,
        fullPage: true,
      });
    }

    // Check if applications are loaded in the store
    const applicationsData = await page.evaluate(() => {
      // Try to access applications data if available in window
      return {
        applicationsExists: typeof window !== 'undefined',
        href: window.location.href,
      };
    });

    console.log(`\\nBrowser state:`, applicationsData);

    console.log('\\n✅ Debug test completed');
  });
});
