import { expect, test } from '@playwright/test';

test.describe('Debug Applications Data', () => {
  test('should examine applications data in browser', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('[data-testid="app-loaded"]');
    await page.waitForTimeout(3000);

    // Try to access the applications data
    const applicationsData = await page.evaluate(() => {
      // Look for applications data in the global scope
      // In Svelte, stores might be accessible somehow
      if (window.__SVELTE_STORES__) {
        return window.__SVELTE_STORES__;
      }

      // Alternative: look for data attributes or other traces
      const appButtons = Array.from(
        document.querySelectorAll(
          '[data-testid^="tab-"]:not([data-testid="tab-people"]):not([data-testid="tab-processes"]):not([data-testid="tab-account"])'
        )
      );

      return {
        appButtonsCount: appButtons.length,
        appButtonsData: appButtons.map((btn) => ({
          testId: btn.getAttribute('data-testid'),
          text: btn.textContent.trim(),
          active: btn.getAttribute('data-active'),
        })),
      };
    });

    console.log('Applications UI data:', JSON.stringify(applicationsData, null, 2));

    // Click each tab and examine the DOM state
    const appTabs = await page
      .locator(
        '[data-testid^="tab-"]:not([data-testid="tab-people"]):not([data-testid="tab-processes"]):not([data-testid="tab-account"])'
      )
      .all();

    for (let i = 0; i < appTabs.length; i++) {
      const tab = appTabs[i];
      const tabText = await tab.textContent();
      const testId = await tab.getAttribute('data-testid');

      console.log(`\\n--- Clicking ${tabText.trim()} ---`);
      await tab.click();
      await page.waitForTimeout(1500);

      // Check for conditional rendering indicators
      const hasSelectedApp = await page.evaluate(() => {
        // Look for elements that would indicate selectedApp exists
        const hasOffboardingView = !!document.querySelector(
          '[data-testid="offboarding-view-overview"]'
        );
        const hasMetricsView = Array.from(document.querySelectorAll('*')).some((el) =>
          el.textContent?.includes('Active Invitations')
        );
        const hasAppHeader = !!document.querySelector('main h2');

        return {
          hasOffboardingView,
          hasMetricsView,
          hasAppHeader,
          mainContentHTML:
            document.querySelector('main')?.innerHTML?.substring(0, 500) || 'No main content',
        };
      });

      console.log('DOM state after click:', JSON.stringify(hasSelectedApp, null, 2));

      // Take screenshot
      await page.screenshot({
        path: `test-results/debug-app-data-${i + 1}.png`,
        fullPage: true,
      });
    }

    console.log('\\n✅ Debug completed');
  });
});
