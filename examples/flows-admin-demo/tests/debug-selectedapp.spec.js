import { test, expect } from '@playwright/test';

test.describe('Debug SelectedApp', () => {
  test('should capture console logs to debug selectedApp issue', async ({ page }) => {
    // Capture all console logs
    const consoleLogs = [];
    page.on('console', (msg) => {
      if (msg.text().includes('🔍') || msg.text().includes('🚀') || msg.text().includes('REACTIVITY')) {
        consoleLogs.push(msg.text());
      }
    });
    
    await page.goto('/');
    await page.waitForSelector('[data-testid="app-loaded"]');
    await page.waitForTimeout(3000);
    
    // Get application tabs
    const appTabs = await page.locator('[data-testid^="tab-"]:not([data-testid="tab-people"]):not([data-testid="tab-processes"]):not([data-testid="tab-account"])').all();
    
    if (appTabs.length === 0) {
      console.log('❌ No application tabs found');
      return;
    }
    
    console.log(`Found ${appTabs.length} application tabs`);
    
    // Click each tab and capture logs
    for (let i = 0; i < appTabs.length; i++) {
      const tab = appTabs[i];
      const tabText = await tab.textContent();
      const testId = await tab.getAttribute('data-testid');
      
      console.log(`\\nClicking tab ${i + 1}: "${tabText.trim()}" (${testId})`);
      await tab.click();
      await page.waitForTimeout(2000); // Wait for any reactive updates
    }
    
    // Print all captured console logs
    console.log('\\n--- Console Debug Logs ---');
    consoleLogs.forEach((log, index) => {
      console.log(`${index + 1}: ${log}`);
    });
    
    if (consoleLogs.length === 0) {
      console.log('⚠️  No debug logs captured - template might not be rendering');
    }
    
    console.log('\\n✅ Debug completed');
  });
});