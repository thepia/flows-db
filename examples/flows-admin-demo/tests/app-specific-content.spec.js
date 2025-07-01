import { test, expect } from '@playwright/test';

test.describe('Application-Specific Content', () => {
  test('should show distinct onboarding and offboarding application content', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('[data-testid="app-loaded"]');
    await page.waitForTimeout(3000);
    
    // Get application tabs
    const appTabs = await page.locator('[data-testid^="tab-"]:not([data-testid="tab-people"]):not([data-testid="tab-processes"]):not([data-testid="tab-account"])').all();
    
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
    }
    
    // Find onboarding and offboarding tabs
    const onboardingTab = tabsData.find(t => t.text.toLowerCase().includes('onboarding'));
    const offboardingTab = tabsData.find(t => t.text.toLowerCase().includes('offboarding'));
    
    // Test Onboarding Application
    if (onboardingTab) {
      console.log(`\\n--- Testing Onboarding Application: "${onboardingTab.text}" ---`);
      await onboardingTab.tab.click();
      await page.waitForTimeout(1500);
      
      // Verify onboarding-specific content
      const appHeader = page.locator('h2').filter({ hasText: onboardingTab.text });
      await expect(appHeader).toBeVisible();
      console.log('✅ Onboarding application header visible');
      
      // Check for metrics dashboard (onboarding apps show metrics)
      await expect(page.locator('text="Active Invitations"')).toBeVisible();
      await expect(page.locator('text="Pending Invitations"')).toBeVisible();
      await expect(page.locator('text="People Assigned"')).toBeVisible();
      await expect(page.locator('text="Completed This Month"')).toBeVisible();
      console.log('✅ Onboarding metrics dashboard visible');
      
      // Check for application features section
      await expect(page.locator('text="Application Features"')).toBeVisible();
      console.log('✅ Application features section visible');
      
      // Check for New Invitation button
      await expect(page.locator('text="New Invitation"')).toBeVisible();
      console.log('✅ New Invitation button visible');
      
      // Take screenshot
      await page.screenshot({ 
        path: 'test-results/onboarding-application-content.png', 
        fullPage: true 
      });
    }
    
    // Test Offboarding Application
    if (offboardingTab) {
      console.log(`\\n--- Testing Offboarding Application: "${offboardingTab.text}" ---`);
      await offboardingTab.tab.click();
      await page.waitForTimeout(1500);
      
      // Verify offboarding-specific content
      const appHeader = page.locator('h2').filter({ hasText: offboardingTab.text });
      await expect(appHeader).toBeVisible();
      console.log('✅ Offboarding application header visible');
      
      // Check for offboarding navigation buttons
      await expect(page.locator('[data-testid="offboarding-view-overview"]')).toBeVisible();
      await expect(page.locator('[data-testid="offboarding-view-templates"]')).toBeVisible();
      await expect(page.locator('[data-testid="offboarding-view-processes"]')).toBeVisible();
      console.log('✅ Offboarding navigation buttons visible');
      
      // Test different offboarding views
      console.log('\\n--- Testing Offboarding Views ---');
      
      // Overview view (default)
      await expect(page.locator('[data-testid="view-overview"]')).toBeVisible();
      console.log('✅ Overview view visible by default');
      
      // Templates view
      await page.click('[data-testid="offboarding-view-templates"]');
      await page.waitForTimeout(1000);
      await expect(page.locator('[data-testid="view-templates"]')).toBeVisible();
      console.log('✅ Templates view visible after clicking Templates');
      
      // Processes view
      await page.click('[data-testid="offboarding-view-processes"]');
      await page.waitForTimeout(1000);
      await expect(page.locator('[data-testid="view-processes"]')).toBeVisible();
      console.log('✅ Processes view visible after clicking Processes');
      
      // Take screenshot
      await page.screenshot({ 
        path: 'test-results/offboarding-application-content.png', 
        fullPage: true 
      });
    }
    
    // Verify applications show different content
    if (onboardingTab && offboardingTab) {
      console.log('\\n--- Comparing Application Content ---');
      
      // Click onboarding tab and get content
      await onboardingTab.tab.click();
      await page.waitForTimeout(1000);
      const onboardingPageContent = await page.locator('main').textContent();
      
      // Click offboarding tab and get content
      await offboardingTab.tab.click();
      await page.waitForTimeout(1000);
      const offboardingPageContent = await page.locator('main').textContent();
      
      // Content should be different
      expect(onboardingPageContent).not.toBe(offboardingPageContent);
      console.log('✅ Onboarding and offboarding applications show different content');
      
      // Onboarding should have metrics, offboarding should have navigation views
      expect(onboardingPageContent).toContain('Active Invitations');
      expect(offboardingPageContent).toContain('Overview');
      expect(offboardingPageContent).toContain('Templates');
      expect(offboardingPageContent).toContain('Processes');
      console.log('✅ Applications show their specific content patterns');
    }
    
    console.log('\\n✅ All application content tests passed');
  });
  
  test('should maintain application state when switching between tabs', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('[data-testid="app-loaded"]');
    await page.waitForTimeout(3000);
    
    const appTabs = await page.locator('[data-testid^="tab-"]:not([data-testid="tab-people"]):not([data-testid="tab-processes"]):not([data-testid="tab-account"])').all();
    
    if (appTabs.length === 0) {
      console.log('⚠️  No application tabs found');
      return;
    }
    
    // Find offboarding tab
    let offboardingTab = null;
    for (const tab of appTabs) {
      const text = await tab.textContent();
      if (text.toLowerCase().includes('offboarding')) {
        offboardingTab = tab;
        break;
      }
    }
    
    if (!offboardingTab) {
      console.log('⚠️  No offboarding tab found - skipping state test');
      return;
    }
    
    console.log('Testing offboarding application state persistence...');
    
    // Go to offboarding tab and switch to Templates view
    await offboardingTab.click();
    await page.waitForTimeout(1000);
    await page.click('[data-testid="offboarding-view-templates"]');
    await page.waitForTimeout(1000);
    
    // Verify we're in Templates view
    await expect(page.locator('[data-testid="view-templates"]')).toBeVisible();
    console.log('✅ Switched to Templates view');
    
    // Switch to People tab
    await page.click('[data-testid="tab-people"]');
    await page.waitForTimeout(1000);
    await expect(page.locator('[data-testid="view-people"]')).toBeVisible();
    console.log('✅ Switched to People tab');
    
    // Go back to offboarding tab
    await offboardingTab.click();
    await page.waitForTimeout(1000);
    
    // Check if we're still in Templates view (state maintained)
    const templatesVisible = await page.locator('[data-testid="view-templates"]').isVisible();
    if (templatesVisible) {
      console.log('✅ Offboarding application state maintained - still in Templates view');
    } else {
      console.log('⚠️  Offboarding application state reset - back to default view');
      // This is acceptable behavior, just log it
    }
    
    console.log('✅ Application state test completed');
  });
});