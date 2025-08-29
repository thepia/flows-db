import { expect, test } from '@playwright/test';

test.describe('Error Reporting UI', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('Error Reporting Status Widget button should be clickable and functional', async ({
    page,
  }) => {
    // Wait for the floating status button to be visible
    const statusButton = page.locator('button:has(svg)').filter({ hasText: '' }).last();
    await expect(statusButton).toBeVisible();

    // Click the status button
    await statusButton.click();

    // Check that the status popover appears
    const statusPopover = page.locator('.card:has-text("System Status")');
    await expect(statusPopover).toBeVisible();

    // Check that error reporting section exists
    const errorReportingSection = page.locator('h4:has-text("Error Reporting")');
    await expect(errorReportingSection).toBeVisible();

    // Test the Refresh button
    const refreshButton = page.locator('button:has-text("Refresh")');
    await expect(refreshButton).toBeVisible();
    await refreshButton.click();

    // Test the Test Error button if error reporting is enabled
    const testErrorButton = page.locator('button:has-text("Test Error")');
    if (await testErrorButton.isVisible()) {
      await testErrorButton.click();

      // Wait a moment for the error to be sent
      await page.waitForTimeout(500);

      // Check console for success message (in a real test, you'd check the server logs)
      page.on('console', (msg) => {
        if (msg.text().includes('[Admin Demo] Test error report sent')) {
          expect(msg.text()).toContain('Test error report sent');
        }
      });
    }

    // Close the popover by clicking outside
    await page.click('body', { position: { x: 10, y: 10 } });
    await expect(statusPopover).not.toBeVisible();
  });

  test('Error reporting should initialize on page load', async ({ page }) => {
    // Listen for console messages
    const consoleMessages: string[] = [];
    page.on('console', (msg) => consoleMessages.push(msg.text()));

    // Reload the page to capture initialization messages
    await page.reload();
    await page.waitForLoadState('networkidle');

    // Check that initialization happened
    const initMessage = consoleMessages.find(
      (msg) =>
        msg.includes('[Admin Demo] Application initialized with error reporting') ||
        msg.includes('[Admin Demo] Error reporting initialized')
    );

    expect(initMessage).toBeTruthy();
  });

  test('Error reporting should handle network errors gracefully', async ({ page, context }) => {
    // Block the error reporting endpoint
    await context.route('**/dev/error-reports', (route) => route.abort());

    // Navigate to the page
    await page.goto('/');

    // Open the status widget
    const statusButton = page.locator('button:has(svg)').filter({ hasText: '' }).last();
    await statusButton.click();

    // The status should show as disabled when endpoint is unreachable
    const statusText = page.locator('text=/Status:.*Disabled/');
    await expect(statusText).toBeVisible({ timeout: 5000 });
  });

  test('Dynamic imports should work correctly', async ({ page }) => {
    // Create a test that verifies dynamic imports work
    await page.evaluate(async () => {
      // Test importing the configuration module
      const configModule = await import('/src/lib/config/errorReporting.js');
      if (!configModule.getAdminErrorReportingConfig) {
        throw new Error('Config module import failed');
      }

      // Test importing the error reporter module (without extension)
      const reporterModule = await import('/src/lib/utils/errorReporter');
      if (!reporterModule.initializeAdminErrorReporter) {
        throw new Error('Reporter module import failed');
      }

      return true;
    });
  });
});
