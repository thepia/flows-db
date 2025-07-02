import { test, expect } from '@playwright/test';

test.describe('People Tab Functionality', () => {
  test('should show People tab content when People tab is clicked', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('[data-testid="app-loaded"]');
    await page.waitForTimeout(3000);
    
    // Click the People tab
    await page.click('[data-testid="tab-people"]');
    await page.waitForTimeout(1500);
    
    // Verify People tab is active
    const peopleTab = page.locator('[data-testid="tab-people"]');
    const isActive = await peopleTab.getAttribute('data-active');
    expect(isActive).toBe('true');
    console.log('✅ People tab is active');
    
    // Verify People view is visible
    const peopleView = page.locator('[data-testid="view-people"]');
    await expect(peopleView).toBeVisible();
    console.log('✅ People view is visible');
    
    // Check for People-specific components
    const peopleHeader = page.locator('h1:has-text("People")');
    await expect(peopleHeader).toBeVisible();
    console.log('✅ People header is visible');
    
    // Check for stats cards (should have employee counts)
    const statsCards = page.locator('.bg-white').filter({ hasText: 'Total People' });
    const hasStatsCards = await statsCards.count() > 0;
    console.log(`Stats cards found: ${hasStatsCards}`);
    
    // Take screenshot
    await page.screenshot({ 
      path: 'test-results/people-tab-content.png', 
      fullPage: true 
    });
    
    console.log('✅ People tab functionality test completed');
  });
  
  test('should navigate between People and Application tabs correctly', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('[data-testid="app-loaded"]');
    await page.waitForTimeout(3000);
    
    // Start with People tab
    await page.click('[data-testid="tab-people"]');
    await page.waitForTimeout(1000);
    await expect(page.locator('[data-testid="view-people"]')).toBeVisible();
    console.log('✅ People tab shows People view');
    
    // Switch to application tab
    const appTab = page.locator('[data-testid="tab-employee-onboarding"]');
    if (await appTab.isVisible()) {
      await appTab.click();
      await page.waitForTimeout(1000);
      
      // People view should not be visible
      await expect(page.locator('[data-testid="view-people"]')).not.toBeVisible();
      console.log('✅ Application tab hides People view');
      
      // Application content should be visible
      const content = await page.locator('[data-testid="app-loaded"]').textContent();
      expect(content).toContain('Employee Onboarding');
      console.log('✅ Application content is visible');
    }
    
    // Switch back to People tab
    await page.click('[data-testid="tab-people"]');
    await page.waitForTimeout(1000);
    await expect(page.locator('[data-testid="view-people"]')).toBeVisible();
    console.log('✅ Back to People view successfully');
    
    console.log('✅ Tab navigation test completed');
  });
});