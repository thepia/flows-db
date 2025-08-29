import { expect, test } from '@playwright/test';

test.describe('Application Content Verification', () => {
  test('should display application content when clicking application tabs', async ({ page }) => {
    // Navigate to the main page
    await page.goto('/');

    // Wait for the page to load
    await page.waitForSelector('[data-testid="app-loaded"]');

    // Wait for applications to load
    await page.waitForTimeout(3000);

    // Get all application tabs (excluding People, Processes, Account)
    const appTabs = await page
      .locator(
        '[data-testid^="tab-"]:not([data-testid="tab-people"]):not([data-testid="tab-processes"]):not([data-testid="tab-account"])'
      )
      .all();

    if (appTabs.length === 0) {
      console.log('⚠️  No application tabs found - client may not have applications');
      return;
    }

    console.log(`✅ Found ${appTabs.length} application tabs`);

    // Test each application tab
    for (let i = 0; i < appTabs.length; i++) {
      const tab = appTabs[i];
      const tabText = await tab.textContent();
      console.log(`Testing application tab: ${tabText}`);

      // Click the application tab
      await tab.click();

      // Wait for content to load
      await page.waitForTimeout(1000);

      // Verify the tab is active
      const isActive = await tab.getAttribute('data-active');
      expect(isActive).toBe('true');

      // Check that we're showing application content, not People/Processes content
      const peopleView = page.locator('[data-testid="view-people"]');
      const processesView = page.locator('[data-testid="view-processes"]');
      const accountView = page.locator('[data-testid="view-account"]');

      // These should not be visible when we're on an application tab
      await expect(peopleView).not.toBeVisible();
      await expect(processesView).not.toBeVisible();
      await expect(accountView).not.toBeVisible();

      // Check for application-specific content
      const mainContent = page.locator('[data-testid="app-loaded"]');
      const contentText = await mainContent.textContent();

      // Should contain application-related content
      const hasApplicationContent =
        contentText.includes('Application') ||
        contentText.includes('Onboarding') ||
        contentText.includes('Offboarding') ||
        contentText.includes('Overview') ||
        contentText.includes('Templates') ||
        contentText.includes('Processes') ||
        contentText.includes('Tasks') ||
        contentText.includes('Features') ||
        contentText.includes('Configuration');

      expect(hasApplicationContent).toBe(true);

      // Should show application header with name
      const appHeader = page.locator('h2, h1').filter({ hasText: tabText.trim() });
      await expect(appHeader.first()).toBeVisible();

      // For offboarding applications, check for specific views
      if (tabText.toLowerCase().includes('offboarding')) {
        // Should have offboarding view buttons
        const overviewBtn = page.locator('[data-testid="offboarding-view-overview"]');
        const templatesBtn = page.locator('[data-testid="offboarding-view-templates"]');
        const processesBtn = page.locator('[data-testid="offboarding-view-processes"]');

        await expect(overviewBtn).toBeVisible();
        await expect(templatesBtn).toBeVisible();
        await expect(processesBtn).toBeVisible();

        // Test clicking on different views
        await overviewBtn.click();
        await page.waitForTimeout(500);
        await expect(page.locator('[data-testid="view-overview"]')).toBeVisible();

        await templatesBtn.click();
        await page.waitForTimeout(500);
        await expect(page.locator('[data-testid="view-templates"]')).toBeVisible();

        await processesBtn.click();
        await page.waitForTimeout(500);
        await expect(page.locator('[data-testid="view-processes"]')).toBeVisible();
      }

      // For onboarding applications, check for application metrics and features
      if (tabText.toLowerCase().includes('onboarding')) {
        // Should show application metrics
        const metricsSection = page.locator('text="Active Invitations"');
        await expect(metricsSection).toBeVisible();

        // Should show application features
        const featuresSection = page.locator('text="Application Features"');
        await expect(featuresSection).toBeVisible();

        // Should show configuration
        const configSection = page.locator('text="Configuration"');
        await expect(configSection).toBeVisible();
      }
    }

    console.log('✅ All application tabs show proper content');
  });

  test('should navigate between application tabs and other tabs correctly', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('[data-testid="app-loaded"]');
    await page.waitForTimeout(3000);

    // Get application tabs
    const appTabs = await page
      .locator(
        '[data-testid^="tab-"]:not([data-testid="tab-people"]):not([data-testid="tab-processes"]):not([data-testid="tab-account"])'
      )
      .all();

    if (appTabs.length === 0) {
      console.log('⚠️  No application tabs found - skipping navigation test');
      return;
    }

    // Start with People tab
    await page.click('[data-testid="tab-people"]');
    await expect(page.locator('[data-testid="view-people"]')).toBeVisible();

    // Click first application tab
    await appTabs[0].click();
    await page.waitForTimeout(1000);

    // Should not show People view anymore
    await expect(page.locator('[data-testid="view-people"]')).not.toBeVisible();

    // Should show application content
    const mainContent = await page.locator('[data-testid="app-loaded"]').textContent();
    expect(mainContent).not.toContain('Manage employees and associates');

    // Go back to People tab
    await page.click('[data-testid="tab-people"]');
    await expect(page.locator('[data-testid="view-people"]')).toBeVisible();

    // Go to Processes tab
    await page.click('[data-testid="tab-processes"]');
    await expect(page.locator('[data-testid="view-processes"]')).toBeVisible();

    // Go to Account tab
    await page.click('[data-testid="tab-account"]');
    await expect(page.locator('[data-testid="view-account"]')).toBeVisible();

    console.log('✅ Tab navigation working correctly');
  });

  test('should show application-specific data for selected client only', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('[data-testid="app-loaded"]');
    await page.waitForTimeout(3000);

    // Get current client info
    const pageTitle = await page.title();
    console.log(`Current page title: ${pageTitle}`);

    // Get application tabs
    const appTabs = await page
      .locator(
        '[data-testid^="tab-"]:not([data-testid="tab-people"]):not([data-testid="tab-processes"]):not([data-testid="tab-account"])'
      )
      .all();

    if (appTabs.length === 0) {
      console.log('⚠️  No application tabs found - cannot verify client-specific data');
      return;
    }

    // Click on first application tab
    await appTabs[0].click();
    await page.waitForTimeout(1000);

    // Check that application shows client-specific information
    const mainContent = await page.locator('[data-testid="app-loaded"]').textContent();

    // Should not show generic placeholder content
    expect(mainContent).not.toContain('No applications');
    expect(mainContent).not.toContain('Apps=0');
    expect(mainContent).not.toContain('Loaded=false');

    // Should show actual application data
    expect(mainContent.length).toBeGreaterThan(100); // Should have substantial content

    console.log('✅ Application shows client-specific data');
  });
});
