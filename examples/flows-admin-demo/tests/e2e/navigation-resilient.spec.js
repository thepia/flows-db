import { test, expect } from '@playwright/test';
import { 
  setupNavigationTest, 
  waitForNavigation, 
  verifyNavigation, 
  getTestContext 
} from './helpers/navigation-test-data.js';

/**
 * Resilient Navigation Tests
 * 
 * These tests use a data-agnostic approach that won't break when demo content changes.
 * They rely on data-testid attributes and structural patterns rather than specific content.
 */

test.describe('Resilient Navigation Tests', () => {
  let testContext;
  
  test.beforeEach(async ({ page }) => {
    // Get test context with selectors
    testContext = getTestContext();
    
    // Optional: Use mocked data for consistent testing
    // await setupNavigationTest(page);
    
    // Navigate to app
    await page.goto('/');
    await waitForNavigation(page);
  });

  test('should have valid navigation structure', async ({ page }) => {
    const validation = await verifyNavigation(page);
    
    if (!validation.isValid) {
      console.error('Navigation structure errors:', validation.errors);
    }
    
    expect(validation.isValid).toBe(true);
  });

  test('should navigate between available tabs', async ({ page }) => {
    // Get all available tabs
    const tabs = await page.locator(testContext.selectors.tabs).all();
    expect(tabs.length).toBeGreaterThan(0);
    
    // Track visited tabs
    const visitedTabs = new Set();
    
    // Visit each tab
    for (const tab of tabs) {
      const tabId = await tab.getAttribute('data-testid');
      
      // Skip if already visited
      if (visitedTabs.has(tabId)) continue;
      
      // Click the tab
      await tab.click();
      
      // Verify it becomes active
      const isActive = await tab.getAttribute('data-active');
      expect(isActive).toBe('true');
      
      // Wait for content to load
      await page.waitForTimeout(100);
      
      // Verify some content is visible
      const viewContent = await page.locator('[data-testid^="view-"]').first();
      await expect(viewContent).toBeVisible();
      
      visitedTabs.add(tabId);
    }
    
    // Verify we visited at least 2 tabs (People + at least one app)
    expect(visitedTabs.size).toBeGreaterThanOrEqual(2);
  });

  test('should handle offboarding navigation if available', async ({ page }) => {
    // Try to find an offboarding tab
    const offboardingTab = await testContext.helpers.getOffboardingTab(page);
    
    if (await offboardingTab.count() === 0) {
      test.skip();
      return;
    }
    
    // Click the offboarding tab
    await offboardingTab.click();
    await page.waitForTimeout(200);
    
    // Check if offboarding views are available
    const offboardingViews = await page.locator('[data-testid^="offboarding-view-"]').all();
    
    if (offboardingViews.length > 0) {
      // Test navigation between views
      const viewsToTest = ['overview', 'templates', 'processes'];
      
      for (const viewName of viewsToTest) {
        const viewButton = page.locator(`[data-testid="offboarding-view-${viewName}"]`);
        
        if (await viewButton.count() > 0) {
          await viewButton.click();
          
          // Verify view is active
          const isActive = await viewButton.getAttribute('data-active');
          expect(isActive).toBe('true');
          
          // Verify content is visible
          await testContext.helpers.waitForViewTransition(page, `view-${viewName}`);
        }
      }
    }
  });

  test('should handle dashboard actions dynamically', async ({ page }) => {
    // Navigate to offboarding if available
    const offboardingTab = await testContext.helpers.getOffboardingTab(page);
    
    if (await offboardingTab.count() > 0) {
      await offboardingTab.click();
      await testContext.helpers.waitForViewTransition(page, 'view-overview');
      
      // Test metric cards if available
      const metricCards = await page.locator('[data-testid^="metric-"]').all();
      
      if (metricCards.length > 0) {
        // Click first available metric card
        const firstMetric = metricCards[0];
        const metricId = await firstMetric.getAttribute('data-testid');
        
        await firstMetric.click();
        
        // Verify navigation occurred (view changed)
        await page.waitForTimeout(200);
        
        // Check if we're no longer on overview
        const overviewVisible = await page.locator('[data-testid="view-overview"]').isVisible();
        expect(overviewVisible).toBe(false);
      }
      
      // Test quick filters if available
      const filters = await page.locator('[data-testid^="filter-"]').all();
      
      if (filters.length > 0) {
        // Go back to overview first
        const overviewButton = page.locator('[data-testid="offboarding-view-overview"]');
        if (await overviewButton.count() > 0) {
          await overviewButton.click();
          await testContext.helpers.waitForViewTransition(page, 'view-overview');
        }
        
        // Click first available filter
        const firstFilter = filters[0];
        await firstFilter.click();
        
        // Verify navigation occurred
        await page.waitForTimeout(200);
        const overviewVisible = await page.locator('[data-testid="view-overview"]').isVisible();
        expect(overviewVisible).toBe(false);
      }
    }
  });

  test('should maintain navigation state correctly', async ({ page }) => {
    // Get initial active tab
    const initialActiveTab = await page.locator(testContext.selectors.activeTab).first();
    const initialTabId = await initialActiveTab.getAttribute('data-testid');
    
    // Navigate to a different tab if available
    const otherTabs = await page.locator(`${testContext.selectors.tabs}:not([data-testid="${initialTabId}"])`).all();
    
    if (otherTabs.length > 0) {
      const targetTab = otherTabs[0];
      const targetTabId = await targetTab.getAttribute('data-testid');
      
      await targetTab.click();
      
      // Verify tab switched
      const newActiveTab = await page.locator(testContext.selectors.activeTab).first();
      const newTabId = await newActiveTab.getAttribute('data-testid');
      
      expect(newTabId).toBe(targetTabId);
      expect(newTabId).not.toBe(initialTabId);
    }
  });

  test('should handle keyboard navigation', async ({ page }) => {
    // Focus first tab
    const firstTab = await page.locator(testContext.selectors.tabs).first();
    await firstTab.focus();
    
    // Tab to next element
    await page.keyboard.press('Tab');
    
    // Check if focused element is a tab or button
    const focusedElement = await page.locator(':focus');
    const tagName = await focusedElement.evaluate(el => el.tagName.toLowerCase());
    
    expect(['button', 'a']).toContain(tagName);
  });

  test('should gracefully handle missing data', async ({ page }) => {
    // Even with no data, basic navigation structure should exist
    const peopleTab = await page.locator(testContext.selectors.peopleTab);
    await expect(peopleTab).toBeVisible();
    
    // Should handle clicks without errors
    await peopleTab.click();
    
    // Page should not show error state
    const errorIndicators = await page.locator('[class*="error"], [data-testid*="error"]').all();
    expect(errorIndicators.length).toBe(0);
  });
});

test.describe('Navigation Pattern Tests', () => {
  test('should follow consistent navigation patterns', async ({ page }) => {
    await page.goto('/');
    await waitForNavigation(page);
    
    const patterns = {
      // Tab pattern: all tabs should have consistent structure
      tabs: {
        selector: '[data-testid^="tab-"]',
        requiredAttributes: ['data-testid', 'data-active'],
        activeClass: 'border-blue-500'
      },
      
      // View pattern: all views should have consistent structure
      views: {
        selector: '[data-testid^="view-"]',
        requiredAttributes: ['data-testid']
      },
      
      // Action pattern: all actions should have consistent structure
      actions: {
        selector: '[data-testid^="action-"]',
        requiredAttributes: ['data-testid']
      }
    };
    
    // Verify patterns
    for (const [patternName, pattern] of Object.entries(patterns)) {
      const elements = await page.locator(pattern.selector).all();
      
      for (const element of elements) {
        // Check required attributes
        for (const attr of pattern.requiredAttributes) {
          const value = await element.getAttribute(attr);
          expect(value).toBeTruthy();
        }
        
        // Check active state styling if applicable
        if (pattern.activeClass) {
          const isActive = await element.getAttribute('data-active') === 'true';
          const classes = await element.getAttribute('class');
          
          if (isActive) {
            expect(classes).toContain(pattern.activeClass);
          }
        }
      }
    }
  });
});