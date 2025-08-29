import { expect, test } from '@playwright/test';

test.describe('Debug Conditional Path', () => {
  test('should check which conditional path is being taken', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('[data-testid="app-loaded"]');
    await page.waitForTimeout(3000);

    // Click application tab
    const appTab = page.locator('[data-testid="tab-employee-onboarding"]');
    await appTab.click();
    await page.waitForTimeout(1500);

    // Check for different conditional indicators
    const loadingIndicator = page.locator('[data-testid="loading-indicator"]');
    const errorElement = page.locator('.bg-red-50');
    const debugIndicator = page.locator('text="DEBUG: Application content section reached"');
    const peopleView = page.locator('[data-testid="view-people"]');
    const processesView = page.locator('[data-testid="view-processes"]');
    const accountView = page.locator('[data-testid="view-account"]');

    const isLoading = await loadingIndicator.isVisible();
    const hasError = await errorElement.isVisible();
    const hasDebug = await debugIndicator.isVisible();
    const isPeopleVisible = await peopleView.isVisible();
    const isProcessesVisible = await processesView.isVisible();
    const isAccountVisible = await accountView.isVisible();

    console.log('Conditional path analysis:');
    console.log(`- Loading state: ${isLoading}`);
    console.log(`- Error state: ${hasError}`);
    console.log(`- Debug indicator (app content): ${hasDebug}`);
    console.log(`- People view: ${isPeopleVisible}`);
    console.log(`- Processes view: ${isProcessesVisible}`);
    console.log(`- Account view: ${isAccountVisible}`);

    // Take screenshot
    await page.screenshot({
      path: 'test-results/conditional-path-debug.png',
      fullPage: true,
    });

    // Check the actual main content HTML
    const mainContent = await page.locator('[data-testid="app-loaded"]').innerHTML();
    console.log(`\\nMain content length: ${mainContent.length}`);
    console.log(`Main content preview (first 300 chars):`);
    console.log(mainContent.substring(0, 300));

    console.log('\\n✅ Conditional path analysis completed');
  });
});
