import { test, expect } from '@playwright/test';

test('Debug application type detection', async ({ page }) => {
  // Navigate to the app
  await page.goto('/');
  await page.waitForLoadState('networkidle');
  
  // Wait for app to load
  await page.waitForSelector('[data-testid="app-loaded"]', { state: 'visible' });
  
  // Wait for any loading to complete
  await page.waitForTimeout(3000);
  
  // Get application data
  const appData = await page.evaluate(() => {
    // Access the Svelte stores directly
    const storesElement = document.querySelector('[data-testid="app-loaded"]');
    if (!storesElement || !storesElement.__svelte__) {
      return { error: 'Cannot access Svelte stores' };
    }
    
    // Try to get the applications data
    const component = storesElement.__svelte__;
    
    // Look for the applications store in component context
    return {
      activeTab: window.activeTab || 'unknown',
      applications: window.$applications || [],
      debugInfo: 'Check console for more details'
    };
  });
  
  console.log('Application data:', appData);
  
  // Click the offboarding tab
  await page.click('[data-testid="tab-knowledge-offboarding"]');
  await page.waitForTimeout(1000);
  
  // Check what's rendered
  const renderedContent = await page.evaluate(() => {
    const mainContent = document.querySelector('main');
    const hasViewOverview = document.querySelector('[data-testid="view-overview"]') !== null;
    const allDataTestIds = Array.from(document.querySelectorAll('[data-testid]')).map(el => el.getAttribute('data-testid'));
    
    return {
      hasViewOverview,
      mainContentLength: mainContent?.innerHTML?.length || 0,
      dataTestIds: allDataTestIds.filter(id => id && (id.includes('view') || id.includes('offboarding')))
    };
  });
  
  console.log('Rendered content after clicking offboarding:', renderedContent);
  
  // Check console logs
  const consoleLogs = [];
  page.on('console', msg => consoleLogs.push({ type: msg.type(), text: msg.text() }));
  
  // Reload and check console
  await page.reload();
  await page.waitForTimeout(2000);
  
  console.log('Console logs:', consoleLogs.filter(log => log.text.includes('app') || log.text.includes('offboarding')));
});