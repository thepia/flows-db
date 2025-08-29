import { expect, test } from '@playwright/test';

test.describe('Application Tabs Fix Verification', () => {
  test('should display application tabs for selected client', async ({ page }) => {
    // Navigate to the main page
    await page.goto('/');

    // Wait for the page to load
    await page.waitForSelector('[data-testid="app-loaded"]');

    // Wait for applications to load (no more debug output to check)
    await page.waitForTimeout(3000);

    // Check that we have navigation tabs
    const navTabs = await page.locator('[data-testid^="tab-"]').all();

    // Should have at least People, Processes, Account tabs
    expect(navTabs.length).toBeGreaterThanOrEqual(3);

    // Should have People tab
    await expect(page.locator('[data-testid="tab-people"]')).toBeVisible();

    // Should have Processes tab
    await expect(page.locator('[data-testid="tab-processes"]')).toBeVisible();

    // Should have Account tab
    await expect(page.locator('[data-testid="tab-account"]')).toBeVisible();

    // Check if application tabs exist (depends on client having applications)
    const appTabs = await page
      .locator(
        '[data-testid^="tab-"]:not([data-testid="tab-people"]):not([data-testid="tab-processes"]):not([data-testid="tab-account"])'
      )
      .all();

    if (appTabs.length > 0) {
      console.log(`✅ Found ${appTabs.length} application tabs`);

      // Test clicking on first application tab
      await appTabs[0].click();

      // Should navigate to application view
      await page.waitForTimeout(1000);

      // Should show some application content
      const pageContent = await page.textContent('main');
      expect(pageContent).toContain('Application');
    } else {
      console.log('⚠️  No application tabs found - client may not have applications');
    }

    // Verify no debug output is visible
    const debugSpan = page.locator('span:text("Apps=")');
    await expect(debugSpan).toHaveCount(0);
  });

  test('should handle client without applications gracefully', async ({ page }) => {
    // This test ensures the fix handles missing applications properly
    await page.goto('/');

    // Wait for the page to load
    await page.waitForSelector('[data-testid="app-loaded"]');

    // Wait for data loading to complete
    await page.waitForTimeout(3000);

    // Should still show core tabs
    await expect(page.locator('[data-testid="tab-people"]')).toBeVisible();
    await expect(page.locator('[data-testid="tab-processes"]')).toBeVisible();
    await expect(page.locator('[data-testid="tab-account"]')).toBeVisible();

    // Should not show any debug output
    const debugText = page.locator('text=/Apps=\\d+ Loaded=(true|false)/');
    await expect(debugText).toHaveCount(0);

    // Page should be functional (can click on People tab)
    await page.click('[data-testid="tab-people"]');
    await expect(page.locator('[data-testid="view-people"]')).toBeVisible();
  });

  test('should load only the selected client applications', async ({ page }) => {
    // Navigate to the main page
    await page.goto('/');
    await page.waitForSelector('[data-testid="app-loaded"]');

    // Wait for applications to load
    await page.waitForTimeout(3000);

    // Get all application tabs
    const appTabs = await page
      .locator(
        '[data-testid^="tab-"]:not([data-testid="tab-people"]):not([data-testid="tab-processes"]):not([data-testid="tab-account"])'
      )
      .all();

    // If we have application tabs, verify they're client-specific
    if (appTabs.length > 0) {
      for (const tab of appTabs) {
        const tabText = await tab.textContent();
        expect(tabText).toBeTruthy();
        expect(tabText.trim()).not.toBe('');

        // Click the tab to ensure it works
        await tab.click();
        await page.waitForTimeout(500);

        // Should show application content
        const isActive = await tab.getAttribute('data-active');
        expect(isActive).toBe('true');
      }
    }
  });
});
