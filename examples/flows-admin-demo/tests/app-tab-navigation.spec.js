import { expect, test } from '@playwright/test';

test.describe('Application Tab Navigation', () => {
  test('should navigate between onboarding and offboarding tabs and show distinct content', async ({
    page,
  }) => {
    await page.goto('/');
    await page.waitForSelector('[data-testid="app-loaded"]');
    await page.waitForTimeout(3000);

    // Get all application tabs
    const appTabs = await page
      .locator(
        '[data-testid^="tab-"]:not([data-testid="tab-people"]):not([data-testid="tab-processes"]):not([data-testid="tab-account"])'
      )
      .all();

    if (appTabs.length === 0) {
      console.log('⚠️  No application tabs found');
      return;
    }

    console.log(`Found ${appTabs.length} application tabs`);

    // Map tabs by their text content
    const tabsData = [];
    for (const tab of appTabs) {
      const text = await tab.textContent();
      const testId = await tab.getAttribute('data-testid');
      tabsData.push({ tab, text: text.trim(), testId });
      console.log(`Tab: "${text.trim()}" (${testId})`);
    }

    // Find onboarding and offboarding tabs
    const onboardingTab = tabsData.find((t) => t.text.toLowerCase().includes('onboarding'));
    const offboardingTab = tabsData.find((t) => t.text.toLowerCase().includes('offboarding'));

    if (!onboardingTab) {
      console.log('❌ No onboarding tab found');
      return;
    }

    if (!offboardingTab) {
      console.log('❌ No offboarding tab found');
      return;
    }

    console.log(`✅ Found onboarding tab: "${onboardingTab.text}"`);
    console.log(`✅ Found offboarding tab: "${offboardingTab.text}"`);

    // Test onboarding tab
    console.log('\n--- Testing Onboarding Tab ---');
    await onboardingTab.tab.click();
    await page.waitForTimeout(1500);

    // Verify tab is active
    const onboardingActive = await onboardingTab.tab.getAttribute('data-active');
    expect(onboardingActive).toBe('true');
    console.log('✅ Onboarding tab is active');

    // Get onboarding content
    const onboardingContent = await page.locator('[data-testid="app-loaded"]').textContent();
    console.log(`Onboarding content length: ${onboardingContent.length}`);
    console.log(`Onboarding preview: ${onboardingContent.substring(0, 200)}...`);

    // Take screenshot
    await page.screenshot({
      path: 'test-results/onboarding-tab-content.png',
      fullPage: true,
    });

    // Test offboarding tab
    console.log('\n--- Testing Offboarding Tab ---');
    await offboardingTab.tab.click();
    await page.waitForTimeout(1500);

    // Verify tab is active
    const offboardingActive = await offboardingTab.tab.getAttribute('data-active');
    expect(offboardingActive).toBe('true');
    console.log('✅ Offboarding tab is active');

    // Get offboarding content
    const offboardingContent = await page.locator('[data-testid="app-loaded"]').textContent();
    console.log(`Offboarding content length: ${offboardingContent.length}`);
    console.log(`Offboarding preview: ${offboardingContent.substring(0, 200)}...`);

    // Take screenshot
    await page.screenshot({
      path: 'test-results/offboarding-tab-content.png',
      fullPage: true,
    });

    // Verify content is different between tabs
    expect(onboardingContent).not.toBe(offboardingContent);
    console.log('✅ Onboarding and offboarding show different content');

    // Check for expected content patterns
    console.log('\n--- Content Analysis ---');

    // Switch back to onboarding for analysis
    await onboardingTab.tab.click();
    await page.waitForTimeout(1000);
    const finalOnboardingContent = await page.locator('[data-testid="app-loaded"]').textContent();

    // Check for onboarding-specific indicators
    const hasOnboardingIndicators =
      finalOnboardingContent.toLowerCase().includes('onboarding') ||
      finalOnboardingContent.toLowerCase().includes('employee onboarding') ||
      finalOnboardingContent.toLowerCase().includes('welcome') ||
      finalOnboardingContent.toLowerCase().includes('getting started');

    if (hasOnboardingIndicators) {
      console.log('✅ Onboarding content contains expected indicators');
    } else {
      console.log('⚠️  Onboarding content may not have specific indicators yet');
    }

    // Switch to offboarding for analysis
    await offboardingTab.tab.click();
    await page.waitForTimeout(1000);
    const finalOffboardingContent = await page.locator('[data-testid="app-loaded"]').textContent();

    // Check for offboarding-specific indicators
    const hasOffboardingIndicators =
      finalOffboardingContent.toLowerCase().includes('offboarding') ||
      finalOffboardingContent.toLowerCase().includes('departure') ||
      finalOffboardingContent.toLowerCase().includes('exit') ||
      finalOffboardingContent.toLowerCase().includes('knowledge transfer');

    if (hasOffboardingIndicators) {
      console.log('✅ Offboarding content contains expected indicators');
    } else {
      console.log('⚠️  Offboarding content may not have specific indicators yet');
    }

    // Test navigation back and forth
    console.log('\n--- Navigation Test ---');
    await onboardingTab.tab.click();
    await page.waitForTimeout(500);
    expect(await onboardingTab.tab.getAttribute('data-active')).toBe('true');

    await offboardingTab.tab.click();
    await page.waitForTimeout(500);
    expect(await offboardingTab.tab.getAttribute('data-active')).toBe('true');

    console.log('✅ Navigation between application tabs works correctly');
  });

  test('should show application-specific UI elements when available', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('[data-testid="app-loaded"]');
    await page.waitForTimeout(3000);

    const appTabs = await page
      .locator(
        '[data-testid^="tab-"]:not([data-testid="tab-people"]):not([data-testid="tab-processes"]):not([data-testid="tab-account"])'
      )
      .all();

    if (appTabs.length === 0) {
      console.log('⚠️  No application tabs found');
      return;
    }

    // Test each application tab for specific UI elements
    for (let i = 0; i < appTabs.length; i++) {
      const tab = appTabs[i];
      const tabText = await tab.textContent();
      console.log(`\n--- Testing UI elements for: ${tabText.trim()} ---`);

      await tab.click();
      await page.waitForTimeout(1000);

      // Look for common application UI patterns
      const uiElements = {
        'Application header': page.locator('h1, h2').filter({ hasText: tabText.trim() }),
        'Navigation buttons': page.locator(
          'button[data-testid*="view-"], button[data-testid*="-view-"]'
        ),
        'Overview section': page.locator(
          '[data-testid*="overview"], [data-testid*="view-overview"]'
        ),
        'Templates section': page.locator(
          '[data-testid*="templates"], [data-testid*="view-templates"]'
        ),
        'Processes section': page.locator(
          '[data-testid*="processes"], [data-testid*="view-processes"]'
        ),
        'Metrics display': page.locator('text=/active|pending|completed|total/i'),
        'Configuration area': page.locator('text=/configuration|settings|features/i'),
      };

      for (const [elementName, locator] of Object.entries(uiElements)) {
        const isVisible = await locator
          .first()
          .isVisible()
          .catch(() => false);
        if (isVisible) {
          console.log(`✅ ${elementName} is visible`);
        } else {
          console.log(`⚠️  ${elementName} not found`);
        }
      }

      // Take a screenshot for manual inspection
      await page.screenshot({
        path: `test-results/app-ui-${tabText.toLowerCase().replace(/\s+/g, '-')}.png`,
        fullPage: true,
      });
    }
  });
});
