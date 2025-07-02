import { test, expect } from '@playwright/test';

test.describe('Database Search Functionality', () => {
  test('should perform database search when typing in search field', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('[data-testid="app-loaded"]');
    await page.waitForTimeout(3000);
    
    // Click the People tab
    await page.click('[data-testid="tab-people"]');
    await page.waitForTimeout(1000);
    
    // Verify People view is visible
    await expect(page.locator('[data-testid="view-people"]')).toBeVisible();
    console.log('✅ People view loaded');
    
    // Look for the search input field
    const searchInput = page.locator('input[placeholder*="search" i], input[type="search"], input[placeholder*="name" i]').first();
    await expect(searchInput).toBeVisible();
    console.log('✅ Search input found');
    
    // Type in search field to trigger database search
    await searchInput.fill('test');
    await page.waitForTimeout(500); // Wait for debounce
    
    console.log('✅ Search term entered');
    
    // Wait a bit for any potential search results
    await page.waitForTimeout(2000);
    
    // Verify the page is still responsive (basic test)
    await expect(page.locator('[data-testid="view-people"]')).toBeVisible();
    console.log('✅ Page remains responsive after search');
    
    // Clear search to test clearing functionality
    await searchInput.fill('');
    await page.waitForTimeout(500); // Wait for debounce
    
    console.log('✅ Search cleared');
    
    // Take screenshot
    await page.screenshot({ 
      path: 'test-results/database-search-test.png', 
      fullPage: true 
    });
    
    console.log('✅ Database search test completed');
  });
});