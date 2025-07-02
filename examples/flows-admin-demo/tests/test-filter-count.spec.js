import { test, expect } from '@playwright/test';

test.describe('Filter Results Count', () => {
  test('should show correct filtered count in "Showing X of Y people" text', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('[data-testid="app-loaded"]');
    await page.waitForTimeout(3000);
    
    // Click the People tab
    await page.click('[data-testid="tab-people"]');
    await page.waitForTimeout(2000);
    
    // First, get the unfiltered total from stats cards (this should not change)
    const totalPeopleCard = await page.locator('dt:has-text("Total People")').locator('..').locator('dd').textContent();
    const totalPeople = parseInt(totalPeopleCard || '0');
    console.log(`📊 Total People (stats card): ${totalPeople}`);
    
    // Expected totals based on Hygge & Hvidløg demo data:
    // - Total People: 1000 (as confirmed in our earlier test)
    // - Active: ~677, Former: ~160, Future: ~163
    expect(totalPeople).toBe(1000);
    
    // Get initial "Showing X of Y" text (use first occurrence to avoid ambiguity)
    const initialShowingText = await page.locator('text=/Showing \\d+ of \\d+ people/').first().textContent();
    console.log(`📋 Initial showing text: ${initialShowingText}`);
    
    // Extract the "of Y" number from initial text
    const initialMatch = initialShowingText?.match(/Showing \d+ of (\d+) people/);
    const initialTotal = initialMatch ? parseInt(initialMatch[1]) : 0;
    console.log(`📈 Initial "of" count: ${initialTotal}`);
    
    // Apply Former filter
    const statusFilter = page.locator('select').first();
    await statusFilter.selectOption('former');
    await page.waitForTimeout(2000);
    console.log('✅ Former filter applied');
    
    // Get filtered "Showing X of Y" text
    const filteredShowingText = await page.locator('text=/Showing \\d+ of \\d+ people/').first().textContent();
    console.log(`📋 Filtered showing text: ${filteredShowingText}`);
    
    // Extract the "of Y" number from filtered text
    const filteredMatch = filteredShowingText?.match(/Showing \d+ of (\d+) people/);
    const filteredTotal = filteredMatch ? parseInt(filteredMatch[1]) : 0;
    console.log(`📈 Filtered "of" count: ${filteredTotal}`);
    
    // Verify the stats card still shows the full total (unchanged)
    const totalPeopleCardAfter = await page.locator('dt:has-text("Total People")').locator('..').locator('dd').textContent();
    const totalPeopleAfter = parseInt(totalPeopleCardAfter || '0');
    console.log(`📊 Total People after filter (stats card): ${totalPeopleAfter}`);
    
    // ASSERTIONS:
    // 1. Stats card should remain unchanged (shows unfiltered total)
    expect(totalPeopleAfter).toBe(totalPeople);
    console.log('✅ Stats card correctly shows unfiltered total');
    
    // 2. "Showing X of Y" should show filtered total (much smaller than 1000)
    expect(filteredTotal).toBeLessThan(totalPeople);
    expect(filteredTotal).toBeGreaterThan(0);
    console.log(`✅ "Showing X of Y" correctly shows filtered total: ${filteredTotal} < ${totalPeople}`);
    
    // 3. Filtered total should be reasonable for "Former" employees 
    // Based on 1000 total - 677 active - 163 future = ~160 former employees
    expect(filteredTotal).toBeLessThan(300); // Should be much less than 1000
    expect(filteredTotal).toBeGreaterThan(50); // But should have some former employees
    console.log(`✅ Filtered count is reasonable for Former employees: ${filteredTotal}`);
    
    // Clear filter and verify count goes back up
    await page.locator('button:has-text("Clear all")').click();
    await page.waitForTimeout(2000);
    console.log('✅ Filters cleared');
    
    const clearedShowingText = await page.locator('text=/Showing \\d+ of \\d+ people/').first().textContent();
    const clearedMatch = clearedShowingText?.match(/Showing \d+ of (\d+) people/);
    const clearedTotal = clearedMatch ? parseInt(clearedMatch[1]) : 0;
    console.log(`📈 Cleared "of" count: ${clearedTotal}`);
    
    // 4. After clearing, should show full total again (1000)
    expect(clearedTotal).toBe(1000);
    console.log('✅ After clearing filters, showing full total again');
    
    // Take screenshot
    await page.screenshot({ 
      path: 'test-results/filter-count-test.png', 
      fullPage: true 
    });
    
    console.log('✅ Filter count test completed successfully');
  });
  
  test('should show correct count when searching', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('[data-testid="app-loaded"]');
    await page.waitForTimeout(3000);
    
    // Click the People tab
    await page.click('[data-testid="tab-people"]');
    await page.waitForTimeout(2000);
    
    // Get search input
    const searchInput = page.locator('input[placeholder*="search" i], input[type="search"], input[placeholder*="name" i]').first();
    
    // Search for something specific
    await searchInput.fill('john');
    await page.waitForTimeout(1000); // Wait for debounce and search
    console.log('✅ Search applied');
    
    // Get search results count
    const searchResultsText = await page.locator('text=/Showing \\d+ of \\d+ people/').textContent();
    console.log(`📋 Search results text: ${searchResultsText}`);
    
    const searchMatch = searchResultsText?.match(/Showing \d+ of (\d+) people/);
    const searchTotal = searchMatch ? parseInt(searchMatch[1]) : 0;
    console.log(`📈 Search results total: ${searchTotal}`);
    
    // Search results should be much smaller than 1000
    expect(searchTotal).toBeLessThan(1000);
    expect(searchTotal).toBeGreaterThan(0);
    console.log('✅ Search results count is reasonable');
    
    console.log('✅ Search count test completed');
  });
});