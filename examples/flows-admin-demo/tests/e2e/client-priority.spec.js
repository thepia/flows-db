/**
 * End-to-end regression test for client loading priority
 *
 * Tests that the demo loads the correct priority client and doesn't
 * fall back to hardcoded 'nets-demo' when hygge-hvidlog is available.
 */

import { expect, test } from '@playwright/test';

test.describe('Client Loading Priority (Regression)', () => {
  test('should load Hygge & Hvidløg as default client, not Nets A/S (Demo)', async ({ page }) => {
    // Navigate to the demo
    await page.goto('/');

    // Wait for the application to load
    await page.waitForLoadState('networkidle');

    // Wait for client data to load (look for the client name in header or settings)
    await page.waitForSelector('[data-testid="client-name"], .client-name, h1, h2', {
      timeout: 10000,
    });

    // Check multiple possible locations where client name might appear
    const clientNameSelectors = [
      '[data-testid="client-name"]',
      '.client-name',
      'h1',
      'h2',
      '[class*="client"]',
      '[class*="header"]',
    ];

    let clientNameFound = false;
    let actualClientName = '';

    for (const selector of clientNameSelectors) {
      try {
        const elements = await page.locator(selector).all();
        for (const element of elements) {
          const text = await element.textContent();
          if (
            text &&
            (text.includes('Hygge') || text.includes('Hvidløg') || text.includes('Nets'))
          ) {
            actualClientName = text.trim();
            clientNameFound = true;
            break;
          }
        }
        if (clientNameFound) break;
      } catch (e) {
        // Continue to next selector
      }
    }

    // Log what we found for debugging
    console.log('Found client name:', actualClientName);

    // The critical assertion: should NOT be Nets A/S (Demo)
    expect(actualClientName).not.toContain('Nets A/S (Demo)');
    expect(actualClientName).not.toContain('Nets A/S');

    // Should be Hygge & Hvidløg A/S
    expect(actualClientName).toContain('Hygge');
    expect(actualClientName).toContain('Hvidløg');
  });

  test('should show Hygge & Hvidløg employees in people table', async ({ page }) => {
    await page.goto('/people');

    // Wait for the table to load
    await page.waitForSelector('table, [data-testid="people-table"], .employee-list', {
      timeout: 10000,
    });

    // Check that we have a significant number of employees (hygge-hvidlog should have 1200)
    const employeeRows = await page.locator('tr, .employee-card, .person-row').count();

    // Should have more than just the 3 nets-demo employees
    expect(employeeRows).toBeGreaterThan(10);

    // Check for hygge-hvidlog employee codes
    const pageContent = await page.content();
    expect(pageContent).toContain('hygge-hvidlog-');

    // Should NOT contain old nets employee codes
    expect(pageContent).not.toContain('emp-001');
    expect(pageContent).not.toContain('emp-002');
    expect(pageContent).not.toContain('emp-003');
  });

  test('should maintain client selection after page refresh', async ({ page }) => {
    await page.goto('/');

    // Wait for initial load
    await page.waitForLoadState('networkidle');

    // Verify Hygge & Hvidløg is loaded
    await expect(page.locator('body')).toContainText('Hygge', { timeout: 10000 });

    // Refresh the page
    await page.reload();

    // Wait for reload
    await page.waitForLoadState('networkidle');

    // Should still show Hygge & Hvidløg, not revert to Nets
    await expect(page.locator('body')).toContainText('Hygge', { timeout: 10000 });
    await expect(page.locator('body')).not.toContainText('Nets A/S (Demo)');
  });

  test('should show correct branding for Hygge & Hvidløg', async ({ page }) => {
    await page.goto('/');

    // Wait for application to load
    await page.waitForLoadState('networkidle');

    // Check for Hygge & Hvidløg specific branding elements
    const pageContent = await page.content();

    // Should show the Danish food tech company branding
    expect(pageContent).toContain('Hygge');
    expect(pageContent).toContain('Hvidløg');

    // Check console logs for branding application
    const logs = [];
    page.on('console', (msg) => {
      if (msg.text().includes('Applied branding')) {
        logs.push(msg.text());
      }
    });

    // Reload to capture branding logs
    await page.reload();
    await page.waitForLoadState('networkidle');

    // Should have applied Hygge & Hvidløg branding
    const brandingLog = logs.find((log) => log.includes('Hygge & Hvidløg'));
    expect(brandingLog).toBeDefined();
  });

  test('settings panel should show Hygge & Hvidløg as active client', async ({ page }) => {
    await page.goto('/settings');

    // Wait for settings page to load
    await page.waitForLoadState('networkidle');

    // Look for client selection UI or current client display
    const settingsContent = await page.content();

    // Should show Hygge & Hvidløg as the current/active client
    expect(settingsContent).toContain('Hygge');
    expect(settingsContent).toContain('Hvidløg');

    // Should NOT show Nets as the active client
    expect(settingsContent).not.toContain('Nets A/S (Demo)');
  });
});
